---
name: plan-executor
description: Execute an existing implementation plan file and report completion status, tests, and validations. Use when the user asks to implement from a written plan.
---

# Plan Executor

## Goal
Implement a plan faithfully and surface any required deviations.

## Workflow
1. Read the full plan document and extract ordered tasks.
2. Run the Plan Reality Check before editing.
3. Execute tasks in dependency order.
4. Keep changes consistent with project conventions and architecture.
5. Implement or update tests defined by the plan.
6. Run validation commands from the plan and report results.
7. When meaningful implementation work completed, write an execution handoff for `subagent-verify`.

## Plan Reality Check
Before changing files:

- Check current git status and identify unrelated dirty or untracked files.
- Verify the plan's cited docs, configs, source files, tests, commands, and artifacts still exist.
- Re-read the minimum relevant docs/config/source evidence when the plan depends on stack, tooling, architecture, public APIs, schemas, migrations, persistence, generated artifacts, or external integrations.
- Inspect direct call sites before editing shared functions, commands, public interfaces, schemas, or reusable helpers.
- If the plan is stale, contradicts repo reality, or omits a required integration path, stop and report the conflict unless the correction is obvious, narrow, and still inside the user's requested scope.
- Record any safe deviation and its reason in the execution handoff.

## Execution Handoff
After implementing a written plan, create:

```text
.agents/reports/<plan-basename>-execution-handoff.md
```

Create `.agents/reports` if it does not exist. If execution stops before meaningful implementation begins, do not create a handoff; report the no-handoff reason instead.

The handoff is an evidence index for a later verifier, not proof that the implementation is correct. Keep it concise and pointer-based. Do not copy long diffs, logs, generated artifacts, or broad architecture summaries.

Use this structure:

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

Include uncertainty explicitly when evidence is missing, partial, or inferred.

## Reporting Contract
Provide:
- Completed tasks
- Files created or modified
- Tests added or updated and outcomes
- Validation command outcomes
- Deviations from plan with reasons
- Execution handoff path, or explicit no-handoff reason
- Whether `subagent-verify` can use the handoff now
- Documentation changed or explicit no-docs-impact note
- Whether `plan-closeout` should run now, after a commit, or not at all
- Remaining risks or follow-up actions

## Guardrails
- Do not skip failed validations; fix and rerun where possible.
- If plan instructions conflict with repository reality, document the conflict and apply the safest compatible change.
- Do not blindly execute stale plans. Verify the plan against current files before edits.

