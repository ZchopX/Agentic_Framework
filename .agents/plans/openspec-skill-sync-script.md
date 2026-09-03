# OpenSpec Skill/Schema Sync Script

## Feature description and user value

`openspec-mod/` (staged per `.agents/plans/openspec-verification-schema.md`) holds a
forked OpenSpec schema and a new `openspec-verify` skill, both meant to be promoted
to fixed global locations before either Claude Code or Codex can actually use them.
Today that promotion is three manual `Copy-Item` commands from `openspec-mod/README.md`,
with no way to tell whether a machine's global copies are already current, stale, or
missing without eyeballing file contents by hand.

This plan adds one PowerShell script that checks all three global destinations,
compares each against the repo's staged source by content (not just presence or
timestamp), and installs/updates only what's missing or different — safe to run
repeatedly, and correct whether the machine has PowerShell 7 or only the
preinstalled Windows PowerShell 5.1.

## In scope / out of scope

**In scope:**
- One new script, `.agents/scripts/sync-openspec-skills.ps1`, that syncs exactly the
  three destinations already documented in `openspec-mod/README.md`:
  1. OpenSpec schema fork → `%LOCALAPPDATA%\openspec\schemas\spec-driven-verified\`
  2. Claude Code skill → `%USERPROFILE%\.claude\skills\openspec-verify\`
  3. Codex skill → `%USERPROFILE%\.agents\skills\openspec-verify\`
- Content-based comparison (hash, not size/timestamp) so a destination that merely
  looks present isn't mistaken for up to date.
- Idempotent, re-runnable sync; no separate "install" vs "update" code path.
- Correct, unmodified operation under both `powershell.exe` (5.1, preinstalled on
  every Windows 10/11 machine) and `pwsh.exe` (7+, this author's shell but not
  guaranteed present elsewhere).
- A `-WhatIf` preview mode (standard PowerShell idiom) so a user can see planned
  changes before anything is written.
- A short update to `openspec-mod/README.md` pointing at the script as the
  automated alternative to the three manual `Copy-Item` blocks (the manual
  commands stay, for anyone who wants to copy-paste without running a script).

**Out of scope:**
- Installing, updating, or detecting the OpenSpec CLI itself — the script only
  checks for it (`Get-Command openspec`) to annotate its report; it does not
  `npm install` anything.
- Any change to `openspec-mod/`'s staged content, the forked schema, or the
  `openspec-verify` skill — this plan only builds a delivery mechanism for files
  that already exist and were verified in the prior plan.
- Uninstall/rollback tooling — not requested, and removing a global skill/schema
  a user may have customized locally is a materially different, riskier operation.
- Cross-platform (macOS/Linux) support — the three destinations and the whole
  premise (`%LOCALAPPDATA%`, `%USERPROFILE%`, Claude Code/Codex global folders on
  Windows) are Windows-specific by the user's explicit ask ("any win 10 win 11 pc").
- Multi-machine CI/automated test execution — this repo has no CI and no other
  Windows test machine available in this environment (see Risks).

## Discovery evidence

- `.agents/plans/openspec-verification-schema.md` — defines the three exact
  source/destination pairs this script must sync (`openspec-mod/openspec-schemas/spec-driven-verified/` → `%LOCALAPPDATA%\openspec\schemas\spec-driven-verified\`; `openspec-mod/claude-skills/openspec-verify/` → `%USERPROFILE%\.claude\skills\openspec-verify\`).
- `.agents/reports/openspec-verification-schema-execution-handoff.md` — confirms
  `openspec-mod/` currently holds exactly those files, untouched since; no drift
  to account for.
- `openspec-mod/README.md` (as it stands after this session's doc update) —
  already documents a third destination, `%USERPROFILE%\.agents\skills\openspec-verify\`,
  for Codex, sourced from the same `openspec-mod/claude-skills/openspec-verify/`
  folder as Claude's target — confirmed via the official Codex skill-discovery docs
  (https://learn.chatgpt.com/docs/build-skills: Codex checks `$HOME/.agents/skills`
  among other locations, not `~/.codex/skills`).
- `.agents/scripts/prepare-ai-code-discovery.ps1` — the repo's one existing
  PowerShell script and its only established convention for this kind of task.
  Directly reusable patterns confirmed by reading it in full:
  - `param()` block + `$ErrorActionPreference = "Stop"` at the top, no
    `[CmdletBinding()]`/advanced-function ceremony beyond what's needed.
  - A small `Get-CommandStatus` helper wrapping `Get-Command -ErrorAction SilentlyContinue`
    for optional-tool detection — the same shape needed here for detecting `openspec`.
  - A `Copy-StartupFile` helper that already does *exactly* this plan's core
    comparison logic for single files: `Get-FileHash -Algorithm SHA256` on both
    sides, `-eq` on `.Hash`, return `"unchanged"` / `"copied"` / `"overwritten"`.
    This script's job is the same idea generalized from single files to whole
    directory trees (many files per target, added/removed files must also be
    detected — a single-file hash pair isn't enough).
  - `$PSScriptRoot`-relative `Join-Path` to locate sibling repo content (`Join-Path
    $PSScriptRoot "..\start"`), rather than assuming a working directory or
    depending on `git rev-parse` for a path that's always at a fixed relative
    location to the script itself — reusable here since `openspec-mod/` sits at a
    fixed relative path from `.agents/scripts/` regardless of caller cwd. (The
    existing script does separately use `git rev-parse --show-toplevel`, but only
    to locate an arbitrary *target* repo passed via `-TargetPath` — a different
    problem than this script's, which always syncs *this* repo's own staged files.)
  - Uses `$HOME` in one place (`Join-Path $HOME ".cocoindex_code\global_settings.yml"`).
    Superseded here — see Decision 2 below; this plan intentionally does not copy
    that specific usage.
  - Plain `Write-Host` progress lines and a final "Changes:" summary loop — the
    reporting style this script's final summary should match.
- Web research (subagent, this session) into current PowerShell command syntax and
  known gotchas — the six numbered findings quoted in full under Decisions below,
  each with a source URL. No repo file conflicts with any of it; there is no
  existing PSScriptAnalyzer config, Pester test setup, or PowerShell style guide in
  this repo to reconcile against.

## Existing system fit

- Lives alongside the repo's one existing script in `.agents/scripts/`, following
  its exact structural conventions (param block, helper functions, `Write-Host`
  reporting, `$ErrorActionPreference = "Stop"`) rather than introducing a new
  scripting style.
- Reads from `openspec-mod/`, writes only to global (outside-repo) locations —
  never touches another repo file, matching the boundary the verification-schema
  plan already established (`openspec-mod/` is the only thing this whole feature
  family is allowed to produce inside the repo).
- Extends, not replaces, `openspec-mod/README.md`'s existing manual-copy
  instructions — the script is offered as a faster path to the same three copies
  the README already specifies, not a new/different promotion mechanism.

## Reuse opportunities

- `Copy-StartupFile`'s hash-compare-and-report pattern from
  `prepare-ai-code-discovery.ps1` is reused directly for the per-file comparison
  primitive, generalized to walk a directory tree (see Decision 1).
- `Get-CommandStatus` is reused near-verbatim for the informational `openspec`
  CLI-on-PATH check.
- The existing script's overall shape (param block → helper functions → main body
  → `Write-Host` summary) is reused as the whole script's skeleton, rather than
  inventing a new layout.

## Decisions and tradeoffs

Each decision below is grounded in one of the six numbered findings from this
session's web research (quoted inline for traceability); no command in this plan
deviates from that research without an explicit reason stated here.

1. **Directory comparison: per-file `Get-FileHash` (SHA256) + `Compare-Object` on
   (relative path, hash) pairs — not a naive hash-list, not `robocopy /L`.**
   Research: *"No built-in folder-diff cmdlet exists. Working pattern: per-file
   hash + Compare-Object on (RelativePath, Hash) pairs — this also catches
   added/removed files, unlike a naive hash-list compare. robocopy /L ... compares
   by size+timestamp not content ... Get-FileHash is the authoritative check."*
   Rejected: trusting `robocopy /L` alone (wrong after any operation that resets
   timestamps without changing content, e.g. a fresh `git clone`); comparing only
   a concatenated/aggregate hash (doesn't identify *which* files differ for the
   report, and doesn't cleanly catch "source has a new file destination lacks").

2. **Use `$env:USERPROFILE`, not `$HOME`, for the profile root; `$env:LOCALAPPDATA`
   for the schema path.** Research: *"`$HOME` has a documented reliability bug
   (PowerShell/PowerShell#17685) ... Use `$env:USERPROFILE` on Windows, not `$HOME`
   ... `$env:LOCALAPPDATA` and `[Environment]::GetFolderPath('LocalApplicationData')`
   are identical on Windows; `$env:LOCALAPPDATA` is simpler and sufficient."* This
   is a deliberate deviation from `prepare-ai-code-discovery.ps1`'s one `$HOME`
   usage — not a repo-convention violation, since that script's `$HOME` use
   predates this research and isn't part of the pattern being reused here (see
   Discovery evidence). Rejected: `[Environment]::GetFolderPath(...)` for
   `%LOCALAPPDATA%` — functionally identical on Windows per research, so the
   simpler `$env:LOCALAPPDATA` wins on the ladder ("stdlib/native already covers
   it, don't add a wrapper").
   **OneDrive question resolved (checked live, not just assumed):** verified
   directly on the author's own OneDrive-enabled machine — `HKCU:\SOFTWARE\
   Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders` shows OneDrive's
   Known Folder Move redirects `Personal` (Documents) and `My Pictures` into
   `...\OneDrive\...`, but `Local AppData` stays at `C:\Users\<user>\AppData\Local`
   and the profile root stays at `C:\Users\<user>` — matching
   `$env:LOCALAPPDATA`/`$env:USERPROFILE` and `[Environment]::GetFolderPath(...)`
   exactly, with zero redirection. Confirms OneDrive's Known Folder Move only
   ever targets Desktop/Documents/Pictures-class folders, never the profile root
   or LocalAppData. Residual caveat: verified against one real OneDrive
   configuration, not an exhaustive survey of every possible IT-managed OneDrive
   policy — but there is no standard OneDrive feature that redirects either path,
   so this is no longer treated as an open question.

3. **Sync via `robocopy /MIR`, not `Copy-Item -Recurse -Force`; exit code checked
   via `$LASTEXITCODE -ge 8`, never `$?`.** Research: *"`Copy-Item -Recurse -Force`
   does NOT delete stale destination files absent from source ... robocopy /MIR
   (mirror) is the safer choice for sync-only-if-different, since it deletes stale
   files too ... never check `$?` after robocopy — robocopy returns 1 for a normal
   successful copy, which PowerShell's native-command `$?` mapping treats as
   failure. Must branch on `$LASTEXITCODE -ge 8`."* This also directly serves the
   "no partial/corrupt state if interrupted" acceptance criterion: `robocopy /MIR`
   is itself resumable — rerunning it after an interruption converges to the same
   correct end state without any extra staging/atomic-rename layer. Building a
   temp-dir-then-rename wrapper around it would be unrequested complexity solving
   a problem `/MIR` already solves. Rejected: `Copy-Item -Recurse -Force` (leaves
   stale files behind — the exact bug this decision avoids); a hand-rolled
   temp-dir + `Move-Item` swap (solves a problem robocopy's own resumability
   already covers).

4. **Write plain PowerShell 5.1-compatible syntax throughout (no `??`, no
   ternary `?:`, no PS7-only cmdlets); detect and report the running engine via
   `$PSVersionTable.PSEdition`/`PSVersion` but do not require PS7.** Research:
   *"`powershell.exe` (5.1, preinstalled on every Win10/11 machine) vs `pwsh.exe`
   (7+, must be separately installed) are different executables ... All commands
   needed here (Get-FileHash, Copy-Item, robocopy, Compare-Object,
   [Environment]::GetFolderPath) exist and behave identically in both 5.1 and 7 —
   no version-gated syntax found. RECOMMENDATION: write plain PS-5.1-compatible
   syntax throughout ... so the same .ps1 runs unmodified under either engine."*
   Matches the user's explicit requirement ("must work on any win 10 win 11 pc,"
   author has pwsh 7 but the script must not assume it). Rejected: requiring pwsh
   7 and erroring out on 5.1-only machines — narrower than the stated requirement
   for no documented benefit (research found zero behavioral differences in the
   cmdlets this script needs).
   **Win10-vs-Win11 default execution policy: unconfirmed, but moot by design.**
   No source found whether the two differ out of the box. This is not a live open
   question because the script's behavior never depends on the answer either
   way — the documented `-ExecutionPolicy Bypass` invocation flag (Decision 5)
   is process-scoped and works identically regardless of whatever the machine's
   persistent default policy is, so there's nothing here left to resolve before
   implementation, and nothing the script needs to detect or branch on.

5. **Do not call `Set-ExecutionPolicy` inside the script; document the two safe
   invocation options in the script's header comment and in the README instead.**
   Research: *"Per-invocation, no persistent change: `powershell.exe
   -ExecutionPolicy Bypass -File .\script.ps1` ... Or process-scoped inside the
   script itself, as its first line: `Set-ExecutionPolicy -Scope Process
   -ExecutionPolicy Bypass` ... `Unblock-File` removes Mark-of-the-Web; needed
   only if the script was downloaded via browser/email, not if git-cloned."*
   Chosen: document the per-invocation flag (`-ExecutionPolicy Bypass`) as the
   recommended way to run the script, rather than have the script silently set
   its own process-scoped policy — a script changing execution policy on its own
   initiative, even process-scoped, is a security-relevant side effect the user
   didn't ask for. `Unblock-File` guidance is documented as conditional ("only if
   you downloaded rather than `git clone`d this repo"), not run automatically,
   for the same reason. Rejected: baking `Set-ExecutionPolicy -Scope Process` into
   the script — technically process-scoped and reversible, but still an
   unrequested, silent policy change; a documented flag achieves the same result
   with the user in control.

6. **`Get-Command openspec -ErrorAction SilentlyContinue` for the informational
   CLI-presence check, annotating the report only — never blocking the sync.**
   Research: *"`$cmd = Get-Command openspec -ErrorAction SilentlyContinue` ...
   CONFIRMED GOTCHA: npm global installs on Windows produce both a `.cmd` shim
   and a `.ps1` script ... a shell session opened BEFORE a global npm install
   won't see the PATH update."* Because of that confirmed gotcha, a "not found"
   result is treated as informational only ("openspec CLI not detected on PATH —
   the schema file will be in place but won't take effect until `openspec` is
   installed, or until a session opened after installing it"), never as a reason
   to skip copying the schema files themselves — the files should sync regardless
   of whether the CLI happens to be visible in *this* particular session. Rejected:
   also checking the npm global prefix as a fallback (research's suggested
   mitigation for the PATH-timing gotcha) — that fallback exists to avoid a false
   negative *blocking* an action; since this script never blocks on the result,
   the extra fallback lookup has no behavior to protect and would be unused
   complexity.

7. **New skill/schema definitions are not touched; this script only ever reads
   `openspec-mod/` and writes to the three destinations.** Matches the plan's own
   scope boundary and the prior plan's established pattern (`openspec-mod/` as a
   read-only source once staged).

## Open questions

None. Both research-flagged unknowns from initial drafting are closed:
OneDrive profile-folder redirection was checked live against the author's own
machine and confirmed not to affect `$env:USERPROFILE`/`$env:LOCALAPPDATA`
(Decision 2); the Windows 10-vs-11 default execution policy was never actually
blocking, since the documented invocation flag (Decision 5) makes the script's
behavior independent of that default either way.

## Existing files to read or re-check during implementation

- `.agents/scripts/prepare-ai-code-discovery.ps1` — re-read in full immediately
  before writing the new script, to match its exact param-block/helper-function/
  `Write-Host`-summary structure rather than approximating it from this plan's
  paraphrase.
- `openspec-mod/README.md` — re-read before editing it, to insert the "automated
  alternative" note in the right place relative to the three existing manual
  `Copy-Item` sections without disturbing them.
- `.agents/plans/openspec-verification-schema.md` and
  `.agents/reports/openspec-verification-schema-execution-handoff.md` — re-check
  that the three source/destination pairs haven't changed since this plan was
  written (they shouldn't have — `openspec-mod/` is treated as stable staged
  output — but confirm before hardcoding the paths into the script).

## New and updated files

New:
```
.agents/scripts/sync-openspec-skills.ps1
```

Updated:
```
openspec-mod/README.md   — add a short "Automated sync" note pointing at the new
                            script, above or alongside the existing manual steps
