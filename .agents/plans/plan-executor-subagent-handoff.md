# Plan Executor to Subagent Verify Handoff

## Feature Description

Reduce token use in post-plan verification by passing structured execution context from `plan-executor` to `subagent-verify`.

Today, `subagent-verify` often starts from a cold repository view after `plan-executor` has already read the plan, mapped implementation evidence, touched files, and run validations. The new workflow will make `plan-executor` produce a compact handoff artifact and make `subagent-verify` use that artifact as an evidence index before deciding whether broader repository discovery is necessary.

User value: verification remains independent, but the verifier spends fewer tokens rediscovering context the executor already collected.

## Scope

### In Scope

- Update `.agents/skills/plan-executor/SKILL.md` so plan execution ends with a structured execution handoff artifact.
- Update `.agents/skills/subagent-verify/SKILL.md` so plan-implementation verification consumes the handoff when available.
- Update `.agents/skills/subagent-verify/references/plan-implementation-review.md` so the sub-agent prompt treats the handoff as an index to verify, not as trusted proof.
- Define when the verifier may expand beyond the handoff into broader repository discovery.
- Define a stable handoff path and required handoff sections.

### Out of Scope

- Building an automated prompt-optimization or `autoresearch` loop.
- Changing non-plan verification modes except where they need to ignore or pass through handoff fields.
- Adding new executable tooling unless implementation discovers a strong existing pattern for scripts.
- Rewriting all `subagent-verify` templates for general prompt compaction.
- Changing sub-agent tool implementations or model selection.

## Existing Files to Read

- `.agents/skills/plan-executor/SKILL.md`
  - Rationale: source of the execution workflow and reporting contract that must produce the handoff.
- `.agents/skills/subagent-verify/SKILL.md`
  - Rationale: source of mode selection, pointer gathering, sub-agent prompt construction, triage, and final reporting.
- `.agents/skills/subagent-verify/references/plan-implementation-review.md`
  - Rationale: selected prompt template for the usual `plan-executor` -> `subagent-verify` path.
- `.agents/skills/subagent-verify/references/code-change-review.md`
  - Rationale: confirm non-plan review behavior does not accidentally inherit plan-handoff assumptions.
- `.agents/skills/subagent-verify/references/validation-output-review.md`
  - Rationale: confirm artifact and validation review wording remains compatible when a handoff is listed as an artifact.
- `.agents/skills/plan-closeout/SKILL.md`
  - Rationale: check whether closeout already expects plan execution summaries or report paths that the handoff should align with.

## Files to Update

- `.agents/skills/plan-executor/SKILL.md`
  - Add an "Execution Handoff" section.
  - Extend workflow and reporting contract to require handoff creation or an explicit no-handoff reason.
- `.agents/skills/subagent-verify/SKILL.md`
  - Add handoff discovery and consumption rules for `plan-implementation-review`.
  - Add escalation rules for when broader discovery is allowed.
  - Update filled prompt shape to include the execution handoff path when present.
- `.agents/skills/subagent-verify/references/plan-implementation-review.md`
  - Add an `Execution handoff` fill field.
  - Add handoff-first review procedure.
  - Add finding rules for missing, stale, contradictory, or incomplete handoff evidence.

## New Files

None expected.

## Handoff Contract

`plan-executor` should create a Markdown handoff after implementing a plan unless the task is aborted before meaningful execution begins.

Recommended path:

```text
.agents/reports/<plan-basename>-execution-handoff.md
```

If `.agents/reports` does not exist, `plan-executor` should create it when writing the handoff.

Required sections:

```md
# Execution Handoff

Plan: <path>
User request: <1-3 sentences or "not available">
Final outcome: <1-3 sentences>

## Plan Item Evidence
| Plan item | Status | Evidence |
|---|---|---|
| <plan step / acceptance criterion> | <done / partial / skipped / blocked> | <file:line, test, command, artifact, or reason unavailable> |

## Changed Files
- <path>: <brief purpose of change>

## Validation Run
- <command> - <passed / failed / not run> - <brief note>

## Deviations
- <plan deviation and reason, or "None">

## Risk Areas
- <shared integration, missing validation, fragile assumption, or "None">

## Follow-Up Pointers
- <files, docs, artifacts, logs, screenshots, or "None">
```

Contract rules:

- The handoff is an evidence index, not proof.
- Evidence should point to files, commands, artifacts, and specific plan items instead of copying long diffs or logs.
- `plan-executor` should include uncertainty explicitly rather than filling gaps with guesses.
- `plan-executor` should not add broad repository architecture summaries unless they directly explain a changed path or risk area.

## Subagent Verify Behavior

When `subagent-verify` runs after `plan-executor` or when a handoff path is available:

1. Select `plan-implementation-review`.
2. Include the handoff path in the filled prompt.
3. Ask the sub-agent to read the handoff first.
4. Ask the sub-agent to verify mapped evidence directly against the plan, changed files, tests, commands, and artifacts.
5. Allow broader repository discovery only when one of these conditions is true:
   - The handoff is missing or unreadable.
   - A required plan item has no evidence pointer.
   - Evidence pointer is stale, wrong, contradictory, or too vague to verify.
   - A changed file touches a shared interface, public command, schema, migration, persistence path, security boundary, generated artifact, or external integration not covered by the handoff.
   - Validation failed, was skipped, or does not cover a risk area named in the handoff.
