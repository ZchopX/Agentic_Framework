# Cross-Repo Agentic Framework Installer Script

## Feature description and user value

Today, adopting this repo's `.agents/` skill system, folder conventions, and the
`spec-driven-verified` OpenSpec schema/`openspec-verify` skill in a *different*
repo means manually copying files and running `sync-openspec-skills.ps1` from
inside this repo's own checkout. There is no single entry point a user can drop
into an unrelated repo and run to pull in what they want from
`Agentic_Framework`.

This plan adds one self-contained PowerShell script,
`install-agentic-framework.ps1`, that a user copies into any target repo and
runs once to: initialize OpenSpec, pull this repo's `.agents/` scaffolding and
a user-chosen subset of skills, install the `spec-driven-verified`
schema/`openspec-verify` skill when present, and optionally make that schema
the target repo's default. Re-running it later updates whatever was
previously installed — it is both the installer and the updater.

## In scope / out of scope

**In scope:**
- One new script, distributed from this repo, that a user copies into any
  other Windows repo and runs directly (no separate download step, no remote
  one-liner) — see Decision 8 on why a local file, not `irm | iex`.
- The 7 steps the user specified, in an order that respects real dependencies
  (fetch-before-copy), detailed under Decisions below.
- Re-run = update: same script, same invocation, diffs what's already present
  against the freshly cloned source and only touches what changed or what the
  user newly selects.
- Terminal-based (no GUI dependency) multi-select for skill choice.
- Windows 10/11, PowerShell 5.1 and 7+ — same constraints and the same
  `Get-FileHashHex`/`robocopy /MIR`/`$env:USERPROFILE` conventions already
  established and validated in `.agents/scripts/sync-openspec-skills.ps1`
  (this plan's implementation, task 3.1below, links to reusing that script,
  not just its patterns).

**Out of scope:**
- Publishing this script anywhere outside the `Agentic_Framework` repo itself
  (no raw-URL hosting, no package manager listing) — the user copies the file
  by hand; see Decision 8.
- Installing the OpenSpec CLI's *dependencies* (Node.js/npm) — the script
  detects and, only with explicit confirmation, runs `npm install -g
  @fission-ai/openspec`; it never installs Node/npm itself.
- Uninstall/rollback tooling for a target repo's `.agents/` tree — matches the
  existing `sync-openspec-skills.ps1` non-goal; this is an installer/updater,
  not a remover.
- Cross-platform (macOS/Linux) support — same rationale as the prior plan:
  Windows-specific paths and the user's explicit Windows framing.
- Anything about *this* repo's own `openspec/config.yaml` — this script is
  meant to run inside *target* repos adopting the framework, never against
  `Agentic_Framework` itself.
- Automatically resolving git merge conflicts or reconciling a target repo's
  hand-edited copy of a skill it once installed — the diff-and-report model
  (Decision 5) surfaces this to the user instead of guessing.

## Discovery evidence

- `git remote -v` (this repo) → `origin  https://github.com/ZchopX/Agentic_Framework.git`
  — the fixed clone source this script bakes in.
- `git status --porcelain` (this repo, current state) → **critical finding**:
  `openspec-mod/`, `.claude/`, `.agents/skills/openspec-{apply-change,
  archive-change,explore,propose,sync-specs,update-change}/`,
  `.agents/skills/.openspec-target`, and this session's new plan/report/script
  files are **all untracked** — not on GitHub yet. `git log origin/main -1`
  matches local HEAD exactly (no unpushed commits either — these files were
  simply never `git add`ed). See Decision 1 and Risks: this installer is not
  actually usable for the OpenSpec pieces (steps 1/6/7) until someone commits
  and pushes that work — a prerequisite outside this plan's scope to perform,
  but blocking for this plan's own end-to-end verification task.
- `git ls-files .agents/skills` → the 20 currently-tracked skills (everything
  under `.agents/skills/` except the 6 `openspec-*` ones and the
  `.openspec-target` marker file) — this is the real, current checkbox
  candidate list; it will grow once the untracked OpenSpec skills are
  committed, but the script must work correctly against *whatever* the clone
  actually contains at run time, not a hardcoded list (Decision 3).
