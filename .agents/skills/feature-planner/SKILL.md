---
name: feature-planner
description: Turn a feature request into a decision-complete implementation plan in `.agents/plans/{kebab-case-name}.md`. Use when the user asks to plan work before coding.
---

# Feature Planner

## Goal
Produce a plan another engineer or agent can execute without extra decisions.

## Workflow
1. Parse request into goal, scope, constraints, and acceptance criteria.
2. Analyze existing code paths, related modules, and testing patterns.
3. Collect exact integration points and affected files.
4. Resolve key tradeoffs before writing the plan.
5. Write plan to `.agents/plans/<kebab-case-descriptive-name>.md`.

## Plan Requirements
- Feature description and user value
- In-scope and out-of-scope
- Existing files to read with rationale
- New and updated files list
- Step-by-step ordered tasks (atomic)
- Test strategy (unit, integration, e2e as relevant)
- Validation commands
- Acceptance criteria checklist
- Risks, assumptions, and fallbacks

## Guardrails
- Use `.agents/...` paths only.
- Reference existing project patterns instead of inventing new ones.
- Include executable validation steps for each phase.
