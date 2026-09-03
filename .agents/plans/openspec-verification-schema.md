# OpenSpec Verification Schema — Repo-Local Staging

## Feature description and user value

OpenSpec's default `spec-driven` workflow (`proposal → specs → design → tasks`, driven by `opsx:propose`/`opsx:apply`/`opsx:archive`) has no independent-review step: `opsx:apply` only checks task boxes as it goes, and `opsx:archive` only checks that boxes are checked. There is no point where a second, independent reviewer looks at the finished work before it's archived.

This repo already has that missing step — `subagent-verify` — but it targets a different filing system (`.agents/plans/*.md` + `.agents/reports/*-execution-handoff.md`), not OpenSpec's `openspec/changes/<name>/` folder.

This plan stages, entirely inside this repo, the two files needed to close that gap:
1. A forked copy of OpenSpec's `spec-driven` schema with one added artifact, `verification`, gated on `tasks` being done.
2. A new, OpenSpec-flavored skill (`openspec-verify`) — an adapted copy of `subagent-verify`, not an edit of it — that the `verification` artifact's instructions delegate to, and that writes its report into the change folder instead of `.agents/reports/`.

Nothing is deployed outside this repo by this plan. A short README documents the two manual copy commands the user runs later to promote these files to the machine-wide locations OpenSpec and Claude Code actually read from.

## In scope / out of scope