- `.agents/skills/skills-usage-guide.md` → confirms `.agents/skills/` and
  `.claude/skills/` are meant to hold identical skill content for Codex vs.
  Claude Code respectively (this repo's own dual-copy convention) — the
  installer mirrors that same dual-copy into the target repo, not a new
  convention (Decision 4).
- `.agents/skills/todo/SKILL.md` → confirms `todo` is the one skill the user
  named as "necessary by default" (manages a per-repo `to-do.md`); no other
  skill in this repo is self-evidently required by every adopting repo, so
  `todo` is the only default-forced install (Decision 6).
- `.agents/skills/project-bootstrap/SKILL.md`, `repo-docs-bootstrap/SKILL.md`
  — read in full; both are single-repo, app-specific bootstraps (env setup,
  doc scaffolding) with no cross-repo installer/updater logic. No existing
  skill or script in this repo does what this plan asks; nothing to extend
  instead of building new.
- `.agents/scripts/sync-openspec-skills.ps1` (this session's prior
  implementation) — read in full. Directly reusable, unmodified, from inside
  a cloned copy of this repo: it resolves its own repo root via
  `$PSScriptRoot\..\..`, so running it from within a fresh `git clone` of
  `Agentic_Framework` (which preserves the same `.agents/scripts/` →
  `openspec-mod/` relative layout) needs no parameterization change (Decision
  2). This is the concrete mechanism for the user's step 6.
- `openspec-mod/README.md`, `openspec/config.yaml` (this repo's own, for
  reference on shape) — confirms the `schema:` field is a single top-level
  YAML scalar (`schema: spec-driven`), i.e. line-anchored and simple enough to
  edit with a targeted line replace instead of a full YAML parse/round-trip
  (Decision 7 — no YAML library dependency needed).
- `dist/core/project-config.js` inside the installed `@fission-ai/openspec`
  npm package (inspected live, per the prior conversation turn) — confirms
  `openspec schemas` labels a schema `(user override)` purely based on where
  its definition was *found* (project/user/package precedence), never based
  on which schema is *active* for a project; only `openspec/config.yaml`'s
  `schema:` field decides that. This directly informs step 7's necessity
  (setting the schema active is a separate, required action even after the
  files are in place) and is why this plan treats steps 6 and 7 as two
  distinct, independently-confirmable actions rather than one.

## Existing system fit

- Distributed from `Agentic_Framework` itself, under `.agents/scripts/`
  alongside `sync-openspec-skills.ps1` — same location convention, so a user
  who already found one script finds the other.
- Directly invokes `sync-openspec-skills.ps1` from the freshly cloned temp
  copy rather than re-implementing its comparison/sync logic — the two
  scripts are cooperating tools, not duplicated ones.
- Reuses this repo's own dual-location skill convention (`.agents/skills/` +
  `.claude/skills/`) for what it writes into the *target* repo, so a target
  repo that adopts this framework ends up with the same shape
  `Agentic_Framework` itself uses, not a new one invented for this script.
- Never modifies `Agentic_Framework` itself — it only reads (via a disposable
  clone) and writes into whatever repo it's run from.

## Reuse opportunities

- `sync-openspec-skills.ps1` (whole script, invoked as-is) for step 6 —
  see Decision 2.
- `Get-FileHashHex`/`Compare-DirectoryContent`-style per-file hash comparison
  (same pattern, reimplemented locally since this script must be a single
  self-contained file a user copies elsewhere — see Decision 9) for deciding
  which already-installed skills are stale on a re-run (step 4/5's "update"
  half).
- `Get-CommandStatus`-style `Get-Command -ErrorAction SilentlyContinue`
  pattern (from both existing scripts) for detecting `git`, `node`/`npm`, and
  `openspec` on PATH.

## Decisions and tradeoffs