```

No other file is touched. `openspec-mod/`'s staged content itself is read-only
input to this script and is not modified by this plan.

## Step-by-step tasks

### 1. Scaffold the script
- [ ] 1.1 Create `.agents/scripts/sync-openspec-skills.ps1` with a `param()` block:
      `[CmdletBinding(SupportsShouldProcess)]`, `-Targets` (`ValidateSet('Schema','Claude','Codex','All')`, default `'All'`). `SupportsShouldProcess` gives a standard, zero-extra-code `-WhatIf`/`-Confirm` preview mode for free — no separate hand-rolled dry-run flag needed. Set `$ErrorActionPreference = "Stop"` at the top, matching the existing script. Verify: `powershell -NoProfile -Command ". '.agents\scripts\sync-openspec-skills.ps1' -WhatIf"` parses without syntax errors (empty body at this stage is fine).

### 2. Path resolution
- [ ] 2.1 Resolve `$repoRoot` via `Resolve-Path (Join-Path $PSScriptRoot "..\..")`,
      matching the existing script's `$PSScriptRoot`-relative convention rather
      than a `git rev-parse` lookup (this script always syncs its own repo's
      staged files, never an arbitrary target repo, so the simpler relative path
      is correct here — see Discovery evidence). Verify: `Write-Host $repoRoot`
      prints the repo root regardless of the caller's current directory.
- [ ] 2.2 Define the three targets as an array of `[pscustomobject]` (`Name`, `Key`
      matching the `-Targets` ValidateSet values, `Source`, `Destination`), using
      `$env:USERPROFILE` and `$env:LOCALAPPDATA` (Decision 2) — not `$HOME` or
      `[Environment]::GetFolderPath`. Verify: print the resolved `Source`/
      `Destination` pairs and confirm they match `openspec-mod/README.md`'s three
      documented pairs exactly.

### 3. Directory comparison helper
- [ ] 3.1 Write a `Compare-DirectoryContent` function: given `Source`/`Destination`
      paths, return `"missing"` if `Destination` doesn't exist (via `Test-Path`);
      otherwise build per-file `(RelativePath, Hash)` objects for both trees using
      `Get-ChildItem -Recurse -File` + `Get-FileHash -Algorithm SHA256` (Decision 1),
      diff them with `Compare-Object -Property RelativePath,Hash`, and return
      `"identical"` or `"different"`. Verify: manually create two tiny scratch
      folders (identical, then with one byte changed, then with an extra file) in
      the scratch directory (not inside the repo) and confirm the function reports
      `"identical"`, `"different"`, and `"different"` respectively for the three
      cases; delete the scratch folders afterward.

### 4. Sync helper
- [ ] 4.1 Write a `Sync-Target` function wrapping
      `robocopy $Source $Destination /MIR /NFL /NDL /NJH /NJS`, capturing
      `$code = $LASTEXITCODE` immediately after the call and throwing if
      `$code -ge 8` (Decision 3). Support `$PSCmdlet.ShouldProcess($Destination,
      "Sync from $Source")` so `-WhatIf` skips the actual `robocopy` call and
      reports what would happen instead. Verify: run against the same scratch
      folders from 3.1's "different" case with `-WhatIf` first (confirm no files
      change), then without, and confirm `Compare-DirectoryContent` now reports
      `"identical"`; delete the scratch folders afterward.

### 5. CLI-presence check (informational)
- [ ] 5.1 Write a small `Get-CommandStatus` helper (reused near-verbatim from
      `prepare-ai-code-discovery.ps1`) and use it once for `openspec`
      (Decision 6). Store the result for the final report only — it must not
      gate or skip any sync step. Verify: read the finished code path and confirm
      no `if`/`return` branches on this check before the schema target's sync
      runs.

### 6. Main loop and report
- [ ] 6.1 Filter the target list by `-Targets` (skip filtering when `'All'`), and
      for each remaining target: run `Compare-DirectoryContent`, then call
      `Sync-Target` only when the result is `"missing"` or `"different"`; collect
      per-target result objects (`Name`, `Status` = one of
      `up-to-date`/`installed`/`updated`/`would-install`/`would-update`/`failed`,
      `Detail`).
- [ ] 6.2 Print a header showing `$PSVersionTable.PSEdition`/`PSVersion` (so the
      report is self-documenting about which engine ran it — Decision 4), the
      `openspec` CLI-presence line from step 5, then a per-target summary table
      via `Write-Host` (matching the existing script's plain-text reporting
      style, not `Format-Table`, so output stays readable when piped/redirected).
      Verify: run once against a machine state with all three destinations
      already synced (from step 4's verify) and confirm the report shows
      `up-to-date` for all three with zero robocopy invocations.

### 7. Documentation
- [ ] 7.1 Add a short "Automated sync" section to `openspec-mod/README.md`
      pointing at `.agents/scripts/sync-openspec-skills.ps1`, including the
      recommended invocation
      (`powershell -ExecutionPolicy Bypass -File .agents\scripts\sync-openspec-skills.ps1`,
      Decision 5) and a one-line note on `-WhatIf` for a dry run. Leave the
      existing three manual `Copy-Item` sections in place, unedited, as a
      no-script fallback. Verify: read the finished README section back and
      confirm it doesn't contradict or duplicate the manual steps' wording.

### 8. End-to-end verification pass
- [ ] 8.1 From a clean state (no prior global installs — rename any existing real
      `openspec-verify`/`spec-driven-verified` global folders aside first if
      present, restore them after), run the script once under `pwsh.exe` and once
      under `powershell.exe`, and confirm both produce identical `installed`
      results for all three targets and identical file content afterward
      (re-run `Compare-DirectoryContent` manually or via the script's own report).
      Then edit one file in one destination, rerun, and confirm only that target
      reports `updated` while the other two report `up-to-date`. Restore any
      renamed-aside real global folders when done.

## Test strategy

No unit/integration test framework exists in this repo (confirmed: no Pester
config, no PSScriptAnalyzer settings file found). Verification is manual/CLI-driven,
mirroring `prepare-ai-code-discovery.ps1`'s own validation approach:
- Function-level: scratch-folder checks in tasks 3.1 and 4.1 (identical / one-byte
  diff / added-file cases).
- End-to-end: task 8.1, run against real global destinations, both engines
  (`pwsh.exe` and `powershell.exe`), covering first-install, no-op re-run, and
  drift-detected-and-fixed cases.
- All scratch/temp state created during verification is deleted afterward; any
  real pre-existing global folder touched during task 8.1 is restored, not left
  altered, if the machine already had a prior install.

## Validation commands

```powershell
# Syntax check
powershell -NoProfile -Command ". '.agents\scripts\sync-openspec-skills.ps1' -WhatIf"

