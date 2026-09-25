# Rubrics

## Contents
- Cause coverage (Google SRE action-item types)
- Technical debt quadrant (Martin Fowler)
- Seam
- Blast radius
- UX severity (NN/g, 0-4)
- Response-time limits

## Cause coverage (Google SRE action-item types)

`prevent` removes the source condition; `mitigate` reduces the impact while the source still occurs; `process` changes how people or tools work (monitoring, review, runbooks). Decision test: "After the fix, can the source condition still occur? If yes, and only its consequence is suppressed, it is mitigate."

## Technical debt quadrant (Martin Fowler)

| | Deliberate | Inadvertent |
|---|---|---|
| **Reckless** | "We don't have time for design." | "What's layering?" |
| **Prudent** | "We must ship now and deal with consequences." | "Now we know how we should have done it." |

Mapping:
- Both reckless cells: blocking rule 1.
- Prudent-deliberate: allowed as `APPROVE + FOLLOW-UP`. Name the "interest", meaning what becomes harder until it is repaid.
- Prudent-inadvertent: record the learning.

Low-interest debt may not be worth paying down.

## Seam

The seam is the component that owns the invariant the bug violates. Test question: "Which component is responsible for this data or state being correct?" Fix there. If no component owns it, that is the finding: `ESCALATE`.

## Blast radius

List the callers of every changed function or type (search, don't guess), and the config, schemas, and public interfaces touched. Rate it `contained` (one function), `module`, or `cross-cutting`.

## UX severity (NN/g, 0-4)

- 0 = not a usability problem at all.
- 1 = cosmetic only; fix if time allows.
- 2 = minor; low priority.
- 3 = major; important to fix, high priority.
- 4 = catastrophe; must fix before release.

Rate on frequency (how often users hit it), impact (how hard it is to overcome), and persistence (one-time or repeated annoyance), plus market impact. Every rating states one reason per factor.

## Response-time limits

See `ux-heuristics.md` for the full table. Crossing the 0.1 s, 1 s, or 10 s boundary in an interactive path is a UX regression.
