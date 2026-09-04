# Execution Handoff

Plan: .agents/plans/install-agentic-framework-tests.md
User request: Implement @.agents/plans/install-agentic-framework-tests.md
Final outcome: Refactored `install-agentic-framework.ps1` for testability (behavior-preserving), added a Pester 5.5.0 Unit suite (16 tests) and E2E suite (14 tests, both engines), a local runner, and a `windows-latest` CI workflow. Full suite (30/30) passes locally with exit code 0. Reviewed by an independent sub-agent (`subagent-verify`, `plan-implementation-review` mode); 4 findings triaged, 3 fixed (see Deviations/Follow-Up), 1 accepted as-is.

## Plan Item Evidence

| Plan item | Status | Evidence |
|---|---|---|
| 1.1 Extract `Get-NormalizedRepoUrl` | done | `.agents/scripts/install-agentic-framework.ps1:139-142`; call sites at lines 178 |
| 1.2 Extract `Test-SymlinkTarget` | done | `.agents/scripts/install-agentic-framework.ps1:144-162`; call site at line 361 |
| 1.3 Dot-source guard | done | `.agents/scripts/install-agentic-framework.ps1:164`; verified clean dot-source + function availability under both `pwsh` and `powershell -ExecutionPolicy Bypass` |
| 2.1 Re-verify no behavior change | done | Fresh scratch-repo `-Yes` run against local `-SourceUrl` reproduced expected report lines (openspec init, `.agents/*` copy, `.gitignore` line, skill install with symlink-fallback-to-copy on this no-Dev-Mode machine) |
| 3.1-3.7 Unit tests | done | `.agents/scripts/tests/install-agentic-framework.Unit.Tests.ps1` — 16/16 pass, `Get-FileHashHex`/`Compare-DirectoryContent`/`Add-IgnoreLine`/`Copy-DirectoryIfChanged`/`Get-NormalizedRepoUrl`/`Test-SymlinkTarget` all covered |
| 3.7 verify: regression proof | done | `Get-NormalizedRepoUrl`'s test deliberately failed against a reverted `TrimEnd('.git')` copy (stripped a trailing `g` from `framework-testing`), then passed again after revert (byte-identical diff confirmed against pre-test backup) |
| 4.1-4.8 E2E tests | done | `.agents/scripts/tests/install-agentic-framework.E2E.Tests.ps1` — 14/14 pass across both `pwsh` and `powershell` engines (not-a-git-repo guard, self-clobber guard, happy path + idempotent rerun, OpenSpec-dependent case, CocoIndex-dependent case, interactive re-prompt) |
| 5.1 Local test runner | done | `.agents/scripts/tests/Invoke-Tests.ps1`; ran `-Tag Unit` alone and full suite, both exit 0 on pass |
| 6.1 CI workflow | done | `.github/workflows/test-install-script.yml` (this repo's first `.github/`); not run on a real GitHub Actions runner (no push made) — YAML only, `windows-latest`, path-scoped triggers |

## Changed Files

- `.agents/scripts/install-agentic-framework.ps1`: replaced inline `$normalize` scriptblock with `Get-NormalizedRepoUrl`; extracted inline symlink-target check into `Test-SymlinkTarget`; added dot-source guard. No behavior change (task 2 re-verification).
- `.agents/scripts/tests/install-agentic-framework.Unit.Tests.ps1`: new, Pester 5.5.0 unit tests for all six helper functions.
- `.agents/scripts/tests/install-agentic-framework.E2E.Tests.ps1`: new, Pester-driven E2E tests spawning the installer as a real child process under both PowerShell engines against scratch git repos, cloning from this repo's own local path.
- `.agents/scripts/tests/Invoke-Tests.ps1`: new, bootstraps/pins Pester 5.5.0 and runs `Invoke-Pester -PassThru`, exiting 1 on any failure.
- `.github/workflows/test-install-script.yml`: new, first CI workflow in this repo.

## Validation Run

- `pwsh -NoProfile -Command "[...]::ParseFile(...)"` (both engines) - passed - no syntax errors
- Dot-source smoke test (both engines, `powershell` needs `-ExecutionPolicy Bypass`) - passed - returns cleanly, all functions loaded
- Manual scratch-repo `-Yes` E2E run against refactored script - passed - matches expected report shape
- `pwsh -File .agents/scripts/tests/Invoke-Tests.ps1 -Tag Unit` - passed - 16/16
- `pwsh -NoProfile -Command "Invoke-Pester -Path .agents/scripts/tests -TagFilter E2E -Output Detailed"` - passed - 14/14 (both engines, no skips - `openspec` and `ccc` are both installed on this machine)
- Regression proof (Decision/3.7): reverted `Get-NormalizedRepoUrl` to the original `TrimEnd('.git')` bug, confirmed 1 test failure, reverted back, confirmed byte-identical to pre-test state via `diff`
- `pwsh -File .agents/scripts/tests/Invoke-Tests.ps1` (full suite via runner) - passed - 30/30, exit code 0
- Exit-code propagation check: deliberately broke one assertion, confirmed `Invoke-Tests.ps1` exits 1 (not 0) - passed, then reverted

## Deviations

- **Pester version pinned to exactly 5.5.0, not "any 5.x".** This machine's PowerShell Gallery already had a newer major (6.1.0) that also satisfies `-MinimumVersion 5.0`/`-MinimumVersion 5.5.0`; Pester 6 renamed `-Tag`→`-TagFilter` and made other breaking changes, so an unpinned `-MinimumVersion` check would nondeterministically pick up whichever is newest on a given machine (locally 6.1.0 today) and silently break. `Invoke-Tests.ps1` and the two test files' `#Requires` now pin `-RequiredVersion 5.5.0` explicitly instead of the plan's originally-described `-MinimumVersion 5.0` check. Reason: correctness under environment drift, not scope creep — the plan's own stated intent throughout ("Pester 5.x", "not... 3.4.0") is unambiguous; it just didn't anticipate a 6.x already being installed.
- **Added `-PassThru` + explicit `exit 1` on `$result.FailedCount -gt 0` to `Invoke-Tests.ps1`**, not present in the plan's task 5.1 description. Reason: verified empirically that Pester 5's `Invoke-Pester` does **not** set a nonzero process exit code on test failure by default (only `-CI` mode or an explicit check does) — without this, both the local runner and the CI workflow would report success even with failing tests, defeating the plan's whole stated purpose (catching regressions automatically). Confirmed via a deliberate-failure smoke test (see Validation Run).
- **E2E interactive-reprompt test (4.7) sends `"bogus"` then a blank line, not `"bogus"` then a specific valid index/name.** The plan's task text says "an invalid token, then a valid selection" without specifying which; a blank line is the script's own documented "accept the pre-ticked default" path, which is unambiguously a valid selection and avoids needing to parse the installer's own numbered skill-list output at test time just to compute a matching index.
- **CI workflow's OpenSpec-install step uses `continue-on-error: true`** (not explicitly stated in task 6.1, which only says "can optionally be installed as a prior step"). Reason: keeps the OpenSpec-dependent E2E case's own `Set-ItResult -Skipped` fallback (task 4.5/7) as the actual safety net if the npm install step ever fails on a runner, rather than failing the whole CI job on an unrelated install hiccup.
- **E2E tests invoke the installer from its real repo path (`Push-Location` into each scratch dir, run `$ScriptUnderTest` from there) instead of literally copying the script file into each scratch repo**, as task 4.1's text describes. Functionally equivalent — the script reads `(Get-Location).Path` for its install target, not `$PSScriptRoot` — and simpler; flagged by the independent review as an undocumented deviation, recorded here for completeness. No fix needed.

## Risk Areas

- CI workflow (`.github/workflows/test-install-script.yml`) has not been exercised on a real GitHub Actions runner — only local Windows validation was possible in this session (no push was made). First real run may surface runner-specific gaps (e.g., `ccc`/CocoIndex absence, which the E2E CocoIndex-dependent test is designed to skip gracefully — untested against an actual runner missing `ccc`).
- `sync-openspec-skills.ps1` remains untested, per the plan's explicit Out of scope.
- Real Windows-symlink-success path stays untested end-to-end (no Developer Mode/elevation on this machine), per the plan's explicit Out of scope; `Test-SymlinkTarget`'s decision logic is unit-tested without a real symlink.
- E2E tests mutate real machine-global state when `openspec`/`ccc` are present (matches any real run of the installer, not introduced by this plan — see plan's own Risks section).

## Compatibility And User-Facing Checks

- Compatibility: Sources checked match the plan's own Compatibility notes (script re-read before refactor, `sync-openspec-skills.ps1` re-checked, no ADR convention exists in this repo). No production/runtime dependency added; Pester 5.5.0 is dev/CI-only. New: this repo's first `.github/workflows/*` file (additive, cannot break an existing process since none existed).
- User-facing: No user-facing surface changed. This plan's only observable output is Pester's own console/CI reporting and the GitHub Actions status check, per the plan's own "No user-facing impact identified" section.

## Independent Verification (subagent-verify)

Mode: `plan-implementation-review` (light `user-facing-review` lens applied to the one interactive CLI path, task 4.7). Sub-agent read the plan, this handoff, and all changed/new files directly; did not modify anything.

Findings and disposition:
- **High — fixed.** `Invoke-Tests.ps1`'s Pester-bootstrap detection accepted any installed version `>= 5.0` (including the 6.1.0 also present on this machine), while the subsequent `Import-Module -RequiredVersion 5.5.0` demands exactly 5.5.0. On a machine/CI runner with a Pester 5.x other than exactly 5.5.0 (or none), detection would wrongly report "already satisfied," skip the install step, and `Import-Module` would then throw a raw terminating error instead of the plan's promised "clear failure message." Reproduced by the sub-agent (`Import-Module Pester -RequiredVersion 5.9.9 -Force -ErrorAction Stop` fails exactly this way). Fixed: detection now checks `-eq [version]"5.5.0"` (`.agents/scripts/tests/Invoke-Tests.ps1:17`). Re-verified: full suite still 30/30 after the fix.
- **Low — fixed.** `install-agentic-framework.E2E.Tests.ps1` called `Set-ItResult -Skipped` from a `Describe`-level `BeforeAll`, which Pester 5 doesn't document as a valid skip site (it's meant for `It`/`BeforeEach`); every `It` already re-checks `Get-Command $Engine` and skips correctly on its own, making the `BeforeAll` block redundant and of unverified correctness (both engines are present on this machine and on `windows-latest`, so it was never exercised). Removed the redundant `BeforeAll` block; per-`It` guards are unchanged and still correct.
- **Low — fixed.** `Test-SymlinkTarget`'s `Resolve-Path -LiteralPath $ExpectedPath` used `-ErrorAction SilentlyContinue`, which the original inline code did not for the equivalent `$agentsDst` resolve — a real (if narrow, `-WhatIf`-only) behavior change the "no behavior change" claim didn't cover. Fixed: removed `-ErrorAction SilentlyContinue` from that one resolve to restore the original throw-if-missing semantics (`.agents/scripts/install-agentic-framework.ps1:160`); the `Item.Target` resolve keeps its `-ErrorAction SilentlyContinue`, matching the original's asymmetry. Re-verified: `Test-SymlinkTarget`'s 4 unit tests still pass (the "nonexistent target" case tests `$Item.Target`, not `$ExpectedPath`, so it's unaffected).
- **Low/informational — no fix, documented.** E2E tests run the installer from its real repo path rather than literally copying it into each scratch repo (task 4.1's text). Functionally equivalent; added to Deviations above.

Post-fix recheck: `pwsh -File .agents/scripts/tests/Invoke-Tests.ps1` (full suite) — 30/30 passed, exit code 0. No scratch dirs left behind (`ls $TEMP/agentic-e2e-*` empty). Working tree otherwise unchanged (only the 3 fix edits plus this handoff).

## Follow-Up Pointers

- `.agents/scripts/tests/install-agentic-framework.Unit.Tests.ps1`, `.agents/scripts/tests/install-agentic-framework.E2E.Tests.ps1`, `.agents/scripts/tests/Invoke-Tests.ps1`, `.github/workflows/test-install-script.yml` — all new, all passing locally as of this handoff.
- First real CI run (on push) should be watched for runner-environment surprises not reproducible locally (see Risk Areas).
