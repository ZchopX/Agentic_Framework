<#
Sync openspec-mod/'s staged schema fork and openspec-verify skill to their
global install locations for OpenSpec, Claude Code, and Codex.

Recommended invocation (no persistent execution-policy change):
  powershell -ExecutionPolicy Bypass -File .agents\scripts\sync-openspec-skills.ps1
  pwsh -ExecutionPolicy Bypass -File .agents\scripts\sync-openspec-skills.ps1

Preview only, writes nothing:
  pwsh -File .agents\scripts\sync-openspec-skills.ps1 -WhatIf
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('Schema', 'Claude', 'Codex', 'All')]
    [string]$Targets = 'All'
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

function Get-FileHashHex {
    # Pure .NET SHA256, not the Get-FileHash cmdlet: on a machine with both
    # PowerShell 7 and Windows PowerShell 5.1 installed, PS7's own
    # Microsoft.PowerShell.Utility module can shadow the Desktop-edition one
    # in $env:PSModulePath, causing Get-FileHash to silently fail to autoload
    # under powershell.exe 5.1. .NET's hash class has no module-resolution
    # dependency, so it works identically under both engines regardless.
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
            Hash = Get-FileHashHex -Path $_.FullName
        }
    }
    $destFiles = Get-ChildItem -LiteralPath $Destination -Recurse -File | ForEach-Object {
        [pscustomobject]@{
            RelativePath = $_.FullName.Substring($Destination.Length).TrimStart('\', '/')
            Hash = Get-FileHashHex -Path $_.FullName
        }
    }

    $diff = Compare-Object -ReferenceObject $sourceFiles -DifferenceObject $destFiles -Property RelativePath, Hash
    if ($diff) {
        return "different"
    }
    return "identical"
}

function Sync-Target {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$Source,
        [string]$Destination
    )

    if (-not $PSCmdlet.ShouldProcess($Destination, "Sync from $Source")) {
        return
    }

    robocopy $Source $Destination /MIR /NFL /NDL /NJH /NJS | Out-Null
    $code = $LASTEXITCODE
    if ($code -ge 8) {
        throw "robocopy failed with code $code syncing $Source -> $Destination"
    }
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

$allTargets = @(
    [pscustomobject]@{
        Name = "OpenSpec schema"
        Key = "Schema"
        Source = Join-Path $repoRoot "openspec-mod\openspec-schemas\spec-driven-verified"
        Destination = Join-Path $env:LOCALAPPDATA "openspec\schemas\spec-driven-verified"
    }
    [pscustomobject]@{
        Name = "Claude Code skill"
        Key = "Claude"
        Source = Join-Path $repoRoot "openspec-mod\claude-skills\openspec-verify"
        Destination = Join-Path $env:USERPROFILE ".claude\skills\openspec-verify"
    }
    [pscustomobject]@{
        Name = "Codex skill"
        Key = "Codex"
        Source = Join-Path $repoRoot "openspec-mod\claude-skills\openspec-verify"
        Destination = Join-Path $env:USERPROFILE ".agents\skills\openspec-verify"
    }
)

if ($Targets -ne 'All') {
    $allTargets = $allTargets | Where-Object { $_.Key -eq $Targets }
}

$openspecCli = Get-CommandStatus "openspec"

$results = New-Object System.Collections.Generic.List[object]
foreach ($target in $allTargets) {
    $state = Compare-DirectoryContent -Source $target.Source -Destination $target.Destination

    if ($state -eq "identical") {
        $results.Add([pscustomobject]@{ Name = $target.Name; Status = "up-to-date"; Detail = $target.Destination })
        continue
    }

    $verb = if ($state -eq "missing") { "install" } else { "update" }
    if ($WhatIfPreference) {
        $results.Add([pscustomobject]@{ Name = $target.Name; Status = "would-$verb"; Detail = $target.Destination })
        Sync-Target -Source $target.Source -Destination $target.Destination -WhatIf | Out-Null
        continue
    }

    try {
        Sync-Target -Source $target.Source -Destination $target.Destination
        $pastVerb = if ($state -eq "missing") { "installed" } else { "updated" }
        $results.Add([pscustomobject]@{ Name = $target.Name; Status = $pastVerb; Detail = $target.Destination })
    } catch {
        $results.Add([pscustomobject]@{ Name = $target.Name; Status = "failed"; Detail = $_.Exception.Message })
    }
}

Write-Host "PowerShell: $($PSVersionTable.PSEdition) $($PSVersionTable.PSVersion)"
if ($openspecCli.Found) {
    Write-Host "openspec CLI: found at $($openspecCli.Source)"
} else {
    Write-Host "openspec CLI: not detected on PATH (informational only - schema files sync regardless)"
}

Write-Host ""
Write-Host "Sync results:"
foreach ($result in $results) {
    Write-Host "  $($result.Name): $($result.Status)"
    Write-Host "    $($result.Detail)"
}
