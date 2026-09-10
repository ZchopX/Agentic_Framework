# Brief Template

Section names are generic and widely recognized (design-doc style: Why, What Changes, Impact, Context, Goals/Non-Goals, Decisions, Risks/Trade-offs), so the brief can be pasted into most spec or design-doc tools without rework.

## Idea brief

```markdown
# Idea Brief: <title>
Change name: <kebab-case>
Idea verdict: BUILD | NARROW | REFRAME (from: <original idea>)
Classification: spike | bounded | architectural · Appetite: <...>

## Why
- Problem story: <...>
- Baseline today: <...>
- Job: <...>
- Why now: <...>

## What Changes
- Chosen option: <name> — <summary>
- Behavior: <externally observable behavior, bullet per behavior>

## Capabilities
- New: `<capability-path>` — <what it covers>
- Modified: `<capability-path>` — <requirement change> | none identified

## Impact
- Affected areas: <modules / files, with evidence>
- Dependencies: existing only | new: <name> — <why the current stack is insufficient>
- Stack notes: <hosting, data, migration, ops>

## Context
- <fact sheet summary: product purpose, stack, overlapping features>

## Goals / Non-Goals
- Goals: <...>
- Non-Goals / no-gos: <...>

## Decisions
- Chosen: Option <X> <name> — Good: <...>; Bad: <...>
- Rejected: Option <Y> <name> — lost because <...>
- Rejected: Option <Z> <name> — lost because <...>
- Resolved with user: <decision — answer, one per line>
- Disagreement recorded: <user position vs recommendation, or none>

## Risks / Trade-offs
- Premortem: <reason> → <mitigation | accepted risk>
- Rabbit holes: <...>
- Load-bearing assumptions: <assumption> — cheapest test: <...>

## Acceptance criteria
- [ ] <observable, testable criterion>
- Success signal: <...>

## UX notes
- Surface: GUI | CLI | API | agent · Heuristics considered: <#s> · States: <...> · Response-time targets: <...>

## Open questions
- none | deferred: <item> — <why it is safe to defer>
```

## Decision record (DEFER / DON'T BUILD)

```markdown
# Idea Decision: <title>
Verdict: DEFER | DON'T BUILD (accepted by user)
- Idea: <one sentence>
- Problem story and baseline: <...>
- Why not now / not at all: <angle findings>
- Strongest case for building (reverse premortem): <...>
- Revisit trigger (DEFER): <observable condition>
```