**In scope:**
- New folder `openspec-mod/` in this repo holding the staged schema fork and the staged skill copy.
- A `verification` artifact definition + template, based on the real installed `spec-driven/schema.yaml`.
- A new skill `openspec-verify`, adapted from `subagent-verify`, scoped to the one review mode this context always needs (an OpenSpec change's `tasks.md` is always "a plan that was implemented").
- A deploy README describing the two manual copy targets (OpenSpec's user schema folder, Claude Code's user skill folder) and how to verify the copy worked.

**Out of scope:**
- Editing `.agents/skills/subagent-verify/**` or any other existing skill — must remain byte-for-byte untouched.
- Wiring `feature-planner`, `plan-executor`, or `plan-closeout` into OpenSpec — settled earlier in this conversation: `opsx:propose`/`opsx:apply`/`opsx:archive` already cover that ground, adding these would be duplication, not integration.
- Actually copying anything to `%LOCALAPPDATA%\openspec\schemas\` or `~/.claude/skills/` — that copy is a manual step the user runs themselves, from the README, after reviewing the staged files. No task in this plan writes outside `C:\PyProjects\Agentic_Framework`.
- Modifying `openspec/config.yaml` or this repo's own `openspec/` change history.

## Discovery evidence

- `C:/Users/donat/AppData/Roaming/npm/node_modules/@fission-ai/openspec/schemas/spec-driven/schema.yaml` — the real, installed default schema. Confirms the exact artifact shape: `id`, `generates`, `description`, `template`, `instruction` (a free-text block shown to the agent), `requires` (array of artifact ids). Top-level `apply: { requires: [tasks], tracks: tasks.md, instruction }` is separate from the artifact list and only gates when implementation may *start* — it does not gate archiving.
- `.../dist/core/artifact-graph/schema.js` — the Zod-backed parser: rejects duplicate ids, dangling `requires` references, and dependency cycles. Confirms `verification` just needs a unique id, a valid `requires: [tasks]` edge, and a template file that exists on disk — nothing else is mechanically enforced.
- `.../dist/commands/schema.js` (`registerSchemaCommand`) — confirms three resolution locations (project → user → package, first match wins) and that `openspec schema fork`/`init` only ever write into the **project** or **user** location, never the package one; `openspec update` only touches the package copy. This is why a staged fork is permanently safe from CLI updates once promoted to layer 2 — established and already agreed on earlier in this conversation, re-verified here directly against source.
- `.agents/skills/openspec-archive-change/SKILL.md` step 2 ("Check artifact completion status") — reads the **full** `artifacts` list from `openspec status --change <name> --json` (every schema-declared artifact, not just the `apply.requires` subset) and warns (non-blocking) if any artifact is neither `done` nor `skipped`. This is schema-agnostic: it will automatically warn about an incomplete `verification` artifact with zero changes to `openspec-archive-change` itself. This is the actual gate mechanism the plan relies on — soft (a warning you can override), not hard.
- `.agents/skills/openspec-apply-change/SKILL.md` — explicitly schema-agnostic ("Other schemas: follow the `contextFiles` from CLI output", "Use `contextFiles` from CLI output, don't assume specific file names") and documents the delegation hook this plan uses: "If the `instruction` field delegates creation to a specific skill or command, invoke it instead of writing the file yourself." Confirms no OpenSpec-generated skill file needs to change for this to work.
- `.agents/skills/subagent-verify/SKILL.md` + `references/plan-implementation-review.md` — the workflow and review procedure being adapted. The reference file's review procedure (plan fidelity, correctness, validation quality, scope control) is generic enough to reuse verbatim; only the *skill's* pointer-gathering and output-writing steps are OpenSpec-specific and need rewriting.
- `openspec/config.yaml` (this repo) — confirms this repo already runs `schema: spec-driven`, so `spec-driven` is the correct fork base.

## Existing system fit

- OpenSpec artifacts are just files + one YAML entry; nothing about adding one requires touching OpenSpec's own code, config schema, or CLI.
- The delegation mechanism (`instruction` text telling the agent to invoke a named skill) is an existing, documented pattern already used by the installed `opsx:*` skills' own guardrails — not a new mechanism being invented here.
- Claude Code's skill loading already supports a project-local (`.claude/skills/` or `.agents/skills/`) and a user-level (`~/.claude/skills/`) location, mirroring OpenSpec's own project/user split — so `openspec-verify` promotes the same way `spec-driven-verified` does, to the analogous user-level slot, for the same "works in every repo" reason.

## Reuse opportunities

- Fork `spec-driven/schema.yaml` and its four templates verbatim rather than hand-retyping the default workflow; add one artifact node.
- Reuse `references/plan-implementation-review.md` and `references/user-facing-review.md` unmodified inside the new skill — the review logic doesn't know or care what filing system produced the plan it's reviewing.
- Reuse the existing triage/apply/recheck logic from `subagent-verify` almost verbatim; only the "gather pointers" and "where the report is written" steps are OpenSpec-specific.

## Decisions and tradeoffs

1. **Fork base: `spec-driven` only.** This repo (and the idea's stated goal) only uses the default schema; forking is cheap enough to redo for another base schema later if needed. Rejected: designing a generic "any schema + verification" mechanism now — unrequested complexity for a problem that doesn't exist yet.
2. **One review mode, not five.** `subagent-verify` picks from five reference files based on what kind of work just happened. In OpenSpec's flow, the artifact preceding `verification` is always `tasks` (an implementation checklist), so the work being reviewed is always "implemented tasks against a plan" — `plan-implementation-review.md`, plus the conditional `user-facing-review.md` lens. The other three reference files (`plan-created-review`, `code-change-review`, `validation-output-review`) don't apply to this artifact and are not copied — copying unused files is dead weight, not portability.
3. **New skill, not a parameterized version of the old one.** The user explicitly asked for the original untouched and a separate copy. A shared-core/two-thin-wrappers design was considered and rejected: it would mean editing `subagent-verify` to extract a shared core, which is exactly the "touch the original" the user ruled out.
4. **Verification is a soft gate (warning), not a hard block.** Nothing in `openspec-archive-change` needs editing to get this; a hard block would require patching the generated `opsx:archive` skill itself, which fails the "survives `openspec update`" requirement this whole approach is built around. If a hard block is wanted later, that's a separate, explicit decision — not assumed here.
5. **Staging layout mirrors the two real deploy targets 1:1** (`openspec-mod/openspec-schemas/…` → OpenSpec's schema folder, `openspec-mod/claude-skills/…` → Claude Code's skill folder), so promotion is a straight folder copy with no restructuring, and the staged tree can be diffed directly against what's live on a machine.

## Open questions

None blocking. (Fork base, review-mode scope, and gate strength are resolved above as defaults; revisit only if the user disagrees after seeing the staged files.)

## Files to read/re-check during implementation

- `C:/Users/donat/AppData/Roaming/npm/node_modules/@fission-ai/openspec/schemas/spec-driven/schema.yaml` and its sibling `templates/*.md` — re-read at implementation time in case the globally installed OpenSpec version has moved since this plan was written; copy from disk, not from this plan's excerpt.
- `.agents/skills/subagent-verify/SKILL.md`, `references/plan-implementation-review.md`, `references/user-facing-review.md` — source for the adapted copy; re-read in full before writing the adapted version (only excerpts were read while planning).
- `.agents/skills/openspec-apply-change/SKILL.md`, `.agents/skills/openspec-archive-change/SKILL.md` — re-check that no wording there needs to change (expected: none) before declaring the feature done.

## New and updated files

New (all inside `openspec-mod/`, nothing else touched):
```
openspec-mod/
  README.md
  openspec-schemas/
    spec-driven-verified/
      schema.yaml
      templates/
        proposal.md
        spec.md
        design.md
        tasks.md
        verification.md
  claude-skills/
    openspec-verify/
      SKILL.md
      references/
        plan-implementation-review.md
        user-facing-review.md
```
Updated: none. `.agents/skills/subagent-verify/**` and every other existing skill are read-only inputs to this plan.

## Step-by-step tasks

### 1. Scaffold the staging tree
- [ ] 1.1 Create `openspec-mod/openspec-schemas/spec-driven-verified/templates/` and `openspec-mod/claude-skills/openspec-verify/references/` (creating parents as needed) and verify both directories exist.

### 2. Fork the schema
- [ ] 2.1 Copy the four templates (`proposal.md`, `spec.md`, `design.md`, `tasks.md`) byte-for-byte from the installed `spec-driven/templates/` into `openspec-mod/openspec-schemas/spec-driven-verified/templates/`, and verify each copied file's content matches its source with a diff.
- [ ] 2.2 Write `openspec-mod/openspec-schemas/spec-driven-verified/schema.yaml`: copy the installed `spec-driven/schema.yaml` verbatim, change top-level `name:` to `spec-driven-verified`, update the `description`, and append a fifth artifact:
  ```yaml
    - id: verification
      generates: verification.md
      description: Independent review of the implemented tasks before archiving
      template: verification.md
      instruction: |
        Invoke the `openspec-verify` skill/command to independently review the
        implementation against this change's proposal, specs, design, and tasks
        before it is archived.

        Do not write this file by hand — the openspec-verify skill produces it.
        If that skill is not installed in this environment, state clearly that
        verification was skipped and why; do not fabricate a review.
      requires:
        - tasks
  ```
  Leave the top-level `apply:` block (`requires: [tasks]`, `tracks: tasks.md`) unchanged — verification must not block implementation from starting.
- [ ] 2.3 Write `openspec-mod/openspec-schemas/spec-driven-verified/templates/verification.md`:
  ```markdown
  ## Verification

  **Result:** <pass | pass with notes | blocked>

  ### Findings Fixed
  - <finding> — <what was changed>

  ### Findings Rejected / Out of Scope
  - <finding> — <why>

  ### Checks Run
  - <command or inspection> — <result>

  ### Residual Risk
  - <risk, or "None">
  ```
- [ ] 2.4 Verify: run `openspec schema validate` with `--verbose` against the staged directory copied into a scratch temp dir (or `openspec schema init`'s validation path) to confirm the YAML parses and passes the duplicate-id / dangling-reference / cycle checks in `schema.js` before this is ever promoted. If running the CLI against a non-standard path isn't feasible, at minimum validate the YAML parses (`python -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]))"` or Node equivalent) and manually re-check ids/requires against the rules in `schema.js`.

### 3. Adapt the verification skill
- [ ] 3.1 Copy `.agents/skills/subagent-verify/references/plan-implementation-review.md` and `references/user-facing-review.md` verbatim into `openspec-mod/claude-skills/openspec-verify/references/`; diff against source to confirm byte-identical copies.
- [ ] 3.2 Write `openspec-mod/claude-skills/openspec-verify/SKILL.md`, adapted from `subagent-verify/SKILL.md`:
  - Frontmatter: `name: openspec-verify`, description scoped to "independent review of an OpenSpec change's implemented tasks before archiving," `allowed-tools: Bash(openspec:*)` (matching the other `opsx:*` skills' convention).
  - Step 1 (gather pointers) rewritten to be OpenSpec-native:
    - Resolve the change name (same selection convention as `openspec-apply-change`: explicit arg → conversation context → sole active change → ask).
    - Run `openspec status --change "<name>" --json` and `openspec instructions verification --change "<name>" --json`; read `planningHome`, `changeRoot`, `contextFiles` (proposal/specs/design/tasks paths), and `resolvedOutputPath` for `verification.md` from the responses.
    - Record changed files via `git status`/`git diff --name-only` scoped to what changed since the change's tasks began (same convention `subagent-verify` already uses), and validation commands already run (from the tasks.md checkbox trail / conversation).
    - There is no execution-handoff file in this flow (OpenSpec has no equivalent artifact) — pass `Execution handoff: none` into the review template; the tasks file itself plus `contextFiles` is the evidence index.
  - Step 2 (mode selection) fixed to always use `references/plan-implementation-review.md`, still applying `references/user-facing-review.md` as an added lens under the same trigger condition as the original (UI/CLI/reports/docs/notifications/user workflows touched).
  - Steps 3–6 (build sub-agent prompt, triage, apply fixes, recheck) carried over unchanged in substance from `subagent-verify`, with "Plan path" filled from `contextFiles.tasks` and "Execution handoff" fixed to `none`.
  - Step 7 (final response) adds one OpenSpec-specific action: write the finished report to `resolvedOutputPath` (the change's `verification.md`) using the template from step 2.3, instead of `.agents/reports/<plan>-execution-handoff.md`.
  - Guardrail line explicitly stating this skill is a standalone copy; `.agents/skills/subagent-verify/**` is never read or written by it.
- [ ] 3.3 Verify: read the finished `openspec-mod/claude-skills/openspec-verify/SKILL.md` end to end and confirm every path/command it references (`openspec status`, `openspec instructions verification`, `resolvedOutputPath`) matches the JSON fields actually returned by the installed CLI (spot-check against `openspec-apply-change`/`openspec-archive-change`'s documented field names, which were read during discovery).

### 4. Write the deploy README
- [ ] 4.1 Write `openspec-mod/README.md` covering, at minimum:
  - What's staged here and why (one paragraph, links to this plan).
  - Exact copy command for layer 2 schema promotion (Windows): copy `openspec-mod/openspec-schemas/spec-driven-verified/` to `%LOCALAPPDATA%\openspec\schemas\spec-driven-verified\`.
  - Exact copy command for the skill: copy `openspec-mod/claude-skills/openspec-verify/` to `~/.claude/skills/openspec-verify/` (or the user's actual global skills path if different — note how to confirm it).
  - How to make the forked schema the default for a repo (`schema: spec-driven-verified` in that repo's `openspec/config.yaml`), vs. selecting it per-change (`openspec new change <name> --schema spec-driven-verified`).
  - How to verify the copy worked: `openspec schema which spec-driven-verified --all` should list it as a `user` schema; running `opsx:propose` on a scratch change with `--schema spec-driven-verified` should show 5 artifacts, not 4.
  - The explicit non-goal reminder: nothing in this repo's `openspec-mod/` is live until these copy commands are run by hand.

### 5. Final consistency pass
- [ ] 5.1 Confirm `.agents/skills/subagent-verify/**` has zero diff against its state at the start of this work (`git diff --stat .agents/skills/subagent-verify`) — must be empty.
- [ ] 5.2 Confirm no file was written outside `openspec-mod/` and `.agents/plans/openspec-verification-schema.md` (`git status`) — no touches to `openspec/`, `.claude/`, or anywhere under `%LOCALAPPDATA%`.

## Test strategy

No unit/integration test suite applies — this is documentation-and-config staging, not application code. Verification is manual/CLI-driven:
- Schema validity: YAML parses, ids unique, `requires` references resolve, no cycles (task 2.4).
- Skill correctness: manual read-through cross-checked against real CLI JSON field names (task 3.3).
- Isolation: git-diff checks proving the original skill and the rest of the repo are untouched (task 5.1–5.2).

## Validation commands

```bash
# YAML sanity (adjust interpreter to whatever's available)
python -c "import yaml; yaml.safe_load(open('openspec-mod/openspec-schemas/spec-driven-verified/schema.yaml'))"

# Confirm original skill untouched
git diff --stat .agents/skills/subagent-verify

# Confirm nothing written outside the intended paths
git status --porcelain
```

## Acceptance criteria checklist

- [ ] `openspec-mod/openspec-schemas/spec-driven-verified/schema.yaml` exists, contains 5 artifacts (`proposal`, `specs`, `design`, `tasks`, `verification`), and `verification.requires == [tasks]`.
- [ ] All 5 templates exist under `openspec-mod/openspec-schemas/spec-driven-verified/templates/`, the first 4 byte-identical to the installed package's templates.
- [ ] `openspec-mod/claude-skills/openspec-verify/SKILL.md` exists, is OpenSpec-native (reads `openspec status`/`openspec instructions verification --json`, writes to the change's `verification.md`), and never references `.agents/reports/`.
- [ ] `openspec-mod/claude-skills/openspec-verify/references/` contains the two copied review references, byte-identical to their sources.
- [ ] `openspec-mod/README.md` gives copy-pasteable commands for both deploy targets and a way to verify each landed correctly.
- [ ] `git diff --stat .agents/skills/subagent-verify` is empty.
- [ ] `git status` shows changes only under `openspec-mod/` and the new plan file.

## Risks, assumptions, and fallbacks

- **Risk:** the globally installed OpenSpec CLI version drifts between planning and implementation, changing `schema.yaml`'s accepted fields. *Mitigation:* task 2.2 copies from the currently-installed package at implementation time, not from this plan's excerpt; task 2.4 validates against the real installed validator.
- **Risk:** `openspec instructions verification --change <name> --json` field names assumed in the new skill (`resolvedOutputPath`, `contextFiles`, `planningHome`) turn out to differ once actually run against a real change with the forked schema (this plan's discovery only observed these fields via other artifacts' documented behavior, not by running the forked schema live). *Mitigation:* task 3.3 is an explicit cross-check step; if a field name doesn't match, this is a one-file, low-risk fix confined to `openspec-verify/SKILL.md` — no other file depends on it.
- **Assumption:** the user's Claude Code global skills directory is `~/.claude/skills/`. *Fallback:* README task 4.1 tells the user how to confirm the actual path rather than asserting one hardcoded location.
- **Assumption:** a warning-level gate (via `openspec-archive-change`'s existing incomplete-artifact check) is sufficient; a hard block was explicitly deferred as a separate decision (Decision 4).

## Compatibility notes

- **Sources checked:** installed `@fission-ai/openspec` package source (`schema.js`, `schema.js` validator, `resolver.js`, `commands/schema.js`, `commands/workflow/instructions.js`), this repo's `openspec/config.yaml`, and the five relevant existing skill files (`openspec-apply-change`, `openspec-archive-change`, `openspec-sync-specs`, `openspec-propose`, `subagent-verify` + its `plan-implementation-review.md`/`user-facing-review.md` references).
- **Compatibility with current stack:** full. This is additive-only: a new artifact type in a *forked* schema (the original `spec-driven` schema is never touched) and a new, separate skill file. No existing schema, skill, or OpenSpec command is modified.
- **Existing stack alternatives considered:** editing `spec-driven` in place (rejected — would be overwritten by `openspec update`, defeating the entire point); parameterizing `subagent-verify` to serve both flows (rejected — user explicitly wants the original untouched and a separate copy).
- **ADR required:** no — no new framework, runtime, database, package manager, build system, or major dependency-policy decision; this is a config/documentation fork within an already-adopted tool.
- **Verification note:** the `openspec instructions verification --change <name> --json` field assumptions (see Risks) are inferred from adjacent artifacts' documented JSON shape, not confirmed by running the forked schema end-to-end against a live change — flagged as the one thing to spot-check live once the staged skill is written (task 3.3), before promoting anything to layer 2.

## No user-facing impact identified beyond skill/CLI output

This changes what an agent running `opsx:apply`/`opsx:archive`/`openspec-verify` prints and what files a change folder contains once promoted and adopted — no UI, no external user-facing surface. Standard user-facing gates (loading/empty/error states, accessibility, responsive layout) don't apply; the one relevant check is that `openspec-verify`'s own output format stays readable and consistent with the other `opsx:*` skills' existing "Output on Completion" style, covered by task 3.2/3.3.