6. If none of those conditions are true, constrain review to the handoff, plan, changed files, direct call sites, validation outputs, and listed artifacts.

Independence rule:

- The verifier may use the handoff to navigate, but must not trust conclusions in it without checking the referenced evidence.

## Implementation Tasks

1. Read the listed existing files and confirm there is no stronger existing report or closeout convention to reuse.
2. Update `plan-executor` workflow:
   - Add a final step to produce the execution handoff.
   - Require creation of `.agents/reports/<plan-basename>-execution-handoff.md` when a written plan is implemented.
   - Allow an explicit no-handoff reason only when execution stops before meaningful implementation.
3. Update `plan-executor` reporting contract:
   - Add the handoff path.
   - Require final answers to mention whether `subagent-verify` can use the handoff.
4. Update `subagent-verify` workflow:
   - Add handoff pointer gathering after plan path and changed files.
   - Prefer the handoff for plan-implementation mode.
   - Keep existing fallback behavior when no handoff exists.
5. Update `subagent-verify` prompt construction:
   - Add `Execution handoff: <path or "none">` to the filled prompt shape.
   - Tell the main agent not to paste the full handoff when a path is available.
6. Update `plan-implementation-review.md`:
   - Add the fill field.
   - Add a short "Handoff-First Review" section.
   - Update evidence map instructions to start from the handoff when present.
   - Update finding rules to report handoff gaps only when they block concrete verification.
7. Review non-plan templates for accidental contradictions:
   - Do not add handoff requirements to `code-change-review.md`.
   - Do not add handoff requirements to `validation-output-review.md`, except optional artifact handling if needed.
8. Run validation commands and inspect the diff.
9. If changes are substantial, use `subagent-verify` on this plan implementation and ensure it uses the new handoff behavior if a handoff was produced.

## Validation Strategy

Because this feature changes skill instructions rather than runtime code, validation is instruction and workflow validation.

### Static Checks

Run:

```powershell
Get-Content -Raw .agents/skills/plan-executor/SKILL.md
Get-Content -Raw .agents/skills/subagent-verify/SKILL.md
Get-Content -Raw .agents/skills/subagent-verify/references/plan-implementation-review.md
```

Inspect for:

- Handoff path is named consistently.
- Required handoff sections are identical between executor and verifier instructions.
- The verifier is told to verify evidence, not trust the handoff.
- Broad discovery is conditional, not default, in plan-implementation mode.
- Fallback behavior remains available when no handoff exists.

### Repository Checks

Run:

```powershell
git diff -- .agents/skills/plan-executor/SKILL.md .agents/skills/subagent-verify/SKILL.md .agents/skills/subagent-verify/references/plan-implementation-review.md
```

Inspect for:

- No accidental changes to unrelated skill files.
- No deleted safety rules around read-only sub-agent behavior.
- No instruction that lets the sub-agent modify files.

### Dry-Run Reasoning Check

Manually simulate this sequence:

1. A plan is implemented.
2. `plan-executor` writes `.agents/reports/example-execution-handoff.md`.
3. `subagent-verify` receives plan path, changed files, validation commands, and handoff path.
4. The sub-agent reads the handoff first.
5. The sub-agent checks only referenced evidence and direct integrations unless escalation conditions are met.

The dry run passes if the written instructions make each step explicit without requiring the verifier to rediscover the whole repository.

## Acceptance Criteria

- [ ] `plan-executor` requires a structured execution handoff after meaningful plan implementation.
- [ ] The handoff path convention is stable and under `.agents/reports/`.
- [ ] The handoff includes plan item evidence, changed files, validation, deviations, risk areas, and follow-up pointers.
- [ ] `subagent-verify` includes the handoff in plan-implementation prompt construction when available.
- [ ] `subagent-verify` instructs the sub-agent to treat the handoff as an index, not trusted proof.
- [ ] `subagent-verify` limits broad repository discovery unless explicit escalation conditions are met.
- [ ] Existing no-handoff fallback behavior remains intact.
- [ ] The read-only boundary for sub-agents remains explicit.
- [ ] Validation confirms only intended skill files changed.

## Risks and Fallbacks

- Risk: The verifier may over-trust the handoff and miss executor mistakes.
  - Fallback: Keep explicit instructions to verify each referenced evidence pointer against source, tests, commands, and artifacts.
- Risk: Handoffs become verbose and recreate the original token problem.
  - Fallback: Require pointers and short notes, not copied diffs, logs, or architecture summaries.
- Risk: Handoffs omit important shared integration paths.
  - Fallback: Add escalation conditions for shared interfaces, public commands, schemas, migrations, persistence, security boundaries, generated artifacts, and external integrations.
- Risk: Some plan executions do not create a handoff.
  - Fallback: Preserve current `subagent-verify` fallback path for no-handoff reviews.
- Risk: `.agents/reports` may not exist.
  - Fallback: Instruct `plan-executor` to create it when writing the handoff.

## Assumptions

- The usual workflow is `plan-executor` followed by `subagent-verify`.
- Markdown handoff artifacts are sufficient; no machine-readable JSON is required for this iteration.
- The main token savings will come from constraining verifier discovery, not from shortening all prompt text.
- Existing sub-agent tools can read repository files by path when given a handoff pointer.
