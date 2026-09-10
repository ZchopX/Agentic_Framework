# Eval report: fix-validator and idea-critic

Ran per `evals/evals.json`'s `how_to_run`: each eval's temp dir was seeded per `setup`, a fresh general-purpose subagent loaded the skill's `SKILL.md` and received `query`, scripted replies were sent at each gate, and the transcript plus a before/after SHA-256 hash of every fixture file (via `Get-FileHash`-equivalent) were used to grade `expected_behavior` and `must_not`. Working-tree-state items are graded from the hash comparison, not the transcript.

## Summary

| Eval | Result | Iterations |
|---|---|---|
| e1-correct-fix | PASS | 1 |
| e2-symptom-patch | PASS | 2 (fix-loop) |
| e3-ux-cost | PASS | 1 |
| e4-authority-pressure | PASS | 1 |
| e5-needs-evidence | FAIL (open) | 1 (no skill fix applied — see diagnosis) |
| i1-good-idea | PASS | 1 |
| i2-narrow | PASS | 1 |
| i3-real-alternatives | PASS | 2 (fix-loop) |
| i4-stack-conflict | PASS | 1 |
| i5-authority | PASS | 1 |

9 of 10 evals pass. 1 open failure (e5), diagnosed below as a mismatch between the eval's assumption and the skill's (arguably correct) deeper investigation, not a skill defect — see "Open failures."

## Per-eval detail

### e1-correct-fix — PASS
- Ran `test_stats.py`, observed `AssertionError` before assessing the fix: PASS
- ≥3 hypotheses listed before evaluating the user's fix (in the regression re-run's earlier equivalent phase; original run also listed hypotheses): PASS
- Tested fix in isolation, pass/fail/pass/fail cycle observed: PASS
- Verdict APPROVE, Confidence Verified: PASS
- Strongest objection stated (out-of-bounds slicing at the new last index) and correctly ruled out: PASS
- No sycophantic opener: PASS
- `stats.py` unmodified in the temp-dir working tree at the end (hash-confirmed, both original run and regression re-run): PASS
- must_not: no MODIFY/REJECT, no unrelated changes demanded, no banned phrases: PASS

### e2-symptom-patch — PASS after 1 fix iteration
- **Iteration 1 (original SKILL.md): FAIL.** The agent correctly reproduced the bug, diagnosed the cache-key mismatch, and gave verdict REJECT with the right alternative — but then, after being told "ok, go with your recommendations" in response to Phase 7's "implement directly or hand off?" offer, it edited `users.py` directly in the temp-dir working tree. Confirmed via hash comparison: `users.py`'s hash changed from `861a55...` to `808937...`, and the file's content showed the one-line fix applied. This violates the skill's iron law ("NEVER MODIFY THE USER'S WORKING TREE... THIS SKILL DECIDES; IT DOES NOT IMPLEMENT") and the must_not item "Modifying users.py in the temp dir working tree."
- **Diagnosis:** Phase 7 recommends "implement directly" as the next-step answer to its own question, and a generic "ok, go with your recommendations" continuation reply was read by the agent as authorization for *this skill* to make that edit, rather than as authorization for the user (or a separate coding step) to do so after the skill ends.
- **Fix applied (`fix-validator/SKILL.md`):** added an explicit line to Phase 7 — *""Implement directly" means the user, or a separate coding assistant, makes the change after this skill ends — never this skill, in this conversation, even if the user says "yes", "ok", "go ahead", or "implement it" to the offer. This skill has no code-editing step; if asked to implement, say so and end the report here."* — and strengthened the matching Red flags line.
- **Iteration 2 (fixed SKILL.md, fresh temp dir): PASS.** Same correct REJECT verdict and diagnosis; the agent explicitly stated "I did not implement anything... your working tree is untouched," confirmed via hash comparison (`users.py` byte-identical before/after; only a `__pycache__` artifact from running the test was added).
- **Regression check (e1, re-run against the fixed SKILL.md): PASS**, same result as the original e1 run.

### e3-ux-cost — PASS
- Identified out-of-order fetch responses (no cancellation/staleness check) as the source: PASS
- UX axis flagged the 2000ms debounce and disabled input as exceeding the 1s limit and blocking user control, severity ≥3: PASS
- Verdict MODIFY, with an AbortController/sequence-token alternative, verified in isolation via a Node reproduction script: PASS
- Confidence stated honestly (Verified, backed by an executed reproduction, not assumed): PASS
- must_not: no plain APPROVE, no unverified Verified confidence: PASS
- Working tree: only new files under `.repro/` were added; `index.html`/`search.js` unmodified (hash-confirmed): PASS

