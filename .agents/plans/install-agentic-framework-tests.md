# Automated Tests for install-agentic-framework.ps1

## Feature description and user value

`.agents/scripts/install-agentic-framework.ps1` (added in commit `b0dc21c`) is
a single-file installer a user copies into any other Windows git repo. It has
been validated so far only by manual scratch-repo runs during two sessions —
a real regression (a `TrimEnd` char-set bug in the self-clobber guard) was
found only because a human happened to test an edge case by hand. This plan
adds two layers of automated tests — Pester unit tests for the script's pure
helper logic, and Pester-driven end-to-end (E2E) tests that formalize the
scratch-repo verification already done manually — plus a minimal CI workflow
so both run on every push, not only when someone remembers to test by hand.

## In scope / out of scope

**In scope:**
- A small, behavior-preserving refactor of `install-agentic-framework.ps1` so
  its helper logic is unit-testable via dot-sourcing, without executing the
  script's live guard/clone/install body.
- Pester unit tests for `Get-FileHashHex`, `Compare-DirectoryContent`,
  `Add-IgnoreLine`, `Copy-DirectoryIfChanged`, and two newly-extracted
  functions (`Get-NormalizedRepoUrl`, `Test-SymlinkTarget` — see Decisions).
- Pester-driven E2E tests that create scratch git repos, run the real script
  end to end (both `-Yes` and interactive-input modes), and assert on
  resulting filesystem/`.gitignore`/report state, then tear down.
