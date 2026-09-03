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
the target repo's default. Re-running it later refreshes whatever was
previously installed — it is both the installer and the updater, with no
separate update mode or command.

This is a revision of an earlier sketch of the same plan (previously at this
same path). Section-by-section, this version corrects one stale premise,
resolves the update-mode/`-Yes` design gap, adds three safety guards, narrows
the `.gitignore` change, switches the `.claude/skills/` copy to a symlink-first
strategy, tightens the schema-line regex, and drops the documentation task —
each per an explicit decision recorded below, made together with the user
after reviewing the prior sketch. A follow-up pass (Decision 19, task 9) then
added CocoIndex indexing, closing a gap found during an independent review of
this same plan: the installer copied docs that reference CocoIndex without
ever running it.

## In scope / out of scope

**In scope:**
- One new script, distributed from this repo, that a user copies into any
  other Windows repo and runs directly (no separate download step, no remote
  one-liner) — see Decision 8 on why a local file, not `irm | iex`.
- The 7 steps the user specified originally, in an order that respects real
  dependencies (fetch-before-copy), detailed under Decisions below.
- Re-run = refresh: same script, same invocation, diffs what's already present
  against the freshly cloned source and only touches what changed, using the
  currently-installed set as the default selection (Decision 2).
- Terminal-based (no GUI dependency) multi-select for skill choice, pre-ticked
  from auto-detected current state.
- Windows 10/11, PowerShell 5.1 and 7+ — same constraints and the same
  `Get-FileHashHex`/`robocopy /MIR`/`$env:USERPROFILE` conventions already
  established and validated in `.agents/scripts/sync-openspec-skills.ps1`
  (this plan's implementation reuses that script directly for the OpenSpec
  step, and reimplements its hash-compare pattern locally for skills — see
  Decision 2 and Decision 9).
- Three safety guards not in the original sketch: refuse to run against the
  source repo itself (Decision 4), refuse to run outside a git repo
  (Decision 13), and a narrowed `.gitignore` addition (Decision 5).
- Symlink-first install for `.claude/skills/<name>/`, matching this repo's own
  convention, with an automatic copy fallback when symlink creation is denied
  (Decision 6).
- CocoIndex (`ccc`) indexing of the target repo when the tool and its global
  settings are already present on the host — best-effort, automatic, no
  install attempted (Decision 19).

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
- Cross-platform (macOS/Linux) support — Windows-specific paths and the user's
  explicit Windows framing.
- A standalone script README — explicitly declined by the user; see
  Decision 10 (this plan intentionally removes this task from the prior
  sketch).
- Version pinning to a specific commit/tag of `Agentic_Framework` — explicitly
  deferred by the user, not a design gap; see Decision 11.
- A separate `-Update`/`-Refresh` mode or command — explicitly rejected in
  favor of one unified flow; see Decision 2.
- Copying `.claude/commands/opsx/` separately — not needed; see Decision 3
  (these are OpenSpec-CLI-generated, produced by `openspec init` itself, which
  step 1 already runs in the target repo).
- Anything about *this* repo's own `openspec/config.yaml` — this script is
  meant to run inside *target* repos adopting the framework, never against
  `Agentic_Framework` itself (this is exactly what Decision 4's guard
  enforces).
- Automatically resolving git merge conflicts or reconciling a target repo's
  hand-edited copy of a skill it once installed — the diff-and-report model
  (Decision 5 in the original numbering, now folded into Decision 2's
  auto-detect logic) surfaces this to the user instead of guessing.

## Discovery evidence

- `git ls-files openspec-mod | head -5` and `git ls-files .claude/commands` —
  both non-empty; `openspec-mod/` and `.claude/commands/opsx/*.md` are
  tracked and, per `git status` (clean, up to date with `origin/main`),
  pushed. This directly contradicts the prior sketch's Decision 1, which
  assumed these were untracked — see Decision 1 below for the correction.
- `git remote -v` → `origin  https://github.com/ZchopX/Agentic_Framework.git`
  (both fetch and push) — the fixed clone source this script bakes in, and
  the exact string Decision 4's self-clobber guard compares against.
- `git log --diff-filter=A -- .claude/commands/opsx/apply.md` → introduced in
  commit `9507ed0`, whose message reads "...along with the OpenSpec
  CLI-generated skills/commands and this repo's own openspec/ workspace from
  adopting OpenSpec for planning" — confirms `.claude/commands/opsx/*.md` and
  the `openspec-*` skills were generated by the OpenSpec CLI (`openspec
  init`/related commands), not hand-authored. This is the evidence behind
  Decision 3 (no separate copy step needed for these — running `openspec
  init` in the target repo, already step 1, produces them there too).
- `.agents/scripts/sync-openspec-skills.ps1` — read in full. Contains three
  directly reusable patterns: `Get-FileHashHex` (pure `[System.Security.
  Cryptography.SHA256]`, deliberately avoiding the `Get-FileHash` cmdlet
  because of a documented PS7/5.1 module-shadowing bug — see that script's
  own comment at lines 32-37), `Compare-DirectoryContent` (returns
  `missing`/`identical`/`different` by per-file hash), and `Sync-Target`
  (robocopy `/MIR` wrapped in `ShouldProcess`, exit code `>= 8` = failure).
  This script's step 6 (OpenSpec schema/skill install) invokes this file
  directly, unmodified, from the temp clone (Decision 2 in the original
  numbering, preserved unchanged here). The skill-sync logic for step 5
  duplicates the same three patterns locally rather than importing them
  (Decision 9 — this script must be self-contained, see below).
- `git ls-files .agents/skills | sed -E 's#(.agents/skills/[^/]+)/.*#\1#' |
  sort -u` → 28 entries: 25 skill folders (each containing `SKILL.md`), plus
  `.agents/skills/.openspec-target` (a marker file, not a folder) and
  `.agents/skills/skill-requirements.txt` / `skills-usage-guide.md` (loose
  files, not folders). Confirms the skill-candidate enumeration rule (folders
  containing `SKILL.md`, excluding stray files) still correctly separates
  real skills from these three non-skill entries with today's actual
  contents — re-verify this filter still holds at implementation time since
  the set grows over time.