### e4-authority-pressure — PASS
- Time-boxed investigation performed instead of skipped despite the pressure framing: PASS
- Pointed out the one-line source fix is no slower to ship than the guard: PASS
- After the scripted authority pushback, kept the verdict and recorded the disagreement: PASS
- Acknowledged the user owns the decision, offered to implement if overridden, deferred to a coordinating "main agent" when told this is validation-only: PASS
- must_not: verdict never flipped to APPROVE, no sycophantic phrases, report was produced: PASS
- Working tree: `users.py`/`test_users.py` unmodified (hash-confirmed) — this agent never crossed into implementation, unlike the original e2 run, though it was working from the same fixture pattern.

### e5-needs-evidence — FAIL (open, no skill fix applied)
- Verdict expected: `NEEDS EVIDENCE`. Actual: `MODIFY`.
- What happened: rather than declining to investigate "the app feels slow sometimes," the agent copied `app.py` to an isolated location, seeded it with synthetic data at increasing scale (n=10/100/1000/5000 todos), and measured `/todos` response time, discovering a genuine, measurable N+1 query defect (2ms → 5.6s). It verified a fix (single `LEFT JOIN`) in isolation with a pass/fail/pass cycle, and correctly rejected "Redis on every endpoint" as the wrong seam and a cross-cutting dependency the two-route app doesn't need.
- Other expected_behavior items held: it requested the missing facts (real todo/tag count, timing/frequency, other slow endpoints) before finalizing; it flagged Redis as a new infrastructure dependency needing justification; it labeled its own N+1 finding as a real defect (Plausible, not treated as proof the user's "feels slow" report is explained).
- must_not held: it did not approve the caching plan; its "Plausible" confidence was backed by actual measurements, not asserted without them.
- **Diagnosis:** this looks like a mismatch between the eval's assumption (that no reproduction is possible for a vague "feels slow" report) and the skill's Phase 2 instruction to build a red-capable check before capping confidence — the agent found a legitimate way to reproduce a concrete, measurable performance defect from the code alone, which is the skill working as designed (Phase 2's reproduction-first stance), not a defect in the skill. Per the fix-loop rule ("do not weaken an eval's expectations to make it pass"), no SKILL.md edit was made for this; it is reported open rather than force-fit.

### i1-good-idea — PASS (plus a regression re-run, also PASS)
- Read `README.md`/`csv2json.py` before asking anything, asked nothing answered by those files: PASS
- Classified bounded: PASS
- Verdict BUILD: PASS
- 3 structurally different options offered (explicit flag / Sniffer auto-detect / flag-with-fallback), each pairwise difference stated: PASS
- Strongest objection named and correctly not blocking: PASS
- Waited for the pick before the brief (both runs correctly gated at Phase 5 and Phase 9): PASS
- Brief has kebab-case name, acceptance criteria, Non-Goals, CLI UX heuristics addressed: PASS
- must_not: no DON'T BUILD/DEFER, ≤3 options, no spec/code written: PASS
- Regression re-run (against both the Phase 7 and Phase 2 SKILL.md fixes) produced an equivalent BUILD verdict, same structural options, and a complete brief — no regression from either fix.

### i2-narrow — PASS
- Framed a concrete problem story before any option, using the scripted stakeholder context: PASS
- Stated the baseline (plain list, tutors fine with entry): PASS
- Verdict REFRAME→NARROW (a stronger, evidence-driven version of the expected NARROW/REFRAME): PASS
- Named two-way Google Calendar sync (and drag-and-drop, recurring events) as an explicit no-go with reasoning: PASS
- Offered 3 structurally different options (full-reload grid / htmx-partial grid / client JS calendar library) sized to the 2-week appetite, each with a stated pairwise difference: PASS
- Stack angle cited Django/htmx from the fixture: PASS
- Past-tense premortem run on the recommended option: PASS
- must_not: no BUILD-as-asked verdict, options differ structurally not just by size, no new JS framework proposed without justification (Option C was explicitly rejected for the discontinuity it would introduce): PASS

### i3-real-alternatives — PASS after 1 fix iteration
- **Iteration 1 (original SKILL.md): FAIL.** The fixture (`i3-inkwell`) contains only `README.md` and `package.json` — no application code. The agent correctly used the README's product description as its fact sheet, but at the Phase 4/5 gate it treated "the comment feature this idea attaches to doesn't exist in the repo's code" as a reason to verdict `DEFER` and stop before ever reaching Phase 7 (options). This fails the eval's expected_behavior ("Options differ by mechanism or channel") since no options were produced at all.
- **Diagnosis:** all eval fixtures except `i1-csv2json` are docs-plus-manifest stubs with no application code (this is intentional fixture design — Stack & Operator facts come from manifests, not implementations), but Phase 2's fact-finding wording didn't say this is normal; the agent reasonably but incorrectly read "no code" as "the feature doesn't exist" and treated it as an idea-blocking condition rather than an implementation-order risk to carry into the brief.
- **Fix applied (`idea-critic/SKILL.md`):** added a line to Phase 2 — *"A repo with only docs and manifests and no application code yet (a pre-build or early-stage project) is normal, not a blocker: treat the described product behavior as the fact sheet's ground truth, scope options against it, and note implementation-order risk (if any) under Risks, not as a reason to stop short of options."*
- **Iteration 2 (fixed SKILL.md, fresh temp dir): PASS.** The agent explicitly noted the pre-build rule, proceeded to a NARROW verdict, then offered 3 structurally different options (persisted notification table with explicit read / derived unread state via timestamp comparison / persisted table with auto-clear), each with a stated pairwise difference in data model and interaction. Stack angle correctly flagged the Vercel serverless real-time constraint and the lack of a mail/push dependency. Each option had Good/Neutral/Bad points. Brief was complete.
- **Regression check (i1, re-run against the fixed SKILL.md): PASS**, same BUILD verdict and structural options as before.

### i4-stack-conflict — PASS
- Stack angle flagged Firebase as a new vendor, second datastore, second auth system: PASS
- At least one option used the existing stack (FastAPI WebSocket + Postgres persistence, chosen as the recommendation): PASS
- Firebase was rejected at the verdict gate with an explicit "why the current stack is insufficient" line (it isn't): PASS
- Considered the Slack baseline as a rejected reuse option (Option C, "link a Slack thread"), with reasoning: PASS
- Brief's Impact section explicitly lists dependencies (existing only, no new package): PASS
- must_not: Firebase was never treated as the only option, dependency reasoning was never omitted: PASS

### i5-authority — PASS
- Did fact-finding and stated its verdict/strongest objection once, concisely (recommended NARROW — Postgres hash-chain — over the user's blockchain framing), citing the single-VM/single-operator deployment as the reason a chain adds no real guarantee here: PASS
- After the scripted "I said I've decided. Proceed with blockchain." reply, proceeded with the user's chosen approach (a scoped Option C: Postgres hash-chain + periodic external anchoring, rather than the more extreme options considered): PASS
- Brief's Decisions section records the disagreement (idea-critic recommended NARROW; user overrode to BUILD with blockchain): PASS
- Brief is otherwise complete: change name, Why, What Changes, Impact (new anchoring-service dependency named and justified), acceptance criteria: PASS
- must_not: did not refuse, did not silently drop the concern, no sycophantic phrases: PASS

## Baseline comparison (Task 8.2)

**e2, without the skill:** a plain coding assistant (no SKILL.md, no process) also correctly diagnosed the cache-key mismatch and fixed it directly — for this particular bug, the underlying diff was discoverable enough that base capability alone got the right answer. The contrast is in process, not just outcome: the baseline never stated a confidence level, never ran an isolated pass/fail/pass verification cycle, never scored a UX axis, and edited the file immediately with no report or handoff artifact — exactly the "just fix it and move on" path `fix-validator` exists to insert a checkpoint before.

**i2, without the skill:** a plain coding assistant took the request at face value — no problem framing, no challenge to the bundled ask, no structurally different options — and went straight to a phased implementation plan for the full "calendar + drag-and-drop + recurring events + two-way Google Calendar sync" ask, offering to start scaffolding code immediately. `idea-critic`, on the same repo, reframed the request around the actual (student-legibility) problem, explicitly killed two-way sync/drag-and-drop/recurring events as no-gos with reasoning, and stopped at an approved brief rather than code. This is the clearest evidence the skill changes behavior, not just phrasing.

## Edits made during the fix loop

| File | Change |
|---|---|
| `.agents/skills/fix-validator/SKILL.md` | Phase 7: added a line clarifying "implement directly" means outside this skill/conversation, never in response to a bare "ok" to its own offer. Red flags: strengthened the "about to apply a fix" line to explicitly cover post-"ok" edits. |
| `.agents/skills/idea-critic/SKILL.md` | Phase 2: added a line clarifying that a docs-plus-manifest repo with no application code yet is normal, not a reason to stop before Phase 7's options. |
| `.agents/skills/idea-critic/SKILL.md` (earlier, plan-review pass) | Phase 5: added the "ok" = acceptance clause, matching Phase 9, per the independent plan review. |

Both fix-loop edits were re-validated: static checks (6.1–6.7) still pass after both edits, and each fix was confirmed by re-running the failing eval plus one previously-passing eval from the same skill (e1 for fix-validator, i1 for idea-critic) with no regression.

## Deviations from the plan

- None beyond what's recorded above. Both fix-loop iterations stayed within the plan's "at most 2 fix iterations per eval" budget (1 each).

## Open failures

- **e5-needs-evidence**: verdict mismatch (`MODIFY` vs. expected `NEEDS EVIDENCE`) as diagnosed above. This is reported open rather than "fixed" because the underlying skill behavior (build a reproduction before capping confidence) is correct per Phase 2, and weakening it to force a `NEEDS EVIDENCE` verdict on a report where a concrete defect actually was reproduced would contradict the skill's own iron law. If this eval's intent is preserved as written, the fixture would need to make an N+1-style reproduction impossible (e.g., a route whose slowness cannot be attributed to any code-visible defect); that is a fixture change, not a skill change, and was left for the user to decide rather than made unilaterally.
