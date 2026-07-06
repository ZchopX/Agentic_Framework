---
name: plan-executor
description: Execute an existing implementation plan file and report completion status, tests, and validations. Use when the user asks to implement from a written plan.
---

# Plan Executor

## Goal
Implement a plan faithfully and surface any required deviations.

## Workflow
1. Read the full plan document and extract ordered tasks.
2. Execute tasks in dependency order.
3. Keep changes consistent with project conventions and architecture.
4. Implement or update tests defined by the plan.
5. Run validation commands from the plan and report results.

## Reporting Contract
Provide:
- Completed tasks
- Files created or modified
- Tests added or updated and outcomes
- Validation command outcomes
- Deviations from plan with reasons
- Documentation changed or explicit no-docs-impact note
- Whether `plan-closeout` should run now, after a commit, or not at all
- Remaining risks or follow-up actions

## Guardrails
- Do not skip failed validations; fix and rerun where possible.
- If plan instructions conflict with repository reality, document the conflict and apply the safest compatible change.

