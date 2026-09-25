# Claude Skills: fix-validator & idea-critic

Two portable, tool-agnostic [Claude Code](https://claude.com/claude-code) skills that sit **before** implementation, not inside it. Neither writes code. Neither writes a spec. Each ends at a decision, backed by evidence, that you hand to whatever you use next — a coding agent, a spec tool, a ticket.

| Skill | Type | Ends at |
|---|---|---|
| [`fix-validator`](./fix-validator) | Reactive | A verdict on a bug and its proposed fix |
| [`idea-critic`](./idea-critic) | Proactive | An approved brief for a new idea |

Both work in any repository, in any language or stack, with no dependency on each other or on any particular planning/spec tool.

## Why these exist

Coding agents are agreeable by default. Told "here's the bug, here's my fix," most will confirm the fix, patch the symptom, and move on — because agreeing is cheaper than investigating, and the fix *sounds* plausible. Told "build this feature," most will start designing immediately, on the user's own framing, without asking whether the idea should exist at all.

These two skills exist to interrupt that pattern at the two moments it's cheapest to catch: before a fix is applied, and before a spec is written.

- **`fix-validator`** reproduces the bug and forms its own root-cause hypotheses *before* looking at any proposed fix, so the fix is judged as one hypothesis among several instead of anchoring the whole investigation.
- **`idea-critic`** frames the real problem from the product's own docs and stack *before* generating design options, and checks whether the idea should be built at all before asking how.

Both are built around an **iron law** — a small set of rules the skill will not rationalize its way around, no matter how the user phrases a follow-up ("ok", "just do it", "you're overthinking this"). See each skill's `SKILL.md` for the exact wording and its "Rationalizations" and "Red flags" tables, which exist specifically to name and block the excuses that erode discipline over a long conversation.

## Install

Both skills are self-contained folders — no external dependencies beyond what's already in the fixtures/evals (standard Python/JS, no packages to install).

**Claude Code:**

```bash
# From this repo, copy into your project
cp -r fix-validator idea-critic /path/to/your/project/.claude/skills/
```

Claude Code discovers skills automatically from `.claude/skills/<name>/SKILL.md`. No further registration needed.

**Codex / other agent runtimes:**

Each skill also ships `agents/openai.yaml` with equivalent metadata for Codex-style skill discovery. Copy the whole skill folder into your runtime's skills directory the same way.

**Any other agent:** the workflow in each `SKILL.md` is plain markdown — paste it into a system prompt or custom instructions if your tool doesn't support a skills folder natively.

## Usage

Invoke by describing the situation; the skill's `description` frontmatter is what your agent matches against, so explicit naming isn't required, but it always works:

```
Use fix-validator: search returns stale results after a filter change.
My fix idea is to clear the cache on every filter change. Is that right?
```

```
Use idea-critic on this idea: let users export their data as CSV.
Challenge it before we spec it.
```

Both skills ask clarifying questions only for facts they can't look up themselves (your intent, priorities, access to something they can't reach) — everything discoverable in the repo, they discover. Both accept a plain "ok" to move through a gate by accepting the stated recommendation, so you're never forced to answer questions you don't have a strong opinion on.

## What you get back

**`fix-validator`** returns a verdict — `APPROVE`, `APPROVE + FOLLOW-UP`, `MODIFY`, `REJECT`, `NOT A BUG`, `NEEDS EVIDENCE`, or `ESCALATE` — with:
- A reproduction (or the evidence collected and why one wasn't possible, with confidence capped accordingly)
- At least 3 independent root-cause hypotheses, tested and ranked
- The fix scored on two separate axes: technical (does it prevent or mitigate, is it at the right seam, what's the blast radius) and UX (does it change any user-visible behavior, and how badly)
- A handoff brief ready to implement directly or paste into a spec tool

**`idea-critic`** returns an idea verdict — `BUILD`, `NARROW`, `REFRAME`, `DEFER`, or `DON'T BUILD` — and, if it clears that gate:
- A problem frame (the story, the baseline, the job, the appetite) grounded in your repo's own docs and stack, not the user's pitch
- A critique from five independent angles (User, UX, Stack & Operator, Future Maintainer, Adversary)
- 2–3 structurally different design options (never "basic vs. full" of the same idea), each with a premortem
- An approved brief once you pick an option, in generic design-doc section names (Why, What Changes, Impact, Context, Goals/Non-Goals, Decisions, Risks/Trade-offs) that paste cleanly into most spec or planning tools

Neither skill implements anything, ever — even if you say "yes, go ahead" to the handoff offer. That refusal is enforced by the iron law and checked by the skill's own "Red flags" list, not left to interpretation.

## Structure

```
fix-validator/
├── SKILL.md                          # the workflow: phases, verdict rubric, rationalizations, red flags
├── agents/openai.yaml                # Codex-style skill metadata
├── references/                       # rubrics, evidence/confidence rules, report template, sources
└── evals/                            # 5 scripted pressure-test scenarios + fixtures, for regression-checking edits to SKILL.md

idea-critic/
├── SKILL.md
├── agents/openai.yaml
├── references/                       # five critique angles, decision frameworks, brief template, sources
└── evals/                            # 5 scripted pressure-test scenarios + fixtures
```

The `evals/` folders aren't required to use the skills — they're pressure tests (symptom-patch pressure, sunk-cost pressure, empty-repo false-blockers, etc.) used to verify the skill holds its line under a scripted adversarial conversation. Useful if you fork and modify either `SKILL.md` and want to check you haven't weakened it.

## Design notes

- **Two axes, never merged** (`fix-validator`): a fix can be technically correct and still a bad idea because of its UX cost, or vice versa. Blending them into one score hides that trade-off; the rubric keeps them separate through to the verdict.
- **Own hypothesis before the user's fix**: stating a position first measurably increases agreement bias in both directions. Both skills form an independent view before looking at what's being proposed.
- **A pre-build repo is not a blocker** (`idea-critic`): a repo with only docs and a manifest is a normal starting state, not evidence the feature can't be evaluated — the skill treats the described product behavior as ground truth and proceeds to options.
- **No named spec tool**: the brief and report formats use generic section names on purpose, so the output is equally useful whether it's pasted into an issue, a design doc, or any spec-generation tool you already use.

## License

Add a license file appropriate for your use before publishing this as a standalone repository — none is bundled here.
