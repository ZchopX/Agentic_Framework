# Angles

## Contents
- Five independent critique angles: User, UX, Stack & Operator, Future Maintainer, Adversary
- Output format per angle
- Subagent prompt template

## User

Who exactly has this problem, and how often? What do they do today (baseline)? Would they notice if it shipped? Which job does it serve? What evidence supports demand (tag it)?

## UX

Walk the primary flow step by step. Which heuristics (use the matching surface column of `ux-heuristics.md`) does each option stress? Which states (loading, empty, error, success, disabled, partial) appear? Are there response-time boundaries? What new concepts or cognitive load are added? Accessibility (GUI)?

## Stack & Operator

Does it fit the existing runtime, framework, datastore, and deploy target (cite files)? Does it need new dependencies or services? Are there hosting constraints (for example, serverless time limits or no long-lived connections)? Data migration? Secrets, monitoring, ops cost? Is there an existing pattern or feature to reuse (cite file)?

## Future Maintainer

What does this make harder to change in 12 months? What coupling and new surface area does it add? Which tests and docs does it require? Is it reversible, and at what cost?

## Adversary

What is the strongest case against building it? Which assumption, if false, kills it? What is "the comparison being avoided", meaning which cheaper alternative the idea is not being compared against? Any abuse, security, or privacy risks?

## Output format per angle

```
Angle: <name>
Concerns (max 3):
- [blocker | major | minor] <concern> — <evidence (<file>) | analogy | intuition>
Opportunity: <one>
Assumptions noticed: <list>
```

## Subagent prompt template

```
You are reviewing a proposed idea from ONE angle only: <ANGLE>.
Idea (one sentence): <...>
User framing (one candidate solution, not the frame): <...>
Fact sheet: <...>
Problem frame: <...>
Answer these questions for your angle: <questions from angles.md>
Rules: Do not design a full solution. Do not soften findings. Tag every claim as evidence (<file>), analogy, or intuition. If you find nothing substantive, say so and give the strongest candidate concern and why it fails.
Return exactly the "Angle / Concerns / Opportunity / Assumptions noticed" block.
```
