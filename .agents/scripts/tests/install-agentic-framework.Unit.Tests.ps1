#Requires -Modules @{ ModuleName = 'Pester'; RequiredVersion = '5.5.0' }

BeforeAll {
    . (Join-Path $PSScriptRoot "..\install-agentic-framework.ps1")
}

Describe "Get-FileHashHex" -Tag Unit {
    It "returns the correct uppercase, unseparated SHA256 hex for known content" {
        $path = Join-Path $TestDrive "known.txt"
        Set-Content -LiteralPath $path -Value "hello world" -NoNewline

        $hash = Get-FileHashHex -Path $path

        # Precomputed: sha256("hello world")
        $hash | Should -Be "B94D27B9934D3E08A52E52D7DA7DABFAC484EFE37A5380EE9088F7ACE2EFCDE9"
        $hash | Should -Not -Match '-'
    }
}

Describe "Compare-DirectoryContent" -Tag Unit {
    BeforeEach {
        $script:source = Join-Path $TestDrive "src-$(New-Guid)"
        New-Item -ItemType Directory -Path $source -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $source "a.txt") -Value "content-a"
    }

    It "returns 'missing' when the destination does not exist" {
        $dest = Join-Path $TestDrive "missing-$(New-Guid)"
        Compare-DirectoryContent -Source $source -Destination $dest | Should -Be "missing"
    }

    It "returns 'identical' for a byte-identical copy" {
        $dest = Join-Path $TestDrive "identical-$(New-Guid)"
        Copy-Item -Recurse $source $dest
        Compare-DirectoryContent -Source $source -Destination $dest | Should -Be "identical"
    }

    It "returns 'different' when one file differs" {
        $dest = Join-Path $TestDrive "different-$(New-Guid)"
        Copy-Item -Recurse $source $dest
        Set-Content -LiteralPath (Join-Path $dest "a.txt") -Value "content-b"
        Compare-DirectoryContent -Source $source -Destination $dest | Should -Be "different"
    }
}

Describe "Add-IgnoreLine" -Tag Unit {
    It "creates the file with exactly one line when absent" {
        $path = Join-Path $TestDrive "absent-$(New-Guid).gitignore"
        $result = Add-IgnoreLine -GitIgnorePath $path -Line ".claude/settings.local.json"
        $result | Should -Be $true
        @(Get-Content -LiteralPath $path) | Should -Be @(".claude/settings.local.json")
    }

    It "appends the line and preserves existing content when present without it" {
        $path = Join-Path $TestDrive "existing-$(New-Guid).gitignore"
        Set-Content -LiteralPath $path -Value "node_modules/"
        $result = Add-IgnoreLine -GitIgnorePath $path -Line ".claude/settings.local.json"
        $result | Should -Be $true
        @(Get-Content -LiteralPath $path) | Should -Be @("node_modules/", ".claude/settings.local.json")
    }

    It "returns false and adds no duplicate when the line already exists" {
        $path = Join-Path $TestDrive "dup-$(New-Guid).gitignore"
        Set-Content -LiteralPath $path -Value ".claude/settings.local.json"
        $before = (Get-Content -LiteralPath $path).Count
        $result = Add-IgnoreLine -GitIgnorePath $path -Line ".claude/settings.local.json"
        $result | Should -Be $false
        (Get-Content -LiteralPath $path).Count | Should -Be $before
    }
}

Describe "Copy-DirectoryIfChanged" -Tag Unit {
    BeforeAll {
        # Copy-DirectoryIfChanged reads $PSCmdlet (for ShouldProcess), which
        # PowerShell resolves via the dynamic call stack, not lexical
        # definition scope. Called directly from a Pester It block there is
        # no advanced-function frame on the stack, so $PSCmdlet is $null.
        # This wrapper puts one there; -Confirm:$false keeps ShouldProcess
        # defaulting to true without prompting.
        function Invoke-CopyDirectoryIfChangedUnderTest {
            [CmdletBinding(SupportsShouldProcess)]
            param([string]$Source, [string]$Destination)
            Copy-DirectoryIfChanged -Source $Source -Destination $Destination
        }
    }

    BeforeEach {
        $script:source = Join-Path $TestDrive "cdif-src-$(New-Guid)"
        New-Item -ItemType Directory -Path $source -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $source "f.txt") -Value "v1"
    }

    It "returns 'installed' and matches source when destination was missing" {
        $dest = Join-Path $TestDrive "cdif-dst-$(New-Guid)"
        $result = Invoke-CopyDirectoryIfChangedUnderTest -Source $source -Destination $dest -Confirm:$false
        $result | Should -Be "installed"
        Compare-DirectoryContent -Source $source -Destination $dest | Should -Be "identical"
    }

    It "returns 'unchanged' when destination is already identical" {
        $dest = Join-Path $TestDrive "cdif-dst2-$(New-Guid)"
        Copy-Item -Recurse $source $dest
        Invoke-CopyDirectoryIfChangedUnderTest -Source $source -Destination $dest -Confirm:$false | Should -Be "unchanged"
    }
}

Describe "Get-NormalizedRepoUrl" -Tag Unit {
    It "round-trips a URL with no literal .git suffix even if it ends in a char from the set {.,g,i,t}" {
        # Regression case for the TrimEnd('.git') char-set bug: TrimEnd treats
        # its argument as a set of characters to strip, not a literal suffix.
        Get-NormalizedRepoUrl "https://github.com/x/framework-testing" | Should -Be "https://github.com/x/framework-testing"
    }

    It "strips a real .git suffix" {
        Get-NormalizedRepoUrl "https://github.com/x/framework.git" | Should -Be "https://github.com/x/framework"
    }

    It "normalizes trailing slash and case variations to the same value" {
        $a = Get-NormalizedRepoUrl "https://GitHub.com/x/Framework.git/"
        $b = Get-NormalizedRepoUrl "https://github.com/x/framework.git"
        $a | Should -Be $b
    }
}

Describe "Test-SymlinkTarget" -Tag Unit {
    BeforeEach {
        $script:realPath = Join-Path $TestDrive "real-$(New-Guid)"
        New-Item -ItemType Directory -Path $realPath -Force | Out-Null
        $script:otherPath = Join-Path $TestDrive "other-$(New-Guid)"
        New-Item -ItemType Directory -Path $otherPath -Force | Out-Null
    }

    It "returns true when the symlink's target matches the expected path" {
        $item = [pscustomobject]@{ LinkType = "SymbolicLink"; Target = @($realPath) }
        Test-SymlinkTarget -Item $item -ExpectedPath $realPath | Should -Be $true
    }

    It "returns false when the symlink's target is a different real path" {
        $item = [pscustomobject]@{ LinkType = "SymbolicLink"; Target = @($otherPath) }
        Test-SymlinkTarget -Item $item -ExpectedPath $realPath | Should -Be $false
    }

    It "returns false when LinkType is not SymbolicLink" {
        $item = [pscustomobject]@{ LinkType = "Directory"; Target = @($realPath) }
        Test-SymlinkTarget -Item $item -ExpectedPath $realPath | Should -Be $false
    }

    It "returns false without throwing when Target points at a nonexistent path" {
        $item = [pscustomobject]@{ LinkType = "SymbolicLink"; Target = @((Join-Path $TestDrive "does-not-exist-$(New-Guid)")) }
        { Test-SymlinkTarget -Item $item -ExpectedPath $realPath | Should -Be $false } | Should -Not -Throw
    }
}