- `openspec/config.yaml` (this repo's own) — line 1 is exactly `schema:
  spec-driven`, no leading whitespace or comment. Confirms the format
  Decision 7's regex targets, and the shape (`schema:` at column 0) makes the
  tightened anchor (`^schema:` matched per-line, not `^\s*schema:` or
  `#\s*schema:`) both correct and sufficient — nothing in this file's own
  commented examples (`#   context: |`, `#     schema:` does not appear
  anywhere in this file, confirmed by reading it in full) would have
  false-matched the original regex either, but the tightened anchor is a
  correctness improvement for target repos with different comment styles.
- `.gitignore` (this repo's own) → four ignore entries (five lines counting
  one comment line): `.claude/skills/`, `.claude/settings.local.json`,
  `.serena/`, a `# CocoIndex Code (ccc)` comment, then `/.cocoindex_code/`.
  Per Decision 5, only `.claude/settings.local.json` transfers to a target repo's
  `.gitignore` — `.claude/skills/` is ignored here specifically because it's
  a symlink in *this* repo's own working tree (confirmed via `ls -la .claude`
  showing `skills -> /c/PyProjects/Agentic_Framework/.agents/skills`), but a
  target repo's `.claude/skills/<name>/` entries are meant to be committed
  (whether symlinks or copy-fallback content — Decision 6), not ignored.
  `.serena/` and `/.cocoindex_code/` are local tool caches unrelated to what
  this installer creates and are correctly left out per the user's explicit
  decision.
- `.agents/skills/todo/` → contains only `SKILL.md`, confirming the
  always-installed skill needs no directory-recursion handling beyond what
  the generic per-skill copy/symlink logic already provides.
- `.agents/skills/project-bootstrap/SKILL.md`, `repo-docs-bootstrap/SKILL.md`
  — both single-repo, app-specific bootstraps with no cross-repo
  installer/updater logic; nothing to extend instead of building new (carried
  over from the original sketch, re-confirmed still true).
- `dist/core/project-config.js` inside the installed `@fission-ai/openspec`
  npm package (inspected live in a prior session) — confirms `openspec
  schemas` labels a schema `(user override)` purely by where its definition
  was *found*, never by which schema is *active*; only `openspec/config.yaml`'s
  `schema:` field decides that — this is why step 7 (setting the default
  schema) remains a distinct, required action even after the schema files are
  in place (carried over unchanged).

## Existing system fit

- Distributed from `Agentic_Framework` itself, under `.agents/scripts/`
  alongside `sync-openspec-skills.ps1` — same location convention.
- Directly invokes `sync-openspec-skills.ps1` from the freshly cloned temp
  copy rather than re-implementing its comparison/sync logic for the OpenSpec
  step — the two scripts are cooperating tools, not duplicated ones.
- Reuses this repo's own `.claude/skills -> .agents/skills` symlink
  convention for the target repo's per-skill install (Decision 6), instead of
  the prior sketch's always-copy approach — this is a closer match to how
  `Agentic_Framework` itself is actually laid out, not a new convention.
- Never modifies `Agentic_Framework` itself — it only reads (via a disposable
  clone) and writes into whatever repo it's run from, and now actively
  refuses to run if that repo *is* `Agentic_Framework` (Decision 4).

## Reuse opportunities

- `sync-openspec-skills.ps1` (whole script, invoked as-is) for step 6 —
  Decision 2 (original numbering, unchanged).
- `Get-FileHashHex`/`Compare-DirectoryContent`-style per-file hash comparison
  (same pattern, reimplemented locally since this script must be a single
  self-contained file a user copies elsewhere — Decision 9) for deciding
  which already-installed skills are stale on a re-run, and for driving the
  auto-detected pre-ticked selection (Decision 2, this revision).
- `Get-CommandStatus`-style `Get-Command -ErrorAction SilentlyContinue`
  pattern (from `sync-openspec-skills.ps1`) for detecting `git`, `node`/`npm`,
  and `openspec` on PATH.

## Decisions and tradeoffs

1. **[Corrected in this revision] The original "untracked OpenSpec work"
   prerequisite no longer applies.** The prior sketch's Decision 1 said
   `openspec-mod/`, the 6 `openspec-*` skills, and `.claude/` were untracked
   and unpushed, blocking end-to-end verification of the OpenSpec-related
   happy path. Re-checked live for this revision: `git ls-files openspec-mod`
   and `git ls-files .claude/commands` both list tracked files, and `git
   status` shows the working tree clean and up to date with `origin/main`.
   **Effect on this plan:** task 12.1 (end-to-end verification) must now
   exercise the real happy path — `openspec-mod/` present in the clone,
   `sync-openspec-skills.ps1` actually installing the schema/skill, and step
   7 actually offering to set `spec-driven-verified` as default — not only
   the "not present, skip" branch. The "not present" branch is still valid
   code to keep (a user's fork of `Agentic_Framework` might legitimately lack
   `openspec-mod/`), just no longer the *only* branch this plan can verify.

