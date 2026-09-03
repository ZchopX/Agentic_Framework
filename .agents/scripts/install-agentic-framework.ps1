<#
Copy this single file into any other Windows git repo and run it there to
pull in Agentic_Framework's .agents/ scaffolding, skills, and OpenSpec
pieces. Re-running it later refreshes whatever was previously installed -
this is both the installer and the updater, no separate mode.

Recommended invocation (no persistent execution-policy change):
  powershell -ExecutionPolicy Bypass -File install-agentic-framework.ps1
  pwsh -ExecutionPolicy Bypass -File install-agentic-framework.ps1

Non-interactive refresh (skip prompts, use currently-installed skill set):
  pwsh -File install-agentic-framework.ps1 -Yes
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$SourceUrl = "https://github.com/ZchopX/Agentic_Framework.git",
    [switch]$Yes
)

$ErrorActionPreference = "Stop"

function Invoke-Native {
    # Native commands (git, npm, openspec, ccc) write normal progress output
    # to stderr; with $ErrorActionPreference = "Stop" that becomes a
    # terminating error under powershell.exe 5.1, even on success. Run native
    # calls with EAP relaxed to Continue and check $LASTEXITCODE instead.
    # Output is captured (not discarded) so a failure can be diagnosed.
    param([scriptblock]$Command)
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & $Command 2>&1 | Out-String -Stream
    } finally {
        $ErrorActionPreference = $prev
    }
}

function Get-CommandStatus {
    param([string]$Name)
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    [pscustomobject]@{
        Name   = $Name
        Found  = $null -ne $cmd
        Source = if ($cmd) { $cmd.Source } else { "" }
    }
}

function Get-FileHashHex {
    # Pure .NET SHA256, not the Get-FileHash cmdlet: on a machine with both
    # PowerShell 7 and Windows PowerShell 5.1 installed, PS7's own
    # Microsoft.PowerShell.Utility module can shadow the Desktop-edition one
    # in $env:PSModulePath, causing Get-FileHash to silently fail to autoload
    # under powershell.exe 5.1.
    param([string]$Path)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $stream = [System.IO.File]::OpenRead($Path)
        try {
            return [System.BitConverter]::ToString($sha256.ComputeHash($stream)).Replace('-', '')
        } finally {
            $stream.Dispose()
        }
    } finally {
        $sha256.Dispose()
    }
}