1. **Prerequisite, not a plan task: the untracked OpenSpec work
   (`openspec-mod/`, the 6 `openspec-*` skills, `.claude/`) must be
   committed and pushed to `origin/main` before this installer is usable for
   anything OpenSpec-related.** This is a repo-hygiene action for the user to
   take separately (a plain `git add`/`git commit`/`git push`), not a task
   this plan implements — but it is called out here explicitly because
   without it, a fresh clone in step 2/6 will simply not contain
   `openspec-mod/`, and step 6 will correctly, harmlessly report "not present
   in this clone" (Decision 2's fallback), not silently succeed with stale
   assumptions. The script must tolerate the current committed state and the
   future post-commit state identically — no code path assumes
   `openspec-mod/` exists.

2. **Step 6 (install `spec-driven-verified`/`openspec-verify` if present) is
   implemented as: `if (Test-Path (Join-Path $tempClone
   "openspec-mod")) { & (Join-Path $tempClone
   ".agents\scripts\sync-openspec-skills.ps1") -Targets All } else { report
   "openspec-mod/ not found in this clone - skipping OpenSpec schema/skill
   install" }`.** No re-implementation of that script's logic — it is invoked
   directly from the temp clone, unmodified, and it already handles both
   engines, `-WhatIf`, idempotency, and reporting. This also means any future
   fix to `sync-openspec-skills.ps1` in `Agentic_Framework` is picked up
   automatically by every target repo's next re-run, with zero change needed
   in this installer. Rejected: copying/vendoring that script's logic inline
   — pure duplication of already-verified code for no benefit, and it would
   drift the moment either script changed.

3. **The skill checkbox (step 4) is built from whatever `.agents/skills/*`
   subfolders actually exist in the freshly cloned temp copy at run time —
   never a hardcoded list baked into the installer script.** Rationale: the
   set of skills in `Agentic_Framework` changes over time (6 OpenSpec skills
   are already written but not yet pushed, per Decision 1); hardcoding today's
   20 tracked skills would make the installer stale the moment more are
   pushed, defeating its own "update" purpose. Implementation: `Get-ChildItem
   -Directory (Join-Path $tempClone ".agents\skills")`, filtered to
   directories containing a `SKILL.md` (excludes stray files like
   `skill-requirements.txt`, `skills-usage-guide.md`, or a future
   non-skill marker file, the same way `.openspec-target` is excluded here).

