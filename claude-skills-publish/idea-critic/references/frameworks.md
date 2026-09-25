# Frameworks

## Contents
- Framing (Shape Up, JTBD)
- Assumption audit
- Idea verdicts
- Options (MADR, Google design docs, Pocock diversity rule)
- Premortem (Klein)

## §Framing (Shape Up, JTBD)

- **Problem story:** "a single specific story that shows why the status quo doesn't work". Example: "A tutor updates their availability on Monday morning, but a student booked Sunday night against the stale list and shows up to an empty slot."
- **Baseline:** "what customers are doing without the thing".
- **Job:** the progress users try to make (functional, social, emotional).
- **Appetite:** a budget chosen up front, not an estimate. Ask "is this possible in <appetite>?" rather than "is this possible?".
- **Success signal:** an observable signal.
- Default answer to weak ideas: "Interesting. Maybe some day."

## §Assumption audit

| Assumption | Impact (load-bearing / material / decorative) | Source (evidence / analogy / intuition / unexamined) | Cheapest test |
|---|---|---|---|

Rule: every load-bearing assumption tagged `intuition` or `unexamined` appears in the brief's Risks with its cheapest test.

## §Idea verdicts

- `BUILD`: the story is concrete, the baseline cost is real, it fits the appetite, and there are no blocker concerns.
- `NARROW`: a smaller slice solves the story; the rest becomes no-gos.
- `REFRAME`: the real problem differs from the stated solution. Restate the problem.
- `DEFER`: real, but not now (appetite, timing, dependencies). Record the trigger to revisit.
- `DON'T BUILD`: the baseline is acceptable, the cost exceeds the value, or it conflicts with the product's purpose. Run a reverse premortem before recommending it.

## §Options (MADR, Google design docs, Pocock diversity rule)

- Structural-difference dimensions: mechanism, data model or state location, primary interaction, build vs reuse vs integrate, where in the stack.
- Pairwise difference statement: "Options <A> and <B> differ in: <dimension>".
- Regenerate-with-exclusion rule: if two options differ only in size, polish, or naming, regenerate one with an explicit exclusion of the shared mechanism.
- Reuse-existing rule: if the fact sheet found a partial existing solution, one option must reuse or extend it.
- Every option is sized to the appetite.

MADR block:
```
### Option <letter>: <name>
<2–4 sentence summary>
How it works:
- <3–6 bullets>
Stack fit: <evidence-based>
UX notes: <heuristics / states / response times>
- Good, because <...>
- Neutral, because <...>
- Bad, because <...>
Appetite fit: <fits | tight | exceeds — why>
Key assumption: <...>
```

Recommendation line format: `Recommended: Option <X> — <why, tied to the problem story and the angle findings>`.

## §Premortem (Klein)

- Script: "It is <appetite + 3 months> from now. We built Option <X>, and it failed. Write why it failed." Past tense. Klein reports that prospective hindsight improves identification of reasons for outcomes by about 30%. Caveat: a 1989 lab finding.
- Each reason → a mitigation or "accepted risk".
- Reverse premortem (for `DON'T BUILD` / `DEFER`): "It is a year from now. Not building this was a mistake. Why?"
- Rabbit holes: "walk through a use case in slow motion", and ask "are we assuming a design solution exists that we couldn't come up with ourselves?"
- No-gos: the explicit exclusions.