- A local runner script to execute both layers with one command.
- A minimal GitHub Actions CI workflow (this repo's first) running both
  layers on `windows-latest`.

**Out of scope:**
- Testing `sync-openspec-skills.ps1` itself (untouched by this plan; it has
  no tests either, but adding them is a separate, symmetrical follow-up, not
  bundled here to keep this plan's diff focused on the installer).
- Exercising a real, successful Windows-symlink creation (Decision, below):
  this dev machine has no Developer Mode and no elevation, so the
  symlink-*success* path (`New-Item -ItemType SymbolicLink` actually
  succeeding) cannot be verified live in this environment or, most likely,
  in a standard CI runner either. The unit layer tests the *target-matching
  decision logic* via a constructed fake object instead (see Decision 3);
  real symlink creation stays a manually-verified, machine-dependent path,
  same as the parent plan's own stated risk.
- Testing CocoIndex (`ccc`) indexing's actual index output/content — already
  covered structurally by the E2E happy-path test exercising the
  found/not-found and initialized/not-initialized branches; `ccc` itself is
  not expected to be installable on a CI runner, so those specific branches
  self-skip there (same tiering as the `openspec`-dependent happy path).
- Rewriting or expanding `install-agentic-framework.ps1`'s actual installer
  behavior — every change to that file in this plan is a refactor for
  testability, not a behavior change (verified by re-running the existing
  manual E2E flow once after the refactor, task 2's verify step).

## Discovery evidence

- `.agents/scripts/install-agentic-framework.ps1` (470 lines, read in full at
  commit `b0dc21c`) — six functions already exist as isolated,
  side-effect-scoped units: `Invoke-Native` (line 23), `Get-CommandStatus`
  (39), `Get-FileHashHex` (49), `Compare-DirectoryContent` (69),
  `Add-IgnoreLine` (99), `Copy-DirectoryIfChanged` (119). Everything from
  line 139 (`$report = New-Object ...`) onward is top-level script body with
  real side effects (guards that call `exit`, `git clone`, `openspec init`,
  skill install, `ccc index`) — dot-sourcing the file today runs all of this
  immediately, with no way to load just the functions.
- Line 151: `$normalize = { param($u) ($u.TrimEnd('/') -replace '\.git$', '').ToLowerInvariant() }`
  — an anonymous scriptblock assigned inline inside the self-clobber guard
  (lines 149-156), not a named, independently-callable function. This is the
  exact spot where a real bug (`.TrimEnd('.git')` treated as a char-set trim)
  was found and fixed by hand this session — precisely the class of
  regression a unit test is meant to catch, but it currently cannot be
  called in isolation at all.
- Lines ~325-345 (post-refactor from the `/subagent-verify` fix pass): the
  existing-symlink-target-matches-or-is-stale check is inline in the task-7
  skill-install loop, not a named function — same untestability problem as
  above, for the other bug class fixed this session (a symlink was trusted
  without checking its target).
- `.agents/scripts/sync-openspec-skills.ps1` (166 lines, read in full) — the
  sibling script this installer's helper functions were duplicated from
  (`Get-FileHashHex`, `Compare-DirectoryContent`-equivalent, `Sync-Target`).
  It also has zero tests and the same "runs immediately when dot-sourced"
  shape. Confirms there is no existing testing convention in this repo to
  follow — this plan establishes the first one, for the installer only (see
  Out of scope).
- `Get-Module -ListAvailable Pester` (run on this machine under both
  `pwsh.exe` and `powershell.exe`) → only `Pester 3.4.0` is present, at
  `C:\Program Files\WindowsPowerShell\Modules\Pester\3.4.0` — the ancient
  version bundled with Windows since ~2015. Its `Should Be` syntax and
  feature set are meaningfully behind modern Pester (5.x): no `BeforeAll`/
  `BeforeDiscovery` separation, weaker mocking, no `-Tag`/`-Output Detailed`
  ergonomics used by this plan's design. **Nothing modern is pre-installed —
  bootstrapping Pester 5.x is a required first step, not optional.**
- `Test-Path .github` → **does not exist**. This repo has no CI today. Any
  workflow this plan adds is the first `.github/workflows/*` file in the
  repo.
- `git log -1 --format=%H -- .agents/scripts/install-agentic-framework.ps1`
  → `b0dc21c...` (matches the commit already pushed to `origin/main`,
  confirming the file discovery above reflects the current, live state, not
  a stale read).
- No `AGENTS.md`, no `.agents/PRD.md`, no `*ADR*` files anywhere in the repo
  (confirmed via search) — there is no existing ADR process for this plan's
  Pester-adoption decision to slot into (see Compatibility notes).

## Existing system fit

- Tests live alongside the script they cover, under a new
  `.agents/scripts/tests/` folder — same tree as `install-agentic-framework.ps1`
  and `sync-openspec-skills.ps1` themselves, not a repo-root `/tests/`
  directory (no such convention exists to match; colocating with
  `.agents/scripts/` keeps the installer and its tests discoverable
  together).
- The refactor (Decisions 1-3) changes only *how* existing logic is exposed
  (named functions instead of inline body/scriptblock), not what it does —
  every existing manual validation this session already performed remains
  valid and is re-run once, unchanged, as this plan's own verification step.
- CI is new to this repo; the workflow is scoped narrowly (one job, this
  script's tests only) rather than a general-purpose CI framework decision —
  it does not touch or assume anything about how other parts of the repo
  might eventually be tested.

## Reuse opportunities

- The scratch-git-repo pattern already exercised by hand twice this session
  (`git init`, `git remote add origin <fake-url>`, copy the script in, run
  it, inspect, delete) is reused directly as the E2E test body — this plan
  is largely "write down and automate what was already done manually."
- `Compare-DirectoryContent`'s own hash-based diffing (already implemented)
  is reused by the E2E idempotency assertions (comparing before/after
  directory state) instead of writing a second, separate diffing helper for
  tests.
- Pester's built-in `TestDrive:` (an auto-cleaned per-test scratch directory)
  is used for every unit test that touches the filesystem — no custom
  temp-dir setup/teardown helper needs to be written.

## Decisions and tradeoffs

1. **Bootstrap Pester 5.x explicitly; do not rely on the bundled 3.4.0.**
   Rationale: 3.4.0's syntax (`Should Be`, no `-Tag` filtering used by this
   plan's Unit/E2E split, no `BeforeAll`) is different enough from 5.x that
   writing tests against it would mean either committing to an obsolete
   dialect or a later painful migration. The test runner script (task 4)
   checks `Get-Module -ListAvailable Pester -MinimumVersion 5.0` and runs
   `Install-Module -Name Pester -MinimumVersion 5.5.0 -Scope CurrentUser
   -Force -SkipPublisherCheck` if missing, printing a clear message first.
   Rejected: writing tests compatible with Pester 3.4.0 — would need to
   avoid modern features this plan's design depends on (tag-based
   Unit/E2E filtering, `BeforeAll`/`AfterAll` scratch-repo lifecycle) for no
   benefit, since Pester 5.x installs cleanly via `Install-Module` on both
   engines and is what CI will use anyway.

2. **Make the script dot-source-safe with a single guard line, not a file
   split.** The original plan's Decision 9 requires the installer stay one
   self-contained file a user copies into a target repo — splitting helpers
   into a separate `lib.ps1` that the main script dot-sources would break
   that (the copied file would silently stop working without its sibling).
   Instead, add one line right after the function definitions end (before
   `$report = New-Object ...`, i.e. after line 137 today):
   ```powershell
   if ($MyInvocation.InvocationName -eq '.') { return }
   ```
   Direct execution (`pwsh -File install-agentic-framework.ps1`, or a target
   user just running it) is unaffected — `$MyInvocation.InvocationName` is
   the script path in that case, not `.`, so this is a no-op for every real
   invocation. Dot-sourcing (`. .\install-agentic-framework.ps1`, what the
   unit tests do) now loads every function definition and then returns
   before any guard/clone/install side effect runs. Rejected: a
   `-TestMode`/`-Import` switch parameter doing the same thing — the
   `$MyInvocation` check needs no new parameter surface and cannot be
   accidentally passed by a real user.

3. **Extract two currently-inline pieces into named, independently callable
   functions, placed with the other helpers (before the guard from Decision
   2):**
   - `Get-NormalizedRepoUrl($u)` — replaces the anonymous `$normalize`
     scriptblock at line 151 with a real function of the same body. The
     self-clobber guard (lines 148-155) calls it the same way it calls the
     scriptblock today; behavior is unchanged, only now independently unit
     testable — this is the function the regression this plan is partly
     motivated by (the `.TrimEnd('.git')` bug) lives in.
   - `Test-SymlinkTarget($Item, $ExpectedPath)` — replaces the inline
     resolve-and-compare block in task 7's skill-install loop (added during
     the `/subagent-verify` fix pass) with a function taking whatever
     `Get-Item` returned (or, in a unit test, a hand-built
     `[pscustomobject]@{ LinkType = 'SymbolicLink'; Target = @($path) }`
     standing in for it) plus the expected resolved target path, returning
     `$true`/`$false`. It still calls `Resolve-Path` internally (so it is
     not perfectly pure), but needs no real symlink to test — only a real
     file/directory at the target path, which `TestDrive:` provides. This
     directly satisfies the constraint that real symlink creation isn't
     exercisable on this machine: the *decision logic* around symlinks is
     tested without ever calling `New-Item -ItemType SymbolicLink`.
   Both extractions are behavior-preserving; the call sites change from
   inline code to a function call with identical inputs/outputs. Rejected:
   leaving these inline and instead trying to unit-test them via regex/text
   inspection of the script source — brittle, and tests the source text
   instead of the actual running logic.

4. **Pester dependency needs no ADR.** The compatibility gate asks
   `ADR required: yes/no` for new framework/tooling decisions. This repo has
   no ADR directory or convention at all (confirmed above) — there is no
   process for this plan to slot an ADR into, and Pester is a dev/test-time
   tool, not a runtime or production dependency of anything this repo ships.
   The decision and its rationale are recorded here, in this plan's
   Decisions section, which is this repo's existing mechanism for durable
   decision records (see the parent installer plan's own 19 numbered
   Decisions as precedent). **ADR required: no** — see Compatibility notes.

5. **E2E tests clone from a local path, never the real GitHub URL.** The
   installer's default `-SourceUrl` is the real
   `https://github.com/ZchopX/Agentic_Framework.git`. Automated E2E tests
   instead pass `-SourceUrl (git rev-parse --show-toplevel)` (this repo's own
   working directory — `git clone` accepts a local filesystem path directly,
   no `file://` prefix needed on Windows) so tests are network-independent,
   fast, and cannot be rate-limited or made flaky by GitHub reachability.
   This does not weaken the guard tests: the self-clobber guard compares the
   *scratch test repo's own* origin remote against whatever `-SourceUrl` was
   passed for that specific test, so a test can still deliberately construct
   a self-clobber match using the local path. Rejected: hitting the real
   GitHub URL in every test run — slow, network-dependent, and pointless
   since the clone source's exact URL is never behavior-relevant to what's
   being tested (only whether clone-then-copy logic works).
   Rejected: mocking `git clone` entirely (e.g. pre-seeding a fake temp dir)
   — would stop exercising the real clone step, which is exactly the kind of
   integration surface E2E tests exist to cover.

6. **E2E tests exercise both PowerShell engines by shelling out to each as
   the subject under test, while Pester itself runs once, under `pwsh`.**
   Rather than installing and running Pester twice (once per engine), the
   E2E `Describe` block uses Pester (in `pwsh`) as the *test driver*, and
   each `It` invokes the installer under test via
   `& powershell.exe -File ...` or `& pwsh.exe -File ...` as a child
   process, asserting on the resulting filesystem state either way. This
   matches how the manual verification was already done this session (one
   engine driving, the other engine as subject) and avoids maintaining two
   parallel Pester installs. Rejected: running the whole Pester suite under
   `powershell.exe` 5.1 too — Pester 5.x itself works under 5.1, but doubling
   the entire suite's runtime for no additional coverage (the engine
   difference only matters for the script under test, not for Pester's own
   execution) is not worth it.

7. **CocoIndex/OpenSpec-CLI-dependent E2E branches self-skip (not fail) when
   the tool isn't on PATH, via Pester's `-Skip`.** A CI runner (or another
   contributor's machine) won't have `ccc` installed, and may not have the
   `openspec` CLI either. Rather than failing the whole suite or silently
   passing without exercising anything, each `It` that needs one of these
   tools checks `Get-Command` first and calls Pester's `Set-ItResult -Skipped
   -Because "<tool> not found on PATH"` if absent — visible in test output as
   a distinct skip, not a false pass or a red build. The always-available
   guard tests (not-a-git-repo, self-clobber) and the structural happy-path
   assertions that don't require `openspec`/`ccc` (`.agents/` copy,
   `.gitignore` line, skill folder placement) still run unconditionally.

8. **Add a minimal CI workflow now, scoped to only this script's tests.**
   The user's original question ("can we check this script with tests")
   plus "wire it into CI" was raised as an open consideration during
   discovery; this plan resolves it by including a small, single-job
   `windows-latest` GitHub Actions workflow rather than leaving CI as a
   follow-up decision — the marginal cost is low (one YAML file, reusing the
   same runner script tasks 3-5 already produce) and the value (regressions
   caught on every push instead of only when someone remembers to test by
   hand — the exact gap that let the `TrimEnd` bug ship once already) is
   the core motivation for this whole plan. Scoped narrowly: this workflow
   tests only `install-agentic-framework.ps1`; it is not a general CI
   policy decision for the rest of the repo.

## Open questions

None blocking. The one genuinely open item from the delegated brief (real
symlink-success testing) is resolved as an explicit non-goal in Out of
scope, not left open.

## Existing files to read or re-check during implementation

- `.agents/scripts/install-agentic-framework.ps1` — re-read immediately
  before the refactor (task 2) to confirm line numbers/exact text still
  match this plan's Discovery evidence (line numbers can drift if anything
  else touches the file first).
- `.agents/scripts/sync-openspec-skills.ps1` — re-check only to confirm it
  still has no tests of its own and its own helper-function shapes, in case
  a future symmetrical test plan for it wants to reuse this plan's Pester
  conventions (informational only; this plan does not modify that file).
- `.agents/plans/cross-repo-framework-installer.md` — re-check Decisions 4
  (self-clobber), 6 (symlink-first install), 8 (single-file distribution),
  9 (self-containment), and 19 (CocoIndex) immediately before writing the
  corresponding E2E assertions, so tests assert the actually-decided
  behavior, not a remembered paraphrase of it.

## New and updated files

New:
```
.agents/scripts/tests/install-agentic-framework.Unit.Tests.ps1
.agents/scripts/tests/install-agentic-framework.E2E.Tests.ps1
.agents/scripts/tests/Invoke-Tests.ps1
.github/workflows/test-install-script.yml
```

Updated:
```
.agents/scripts/install-agentic-framework.ps1   (Decisions 2 and 3 only —
  one dot-source guard line, two extracted functions; no behavior change)
```

## Step-by-step ordered tasks

### 1. Refactor install-agentic-framework.ps1 for testability
- [ ] 1.1 Replace the inline `$normalize = { ... }` scriptblock (line 151)
      with a named function `Get-NormalizedRepoUrl` defined alongside the
      other helper functions (after `Copy-DirectoryIfChanged`); update the
      self-clobber guard's two call sites to call the function instead of
      invoking the scriptblock.
- [ ] 1.2 Extract the existing-symlink-target check from the task-7 loop
      into a named function `Test-SymlinkTarget($Item, $ExpectedPath)`
      returning `$true`/`$false`; update the loop to call it.
- [ ] 1.3 Add `if ($MyInvocation.InvocationName -eq '.') { return }`
      immediately after the last function definition, before
      `$report = New-Object ...`.
      Verify: syntax check under both `powershell.exe` and `pwsh.exe`
      (same tokenizer/parser check used during the original implementation);
      dot-source the file under `pwsh` (`. .\install-agentic-framework.ps1`)
      and confirm it returns immediately with no guard/clone/prompt output,
      then confirm `Get-Command Get-NormalizedRepoUrl` (etc.) succeeds in
      that same session, proving the functions loaded.

### 2. Re-verify no behavior change from the refactor
- [ ] 2.1 Re-run the exact manual scratch-repo flow already used twice this
      session (fresh scratch repo, `-Yes` run, idempotent re-run, both
      `pwsh.exe` and `powershell.exe`) once against the refactored script.
      Verify: output and resulting filesystem state match what the
      pre-refactor script produced (same report lines, same `.gitignore`
      contents, same skill placement) — this is a regression check, not new
      coverage; it confirms tasks 1.1-1.3 changed nothing observable.

### 3. Unit tests
- [ ] 3.1 Create `.agents/scripts/tests/install-agentic-framework.Unit.Tests.ps1`
      tagged `Unit`. In `BeforeAll`, dot-source the (refactored) script from
      its real path (`$PSScriptRoot\..\install-agentic-framework.ps1`).
- [ ] 3.2 `Get-FileHashHex`: write known content to a `TestDrive:` file,
      assert the returned hex string matches a precomputed SHA256 for that
      exact content, is uppercase, and contains no `-` separators.
- [ ] 3.3 `Compare-DirectoryContent`: three cases against `TestDrive:`
      fixtures — destination missing → `"missing"`; destination is a
      byte-identical copy → `"identical"`; destination has one differing
      file → `"different"`.
- [ ] 3.4 `Add-IgnoreLine`: destination file absent → created containing
      exactly the one line; file present without the line → line appended,
      existing content preserved; file present with the exact line already
      → returns `$false`, file byte-count unchanged (no duplicate line).
- [ ] 3.5 `Copy-DirectoryIfChanged`: source→missing-destination returns
      `"installed"` and destination now matches source (via
      `Compare-DirectoryContent` returning `"identical"` afterward);
      source→identical-destination returns `"unchanged"`.
- [ ] 3.6 `Get-NormalizedRepoUrl`: the exact regression case — a URL with no
      literal `.git` suffix but ending in a character from the set
      `{.,g,i,t}` (e.g. `https://github.com/x/framework-testing`) must
      round-trip unchanged (lowercased, trailing `/` trimmed) rather than
      losing trailing characters; a URL with a real `.git` suffix has
      exactly that suffix removed; trailing-slash and case variations of
      the same URL normalize to the same value.
- [ ] 3.7 `Test-SymlinkTarget`: construct a fake item
      (`[pscustomobject]@{ LinkType = 'SymbolicLink'; Target = @($realPath) }`
      where `$realPath` is a real `TestDrive:` file/folder) — matching
      target → `$true`; a different real `TestDrive:` path as target →
      `$false`; `LinkType` not `SymbolicLink` → `$false`; `Target` pointing
      at a path that doesn't exist → `$false`, no exception thrown.
      Verify: `Invoke-Pester -Path .agents/scripts/tests -Tag Unit -Output
      Detailed` passes with zero failures, and a deliberately-reintroduced
      copy of the original `TrimEnd('.git')` bug (test-only, reverted after)
      is confirmed to fail test 3.6 — proving the test actually catches the
      regression it's named for.

### 4. E2E tests
- [ ] 4.1 Create `.agents/scripts/tests/install-agentic-framework.E2E.Tests.ps1`
      tagged `E2E`. `BeforeEach` creates a fresh scratch dir under
      `[System.IO.Path]::GetTempPath()`, `git init`s it, copies the
      refactored script in; `AfterEach` removes the scratch dir.
- [ ] 4.2 Not-a-git-repo guard: run the script (via child process, either
      engine) from a non-git scratch folder; assert non-zero exit and no
      `.agents/`/`.gitignore` created.
- [ ] 4.3 Self-clobber guard: `git remote add origin <SourceUrl-under-test>`
      in the scratch repo, run with that same `-SourceUrl`; assert non-zero
      exit and no `.agents/`/`.gitignore` appear in the scratch repo
      afterward (the guard must fire before task 5's copy step runs). Do
      not attempt to detect the temp clone directory itself: it's named with
      a runtime-generated GUID (`install-agentic-framework.ps1` line 165,
      `"agentic-framework-" + [System.Guid]::NewGuid().ToString("N")`),
      unknowable to the test in advance, so no marker-file check on it is
      possible — the absence of any target-repo side effect is the
      observable proxy for "never cloned."
- [ ] 4.4 Happy-path structural assertions (no `openspec`/`ccc` required):
      run `-Yes` with `-SourceUrl <local repo path>` (Decision 5); assert
      `.agents/templates`, `.agents/start`, `.agents/reference` exist and
      are non-empty, `.gitignore` contains exactly one
      `.claude/settings.local.json` line, at least the `todo` skill folder
      exists under both `.agents/skills/` and `.claude/skills/`. Repeat
      immediately (second run, same repo) and assert: no new/changed
      `.gitignore` line count, report output shows `unchanged`/`up-to-date`
      for everything from the first run.
- [ ] 4.5 OpenSpec-dependent case (skipped via `Set-ItResult -Skipped` when
      `Get-Command openspec` is absent): assert `openspec/config.yaml`
      exists after the run and, when `openspec-mod/` exists in the source
      repo (true for this repo today), that the schema-install step's
      report line indicates success, not the "not found" skip branch.
- [ ] 4.6 CocoIndex-dependent case (skipped when `ccc` is absent, per
      Decision 7): assert the report contains one of the four documented
      CocoIndex outcome strings and never an unhandled exception.
- [ ] 4.7 Interactive re-prompt case: pipe `"bogus`nb`n"` style stdin (an
      invalid token, then a valid selection) into a child-process invocation
      without `-Yes`; assert the process's stdout contains the
      "Could not parse" message once, then completes successfully with the
      valid selection's skill installed — this is the exact regression this
      plan calls out from the `/subagent-verify` fix pass.
- [ ] 4.8 Both engines: parameterize 4.2-4.7 to run once with the child
      process as `pwsh.exe -File ...` and once as `powershell.exe -File
      ...` (Decision 6) — e.g. via Pester's `-ForEach @('pwsh','powershell')`
      on the `Describe`/`Context` block.
      Verify: `Invoke-Pester -Path .agents/scripts/tests -Tag E2E -Output
      Detailed` passes (with expected skips reported, not failures, on a
      machine/CI runner lacking `openspec`/`ccc`).

### 5. Local test runner
- [ ] 5.1 Create `.agents/scripts/tests/Invoke-Tests.ps1`: checks for Pester
      `-MinimumVersion 5.0`, installs it (Decision 1) if missing with a
      clear one-line message, then runs
      `Invoke-Pester -Path $PSScriptRoot -Tag $Tag -Output Detailed` where
      `$Tag` is a `-Tag` parameter defaulting to `@('Unit','E2E')` (so
      `-Tag Unit` alone runs only the fast layer).
      Verify: `pwsh -File .agents/scripts/tests/Invoke-Tests.ps1 -Tag Unit`
      and the same with `-Tag E2E` both run cleanly end to end.

### 6. CI workflow
- [ ] 6.1 Create `.github/workflows/test-install-script.yml`: trigger on
      `push`/`pull_request` touching `.agents/scripts/install-agentic-framework.ps1`
      or `.agents/scripts/tests/**`; single job on `windows-latest`;
      `actions/checkout@v4`; run
      `pwsh -File .agents/scripts/tests/Invoke-Tests.ps1` (both tags, letting
      task 3/4's own skip logic handle missing `openspec`/`ccc` on the
      runner — `npm`/`node` are present on `windows-latest` by default, so
      the `openspec` CLI can optionally be installed as a prior step to
      widen 4.5's coverage; `ccc` is not expected to be installable and 4.6
      stays skipped in CI, which is expected and acceptable).
      Verify: push a branch with this workflow and confirm the Actions run
      completes and reports the expected pass/skip split (not a hang or a
      false green from an empty test discovery).

## Test strategy

- **Unit** (task 3): pure/near-pure helper functions, `TestDrive:`-scoped,
  no network, no external tool beyond PowerShell/.NET built-ins and
  `robocopy` (OS-native). Fast, always run.
- **E2E** (task 4): real scratch git repos, real child-process invocation of
  the installer under both engines, real `git`/optionally-real
  `openspec`/`ccc`. Slower, gracefully skips tool-dependent branches rather
  than failing when a tool is absent.
- **Regression proof** (task 3's verify step): the two bugs found by hand
  this session (`TrimEnd` char-set gotcha, untrusted stale symlink) each map
  to one specific unit test (3.6, 3.7) that is confirmed to fail against a
  deliberately-reintroduced copy of the original buggy code before being
  reverted — this is the concrete evidence that the test suite would have
  caught what manual testing only caught by luck.

## Validation commands

```powershell
# Syntax check (refactored script)
powershell -NoProfile -Command ". '.agents\scripts\install-agentic-framework.ps1' -WhatIf"
pwsh -NoProfile -Command ". '.agents/scripts/install-agentic-framework.ps1' -WhatIf"

# Unit tests only (fast loop)
pwsh -File .agents/scripts/tests/Invoke-Tests.ps1 -Tag Unit

# Full suite (unit + E2E)
pwsh -File .agents/scripts/tests/Invoke-Tests.ps1

# E2E only, verbose
pwsh -NoProfile -Command "Invoke-Pester -Path .agents/scripts/tests -Tag E2E -Output Detailed"
```

## Acceptance criteria checklist

- [ ] `install-agentic-framework.ps1` can be dot-sourced with zero
      side effects (no guard exit, no clone, no prompt) and exposes every
      helper function afterward.
- [ ] `Get-NormalizedRepoUrl` and `Test-SymlinkTarget` exist as named
      functions with identical behavior to the code they replaced (task 2's
      regression check).
- [ ] All Unit-tagged tests pass; `Get-NormalizedRepoUrl`'s test fails
      against a deliberately-reverted buggy version (proves regression
      coverage) and passes against the current code.
- [ ] All E2E-tagged tests pass on a machine with `git`, `openspec`, and
      `npm` available; tool-dependent cases (`openspec`, `ccc`) report as
      Pester skips, not failures or false passes, when those tools are
      absent.
- [ ] E2E tests never clone from the real GitHub URL (Decision 5) and never
      leave a scratch repo behind on failure (cleanup runs in `AfterEach`
      regardless of test outcome).
- [ ] Both engines (`pwsh.exe`, `powershell.exe`) are exercised as the
      subject under test by the E2E suite (Decision 6).
- [ ] `Invoke-Tests.ps1` bootstraps Pester 5.x when only the bundled 3.4.0 is
      present, with a clear message, not a silent version mismatch failure.
- [ ] CI workflow runs on `windows-latest`, triggers on changes to the
      installer or its tests, and completes without hanging or false-greening
      on empty test discovery.
- [ ] No behavior change to `install-agentic-framework.ps1` from a real
      user's perspective (task 2's re-verification against the pre-existing
      manual E2E flow).

## Risks, assumptions, and fallbacks

- **Risk:** `Install-Module -Name Pester` requires PowerShell Gallery
  reachability; a fully offline machine or a network-locked-down CI runner
  can't bootstrap Pester 5.x. *Mitigation:* `Invoke-Tests.ps1` prints a clear
  failure message naming the exact missing prerequisite (matches this
  repo's existing pattern for `openspec`/`npm` absence) rather than a raw
  `Install-Module` stack trace; `windows-latest` GitHub-hosted runners have
  outbound internet access by default, so CI itself is not at risk.
- **Risk:** E2E tests mutate real machine-global state — specifically, the
  `npm install -g @fission-ai/openspec` remediation path, `ccc index`'s own
  global CocoIndex config, and `sync-openspec-skills.ps1`'s read of
  `%LOCALAPPDATA%\openspec\schemas\...` (per-skill/per-repo installs under
  `.agents/skills/`/`.claude/skills/` are scratch-repo-local, not global —
  they're rooted at `$cwd`, i.e. the scratch repo, not `$HOME`) —
  same as any real run of the installer, inherent to the tool, not
  introduced by this plan. *Mitigation:* on CI this is a fresh VM per run
  (no accumulation across runs); locally, this exactly matches the
  side effects a developer already accepts by running the script by hand,
  and the E2E tests use the same idempotent, hash-compared writes the
  script always uses, so repeated local test runs don't corrupt anything.
- **Risk:** the symlink-success path (real `New-Item -ItemType
  SymbolicLink` succeeding) stays untested end-to-end on this machine and
  possibly in CI. *Mitigation:* explicitly out of scope (see Out of scope);
  the decision-logic half of that code path (`Test-SymlinkTarget`) is unit
  tested without needing a real symlink (Decision 3), which is the part
  that actually had a bug this session — the copy-fallback path (which
  every test environment so far *does* exercise, since symlink creation is
  denied) remains covered by the E2E happy-path assertions.
- **Assumption:** GitHub Actions `windows-latest` ships `git` and `node`/
  `npm` preinstalled (true as of current runner images) — if that ever
  changes, task 6.1's optional `openspec` CLI install step would need an
  explicit Node setup step added; not anticipated as likely.
- **Fallback:** if Pester 5.x's `-ForEach` parameterization (Decision 6)
  proves awkward for driving two separate child-process engines cleanly,
  fall back to two fully separate `Context` blocks (one hardcoded to
  `pwsh.exe`, one to `powershell.exe`) with duplicated `It` bodies — more
  repetition, same coverage, lower risk if `-ForEach` has surprising scoping
  behavior under Pester 5.x's discovery/run phase split.

## Compatibility notes

- **Sources checked:** `.agents/scripts/install-agentic-framework.ps1` (full
  read, current commit), `.agents/scripts/sync-openspec-skills.ps1` (full
  read, confirms no existing test convention), `Get-Module -ListAvailable
  Pester` (both engines, confirms only 3.4.0 present), `Test-Path .github`
  (confirms no CI exists), repo-wide search for `AGENTS.md`/`.agents/PRD.md`/
  `*ADR*` (confirms no ADR process exists).
- **Compatibility with current stack:** Full for the script refactor (no
  behavior change, verified by task 2). New for testing/CI: Pester 5.x
  (dev/CI-only dependency, not shipped to end users of the installer script)
  and one GitHub Actions workflow (this repo's first, but standard, free for
  public/private repos within normal usage, and additive — it cannot break
  any existing process since none exists yet).
- **Existing stack alternatives considered:** writing tests in a different
  language/runner entirely (e.g. a Python test harness shelling out to
  PowerShell) — rejected, adds a second language/runtime dependency to a
  repo that is otherwise pure PowerShell/markdown, for no benefit over
  Pester, which is PowerShell's own standard and already partially present
  (3.4.0) on the target platform. Manual-testing-only, no automation —
  rejected as the status quo this plan exists to fix (the `TrimEnd` bug
  already shipped once under manual-only testing).
- **ADR required: no** — see Decision 4. No ADR convention exists in this
  repo to record one in; the decision and its rationale live in this plan's
  Decisions section instead, consistent with how the parent installer plan
  already records its own 19 decisions the same way.

## No user-facing impact identified beyond CI/test-output surfaces

This plan adds developer/CI-facing test tooling only. Its only "user-facing"
surface is Pester's own console/CI output (pass/fail/skip reporting) and the
CI workflow's status check — both use Pester's and GitHub Actions' standard,
already-established output conventions rather than inventing new ones.
