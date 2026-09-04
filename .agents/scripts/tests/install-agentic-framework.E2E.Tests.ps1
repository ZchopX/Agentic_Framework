#Requires -Modules @{ ModuleName = 'Pester'; RequiredVersion = '5.5.0' }

BeforeAll {
    $script:ScriptUnderTest = Join-Path $PSScriptRoot "..\install-agentic-framework.ps1"
    $script:RepoRoot = (git -C $PSScriptRoot rev-parse --show-toplevel)

    function New-ScratchRepo {
        $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("agentic-e2e-" + [System.Guid]::NewGuid().ToString("N"))
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        git init -q $dir
        $dir
    }

    function Remove-ScratchRepo {
        param([string]$Path)
        if ($Path -and (Test-Path -LiteralPath $Path)) {
            Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    # Runs the installer as a real child process under the given engine.
    # powershell.exe (5.1) on this class of machine refuses to load an
    # unsigned -File script at all under the default execution policy, so
    # -ExecutionPolicy Bypass is required for that engine (matches the
    # script's own documented recommended invocation); pwsh.exe needs no
    # such flag.
    function Invoke-InstallerProcess {
        param(
            [string]$Engine,
            [string]$WorkingDirectory,
            [string[]]$ScriptArgs = @(),
            [string]$StdIn
        )
        $exe = if ($Engine -eq "pwsh") { (Get-Command pwsh).Source } else { (Get-Command powershell).Source }
        $baseArgs = if ($Engine -eq "pwsh") { @("-NoProfile", "-File", $script:ScriptUnderTest) } else { @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $script:ScriptUnderTest) }
        $allArgs = $baseArgs + $ScriptArgs

        Push-Location $WorkingDirectory
        try {
            if ($StdIn) {
                $output = $StdIn | & $exe @allArgs 2>&1
            } else {
                $output = & $exe @allArgs 2>&1
            }
            [pscustomobject]@{
                ExitCode = $LASTEXITCODE
                Output   = ($output | Out-String)
            }
        } finally {
            Pop-Location
        }
    }
}

Describe "install-agentic-framework.ps1 E2E" -Tag E2E -ForEach @(
    @{ Engine = "pwsh" }
    @{ Engine = "powershell" }
) {
    Context "<Engine>: not-a-git-repo guard" {
        BeforeEach {
            $script:scratch = Join-Path ([System.IO.Path]::GetTempPath()) ("agentic-e2e-nogit-" + [System.Guid]::NewGuid().ToString("N"))
            New-Item -ItemType Directory -Path $scratch -Force | Out-Null
        }
        AfterEach { Remove-ScratchRepo -Path $scratch }

        It "exits non-zero and creates nothing when run outside a git repo" {
            if (-not (Get-Command $Engine -ErrorAction SilentlyContinue)) { Set-ItResult -Skipped -Because "$Engine not found on PATH"; return }
            $result = Invoke-InstallerProcess -Engine $Engine -WorkingDirectory $scratch -ScriptArgs @("-SourceUrl", $script:RepoRoot, "-Yes")
            $result.ExitCode | Should -Not -Be 0
            Test-Path (Join-Path $scratch ".agents") | Should -Be $false
            Test-Path (Join-Path $scratch ".gitignore") | Should -Be $false
        }
    }

    Context "<Engine>: self-clobber guard" {
        BeforeEach {
            $script:scratch = New-ScratchRepo
            git -C $scratch remote add origin $script:RepoRoot
        }
        AfterEach { Remove-ScratchRepo -Path $scratch }

        It "exits non-zero and creates nothing when origin matches -SourceUrl" {
            if (-not (Get-Command $Engine -ErrorAction SilentlyContinue)) { Set-ItResult -Skipped -Because "$Engine not found on PATH"; return }
            $result = Invoke-InstallerProcess -Engine $Engine -WorkingDirectory $scratch -ScriptArgs @("-SourceUrl", $script:RepoRoot, "-Yes")
            $result.ExitCode | Should -Not -Be 0
            Test-Path (Join-Path $scratch ".agents") | Should -Be $false
            Test-Path (Join-Path $scratch ".gitignore") | Should -Be $false
        }
    }

    Context "<Engine>: happy path" {
        BeforeAll {
            $script:scratch = New-ScratchRepo
            git -C $scratch remote add origin "https://example.invalid/not-this-repo.git"
        }
        AfterAll { Remove-ScratchRepo -Path $scratch }

        It "installs .agents/ structure, skills, and .gitignore on first run" {
            if (-not (Get-Command $Engine -ErrorAction SilentlyContinue)) { Set-ItResult -Skipped -Because "$Engine not found on PATH"; return }
            $result = Invoke-InstallerProcess -Engine $Engine -WorkingDirectory $scratch -ScriptArgs @("-SourceUrl", $script:RepoRoot, "-Yes")
            $result.ExitCode | Should -Be 0

            foreach ($dir in @("templates", "start", "reference")) {
                $p = Join-Path $scratch ".agents\$dir"
                Test-Path -LiteralPath $p | Should -Be $true
                (Get-ChildItem -LiteralPath $p -Recurse -File | Measure-Object).Count | Should -BeGreaterThan 0
            }

            $gitignore = Get-Content -LiteralPath (Join-Path $scratch ".gitignore")
            @($gitignore | Where-Object { $_ -eq ".claude/settings.local.json" }).Count | Should -Be 1

            Test-Path (Join-Path $scratch ".agents\skills\todo") | Should -Be $true
            Test-Path (Join-Path $scratch ".claude\skills\todo") | Should -Be $true
        }

        It "is idempotent: a second run adds no new .gitignore lines and reports unchanged/up-to-date" {
            if (-not (Get-Command $Engine -ErrorAction SilentlyContinue)) { Set-ItResult -Skipped -Because "$Engine not found on PATH"; return }
            $before = @(Get-Content -LiteralPath (Join-Path $scratch ".gitignore")).Count

            $result = Invoke-InstallerProcess -Engine $Engine -WorkingDirectory $scratch -ScriptArgs @("-SourceUrl", $script:RepoRoot, "-Yes")
            $result.ExitCode | Should -Be 0

            $after = @(Get-Content -LiteralPath (Join-Path $scratch ".gitignore")).Count
            $after | Should -Be $before
            ($result.Output -match "already present") -or ($result.Output -match "unchanged") -or ($result.Output -match "up-to-date") | Should -Be $true
        }
    }

    Context "<Engine>: OpenSpec-dependent case" {
        BeforeAll {
            $script:scratch = New-ScratchRepo
            git -C $scratch remote add origin "https://example.invalid/not-this-repo.git"
        }
        AfterAll { Remove-ScratchRepo -Path $scratch }

        It "initializes openspec/config.yaml when the openspec CLI is available" {
            if (-not (Get-Command $Engine -ErrorAction SilentlyContinue)) { Set-ItResult -Skipped -Because "$Engine not found on PATH"; return }
            if (-not (Get-Command openspec -ErrorAction SilentlyContinue)) { Set-ItResult -Skipped -Because "openspec CLI not found on PATH"; return }

            $result = Invoke-InstallerProcess -Engine $Engine -WorkingDirectory $scratch -ScriptArgs @("-SourceUrl", $script:RepoRoot, "-Yes")
            $result.ExitCode | Should -Be 0
            Test-Path (Join-Path $scratch "openspec\config.yaml") | Should -Be $true
            $result.Output | Should -Not -Match "OpenSpec init: failed"
        }
    }

    Context "<Engine>: CocoIndex-dependent case" {
        BeforeAll {
            $script:scratch = New-ScratchRepo
            git -C $scratch remote add origin "https://example.invalid/not-this-repo.git"
        }
        AfterAll { Remove-ScratchRepo -Path $scratch }

        It "reports a known CocoIndex outcome and never an unhandled exception" {
            if (-not (Get-Command $Engine -ErrorAction SilentlyContinue)) { Set-ItResult -Skipped -Because "$Engine not found on PATH"; return }
            if (-not (Get-Command ccc -ErrorAction SilentlyContinue)) { Set-ItResult -Skipped -Because "ccc not found on PATH"; return }

            $result = Invoke-InstallerProcess -Engine $Engine -WorkingDirectory $scratch -ScriptArgs @("-SourceUrl", $script:RepoRoot, "-Yes")
            $result.ExitCode | Should -Be 0
            $knownOutcomes = @(
                "CocoIndex: indexed",
                "CocoIndex: failed",
                "CocoIndex: skipped - ccc not found",
                "CocoIndex: skipped - ccc not initialized"
            )
            $matched = $false
            foreach ($outcome in $knownOutcomes) {
                if ($result.Output -match [regex]::Escape($outcome)) { $matched = $true }
            }
            $matched | Should -Be $true
            $result.Output | Should -Not -Match "Exception"
        }
    }

    Context "<Engine>: interactive re-prompt" {
        BeforeAll {
            $script:scratch = New-ScratchRepo
            git -C $scratch remote add origin "https://example.invalid/not-this-repo.git"
        }
        AfterAll { Remove-ScratchRepo -Path $scratch }

        It "reprompts once on an invalid selection, then accepts a valid one" {
            if (-not (Get-Command $Engine -ErrorAction SilentlyContinue)) { Set-ItResult -Skipped -Because "$Engine not found on PATH"; return }

            # First line is an unparseable answer; second (blank) line accepts
            # the pre-ticked default set - a valid selection per the script's
            # own parsing rules. "todo" is force-added regardless of selection.
            $result = Invoke-InstallerProcess -Engine $Engine -WorkingDirectory $scratch -ScriptArgs @("-SourceUrl", $script:RepoRoot) -StdIn "bogus`r`n`r`n"

            $result.Output | Should -Match "Could not parse 'bogus'"
            $result.ExitCode | Should -Be 0
            Test-Path (Join-Path $scratch ".agents\skills\todo") | Should -Be $true
        }
    }
}
