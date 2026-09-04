<#
Runs the install-agentic-framework.ps1 test suite. Bootstraps Pester 5.x if
only the Windows-bundled 3.4.0 is present (that ancient version's syntax and
feature set are too different from what these tests use).

Usage:
  pwsh -File .agents/scripts/tests/Invoke-Tests.ps1            # unit + E2E
  pwsh -File .agents/scripts/tests/Invoke-Tests.ps1 -Tag Unit   # fast loop only
#>

param(
    [string[]]$Tag = @('Unit', 'E2E')
)

$ErrorActionPreference = "Stop"

$pester = Get-Module -ListAvailable Pester | Where-Object { $_.Version -eq [version]"5.5.0" } | Select-Object -First 1
if (-not $pester) {
    Write-Host "Pester 5.5.0 not found - installing it for the current user..."
    Install-Module -Name Pester -RequiredVersion 5.5.0 -Scope CurrentUser -Force -SkipPublisherCheck
}

Import-Module Pester -RequiredVersion 5.5.0 -Force
$result = Invoke-Pester -Path $PSScriptRoot -TagFilter $Tag -Output Detailed -PassThru
if ($result.FailedCount -gt 0) {
    exit 1
}