function Compare-DirectoryContent {
    param(
        [string]$Source,
        [string]$Destination
    )

    if (-not (Test-Path -LiteralPath $Destination)) {
        return "missing"
    }

    $sourceFiles = Get-ChildItem -LiteralPath $Source -Recurse -File | ForEach-Object {
        [pscustomobject]@{
            RelativePath = $_.FullName.Substring($Source.Length).TrimStart('\', '/')
            Hash         = Get-FileHashHex -Path $_.FullName
        }
    }
    $destFiles = Get-ChildItem -LiteralPath $Destination -Recurse -File | ForEach-Object {
        [pscustomobject]@{
            RelativePath = $_.FullName.Substring($Destination.Length).TrimStart('\', '/')
            Hash         = Get-FileHashHex -Path $_.FullName
        }
    }

    $diff = Compare-Object -ReferenceObject $sourceFiles -DifferenceObject $destFiles -Property RelativePath, Hash
    if ($diff) {
        return "different"
    }
    return "identical"
}

function Add-IgnoreLine {
    param(
        [string]$GitIgnorePath,
        [string]$Line
    )

    if (-not (Test-Path -LiteralPath $GitIgnorePath)) {
        Set-Content -LiteralPath $GitIgnorePath -Value $Line
        return $true
    }

    $existing = Get-Content -LiteralPath $GitIgnorePath -ErrorAction SilentlyContinue
    if ($existing | Select-String -SimpleMatch -Pattern $Line -CaseSensitive) {
        return $false
    }

    Add-Content -LiteralPath $GitIgnorePath -Value $Line
    return $true
}

function Copy-DirectoryIfChanged {
    param(
        [string]$Source,
        [string]$Destination
    )

    $state = Compare-DirectoryContent -Source $Source -Destination $Destination
    if ($state -eq "identical") {
        return "unchanged"
    }
    if (-not $PSCmdlet.ShouldProcess($Destination, "Copy from $Source")) {
        return $state
    }
    robocopy $Source $Destination /MIR /NFL /NDL /NJH /NJS | Out-Null
    if ($LASTEXITCODE -ge 8) {
        throw "robocopy failed with code $LASTEXITCODE syncing $Source -> $Destination"
    }
    return $(if ($state -eq "missing") { "installed" } else { "updated" })
}

$report = New-Object System.Collections.Generic.List[string]

# --- 2. Safety guards ---------------------------------------------------

$cwd = (Get-Location).Path
if (-not (Test-Path (Join-Path $cwd ".git"))) {
    Write-Error "Not a git repository. Run this script from the root of the git repository you want to install into."
    exit 1
}

$originUrl = (& git remote get-url origin 2>$null)
if ($LASTEXITCODE -eq 0 -and $originUrl) {
    $normalize = { param($u) ($u.TrimEnd('/') -replace '\.git$', '').ToLowerInvariant() }
    if ((& $normalize $originUrl) -eq (& $normalize $SourceUrl)) {
        Write-Error "This script installs Agentic_Framework *into* other repos - it looks like you're running it from inside Agentic_Framework itself."
        exit 1
    }
}

# --- 3. Clone the source repo to a temp dir ------------------------------

$gitCmd = Get-CommandStatus "git"
if (-not $gitCmd.Found) {
    Write-Error "git is required and was not found on PATH."
    exit 1
}

$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("agentic-framework-" + [System.Guid]::NewGuid().ToString("N"))

try {
    $cloneOutput = Invoke-Native { & git clone --depth 1 $SourceUrl $tempDir }
    if ($LASTEXITCODE -ne 0) {
        Write-Host ($cloneOutput -join "`n")
        throw "git clone failed for $SourceUrl (exit code $LASTEXITCODE)"
    }

    # --- 4. OpenSpec init (step 1) --------------------------------------

    $openspecCmd = Get-CommandStatus "openspec"
    $openspecAvailable = $openspecCmd.Found
    if ($openspecAvailable) {
        $report.Add("OpenSpec CLI: found at $($openspecCmd.Source)")
    } else {
        $npmCmd = Get-CommandStatus "npm"
        if ($npmCmd.Found) {
            $doInstall = $Yes -or $PSCmdlet.ShouldContinue("Install the OpenSpec CLI now via 'npm install -g @fission-ai/openspec'?", "OpenSpec CLI not found")
            if ($doInstall) {
                $npmOutput = Invoke-Native { & npm install -g @fission-ai/openspec }
                if ($LASTEXITCODE -eq 0) {
                    $openspecCmd = Get-CommandStatus "openspec"
                    $openspecAvailable = $openspecCmd.Found
                    $report.Add("OpenSpec CLI: installed via npm")
                } else {
                    Write-Host ($npmOutput -join "`n")
                    $report.Add("OpenSpec CLI: npm install failed (exit code $LASTEXITCODE)")
                }
            }
        }
        if (-not $openspecAvailable) {
            $report.Add("OpenSpec init: skipped - openspec CLI not available")
        }
    }

    $openspecConfigPath = Join-Path $cwd "openspec\config.yaml"
    if ($openspecAvailable) {
        if (Test-Path -LiteralPath $openspecConfigPath) {
            $report.Add("OpenSpec init: already initialized")
        } else {
            $initOutput = Invoke-Native { & openspec init --tools "claude,codex" --no-animation }
            if ($LASTEXITCODE -eq 0) {
                $report.Add("OpenSpec init: initialized")
            } else {
                Write-Host ($initOutput -join "`n")
                $report.Add("OpenSpec init: failed (exit code $LASTEXITCODE)")
            }
        }
    }

    # --- 5. Copy .agents/ structure (step 3) ----------------------------

    foreach ($dir in @("templates", "states", "start", "reference")) {
        $src = Join-Path $tempDir ".agents\$dir"
        $dst = Join-Path $cwd ".agents\$dir"
        if (Test-Path -LiteralPath $src) {
            $result = Copy-DirectoryIfChanged -Source $src -Destination $dst
            $report.Add(".agents/${dir}: $result")
        } else {
            $report.Add(".agents/${dir}: not found in source, skipped")
        }
    }

    foreach ($dir in @("plans", "reports", "reviews")) {
        $dst = Join-Path $cwd ".agents\$dir"
        if (-not (Test-Path -LiteralPath $dst)) {
            if ($PSCmdlet.ShouldProcess($dst, "Create empty directory")) {
                New-Item -ItemType Directory -Path $dst -Force | Out-Null
            }
            $report.Add(".agents/${dir}: created")
        } else {
            $report.Add(".agents/${dir}: already exists")
        }
    }

    # --- 6. .gitignore entry ---------------------------------------------

    $gitignorePath = Join-Path $cwd ".gitignore"
    if ($PSCmdlet.ShouldProcess($gitignorePath, "Ensure .claude/settings.local.json is ignored")) {
        $added = Add-IgnoreLine -GitIgnorePath $gitignorePath -Line ".claude/settings.local.json"
        $report.Add(".gitignore: " + $(if ($added) { "added .claude/settings.local.json" } else { "already present" }))
    }

    # --- 7. Skill selection and install (steps 4-5) ----------------------

    $sourceSkillsRoot = Join-Path $tempDir ".agents\skills"
    $targetSkillsRoot = Join-Path $cwd ".agents\skills"
    $claudeSkillsRoot = Join-Path $cwd ".claude\skills"

    $candidates = if (Test-Path -LiteralPath $sourceSkillsRoot) {
        Get-ChildItem -LiteralPath $sourceSkillsRoot -Directory |
            Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName "SKILL.md") }
    } else {
        $report.Add("Skills: skipped - .agents/skills not found in source")
        @()
    }

    $tagged = foreach ($c in $candidates) {
        $dst = Join-Path $targetSkillsRoot $c.Name
        $state = Compare-DirectoryContent -Source $c.FullName -Destination $dst
        $tag = switch ($state) {
            "missing"   { "new" }
            "identical" { "installed-up-to-date" }
            "different" { "installed-update-available" }
        }
        [pscustomobject]@{ Name = $c.Name; Source = $c.FullName; Tag = $tag }
    }

    $selected = New-Object System.Collections.Generic.List[string]

    if ($Yes) {
        foreach ($t in $tagged) {
            if ($t.Tag -ne "new") { $selected.Add($t.Name) }
        }
    } else {
        Write-Host ""
        Write-Host "Available skills (pre-ticked = currently installed):"
        $index = 1
        $indexed = foreach ($t in $tagged) {
            $mark = if ($t.Tag -ne "new") { "x" } else { " " }
            Write-Host ("  [{0}] {1,2}. {2}  [{3}]" -f $mark, $index, $t.Name, $t.Tag)
            [pscustomobject]@{ Index = $index; Name = $t.Name; Preticked = ($t.Tag -ne "new") }
            $index++
        }

        $defaultSet = ($indexed | Where-Object { $_.Preticked }).Name
        $picked = $null
        while ($null -eq $picked) {
            $answer = Read-Host "Enter comma-separated numbers, 'all', or press Enter to accept the pre-ticked set"

            if ([string]::IsNullOrWhiteSpace($answer)) {
                $picked = @($defaultSet)
            } elseif ($answer.Trim() -ieq "all") {
                $picked = @($tagged.Name)
            } else {
                $attempt = New-Object System.Collections.Generic.List[string]
                $valid = $true
                foreach ($part in ($answer -split ",")) {
                    $num = 0
                    if ([int]::TryParse($part.Trim(), [ref]$num) -and $num -ge 1 -and $num -le $indexed.Count) {
                        $attempt.Add(($indexed | Where-Object { $_.Index -eq $num }).Name)
                    } else {
                        $valid = $false
                    }
                }
                if ($valid -and $attempt.Count -gt 0) {
                    $picked = @($attempt)
                } else {
                    Write-Host "Could not parse '$answer' - enter numbers like '1,3,5', 'all', or press Enter."
                }
            }
        }
        foreach ($n in $picked) { $selected.Add($n) }
    }

    if (-not $selected.Contains("todo")) { $selected.Add("todo") }

    foreach ($name in ($selected | Select-Object -Unique)) {
        $src = $tagged | Where-Object { $_.Name -eq $name } | Select-Object -First 1 -ExpandProperty Source
        if (-not $src) { $src = Join-Path $sourceSkillsRoot $name }

        $agentsDst = Join-Path $targetSkillsRoot $name
        $agentsResult = Copy-DirectoryIfChanged -Source $src -Destination $agentsDst

        $claudeDst = Join-Path $claudeSkillsRoot $name
        $linkStatus = "unchanged"
        $existingItem = Get-Item -LiteralPath $claudeDst -ErrorAction SilentlyContinue

        $isCorrectSymlink = $false
        if ($existingItem -and $existingItem.LinkType -eq "SymbolicLink") {
            $existingTarget = $existingItem.Target | Select-Object -First 1
            $resolvedTarget = if ($existingTarget) { (Resolve-Path -LiteralPath $existingTarget -ErrorAction SilentlyContinue).Path } else { $null }
            $resolvedAgentsDst = (Resolve-Path -LiteralPath $agentsDst).Path
            $isCorrectSymlink = ($resolvedTarget -eq $resolvedAgentsDst)
            if (-not $isCorrectSymlink) {
                # Stale symlink pointing at the wrong target - remove and recreate below.
                if ($PSCmdlet.ShouldProcess($claudeDst, "Recreate stale symlink")) {
                    Remove-Item -LiteralPath $claudeDst -Force
                }
                $existingItem = $null
            }
        }

        if ($isCorrectSymlink) {
            $linkStatus = "symlinked (existing)"
        } elseif ($existingItem) {
            $copyState = Compare-DirectoryContent -Source $agentsDst -Destination $claudeDst
            if ($copyState -eq "identical") {
                $linkStatus = "copied (existing, up to date)"
            } else {
                if ($PSCmdlet.ShouldProcess($claudeDst, "Update copied skill")) {
                    robocopy $agentsDst $claudeDst /MIR /NFL /NDL /NJH /NJS | Out-Null
                    if ($LASTEXITCODE -ge 8) {
                        throw "robocopy failed with code $LASTEXITCODE syncing $agentsDst -> $claudeDst"
                    }
                }
                $linkStatus = "copied (updated)"
            }
        } else {
            if ($PSCmdlet.ShouldProcess($claudeDst, "Symlink to $agentsDst")) {
                New-Item -ItemType Directory -Path (Split-Path $claudeDst -Parent) -Force | Out-Null
                try {
                    New-Item -ItemType SymbolicLink -Path $claudeDst -Target $agentsDst -ErrorAction Stop | Out-Null
                    $linkStatus = "symlinked"
                } catch {
                    Copy-Item -LiteralPath $agentsDst -Destination $claudeDst -Recurse -Force
                    $linkStatus = "copied (enable Developer Mode or run as admin for symlinks)"
                }
            }
        }

        $report.Add("Skill ${name}: $agentsResult, .claude/skills = $linkStatus")
    }

    # --- 8. OpenSpec schema/skill install (step 6) ------------------------

    $openspecModDir = Join-Path $tempDir "openspec-mod"
    if (Test-Path -LiteralPath $openspecModDir) {
        $syncScript = Join-Path $tempDir ".agents\scripts\sync-openspec-skills.ps1"
        $prevEap = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        try { & $syncScript -Targets All } finally { $ErrorActionPreference = $prevEap }
        $report.Add("OpenSpec schema/skill: sync-openspec-skills.ps1 invoked (see output above)")
    } else {
        $report.Add("OpenSpec schema/skill: skipped - openspec-mod/ not found in this clone")
    }

    # --- 9. CocoIndex indexing (Decision 19) ------------------------------

    $cccCmd = Get-CommandStatus "ccc"
    if (-not $cccCmd.Found) {
        Write-Host "Install cocoindex-code globally, then run: ccc index"
        $report.Add("CocoIndex: skipped - ccc not found")
    } else {
        $cocoindexGlobalSettings = Join-Path $HOME ".cocoindex_code\global_settings.yml"
        if (-not (Test-Path -LiteralPath $cocoindexGlobalSettings)) {
            Write-Host 'CocoIndex global settings missing - run `ccc init` first, then re-run this script'
            $report.Add("CocoIndex: skipped - ccc not initialized")
        } else {
            if ($PSCmdlet.ShouldProcess($gitignorePath, "Ensure .cocoindex_code/ is ignored")) {
                Add-IgnoreLine -GitIgnorePath $gitignorePath -Line ".cocoindex_code/" | Out-Null
            }
            Push-Location $cwd
            $prevEap = $ErrorActionPreference
            $ErrorActionPreference = "Continue"
            try {
                & ccc index
                if ($LASTEXITCODE -ne 0) {
                    $report.Add("CocoIndex: failed (exit code $LASTEXITCODE)")
                } else {
                    $report.Add("CocoIndex: indexed")
                }
            } finally {
                $ErrorActionPreference = $prevEap
                Pop-Location
            }
        }
    }

    # --- 10. Set default schema (step 7) ----------------------------------

    if ((Test-Path -LiteralPath $openspecConfigPath)) {
        $schemaInstalled = Test-Path -LiteralPath (Join-Path $env:LOCALAPPDATA "openspec\schemas\spec-driven-verified")
        if ($schemaInstalled) {
            $lines = Get-Content -LiteralPath $openspecConfigPath
            $matchIndex = -1
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match '^schema:\s*.*$') {
                    $matchIndex = $i
                    break
                }
            }
            if ($matchIndex -lt 0) {
                $report.Add("Default schema: skipped - schema: line not found - edit openspec/config.yaml manually")
            } else {
                $current = $lines[$matchIndex]
                $doSet = $Yes -or $PSCmdlet.ShouldContinue("Set openspec/config.yaml default schema to 'spec-driven-verified' (currently: $current)?", "Set default OpenSpec schema")
                if ($doSet) {
                    $lines[$matchIndex] = "schema: spec-driven-verified"
                    Set-Content -LiteralPath $openspecConfigPath -Value $lines
                    $report.Add("Default schema: set to spec-driven-verified")
                } else {
                    $report.Add("Default schema: skipped - declined")
                }
            }
        } else {
            $report.Add("Default schema: skipped - spec-driven-verified schema not installed")
        }
    } else {
        $report.Add("Default schema: skipped - no openspec/config.yaml")
    }
} finally {
    Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}

# --- 11. Summary report --------------------------------------------------

Write-Host ""
Write-Host "PowerShell: $($PSVersionTable.PSEdition) $($PSVersionTable.PSVersion)"
Write-Host ""
Write-Host "Install/update summary:"
foreach ($line in $report) {
    Write-Host "  $line"
}
