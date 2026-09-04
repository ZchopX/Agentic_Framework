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

Non-interactive install/refresh of the econometric team (skips the team
prompt; -Yes alone defaults to Programming, no econ files):
  pwsh -File install-agentic-framework.ps1 -Yes -Team Econometric
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$SourceUrl = "https://github.com/ZchopX/Agentic_Framework.git",
    [switch]$Yes,
    [ValidateSet('Programming', 'Econometric')]
    [string]$Team = ""
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

function Copy-MatchingFilesIfChanged {
    # Copies only files matching $Pattern from $Source into $Destination,
    # without robocopy /MIR - unlike Copy-DirectoryIfChanged, this never
    # deletes anything already in $Destination. Used for locked files (like
    # the econ-*.md agent definitions) landing in a general-purpose directory
    # (.claude/agents, .agents/agents) that a target repo may already have
    # unrelated content in; a directory mirror there would silently delete it.
    param(
        [string]$Source,
        [string]$Destination,
        [string]$Pattern
    )

    if (-not (Test-Path -LiteralPath $Destination)) {
        if (-not $PSCmdlet.ShouldProcess($Destination, "Create directory")) {
            return "skipped"
        }
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    }
    if (-not $PSCmdlet.ShouldProcess($Destination, "Copy $Pattern from $Source")) {
        return "skipped"
    }
    robocopy $Source $Destination $Pattern /NFL /NDL /NJH /NJS | Out-Null
    if ($LASTEXITCODE -ge 8) {
        throw "robocopy failed with code $LASTEXITCODE syncing $Pattern from $Source -> $Destination"
    }
    return $(if ($LASTEXITCODE -eq 0) { "unchanged" } else { "synced" })
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

function Get-NormalizedRepoUrl {
    param([string]$Url)
    ($Url.TrimEnd('/') -replace '\.git$', '').ToLowerInvariant()
}

function Test-SymlinkTarget {
    # Returns $true only if $Item is a symlink whose resolved target matches
    # $ExpectedPath. Used to distinguish a valid existing symlink from a
    # stale one (pointing at a moved/renamed source) that must be recreated.
    param($Item, [string]$ExpectedPath)
    if (-not $Item -or $Item.LinkType -ne "SymbolicLink") {
        return $false
    }
    $target = $Item.Target | Select-Object -First 1
    if (-not $target) {
        return $false
    }
    $resolvedTarget = (Resolve-Path -LiteralPath $target -ErrorAction SilentlyContinue).Path
    if (-not $resolvedTarget) {
        return $false
    }
    # No -ErrorAction here: matches the original inline code's behavior of
    # letting a missing $ExpectedPath throw (it always exists by this point
    # in real invocations - only unreachable under -WhatIf).
    $resolvedExpected = (Resolve-Path -LiteralPath $ExpectedPath).Path
    return ($resolvedTarget -eq $resolvedExpected)
}

if ($MyInvocation.InvocationName -eq '.') { return }

$report = New-Object System.Collections.Generic.List[string]

# --- 2. Safety guards ---------------------------------------------------

$cwd = (Get-Location).Path
if (-not (Test-Path (Join-Path $cwd ".git"))) {
    Write-Error "Not a git repository. Run this script from the root of the git repository you want to install into."
    exit 1
}

$originUrl = (& git remote get-url origin 2>$null)
if ($LASTEXITCODE -eq 0 -and $originUrl) {
    if ((Get-NormalizedRepoUrl $originUrl) -eq (Get-NormalizedRepoUrl $SourceUrl)) {
        Write-Error "This script installs Agentic_Framework *into* other repos - it looks like you're running it from inside Agentic_Framework itself."
        exit 1
    }
}

# --- 2b. Team selection ---------------------------------------------------

if ([string]::IsNullOrEmpty($Team)) {
    if ($Yes) {
        $Team = "Programming"
    } else {
        Write-Host ""
        Write-Host "Which team should this repo install?"
        Write-Host "  [1] Programming (default) - skills only, no econometric agents/schema"
        Write-Host "  [2] Econometric - adds the econ-* agent team, model-test-pipeline skill, and the econometric-verified schema"
        $teamPicked = $null
        while ($null -eq $teamPicked) {
            $teamAnswer = Read-Host "Enter 1/Programming or 2/Econometric (Enter = Programming)"
            switch -Regex ($teamAnswer.Trim()) {
                '^(1|)$'            { $teamPicked = "Programming" }
                '^(?i)programming$' { $teamPicked = "Programming" }
                '^2$'                { $teamPicked = "Econometric" }
                '^(?i)econometric$' { $teamPicked = "Econometric" }
                default              { Write-Host "Could not parse '$teamAnswer' - enter 1, 2, Programming, or Econometric." }
            }
        }
        $Team = $teamPicked
    }
}
$report.Add("Team: $Team")

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
    if ($Team -eq "Econometric" -and -not $selected.Contains("model-test-pipeline")) {
        $selected.Add("model-test-pipeline")
    }

    foreach ($name in ($selected | Select-Object -Unique)) {
        $src = $tagged | Where-Object { $_.Name -eq $name } | Select-Object -First 1 -ExpandProperty Source
        if (-not $src) { $src = Join-Path $sourceSkillsRoot $name }

        $agentsDst = Join-Path $targetSkillsRoot $name
        $agentsResult = Copy-DirectoryIfChanged -Source $src -Destination $agentsDst

        $claudeDst = Join-Path $claudeSkillsRoot $name
        $linkStatus = "unchanged"
        $existingItem = Get-Item -LiteralPath $claudeDst -ErrorAction SilentlyContinue

        $isCorrectSymlink = Test-SymlinkTarget -Item $existingItem -ExpectedPath $agentsDst
        if ($existingItem -and $existingItem.LinkType -eq "SymbolicLink" -and -not $isCorrectSymlink) {
            # Stale symlink pointing at the wrong target - remove and recreate below.
            if ($PSCmdlet.ShouldProcess($claudeDst, "Recreate stale symlink")) {
                Remove-Item -LiteralPath $claudeDst -Force
            }
            $existingItem = $null
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

    # --- 7b. Econometric team locked files (agents + schema) --------------

    $econSchemaInstalledThisRun = $false
    if ($Team -eq "Econometric") {
        $econClaudeAgentsSrc = Join-Path $tempDir ".claude\agents"
        $econClaudeAgentsDst = Join-Path $cwd ".claude\agents"
        if (Test-Path -LiteralPath $econClaudeAgentsSrc) {
            $result = Copy-MatchingFilesIfChanged -Source $econClaudeAgentsSrc -Destination $econClaudeAgentsDst -Pattern "econ-*.md"
            $report.Add(".claude/agents (econ team): $result")
        } else {
            $report.Add(".claude/agents (econ team): not found in source, skipped")
        }

        $econCodexAgentsSrc = Join-Path $tempDir ".agents\agents"
        $econCodexAgentsDst = Join-Path $cwd ".agents\agents"
        if (Test-Path -LiteralPath $econCodexAgentsSrc) {
            $result = Copy-MatchingFilesIfChanged -Source $econCodexAgentsSrc -Destination $econCodexAgentsDst -Pattern "econ-*.md"
            $report.Add(".agents/agents (econ team, Codex): $result")
        } else {
            $report.Add(".agents/agents (econ team, Codex): not found in source, skipped")
        }

        $econSchemaSrc = Join-Path $tempDir "openspec\schemas\econometric-verified"
        $econSchemaDst = Join-Path $cwd "openspec\schemas\econometric-verified"
        if (Test-Path -LiteralPath $econSchemaSrc) {
            $result = Copy-DirectoryIfChanged -Source $econSchemaSrc -Destination $econSchemaDst
            $report.Add("openspec/schemas/econometric-verified: $result")
            $econSchemaInstalledThisRun = Test-Path -LiteralPath (Join-Path $econSchemaDst "schema.yaml")
        } else {
            $report.Add("openspec/schemas/econometric-verified: not found in source, skipped")
        }
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

    $defaultSchemaCandidate = if ($Team -eq "Econometric") { "econometric-verified" } else { "spec-driven-verified" }
    $schemaInstalled = if ($Team -eq "Econometric") {
        $econSchemaInstalledThisRun
    } else {
        Test-Path -LiteralPath (Join-Path $env:LOCALAPPDATA "openspec\schemas\spec-driven-verified")
    }

    if ((Test-Path -LiteralPath $openspecConfigPath)) {
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
                $doSet = $Yes -or $PSCmdlet.ShouldContinue("Set openspec/config.yaml default schema to '$defaultSchemaCandidate' (currently: $current)?", "Set default OpenSpec schema")
                if ($doSet) {
                    $lines[$matchIndex] = "schema: $defaultSchemaCandidate"
                    Set-Content -LiteralPath $openspecConfigPath -Value $lines
                    $report.Add("Default schema: set to $defaultSchemaCandidate")
                } else {
                    $report.Add("Default schema: skipped - declined")
                }
            }
        } else {
            $report.Add("Default schema: skipped - $defaultSchemaCandidate schema not installed")
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