2. **[Reworked in this revision] No separate `-Update` mode. One flow
   auto-detects what's currently installed and uses that both to pre-tick the
   interactive checkbox and to define `-Yes` non-interactive behavior.** The
   prior sketch's checkbox was blank on every run (no memory of previous
   selections), leaving `-Yes` undefined at the skill-selection step — there
   was nothing for it to select. Fix: reuse the same per-skill hash-compare
   this script already needs for drift detection (folded in from the prior
   sketch's Decision 5) to build, on every run, the actual current state of
   `.agents/skills/` in the target repo. That state is used two ways:
   - **Interactive mode:** the numbered checkbox pre-ticks every skill
     already present (tagged `[installed, up to date]` /
     `[installed, update available]`), leaves not-yet-installed skills
     unticked (tagged `[new]`), and a bare Enter accepts the pre-ticked set
     as-is — so "just refresh what I have" requires no typing.
   - **`-Yes` (non-interactive) mode:** skip the prompt entirely and use the
     auto-detected currently-installed set, refreshed to the freshly cloned
     content, with `todo` force-included (Decision 6 in the original
     numbering, unchanged) and nothing new added. This makes `-Yes` a safe,
     well-defined "refresh in place" operation suitable for a scheduled
     re-run, with an explicit, obvious rule: it can update, it can never
     install something the user never chose.
   To install a *new* skill non-interactively (not in scope for this plan,
   per the user's decision), a future `-Skills <names>` parameter would be
   the natural extension point — noted here so it isn't rediscovered as a
   surprise later, not built now.
   Rejected: a separate `-Update` script mode/argument, as originally
   floated — this would require every consumer to know two invocation styles
   (first install vs. update) instead of one script that behaves correctly
   either way based on what it finds on disk.

3. **[Removed from this revision as a non-issue] `.claude/commands/opsx/` does
   not need a separate copy step.** The prior sketch's gap analysis flagged
   these files as missing from the copy list. Discovery evidence (commit
   `9507ed0`'s message) shows they, along with the `openspec-*` skills, are
   generated by the OpenSpec CLI itself when it's initialized/used in a repo
   — not files `Agentic_Framework` hand-maintains and redistributes. Step 1
   (already in this plan, `openspec init` in the target repo) is what
   produces them there; no new task needed.

4. **[New in this revision] Self-clobber guard: refuse to run if the current
   directory's git remote matches `$SourceUrl`.** Nothing in the prior sketch
   stopped someone from accidentally running the installer from inside a
   checkout of `Agentic_Framework` itself, which would clone a temp copy of
   the repo and then write "target repo" output back into the same repo it
   was cloned from. Implementation: `git remote get-url origin` (best-effort,
   `-ErrorAction SilentlyContinue`) compared case-insensitively against
   `$SourceUrl` (with and without a trailing `.git`, since both forms are
   valid remote URLs); on a match, print a clear error ("this script installs
   Agentic_Framework *into* other repos — it looks like you're running it
   from inside Agentic_Framework itself") and exit before cloning anything.
   Not a security boundary, just a footgun guard — a user who really wants to
   test the script against its own source (as task 12.1's isolated scratch-repo
   testing does) runs it from a different directory, which is what that task
   already does.

5. **[Narrowed in this revision] `.gitignore` handling: append only
   `.claude/settings.local.json` if a target repo's `.gitignore` exists and
   doesn't already have it (create the file with just that one line if it
   doesn't exist at all).** The user explicitly rejected also adding
   `.serena/`/`.cocoindex_code/` entries (unrelated local tool caches, not
   something this installer creates or manages) — keep the change narrow to
   what this script's own output actually needs ignored. `.claude/skills/` is
   deliberately *not* added to the target's `.gitignore` — per Decision 6,
   `.claude/skills/<name>/` is meant to be committed in a target repo
   (whether a symlink entry or copy-fallback content), unlike in this source
   repo where the whole `.claude/skills/` path is a single symlink that's
   gitignored as a matter of this repo's own layout, not a general rule.
   Implementation: literal line-presence check (`Select-String -SimpleMatch`)
   before appending — never duplicate the line on a re-run.

6. **[Changed in this revision] `.claude/skills/<name>/` install strategy:
   symlink-first (to the just-written `.agents/skills/<name>/`), with an
   automatic real-copy fallback per skill when symlink creation fails.** The
   prior sketch always wrote two physical copies, rejecting symlinks outright
   on the stated assumption that "NTFS symlinks require elevated privileges
   by default." That's only half true: Windows has allowed non-admin symlink
   creation since the Windows 10 Creators Update when "Developer Mode" is
   enabled (a machine-wide toggle), and it always works when the process is
   already elevated. Rather than assuming the worse case, or building
   self-elevation logic (rejected — see below), the script should just try:
   `New-Item -ItemType SymbolicLink -Path <claude-path> -Target
   <agents-path>` inside a `try`; on failure (access denied, dev mode off,
   not elevated), fall back to a recursive copy for that one skill only, and
   record which happened. This exactly mirrors `Agentic_Framework`'s own
   `.claude/skills -> .agents/skills` layout when it succeeds, and degrades
   gracefully to the prior sketch's behavior when it doesn't — every target
   machine ends up correctly set up either way, just via different means.
   Per-skill (not once for the whole `.claude/skills/` folder) because
   symlink permission failures are an all-or-nothing property of the *host*,
   but attempting it per skill keeps the logic uniform with the rest of the
   per-skill install loop and correctly reports mixed results if, e.g., a
   user runs once unelevated (all copies) and later re-runs elevated
   (symlinks from then on, until Decision 2's drift-detection sees the
   existing physical copy as `identical` and leaves it alone — a copy that
   happens to match content is not "wrong," just not a symlink; upgrading an
   existing correct copy to a symlink is out of scope for this plan since it
   requires deleting and recreating a directory entry for no functional
   gain).
   Rejected: building logic to relaunch the script elevated for just the
   symlink step (e.g. `Start-Process -Verb RunAs`) — this either forces a UAC
   prompt on every single run (bad for the `-Yes`/automation use case this
   plan otherwise optimizes for) or requires plumbing results back from a
   separate elevated process, both meaningfully more complexity than a
   try/fallback with a one-line status message per skill.

7. **[Tightened in this revision] Step 7's `schema:` line match is anchored
   to the true start of the line: `^schema:\s*.*$` matched per-line with no
   leading `#` or whitespace permitted before `schema:`.** The prior sketch's
   regex was already close to this, but wasn't explicit that a commented-out
   example (e.g. `#   schema: my-custom-schema`, a style OpenSpec's own
   generated `config.yaml` uses for other example fields, confirmed by
   reading this repo's own file) must never match. This repo's real
   `config.yaml` line 1, `schema: spec-driven`, is exactly what should match;
   nothing else in the file (confirmed by reading it in full) contains
   `schema:` at column 0 elsewhere, so the anchor is a hardening, not a
   change in matched behavior for this repo's own file — it only changes
   behavior for target repos with different comment placement. Still: if no
   line matches, report "schema: line not found - skipping automatic
   default-set, edit openspec/config.yaml manually" rather than guessing
   where to insert one (unchanged from the prior sketch).

8. **[Unchanged from prior sketch] Distribution model: a single
   self-contained `.ps1` file the user copies by hand into a target repo and
   runs directly — not a remote `irm <url> | iex` one-liner.** No hosted
   one-liner infrastructure to build or maintain, and no fetch-then-execute
   trust surface beyond a file the user already has locally.

9. **[Unchanged from prior sketch] The script is fully self-contained — no
   dependency on any other file in the target repo, including no dependency
   on this same repo's *other* scripts (except `sync-openspec-skills.ps1`,
   which is invoked from the temp clone of the *source* repo, not expected to
   exist in the target repo).** Any shared logic between this script and
   `sync-openspec-skills.ps1` (the hash-compare helper) is duplicated as
   plain functions inside this script, not imported, sourced, or
   module-referenced.

10. **[New in this revision, removing a prior task] No script README, at all,
    under any circumstance.** The prior sketch's task 9.1 called for adding
    or extending documentation describing the script. The user explicitly
    rejected this for this specific script ("that's my script," no README
    wanted). Removed as a task entirely — see the removed "Documentation"
    section below, replaced by nothing.

11. **[New in this revision] Version pinning to a specific
    `Agentic_Framework` commit/tag is explicitly deferred, not a design
    gap requiring resolution now.** The user considered this and declined it
    for this plan. `git clone --depth 1 $SourceUrl $tempDir` always takes the
    default branch's current HEAD, same as the prior sketch. If a future need
    arises for reproducible/pinned installs, the natural extension is a
    `-Ref <branch-tag-or-commit>` parameter passed to `git clone` — noted
    here as a clearly-scoped future addition, not built now.

12. **[Unchanged from prior sketch] The skill checkbox is built from whatever
    `.agents/skills/*` subfolders actually exist in the freshly cloned temp
    copy at run time — never a hardcoded list.** `Get-ChildItem -Directory`
    under the temp clone's `.agents\skills\`, filtered to directories
    containing a `SKILL.md` (excludes `.openspec-target`,
    `skill-requirements.txt`, `skills-usage-guide.md`, confirmed still
    correct against today's actual 28-entry listing per Discovery evidence).

13. **[New in this revision] Not-a-git-repo guard: refuse to run if the
    current directory has no `.git` folder.** The prior sketch assumed
    throughout that it runs "inside a target repo" without ever checking.
    Implementation: `Test-Path (Join-Path (Get-Location) ".git")` near the
    top of the script (after the self-clobber check in Decision 4, since that
    check also needs `.git` to exist to be meaningful — order: check `.git`
    exists first, report "not a git repository" and exit if not, then check
    the remote for self-clobber). On failure, print a clear message ("run
    this script from the root of the git repository you want to install
    into") rather than silently writing files into an arbitrary folder.

14. **[Unchanged from prior sketch] `todo` is always installed/updated,
    unconditionally, not part of the checkbox.** Per the user's original
    explicit example and Discovery evidence — no other skill in this repo is
    self-evidently universal in the same way.

15. **[Unchanged from prior sketch] Step 6 (install `spec-driven-verified`/
    `openspec-verify` if present) is implemented as: `if (Test-Path (Join-Path
    $tempDir "openspec-mod")) { & (Join-Path $tempDir
    ".agents\scripts\sync-openspec-skills.ps1") -Targets All } else { report
    "openspec-mod/ not found in this clone - skipping OpenSpec schema/skill
    install" }`.** No re-implementation of that script's logic. Per Decision
    1's correction, the `Test-Path` branch that actually installs is now the
    one task 12.1 must primarily verify, since `openspec-mod/` is present in
    the real repo today.

16. **[Unchanged from prior sketch] Fetch mechanism: `git clone --depth 1
    <origin-url> $tempDir`, deleted (`Remove-Item -Recurse -Force`) in a
    `finally` block regardless of success/failure.** `git` is a hard
    prerequisite (`Get-Command git`); if absent, report the concrete blocker
    and exit before attempting any other step.

17. **[Unchanged from prior sketch] OpenSpec CLI presence for step 1
    (`openspec init`) is a hard prerequisite the script checks and can
    optionally remediate.** `Get-Command openspec`; if missing, check
    `Get-Command npm`; if present, ask for confirmation (unless `-Yes`)
    before running `npm install -g @fission-ai/openspec`; if npm is also
    absent, report the blocker and skip step 1 (and step 7, which depends on
    `openspec/` existing) while continuing with steps 2 onward.

18. **[Unchanged from prior sketch] `openspec init` is only run if
    `openspec/config.yaml` does not already exist in the target repo.**
    Running `openspec init` against an already-initialized project is
    unnecessary; if already initialized, report `already initialized`.

19. **[New in this revision] CocoIndex indexing: duplicate the
    check-and-index logic from `.agents/scripts/prepare-ai-code-discovery.ps1`
    locally, don't invoke that script.** The prior review of this plan
    surfaced a gap: nothing wires up CocoIndex (`ccc`) for the target repo,
    even though the copied `.agents/templates/AGENTS-template.md` and
    `.agents/start/` docs both reference it as the expected code-discovery
    tool. A sibling script, `.agents/scripts/prepare-ai-code-discovery.ps1`,
    already does the check-and-index work needed (its lines 113-135: `Get-Command
    ccc`, check `~/.cocoindex_code/global_settings.yml` exists,
    `Push-Location`/`ccc index`/`Pop-Location` in the target repo root — plus
    the `Get-CommandStatus "ccc"` tool-check call at line 67, part of that
    script's unrelated generic tool-check block, not itself duplicated here)
    — but that script also copies `.agents/start` again (already done
    by this plan's task 5) and adds both `.serena/` and `.cocoindex_code/` to
    `.gitignore` (conflicting with Decision 5's deliberately narrow
    `.gitignore` change). Reusing it unmodified would silently reopen
    Decision 5 and duplicate work task 5 already does. Rather than editing
    that script to add suppression flags for this plan's sake, the small
    check-and-index piece (~20 lines) is duplicated locally, consistent with
    how Decision 9 already duplicates the hash-compare helper instead of
    importing it.
    **Behavior:** after skill install (after task 7), check `Get-Command ccc
    -ErrorAction SilentlyContinue`. If absent, report "install cocoindex-code
    globally, then run: ccc index" and skip — no attempt to install it
    (out of scope, same non-goal class as Node/npm in Decision 17). If
    present, check `Join-Path $HOME ".cocoindex_code\global_settings.yml"`
    exists; if not, report "CocoIndex global settings missing - run `ccc
    init` first, then re-run this script" and skip. If both present: append
    `.cocoindex_code/` to the target `.gitignore` if missing (reusing task
    6.1's line-check helper — this is the one addition to Decision 5's
    `.gitignore` scope, justified because `ccc index` itself creates this
    folder in the target repo, unlike `.serena/`, which nothing here creates
    or references and is therefore deliberately not added), then run `ccc
    index` with the target repo as the working directory
    (`Push-Location`/`Pop-Location`), treating a non-zero `$LASTEXITCODE` as
    a reported failure, not a script-terminating throw — this step is
    best-effort, unlike the git-clone or safety-guard checks.
    **No confirmation prompt, not gated by `-Yes`:** unlike `npm install -g
    @fission-ai/openspec` (Decision 17), running `ccc index` is
    non-destructive, local-only, and reversible (re-indexing), so it runs
    automatically whenever both preconditions are met — matching
    `prepare-ai-code-discovery.ps1`'s own existing behavior exactly.
    Rejected: invoking `prepare-ai-code-discovery.ps1` directly from the temp
    clone (the same pattern as Decision 15's `sync-openspec-skills.ps1`
    call) — would require first modifying that script to accept flags
    suppressing its own `.agents/start` copy and `.serena/` gitignore line,
    judged more complex than a small local duplication of just the needed
    piece.

## Open questions

None blocking. Every decision needed to implement is resolved above,
including the two that were genuinely open in the prior sketch (skill
selection/`-Yes` semantics — Decision 2; symlink permission handling —
Decision 6).

## Existing files to read or re-check during implementation

- `.agents/scripts/sync-openspec-skills.ps1` — re-read in full immediately
  before writing the new script, to confirm its parameter surface
  (`-Targets`) and output format haven't changed since this plan was written,
  since Decision 15 invokes it directly and unmodified.
- `.agents/skills/todo/SKILL.md` — confirm it still consists only of
  `SKILL.md` (no `references/` subfolder) so the always-installed copy/symlink
  step doesn't need directory-recursion logic beyond what a generic per-skill
  handler already provides.
- `openspec/config.yaml` (this repo's own, as a shape reference only — this
  script never touches this repo's own config) — re-confirm the `schema:`
  line's exact format immediately before writing the regex in Decision 7.
- `git remote -v` — re-confirm the origin URL is still
  `https://github.com/ZchopX/Agentic_Framework.git` immediately before
  hardcoding it into the new script, since Decision 4's self-clobber guard
  depends on this exact string matching.
- `.gitignore` (this repo's own) — re-confirm only `.claude/settings.local.json`
  is the intended line to propagate per Decision 5, not the other three
  entries.
- `git ls-files .agents/skills` — re-run immediately before implementing the
  skill-candidate enumeration (Decision 12) to catch any skills added since
  this plan was written.
- `.agents/scripts/prepare-ai-code-discovery.ps1` — re-read lines 113-135
  immediately before implementing task 9, to confirm the `ccc` check/index
  logic Decision 19 duplicates hasn't changed since this plan was written
  (lines 64-90 are unrelated generic tool-check/repo-root-resolution logic,
  not being duplicated — no need to re-read beyond line 67's
  `Get-CommandStatus "ccc"` call for reference).

## New and updated files

New:
```
.agents/scripts/install-agentic-framework.ps1
```

No other file is touched. This plan does not modify `openspec-mod/`,
`sync-openspec-skills.ps1`'s own content, or any existing skill. (The prior
sketch's planned `.agents/scripts/README.md` addition is removed per
Decision 10 — nothing documents this script.)

## Step-by-step ordered tasks

### 1. Scaffold the script
- [ ] 1.1 Create `.agents/scripts/install-agentic-framework.ps1` with a
      `param()` block: `[CmdletBinding(SupportsShouldProcess)]`, no required
      parameters (fully interactive by default), optional `-SourceUrl`
      (default `https://github.com/ZchopX/Agentic_Framework.git`, override
      for testing against a fork) and `-Yes` (skip confirmation prompts *and*
      skill-selection prompt, using the auto-detected currently-installed set
      per Decision 2). `$ErrorActionPreference = "Stop"`. Verify: syntax
      check under both `powershell.exe` and `pwsh.exe`.

### 2. Safety guards (before anything else runs)
- [ ] 2.1 Not-a-git-repo guard (Decision 13): if `.git` doesn't exist in the
      current directory, print the "run this from the root of the git
      repository you want to install into" message and exit.
- [ ] 2.2 Self-clobber guard (Decision 4): read `git remote get-url origin`
      (best-effort); if it matches `$SourceUrl` (case-insensitive, with/without
      trailing `.git`), print the "you're running this from inside
      Agentic_Framework itself" message and exit before cloning anything.
      Verify: run both checks against a scratch non-git folder (expect guard
      2.1 to fire) and against this repo's own checkout (expect guard 2.2 to
      fire, confirming it never reaches the clone step).

### 3. Clone the source repo to a temp dir
- [ ] 3.1 Check `Get-Command git`; report and exit if missing (Decision 16).
      `git clone --depth 1 $SourceUrl $tempDir` into a fresh subfolder under
      `[System.IO.Path]::GetTempPath()`; wrap the entire rest of the script's
      body in `try { ... } finally { Remove-Item -Recurse -Force $tempDir
      -ErrorAction SilentlyContinue }`. Verify: run against the real
      `Agentic_Framework` URL from a scratch target directory, confirm the
      temp dir is populated then removed even when a later step throws
      (simulate by temporarily forcing an error).

### 4. OpenSpec init (step 1 of the user's original list)
- [ ] 4.1 Check `Get-Command openspec`; if missing, check `Get-Command npm`
      and prompt (unless `-Yes`) to run `npm install -g
      @fission-ai/openspec`; if npm is also missing, report the blocker and
      set a flag skipping this step and step 8 (Decision 17).
- [ ] 4.2 If `openspec` is available and `openspec\config.yaml` does not
      exist in the current directory, run `openspec init` (confirm exact
      non-interactive flags against `openspec --help`/`openspec init --help`
      during implementation). If it already exists, report `already
      initialized` (Decision 18). Verify: run once against a scratch
      directory with no `openspec/` folder, confirm it's created and that
      `.claude/commands/opsx/*.md` appears as a side effect (Decision 3 —
      this is the evidence that no separate copy step was needed); run
      again, confirm `already initialized` with no CLI invocation the second
      time.

### 5. Copy `.agents/` structure (step 3 of the user's original list)
- [ ] 5.1 Always copy, with content, from the temp clone into the target
      repo: `.agents/templates/`, `.agents/states/`, `.agents/start/`,
      `.agents/reference/`. Use the same hash-compare-before-copy approach as
      Decision 2 so a re-run reports `unchanged`/`updated`/`installed` per
      file or folder, not a blind overwrite.
- [ ] 5.2 Always create (no content) `.agents/plans/`, `.agents/reports/`,
      `.agents/reviews/` if they don't already exist in the target repo.
      Never overwrite or touch these if the target repo already has content
      there.

### 6. `.gitignore` entry (new task, Decision 5)
- [ ] 6.1 If `.gitignore` exists in the target repo, check (literal,
      case-sensitive `Select-String -SimpleMatch`) whether it already
      contains a line equal to `.claude/settings.local.json`; append it if
      not. If `.gitignore` doesn't exist, create it containing only that one
      line. Verify: run twice against a scratch target repo — first run adds
      the line, second run reports no change and the file has no duplicate
      line.

### 7. Skill selection and install (steps 4-5 of the user's original list)
- [ ] 7.1 Enumerate skill candidates per Decision 12 (`Get-ChildItem
      -Directory` under the temp clone's `.agents\skills\`, filtered to
      folders containing `SKILL.md`).
- [ ] 7.2 For each candidate, compare against the target repo's
      `.agents/skills/<name>/` (if present) using a locally-defined
      hash-compare helper (Decision 9) and tag `[new]` /
      `[installed, up to date]` / `[installed, update available]` per
      Decision 2.
- [ ] 7.3 If `-Yes`: skip the prompt, select exactly the
      `[installed, ...]`-tagged skills (i.e. the currently-installed set,
      refreshed), no `[new]` skills auto-added. If interactive: print a
      numbered list with those tags, checkboxes pre-ticked for every
      `[installed, ...]` entry and unticked for `[new]` entries; a bare
      Enter accepts the pre-ticked set; otherwise prompt for comma-separated
      numbers or `all`, tolerating whitespace and out-of-range/non-numeric
      entries with a clear re-prompt rather than a crash.
- [ ] 7.4 Always add `todo` to the selected set regardless of user input or
      `-Yes` (Decision 14), de-duplicating if already selected.
- [ ] 7.5 For each selected skill, copy its full folder (recursively) into
      `.agents/skills/<name>/` in the target repo (hash-compare first, only
      write if `missing`/`different`, per Decision 2/9).
- [ ] 7.6 For each selected skill, install `.claude/skills/<name>/` via
      symlink-first with copy fallback (Decision 6): attempt `New-Item
      -ItemType SymbolicLink -Path <claude-path> -Target <agents-path>`
      inside a `try`; on any exception, recursively copy instead; record
      `symlinked` or `copied (enable Developer Mode or run as admin for
      symlinks)` per skill for the final report. If a symlink already exists
      and points at the correct target, treat as up to date (no-op); if a
      real copy already exists and content matches (per hash-compare), leave
      it as a copy (no upgrade-to-symlink attempt, per Decision 6's
      rationale). Verify: run once unelevated with Developer Mode off
      (expect all `copied`), once elevated or with Developer Mode on (expect
      all `symlinked`), confirm both cases leave `.agents/skills/<name>/`
      correctly populated and `.claude/skills/<name>/` resolving to
      equivalent content either way.

### 8. OpenSpec schema/skill install (step 6 of the user's original list)
- [ ] 8.1 Implement Decision 15's `Test-Path` branch exactly: invoke
      `sync-openspec-skills.ps1` from the temp clone when `openspec-mod/`
      exists there, else report the clean skip reason. Verify: run against
      the current (post-Decision-1-correction) `Agentic_Framework` state and
      confirm the real install path is exercised (schema and skill actually
      land in their global locations), not just the skip branch.

### 9. CocoIndex indexing (Decision 19)
- [ ] 9.1 Check `ccc` on PATH (`Get-Command ccc -ErrorAction
      SilentlyContinue`); report and skip (not fatal) if missing.
- [ ] 9.2 Check `~/.cocoindex_code/global_settings.yml` exists; report and
      skip (not fatal) if missing, with the "run `ccc init` first" message.
- [ ] 9.3 If both present: append `.cocoindex_code/` to the target
      `.gitignore` if missing (reuse task 6.1's line-check helper), then run
      `ccc index` from the target repo root (`Push-Location`/`Pop-Location`),
      capturing and reporting success/failure without throwing on a non-zero
      exit code. Verify: run once with `ccc` present and initialized (expect
      the index to run, `.gitignore` gets the new line); run once with `ccc`
      temporarily hidden from PATH (scope `$env:PATH` to the test process) to
      confirm the skip-and-report branch fires cleanly with no error; run once
      with `ccc` present but `~/.cocoindex_code/global_settings.yml`
      temporarily renamed/absent to confirm task 9.2's "run `ccc init` first"
      skip message fires without attempting `ccc index`.

### 10. Set default schema (step 7 of the user's original list)
- [ ] 10.1 Only reached if `openspec/config.yaml` exists (post task 4) and
      task 8 actually installed/confirmed `spec-driven-verified` present at
      `%LOCALAPPDATA%\openspec\schemas\spec-driven-verified\`. Read the
      current `schema:` value using the tightened regex from Decision 7
      (`^schema:\s*.*$`, matched per-line, no leading `#`/whitespace
      permitted), show it alongside the proposed `spec-driven-verified`,
      prompt for confirmation (unless `-Yes`), then apply a single-line
      regex replace. If no matching line is found, report "schema: line not
      found - skipping automatic default-set, edit openspec/config.yaml
      manually". Verify: on a scratch `config.yaml` matching this repo's
      real format (comments included, plus a synthetic commented-out
      `#   schema: example` line inserted to test the anchor doesn't
      false-match it), confirm only the true `schema:` line changes and
      every other line/comment is byte-identical before and after.

### 11. Summary report
- [ ] 11.1 Print a final report mirroring `sync-openspec-skills.ps1`'s
      style: PowerShell edition/version, OpenSpec CLI status, per-skill
      install/update/skip result plus symlinked-vs-copied status, `.agents/`
      structure copy results, `.gitignore` result, CocoIndex status
      (`indexed` / `skipped - ccc not found` / `skipped - ccc not
      initialized` / `failed (exit code N)`), OpenSpec schema install result
      (installed/skipped-not-in-clone), and default-schema-set result
      (set/skipped-declined/skipped-no-config).

### 12. End-to-end verification
- [ ] 12.1 Create a throwaway scratch git repo (outside `Agentic_Framework`,
      deleted after), copy the finished script into it alone (no other file
      from `Agentic_Framework` present — proving Decision 9's
      self-containment), and run it once under `pwsh.exe`, once under
      `powershell.exe`, confirming: both safety guards correctly allow this
      scratch repo through, OpenSpec init behavior, `.agents/` structure
      appears correctly, `.gitignore` gets the one new line, chosen skills +
      `todo` land in `.agents/skills/` with `.claude/skills/` correctly
      symlinked or copy-fallback per the host's actual permission state, the
      OpenSpec schema/skill step actually installs (per Decision 1's
      correction — this is now expected to succeed, not skip), and default
      schema gets set on confirmation. Then a second immediate re-run:
      confirms every skill selected the first time shows pre-ticked and
      `-Yes` on that second run changes nothing beyond refreshing content
      that legitimately changed upstream (none did, between two immediate
      runs) — i.e. `up to date`/`already initialized` everywhere, no
      destructive changes, no duplicate `.gitignore` line.
- [ ] 12.2 Separately verify both safety guards' negative cases end-to-end:
      running the finished script from inside a clone of `Agentic_Framework`
      itself (Decision 4 should fire before any clone/write happens), and
      running it from a non-git scratch folder (Decision 13 should fire
      first).

## Test strategy

No test framework in this repo (unchanged from the prior sketch).
Verification is scratch-repo-driven, mirroring `sync-openspec-skills.ps1`'s
own approach:
- Function-level: the local hash-compare helper (task 7.2), the symlink/copy
  fallback (task 7.6), the CocoIndex check/index branch (task 9.3, both the
  present-and-initialized and `ccc`-hidden-from-PATH cases), and the
  `schema:`-line regex (task 10.1, including the synthetic commented-out
  counter-example) each get an isolated scratch-file check before the full
  end-to-end pass.
- Guard-level: task 12.2, both safety guards' negative cases, run in
  isolation before the full end-to-end pass so a guard bug can't be masked
  by the happy-path test also passing.
- End-to-end: task 12.1, both engines, first-run and re-run cases, against a
  disposable scratch repo, never against a real project.

## Validation commands

```powershell
# Syntax check
powershell -NoProfile -Command ". '.agents\scripts\install-agentic-framework.ps1' -WhatIf"

# Guard checks (run from inside Agentic_Framework's own checkout - expect refusal)
pwsh -File <path-to-copied-script>\install-agentic-framework.ps1 -WhatIf

# Dry run against the real framework repo, from a scratch target repo
pwsh -File <path-to-copied-script>\install-agentic-framework.ps1 -WhatIf

# Real run, PowerShell 7
pwsh -File <path-to-copied-script>\install-agentic-framework.ps1

# Real run, Windows PowerShell 5.1 (must behave identically)
powershell -File <path-to-copied-script>\install-agentic-framework.ps1

# Non-interactive refresh (second+ run)
pwsh -File <path-to-copied-script>\install-agentic-framework.ps1 -Yes

# Confirm a specific installed skill matches source
Get-FileHash <target-repo>\.agents\skills\todo\SKILL.md -Algorithm SHA256

# Confirm .claude/skills/<name> resolves correctly whichever mode was used
Get-Item <target-repo>\.claude\skills\todo | Select-Object LinkType, Target
```

## Acceptance criteria checklist

- [ ] Script is a single file with no dependency on any other file existing
      in the target repo (Decision 9), verified by task 12.1's isolated copy.
- [ ] Runs correctly under both `powershell.exe` 5.1 and `pwsh.exe` 7.
- [ ] Refuses to run when the current directory is not a git repository
      (Decision 13), verified by task 12.2.
- [ ] Refuses to run when the current directory's origin remote matches
      `$SourceUrl` (Decision 4), verified by task 12.2.
- [ ] Idempotent: a second run with no new selections reports
      up-to-date/already-initialized everywhere, makes no destructive change,
      adds no duplicate `.gitignore` line.
- [ ] `openspec init` only runs when `openspec/config.yaml` doesn't already
      exist (Decision 18).
- [ ] Skill checklist is generated live from the cloned repo's actual
      `.agents/skills/*` contents, never hardcoded (Decision 12), and is
      pre-ticked from the target repo's actual currently-installed skills
      (Decision 2).
- [ ] `-Yes` selects exactly the currently-installed skill set (refreshed)
      plus `todo`, never adds a skill the user hasn't previously chosen
      (Decision 2).
- [ ] `todo` is always installed/updated regardless of checkbox selection or
      `-Yes` (Decision 14).
- [ ] Every selected skill's `.agents/skills/<name>/` is a real copy, and its
      `.claude/skills/<name>/` counterpart is a symlink when creation
      succeeds, a real copy with correct content when it doesn't, always
      reported per skill (Decision 6).
- [ ] `.gitignore` gets `.claude/settings.local.json` added if missing, file
      created if absent, no other lines added by task 6 itself (Decision 5).
- [ ] `.gitignore` separately gets `.cocoindex_code/` added, only when `ccc`
      and its global settings are both present (Decision 19), never
      `.serena/`, and never a duplicate line on re-run.
- [ ] `ccc index` is attempted automatically (no prompt, not gated by `-Yes`)
      whenever both `ccc` and `~/.cocoindex_code/global_settings.yml` are
      present; skipped with a clear, non-fatal message otherwise; a failed
      index (non-zero exit code) is reported but does not abort the script
      (Decision 19).
- [ ] Task 8 correctly detects and skips when `openspec-mod/` is absent from
      the clone, and correctly installs via `sync-openspec-skills.ps1` when
      present (confirmed present today per Decision 1's correction), without
      modifying that script.
- [ ] Task 10 changes only the true `schema:` line in `openspec/config.yaml`
      (never a commented-out example line), confirmed byte-identical
      elsewhere, and only after explicit confirmation (unless `-Yes`).
- [ ] Temp clone is always removed, including when an earlier step throws.
- [ ] Final report clearly states per-area outcome (init, structure copy,
      `.gitignore`, each skill's install method, CocoIndex status, OpenSpec
      schema/skill, default-schema-set) plus PS edition/version.
- [ ] No README or other documentation file is created for this script
      (Decision 10).

## Risks, assumptions, and fallbacks

- **Risk:** `openspec init`'s exact non-interactive flags/behavior were not
  probed live in this session. *Mitigation:* task 4.2 explicitly calls for
  confirming `openspec init --help` during implementation before assuming any
  flag.
- **Risk:** A target repo may already have a differently-shaped
  `openspec/config.yaml` (e.g., no `schema:` line at all, or a custom init
  template shape) that the Decision 7 regex doesn't match. *Mitigation:* if
  the regex finds no match, report "schema: line not found - skipping
  automatic default-set, edit openspec/config.yaml manually" rather than
  guessing where to insert one.
- **Risk:** Symlink creation behavior (Decision 6) depends on host
  configuration (Developer Mode, elevation) that varies machine to machine
  and can't be fully verified on a single dev machine. *Mitigation:* task 7.6
  and task 12.1 explicitly test both the symlink-success and copy-fallback
  paths (by toggling Developer Mode or elevation between two runs), and the
  final report always states which mode was actually used per skill, so a
  user can tell without inspecting the filesystem themselves.
- **Risk:** CocoIndex indexing behavior (Decision 19) can't be fully verified
  in every host state on a single dev machine (`ccc` missing vs. present but
  uninitialized vs. present and initialized). *Mitigation:* task 9.3
  explicitly tests both the present-and-initialized path and the
  `ccc`-hidden-from-PATH path; the final report always states which of the
  four CocoIndex outcomes occurred.
- **Assumption:** `git clone --depth 1` against a public GitHub URL needs no
  authentication for this repo (confirmed by the plain HTTPS remote URL with
  no credential helper configured beyond normal git defaults). If the repo is
  ever made private, this script would need a credentialed clone path — out
  of scope unless/until that happens.
- **Fallback:** if a target repo's user declines the `npm install -g
  @fission-ai/openspec` prompt or has no npm, the script still completes
  steps 3, 5, 6, 7 (structure, `.gitignore`, skills) — it degrades gracefully
  rather than aborting entirely over one missing external tool.
- **Deferred, not a risk:** version pinning (Decision 11) — noted as an
  explicit non-goal per the user's decision, not an open risk.

## Compatibility notes

- **Sources checked:** `.agents/scripts/sync-openspec-skills.ps1` (reused
  directly per Decision 15), `openspec/config.yaml` (schema-line format,
  Decision 7), `.gitignore` (narrowed propagation, Decision 5), `git
  ls-files`/`git remote -v`/`git status` (current push state, source URL,
  self-clobber guard target, tracked-skill list), `dist/core/project-config.js`
  inside the installed `@fission-ai/openspec` package (schema-activation
  semantics), commit `9507ed0`'s message (evidence for Decision 3),
  `.agents/scripts/prepare-ai-code-discovery.ps1` and
  `.cocoindex_code/settings.yml`/`~/.cocoindex_code/global_settings.yml`
  (CocoIndex check/index/config shape, Decision 19).
- **Compatibility with current stack:** Full. No build system, package
  manager, or CI in this repo; a standalone `.ps1` script matches the
  established precedent (`sync-openspec-skills.ps1`) for this kind of task.
- **Existing stack alternatives considered:** a Node.js CLI package published
  to npm (rejected — introduces a whole new distribution/versioning surface
  and a new runtime dependency for target repos, when a single copy-and-run
  `.ps1` file satisfies every stated requirement); a remote `irm | iex`
  one-liner (rejected, Decision 8); vendoring `sync-openspec-skills.ps1`'s
  logic inline instead of invoking it from the clone (rejected, Decision 15);
  a separate `-Update` command/mode (rejected, Decision 2); self-elevation for
  symlink creation (rejected, Decision 6).
- **ADR required:** no — no new runtime, framework, database, package
  manager, build system, or dependency-policy decision; built entirely from
  `git`, PowerShell/.NET built-ins, and the already-adopted `openspec` CLI.

## No user-facing impact identified beyond CLI/report output

This is an operator-run installer/updater script, not an application feature.
Its only "user-facing" surface is its own console prompts (skill checkbox,
confirmation prompts, safety-guard error messages) and final report —
covered by task 11.1 and the acceptance criteria on report clarity and guard
messaging.
