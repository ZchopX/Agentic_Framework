# Statquest Ultimate Improvement Report

This report is for the next ChatGPT iteration working on this skill.

## Current verdict

The current prototype is good at producing a friendly, intuition-first explainer.
It is not yet strong at producing a clearly recognizable StatQuest-like explanation style.

The main issue is not content structure. The main issue is weak voice anchoring.

## Keep

- Keep the core teaching flow in [SKILL.md](./SKILL.md): plain-English start, why it matters, tiny example, formal version, common confusion, recap.
- Keep the domain coverage checklist in [references/topic-coverage-map.md](./references/topic-coverage-map.md). This is the strongest support file.
- Keep the tiny-example discipline in [references/example-patterns.md](./references/example-patterns.md): small story, 3-5 numbers, one visible calculation, one interpretation.

## Improve

### 1. Strengthen the voice contract

Right now the skill mostly says "be clear, friendly, and example-first". That is too generic.

Add explicit instructions for:

- sentence rhythm
- transition style
- recap frequency
- how to introduce formulas
- how to translate jargon into plain speech
- how energetic the tone should be

The skill needs a repeatable explanation rhythm, not just a section order.

### 2. Add rhetorical moves

The skill should define recurring explanation moves such as:

- "Here's the big idea"
- "Let's make that concrete"
- "Ignore the notation for a second"
- "What is this really doing?"
- "The common trap is..."

Without these, the output stays generic.

### 3. Add style-calibrated exemplars

Add 3-5 short example responses that actually sound like the intended style.

Recommended set:

- one statistics concept
- one econometrics concept
- one Bayesian concept
- one machine-learning concept
- one coding or algorithm concept

This is the biggest missing piece if the goal is real style anchoring.

### 4. Add anti-patterns

Add a compact "this is not the style" section:

- do not sound like a textbook
- do not front-load notation
- do not write neutral encyclopedia prose
- do not jump from intuition straight to formalism
- do not use oversized fake datasets

## Add correctness guardrails

This was a valid concern in the earlier review and should stay.

Add explicit rules:

- do not oversimplify into false claims
- label toy examples as illustrative
- do not invent empirical facts or study results
- preserve the real statistical meaning when simplifying
- if the interpretation is subtle, say so

This matters for topics like p-values, credible vs confidence intervals, IRFs, Bayesian updating, and BVAR shrinkage.

## Simplify the file set

This was also a valid part of the earlier review.

The skill is more fragmented than it needs to be.

- [references/response-blueprints.md](./references/response-blueprints.md) and [references/example-patterns.md](./references/example-patterns.md) could be merged into [SKILL.md](./SKILL.md) unless you plan to expand this into a larger maintained style system.
- [agents/openai.yaml](./agents/openai.yaml) should stay only if something in the workflow actually uses it.

More files will not fix the current weakness. Sharper style instructions will.

## Tighten repo-level documentation

This was a valid part of the earlier review.

- [AGENTS.md](../../../../AGENTS.md) currently lists the skill too generically.
- [.agent/skills/skills-usage-guide.md](../skills-usage-guide.md) also describes it too generically.

If this skill is meant to be style-driven, those docs should say that it uses a specific high-energy, intuition-first, example-before-formula teaching rhythm.

## Bottom line

Do not expand the prototype sideways.

Make it:

- smaller
- sharper
- more explicit about voice mechanics
- safer on correctness

The current version already knows how to explain simply.
The next version needs to explain simply in a distinctive, repeatable style.
