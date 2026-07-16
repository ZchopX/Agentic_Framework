param(
    [string]$TargetPath = ".",
    [switch]$SkipIndex,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

function Get-CommandStatus {
    param([string]$Name)
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    [pscustomobject]@{
        Name = $Name
        Found = $null -ne $cmd
        Source = if ($cmd) { $cmd.Source } else { "" }
    }
}

function Add-IgnoreEntry {
    param(
        [string]$GitIgnorePath,
        [string]$Entry
    )

    if (-not (Test-Path -LiteralPath $GitIgnorePath)) {
        New-Item -ItemType File -Path $GitIgnorePath | Out-Null
    }

    $lines = Get-Content -LiteralPath $GitIgnorePath -ErrorAction SilentlyContinue
    if ($lines -notcontains $Entry) {
        Add-Content -LiteralPath $GitIgnorePath -Value $Entry
        return $true
    }

    return $false
}

function Copy-StartupFile {
    param(
        [string]$Source,
        [string]$Destination,
        [switch]$Force
    )

    if (-not (Test-Path -LiteralPath $Destination)) {
        Copy-Item -LiteralPath $Source -Destination $Destination
        return "copied"
    }

    $sourceHash = (Get-FileHash -LiteralPath $Source -Algorithm SHA256).Hash
    $destHash = (Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash
    if ($sourceHash -eq $destHash) {
        return "unchanged"
    }

    if ($Force) {
        Copy-Item -LiteralPath $Source -Destination $Destination -Force
        return "overwritten"
    }

    return "skipped-different"
}

$target = Resolve-Path -LiteralPath $TargetPath
$tools = @(
    Get-CommandStatus "git"
    Get-CommandStatus "ccc"
    Get-CommandStatus "rg"
    Get-CommandStatus "ast-grep"
)

Write-Host "Tool check:"
foreach ($tool in $tools) {
    if ($tool.Found) {
        Write-Host "  OK      $($tool.Name) $($tool.Source)"
    } else {
        Write-Host "  MISSING $($tool.Name)"
    }
}

if (-not ($tools | Where-Object { $_.Name -eq "git" }).Found) {
    throw "git is required to locate the target worktree."
}

$repoRoot = (& git -C $target rev-parse --show-toplevel 2>$null)
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($repoRoot)) {
    throw "Target path is not inside a git worktree: $target"
}

$repoRoot = (Resolve-Path -LiteralPath $repoRoot).Path
$startSource = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\start")
$startTarget = Join-Path $repoRoot ".agents\start"
New-Item -ItemType Directory -Path $startTarget -Force | Out-Null

$changed = New-Object System.Collections.Generic.List[string]
$gitignore = Join-Path $repoRoot ".gitignore"
foreach ($entry in @(".cocoindex_code/", ".serena/")) {
    if (Add-IgnoreEntry -GitIgnorePath $gitignore -Entry $entry) {
        $changed.Add(".gitignore: added $entry")
    }
}

foreach ($file in @("onboard-repo.prompt.md", "README.md")) {
    $result = Copy-StartupFile `
        -Source (Join-Path $startSource $file) `
        -Destination (Join-Path $startTarget $file) `
        -Force:$Force
    if ($result -ne "unchanged") {
        $changed.Add(".agents/start/${file}: $result")
    }
}

$ccc = $tools | Where-Object { $_.Name -eq "ccc" }
if ($ccc.Found -and -not $SkipIndex) {
    $cocoindexGlobalSettings = Join-Path $HOME ".cocoindex_code\global_settings.yml"
    if (-not (Test-Path -LiteralPath $cocoindexGlobalSettings)) {
        Write-Host "Cocoindex global settings are missing. Run manually: ccc init"
        Write-Host "Then rerun this script or run: ccc index"
    } else {
        Write-Host "Running ccc index in $repoRoot"
        Push-Location $repoRoot
        try {
            & ccc index
            if ($LASTEXITCODE -ne 0) {
                throw "ccc index failed."
            }
        } finally {
            Pop-Location
        }
    }
} elseif (-not $ccc.Found) {
    Write-Host "Install cocoindex-code globally, then run: ccc index"
} else {
    Write-Host "Skipped ccc index because -SkipIndex was supplied."
}

Write-Host ""
Write-Host "Target repo: $repoRoot"
Write-Host "Changes:"
if ($changed.Count -eq 0) {
    Write-Host "  none"
} else {
    foreach ($item in $changed) {
        Write-Host "  $item"
    }
}

Write-Host ""
Write-Host "Next:"
Write-Host "  1. Open the target repo with your AI agent."
Write-Host "  2. Ask it to follow .agents/start/onboard-repo.prompt.md."
Write-Host "  3. Review AGENTS.md, then delete .agents/start if it was temporary."
Write-Host ""
Write-Host "Codex MCP hint: codex mcp add cocoindex-code -- ccc mcp"
Write-Host "Claude: use the upstream cocoindex integration globally; do not copy it into this repo."