4. **Each selected skill is written into the target repo at *both*
   `.agents/skills/<name>/` and `.claude/skills/<name>/`, mirroring
   `Agentic_Framework`'s own dual-copy convention (confirmed via
   `skills-usage-guide.md` and this repo's identical folder listings under
   both roots).** This is a different mechanism from the prior plan's
   *global* Codex/Claude promotion for `openspec-verify` specifically
   (`%USERPROFILE%\.agents\skills\`, `%USERPROFILE%\.claude\skills\`) — this
   step is *project-local* (inside the target repo's own working tree, the
   same way `Agentic_Framework` keeps its own skills project-local), which is
   why `openspec-verify` still separately goes through
   `sync-openspec-skills.ps1`'s global-install step in Decision 2, not this
   step. Rejected: writing to only one location and symlinking the other —
   NTFS symlinks require elevated privileges by default on Windows 10/11,
   violating the "any Win10/11 PC, no special privileges" requirement; a
   plain second copy has no such requirement and matches source-repo
   convention exactly.

5. **A skill already present in the target repo is compared by content
   (per-file hash, same technique as `sync-openspec-skills.ps1`'s
   `Compare-DirectoryContent`/`Get-FileHashHex`) against the freshly cloned
   version before being offered in the checkbox.** The checkbox prompt
   annotates each entry as `[new]`, `[up to date]`, or `[update available]`
   so a re-run is genuinely useful as an updater, not just a reinstaller —
   satisfying the user's explicit "so this script may be used just to update
   previous version" requirement. A user can still select an `[up to date]`
   entry (re-copies it, a harmless no-op) or skip an `[update available]`
   one (leaves their local copy, e.g. if they hand-edited it) — the script
   never force-overwrites a selection the user didn't check.

6. **`todo` is always installed/updated, unconditionally, not part of the
   checkbox.** Per the user's explicit example ("necessary by default skills
   like todo.md") and Discovery evidence — no other skill in this repo is
   self-evidently universal in the same way, so nothing else is force-
   installed. If `Agentic_Framework` later grows more skills the maintainer
   considers universal, this is a one-line change to the script's
   `$alwaysInstall` array, not a design change.

7. **Step 7 (set `spec-driven-verified` as the target repo's default schema)
   edits `openspec/config.yaml`'s `schema:` line with a targeted regex
   line-replace, not a full YAML parse/serialize round-trip.** Per Discovery
   evidence, the field is a single top-level scalar
   (`^schema:\s*.*$` → `schema: spec-driven-verified`) — introducing a YAML
   parsing library (there is no built-in one in PowerShell 5.1/7) to safely
   round-trip a file whose comments and structure must survive untouched
   would be strictly worse: a naive parse-and-re-serialize approach risks
   reordering keys or dropping the file's explanatory comments (this repo's
   own `config.yaml` is comment-heavy, as Discovery evidence shows). A single
   anchored regex replace on the `schema:` line only, leaving every other
   line byte-for-byte untouched, is both simpler and safer here. Confirmation
   is required first (per the earlier decision from this conversation): show
   the current `schema:` value and the proposed new one, require an explicit
   yes. If `openspec/config.yaml` doesn't exist yet (step 1 was skipped or
   failed), step 7 is skipped with a clear reason rather than creating a
   malformed config file from scratch.

8. **Distribution model: a single self-contained `.ps1` file the user copies
   by hand into a target repo (e.g. into that repo's own `.agents/scripts/`,
   or its root) and runs directly — not a remote `irm <url> | iex`
   one-liner.** The user's own phrasing ("a script that I can put into my
   repo and install with one command") matches "one command" = *running* the
   copied script, not *fetching* it over the network first. Rejected: a
   hosted one-liner installer — it would need a stable public raw-file URL
   this plan has no mandate to set up or maintain (this repo's GitHub
   visibility/branch stability is outside this plan's control), and it adds
   an extra trust/network dependency (fetch-then-execute from a URL) beyond
   what running a file the user already has locally requires.

9. **The script is fully self-contained — no dependency on any other file in
   the target repo (including no dependency on this same repo's other
   scripts) — because it must survive being copied alone into a repo that has
   never seen `Agentic_Framework` before.** Any shared logic between this
   script and `sync-openspec-skills.ps1` (e.g., the hash-compare helper) is
   duplicated as plain functions inside this script, not imported, sourced,
   or module-referenced — a target repo has no guarantee any other file from
   `Agentic_Framework` exists locally before this script's first run clones
   one down.

10. **Fetch mechanism: `git clone --depth 1 <origin-url> $tempDir`, deleted
    (`Remove-Item -Recurse -Force`) in a `finally` block regardless of
    success/failure.** Matches the user's own selection. `git` is a hard
    prerequisite (`Get-Command git`); if absent, the script reports the
    concrete blocker and exits before attempting any other step, rather than
    partially running with stale/no framework content. `--depth 1` keeps the
    clone fast and avoids pulling this repo's full history into a disposable
    temp folder on every run.

11. **OpenSpec CLI presence for step 1 (`openspec init`) is a hard
    prerequisite the script checks and can optionally remediate, unlike the
    prior script's informational-only check.** Unlike
    `sync-openspec-skills.ps1` (where a missing CLI only meant "the schema
    file won't take effect yet," files still copy fine), `openspec init`
    itself cannot run at all without the CLI on PATH — this step has a real,
    blocking dependency the prior one didn't. Behavior: `Get-Command openspec
    -ErrorAction SilentlyContinue`; if missing, check `Get-Command npm`; if
    npm is present, ask for confirmation before running `npm install -g
    @fission-ai/openspec` (an explicit external-tool install, not silently
    run); if npm is also absent, report the blocker and skip step 1 (and step
    7, which depends on `openspec/` existing) while continuing with steps
    2-6, which don't need the CLI. This keeps the script maximally useful
    even on a machine missing Node entirely — it still sets up skills/`.agents`
    structure, just not the OpenSpec pieces.

12. **`openspec init` is only run if `openspec/config.yaml` does not already
    exist in the target repo** (`-not (Test-Path "openspec\config.yaml")`) —
    running `openspec init` against an already-initialized project is
    unnecessary and the CLI's own re-init behavior is not something this
    plan should rely on or paper over. If already initialized, step 1 reports
    `already initialized`, matching the idempotent-rerun requirement carried
    over from the prior script.

## Open questions

None blocking. One prerequisite is called out explicitly (Decision 1: commit
and push the untracked OpenSpec work) but it is a repo-hygiene action outside
this plan's own task list, not an unresolved design question — the script's
behavior is fully specified for both the current (pre-push) and future
(post-push) repo states.

## Existing files to read or re-check during implementation

- `.agents/scripts/sync-openspec-skills.ps1` — re-read in full immediately
  before writing the new script, to confirm its parameter surface
  (`-Targets`) and output format haven't changed since this plan was written,
  since Decision 2 invokes it directly and unmodified.
- `.agents/skills/todo/SKILL.md` — confirm it still consists only of
  `SKILL.md` (no `references/` subfolder) so the always-installed copy step
  doesn't need directory-recursion logic beyond what a generic per-skill copy
  already does.
- `openspec/config.yaml` (this repo's own, as a shape reference only — this
  script never touches this repo's own config) — re-confirm the `schema:`
  line's exact format immediately before writing the regex in Decision 7.
- `git remote -v` — re-confirm the origin URL is still
  `https://github.com/ZchopX/Agentic_Framework.git` immediately before
  hardcoding it into the new script.

## New and updated files

New:
```
.agents/scripts/install-agentic-framework.ps1
```

Updated:
```
.agents/scripts/README.md   — create if it doesn't exist yet; a one-paragraph
                               index of both scripts in this folder (currently
                               undocumented as a set). If a fitting existing
                               doc surface is found during implementation
                               (e.g. root README) that already indexes
                               scripts, extend that instead of creating a new
                               file — check before creating.
```

No other file is touched. This plan does not modify `openspec-mod/`,
`sync-openspec-skills.ps1`'s own content, or any existing skill.

## Step-by-step tasks

### 1. Scaffold the script
- [ ] 1.1 Create `.agents/scripts/install-agentic-framework.ps1` with a
      `param()` block: `[CmdletBinding(SupportsShouldProcess)]`, no required
      parameters (fully interactive by default), optional `-SourceUrl`
      (default `https://github.com/ZchopX/Agentic_Framework.git`, override
      for testing against a fork) and `-Yes` (skip confirmation prompts, for
      non-interactive re-runs). `$ErrorActionPreference = "Stop"`. Verify:
      syntax check under both `powershell.exe` and `pwsh.exe` as in the prior
      script's task 1.1.

### 2. Clone the source repo to a temp dir
- [ ] 2.1 Check `Get-Command git`; report and exit if missing (Decision 10).
      `git clone --depth 1 $SourceUrl $tempDir` into a fresh subfolder under
      `[System.IO.Path]::GetTempPath()`; wrap the entire rest of the script's
      body in `try { ... } finally { Remove-Item -Recurse -Force $tempDir
      -ErrorAction SilentlyContinue }`. Verify: run against the real
      `Agentic_Framework` URL, confirm the temp dir is populated then removed
      even when a later step throws (simulate by temporarily forcing an
      error).

### 3. OpenSpec init (step 1 of the user's list)
- [ ] 3.1 Check `Get-Command openspec`; if missing, check `Get-Command npm`
      and prompt (unless `-Yes`) to run `npm install -g
      @fission-ai/openspec`; if npm is also missing, report the blocker and
      set a flag skipping this step and step 7 (Decision 11).
- [ ] 3.2 If `openspec` is available and `openspec\config.yaml` does not
      exist in the current directory, run `openspec init` (or the correct
      non-interactive init invocation — confirm exact flags against
      `openspec --help`/`openspec init --help` during implementation, since
      this wasn't part of this session's prior CLI probing). If it already
      exists, report `already initialized` (Decision 12). Verify: run once
      against a scratch directory with no `openspec/` folder, confirm it's
      created; run again, confirm `already initialized` with no CLI
      invocation the second time.

### 4. Copy `.agents/` structure (step 3)
- [ ] 4.1 Always copy, with content, from the temp clone into the target
      repo: `.agents/templates/`, `.agents/states/`, `.agents/start/`,
      `.agents/reference/` (per the clarified default-copy decision). Use the
      same hash-compare-before-copy approach as Decision 5 so a re-run
      reports `unchanged`/`updated`/`installed` per file or folder, not a
      blind overwrite.
- [ ] 4.2 Always create (no content) `.agents/plans/`, `.agents/reports/`,
      `.agents/reviews/` if they don't already exist in the target repo — per
      the clarified decision ("copy them as empty folders"). Never overwrite
      or touch these if the target repo already has content there.

### 5. Skill selection and install (steps 4-5)
- [ ] 5.1 Enumerate skill candidates per Decision 3
      (`Get-ChildItem -Directory` under the temp clone's `.agents\skills\`,
      filtered to folders containing `SKILL.md`).
- [ ] 5.2 For each candidate, compare against the target repo's
      `.agents/skills/<name>/` (if present) using a locally-defined
      hash-compare helper (Decision 9 — self-contained, not imported from
      `sync-openspec-skills.ps1`) and tag `[new]` / `[up to date]` /
      `[update available]`.
- [ ] 5.3 Print a numbered list (Decision: terminal multi-select, per the
      earlier answered question) with those tags; prompt for comma-separated
      numbers or `all`; parse the response, tolerating whitespace and
      out-of-range/non-numeric entries with a clear re-prompt rather than a
      crash.
- [ ] 5.4 Always add `todo` to the selected set regardless of user input
      (Decision 6), de-duplicating if the user also explicitly selected it.
- [ ] 5.5 For each selected skill, copy its full folder (recursively) into
      both `.agents/skills/<name>/` and `.claude/skills/<name>/` in the
      target repo (Decision 4). Verify: run against a scratch target
      directory, select 2 skills plus confirm `todo` is force-included,
      confirm both destination roots receive identical content
      (hash-compare after copy).

### 6. OpenSpec schema/skill install (step 6)
- [ ] 6.1 Implement Decision 2's `Test-Path` branch exactly: invoke
      `sync-openspec-skills.ps1` from the temp clone when `openspec-mod/`
      exists there, else report the clean skip reason. Verify: run once
      against the current (pre-push) `Agentic_Framework` state and confirm
      the "not found in this clone" path is taken and reported clearly (since
      `openspec-mod/` is not yet on GitHub per Decision 1) — this is the
      correct, expected outcome today, not a bug.

### 7. Set default schema (step 7)
- [ ] 7.1 Only reached if `openspec/config.yaml` exists (post step 3) and
      step 6 actually installed/confirmed `spec-driven-verified` present at
      `%LOCALAPPDATA%\openspec\schemas\spec-driven-verified\`. Read the
      current `schema:` value, show it alongside the proposed
      `spec-driven-verified`, prompt for confirmation (unless `-Yes`), then
      apply the single-line regex replace from Decision 7. Verify: on a
      scratch `config.yaml` matching this repo's real format (comments
      included), confirm only the `schema:` line changes and every other
      line/comment is byte-identical before and after.

### 8. Summary report
- [ ] 8.1 Print a final report mirroring `sync-openspec-skills.ps1`'s
      style: PowerShell edition/version, OpenSpec CLI status, per-skill
      install/update/skip results, `.agents/` structure copy results,
      OpenSpec schema install result (installed/skipped-not-in-clone), and
      default-schema-set result (set/skipped-declined/skipped-no-config).

### 9. Documentation
- [ ] 9.1 Add or extend a short doc (per New and updated files above)
      describing what the script does, how to obtain and run it (copy the
      file into the target repo, then
      `powershell -ExecutionPolicy Bypass -File install-agentic-framework.ps1`),
      and that re-running it is the update path.

### 10. End-to-end verification
- [ ] 10.1 Create a throwaway scratch git repo (outside
      `Agentic_Framework`, deleted after), copy the finished script into it
      alone (no other file from `Agentic_Framework` present — proving
      Decision 9's self-containment), and run it once under `pwsh.exe`, once
      under `powershell.exe`, confirming: OpenSpec init behavior, `.agents/`
      structure appears correctly, chosen skills + `todo` land in both
      `.agents/skills/` and `.claude/skills/`, the OpenSpec schema step
      reports the expected skip (pre-push state) or install (if the
      prerequisite from Decision 1 has been completed by the time this task
      runs — check `git ls-files openspec-mod` against `origin/main` at
      implementation time and adjust the expected verification outcome
      accordingly), and a second immediate re-run reports `up to date`/
      `already initialized` everywhere with no destructive changes.

## Test strategy

No test framework in this repo (confirmed, same as the prior plan).
Verification is scratch-repo-driven, mirroring `sync-openspec-skills.ps1`'s
own approach:
- Function-level: the local hash-compare helper (task 5.2) and the
  `schema:`-line regex (task 7.1) each get an isolated scratch-file check
  before the full end-to-end pass.
- End-to-end: task 10.1, both engines, first-run and re-run (update) cases,
  against a disposable scratch repo, never against a real project.

## Validation commands

```powershell
# Syntax check
powershell -NoProfile -Command ". '.agents\scripts\install-agentic-framework.ps1' -WhatIf"

# Dry run against the real framework repo, from a scratch target repo
pwsh -File <path-to-copied-script>\install-agentic-framework.ps1 -WhatIf

# Real run, PowerShell 7
pwsh -File <path-to-copied-script>\install-agentic-framework.ps1

# Real run, Windows PowerShell 5.1 (must behave identically)
powershell -File <path-to-copied-script>\install-agentic-framework.ps1

# Confirm a specific installed skill matches source
Get-FileHash <target-repo>\.agents\skills\todo\SKILL.md -Algorithm SHA256
```
(`Get-FileHash` is fine here as an ad hoc validation command run by a human;
only the script's own internal comparison logic needs the module-shadowing-
proof `Get-FileHashHex` helper from Decision 9/the prior script's fix.)

## Acceptance criteria checklist

- [ ] Script is a single file with no dependency on any other file existing
      in the target repo (Decision 9), verified by task 10.1's isolated copy.
- [ ] Runs correctly under both `powershell.exe` 5.1 and `pwsh.exe` 7.
- [ ] Idempotent: a second run with no new selections reports
      up-to-date/already-initialized everywhere, makes no destructive change.
- [ ] `openspec init` only runs when `openspec/config.yaml` doesn't already
      exist (Decision 12).
- [ ] Skill checklist is generated live from the cloned repo's actual
      `.agents/skills/*` contents, never hardcoded (Decision 3).
- [ ] `todo` is always installed/updated regardless of checkbox selection
      (Decision 6).
- [ ] Every selected skill lands in both `.agents/skills/` and
      `.claude/skills/` in the target repo (Decision 4).
- [ ] Step 6 correctly detects and skips when `openspec-mod/` is absent from
      the clone, and correctly installs via `sync-openspec-skills.ps1` when
      present, without modifying that script.
- [ ] Step 7 changes only the `schema:` line in `openspec/config.yaml`,
      confirmed byte-identical elsewhere, and only after explicit
      confirmation (unless `-Yes`).
- [ ] Temp clone is always removed, including when an earlier step throws.
- [ ] Final report clearly states per-area outcome (init, structure copy,
      each skill, OpenSpec schema/skill, default-schema-set) plus PS
      edition/version.

## Risks, assumptions, and fallbacks

- **Blocking prerequisite, not a script risk:** `openspec-mod/`, the 6
  `openspec-*` skills, and `.claude/` are not yet committed/pushed to
  `origin/main` (Decision 1/Discovery evidence). Until that happens, steps
  1/6/7 exercise only their "not present" / "CLI missing" branches in
  real-world testing — those branches are still fully real code paths worth
  verifying, but the "happy path" (schema actually installed and set as
  default end-to-end) cannot be demonstrated against the real repo until the
  prerequisite commit/push happens. *Mitigation:* task 10.1 explicitly checks
  current push state at implementation time and verifies whichever branch is
  actually reachable; if the prerequisite is completed before implementation,
  re-verify the happy path too.
- **Risk:** `openspec init`'s exact non-interactive flags/behavior were not
  probed live in this session (unlike `status`/`instructions`/`schema
  validate`, which were). *Mitigation:* task 3.2 explicitly calls for
  confirming `openspec init --help` during implementation before assuming any
  flag.
- **Risk:** A target repo may already have a differently-shaped
  `openspec/config.yaml` (e.g., no `schema:` line at all, or a custom
  init template shape) that the Decision 7 regex doesn't match.
  *Mitigation:* if the regex finds no match, report "schema: line not found -
  skipping automatic default-set, edit openspec/config.yaml manually" rather
  than guessing where to insert one.
- **Assumption:** `git clone --depth 1` against a public GitHub URL needs no
  authentication for this repo (`Agentic_Framework` is public, confirmed by
  the plain HTTPS remote URL with no credential helper configured beyond
  normal git defaults). If the repo is ever made private, this script would
  need a credentialed clone path — out of scope unless/until that happens.
- **Fallback:** if a target repo's user declines the `npm install -g
  @fission-ai/openspec` prompt (Decision 11) or has no npm, the script still
  completes steps 2, 4, 5 (structure and skills) — it degrades gracefully
  rather than aborting entirely over one missing external tool.

## Compatibility notes

- **Sources checked:** `.agents/scripts/sync-openspec-skills.ps1` (reused
  directly per Decision 2), `.agents/skills/skills-usage-guide.md` (dual-copy
  convention), `.agents/skills/{project-bootstrap,repo-docs-bootstrap,todo}/SKILL.md`
  (confirmed no overlapping existing tooling), `git remote -v` /
  `git ls-files` / `git status --porcelain` (current push state, source URL,
  tracked-skill list), `dist/core/project-config.js` inside the installed
  `@fission-ai/openspec` package (schema-activation semantics, carried over
  from the prior conversation turn's live inspection).
- **Compatibility with current stack:** Full. Same as the prior plan — no
  build system, package manager, or CI in this repo; a standalone `.ps1`
  script matches the one established precedent (now two scripts) for this
  kind of task.
- **Existing stack alternatives considered:** a Node.js CLI package published
  to npm (rejected — introduces a whole new distribution/versioning
  surface and a new runtime dependency for target repos, when a single
  copy-and-run `.ps1` file satisfies every stated requirement); a remote
  `irm | iex` one-liner (rejected, Decision 8); vendoring
  `sync-openspec-skills.ps1`'s logic inline instead of invoking it from the
  clone (rejected, Decision 2 — duplication with no benefit).
- **ADR required:** no — no new runtime, framework, database, package
  manager, build system, or dependency-policy decision; built entirely from
  `git`, PowerShell/.NET built-ins, and the already-adopted `openspec` CLI.

## No user-facing impact identified beyond CLI/report output

Same framing as the prior plan: this is an operator-run installer/updater
script, not an application feature. Its only "user-facing" surface is its
own console prompts (skill checkbox, confirmation prompts) and final report —
covered by task 8.1 and the acceptance criterion on report clarity.