# Dry run (no changes)
pwsh -File .agents\scripts\sync-openspec-skills.ps1 -WhatIf

# Real sync, PowerShell 7
pwsh -File .agents\scripts\sync-openspec-skills.ps1

# Real sync, Windows PowerShell 5.1 (must behave identically)
powershell -File .agents\scripts\sync-openspec-skills.ps1

# Confirm a specific destination matches source afterward
Get-FileHash -Path "$env:USERPROFILE\.claude\skills\openspec-verify\SKILL.md" -Algorithm SHA256
Get-FileHash -Path "openspec-mod\claude-skills\openspec-verify\SKILL.md" -Algorithm SHA256
```

## Acceptance criteria checklist

- [ ] Script runs correctly under both `powershell.exe` (5.1) and `pwsh.exe` (7)
      with no syntax or cmdlet errors and identical resulting file state.
- [ ] Script is idempotent: running it twice in a row with no intervening change
      produces `up-to-date` for all targets on the second run and performs zero
      `robocopy` writes.
- [ ] Script never leaves a partial/corrupt install if interrupted mid-copy —
      satisfied by `robocopy /MIR`'s own resumability (Decision 3); re-running
      the script after an interruption converges to the correct end state.
- [ ] All three destinations (`%LOCALAPPDATA%\openspec\schemas\spec-driven-verified\`,
      `%USERPROFILE%\.claude\skills\openspec-verify\`,
      `%USERPROFILE%\.agents\skills\openspec-verify\`) are checked and, when
      missing or different, synced from their exact `openspec-mod/` source.
- [ ] `-WhatIf` previews all planned changes without writing anything.
- [ ] `-Targets` correctly limits the run to a subset of the three destinations.
- [ ] The `openspec` CLI-presence check is informational only and never blocks or
      skips a sync.
- [ ] Final report clearly states, per target: already up to date / installed /
      updated / would-install / would-update (under `-WhatIf`), plus the
      PowerShell edition/version the script ran under.
- [ ] `openspec-mod/README.md` documents the script without altering or
      contradicting the existing manual `Copy-Item` steps.
- [ ] No file outside `.agents/scripts/sync-openspec-skills.ps1` and
      `openspec-mod/README.md` is created or modified by this work
      (`git status --porcelain` shows only those two).

## Risks, assumptions, and fallbacks

- **Risk:** No second physical Windows 10 (or PS-5.1-only) machine is available
  in this environment to fully validate cross-machine behavior. *Mitigation:*
  task 8.1 runs the script under both `powershell.exe` and `pwsh.exe` on the
  available Windows 10/11 dev machine — the two engines are the actual behavioral
  variable research found to matter (Decision 4 found no cmdlet differences
  attributable to the Windows 10-vs-11 OS version itself, only to the PS
  edition) — plus a full read-through confirming no PS7-only syntax was used
  anywhere in the script.
- **Verified (not just assumed):** `$env:USERPROFILE`/`$env:LOCALAPPDATA`
  resolve correctly under OneDrive folder redirection — checked live against the
  author's own OneDrive-enabled machine's registry and environment (Decision 2).
  Residual, low-probability risk: an atypical IT-managed OneDrive policy on some
  other machine could theoretically differ; if a user ever reports an unexpected
  destination path, the fix would be swapping to
  `[Environment]::GetFolderPath(...)` with an explicit redirection check — a
  small, isolated change, not a design rework.
- **Non-issue by design:** Windows 11's default execution policy doesn't need to
  match Windows 10's, because the documented `-ExecutionPolicy Bypass` invocation
  flag (Decision 5) works regardless of the machine's persistent default policy,
  since it only affects the one invoked process.
- **Risk:** `robocopy` is assumed present on every Windows 10/11 machine (it
  ships with Windows since XP Professional / all client SKUs since Vista) — no
  source contradicted this, but it wasn't independently reconfirmed for Windows
  11 specifically during research. *Mitigation:* low risk given `robocopy`'s long
  history as a built-in Windows component; if ever absent, the script's own
  `$LASTEXITCODE`-based error handling (Decision 3) will surface a clear failure
  rather than silently doing nothing.

## Compatibility notes

- **Sources checked:** `.agents/scripts/prepare-ai-code-discovery.ps1` (existing
  script conventions), `openspec-mod/README.md` (destination paths and existing
  manual promotion steps), `.agents/plans/openspec-verification-schema.md` and its
  execution handoff (source-of-truth for what `openspec-mod/` contains), plus
  this session's web research into `Get-FileHash`, `Copy-Item`/`robocopy`
  semantics, `$HOME` vs `$env:USERPROFILE`, PS 5.1 vs 7 edition differences,
  execution-policy invocation options, and `Get-Command`/npm-PATH behavior — each
  cited inline in Decisions 1-6 with source URLs.
- **Compatibility with current stack:** Full. This repo has no build system,
  package manager, or CI to integrate with (confirmed by `repo-primer`'s earlier
  findings: no `package.json`/`pyproject.toml`/lockfile/CI config exists) — a
  standalone `.ps1` script under `.agents/scripts/` matches the one precedent
  this repo already has for this exact kind of task.
- **Existing stack alternatives considered:** `Copy-Item -Recurse -Force` alone
  (rejected — leaves stale destination files, Decision 3); requiring PowerShell 7
  (rejected — narrower than the explicit "any win 10 win 11 pc" requirement,
  Decision 4); a Python or Node.js script (rejected — this is a Windows-only,
  filesystem-only task with zero existing Python/Node tooling in this repo to
  justify introducing either runtime as a new dependency category).
- **ADR required:** no — no new runtime, framework, database, package manager,
  build system, or dependency-policy decision; this is a single utility script
  using only built-in Windows/PowerShell facilities already present on every
  target machine by definition.

## No user-facing impact identified beyond CLI/report output

This is an operator-run utility script, not an application feature. The only
"user-facing" surface is the script's own console output (the per-target summary
report and `-WhatIf` preview messages), covered by task 6.2's verification and the
acceptance criterion on report clarity. No UI, no persistent user data, no
external user-facing behavior change beyond what running the script and reading
its report already covers.
