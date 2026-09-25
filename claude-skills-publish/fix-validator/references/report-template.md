# Report Template

## Full report (bounded and systemic tiers)

```markdown
## Fix Validation: <short bug title>
**Verdict:** <VERDICT> · **Confidence:** Verified | Plausible | Speculative · **Tier:** trivial | bounded | systemic

### Bug
- Symptom: <user's words>
- Expected vs actual: <...>
- Reproduction: <command / test / steps> → before fix: FAIL (<observed failure>)
- Pre-existing or introduced: <which> (<evidence: commit hash + message, or blame line>)

### Diagnosis
| # | Hypothesis | Test | Result |
|---|---|---|---|
| 1 | <If X is the cause, then ...> | <what was run or checked> | confirmed / refuted |
- Mechanism: <symptom> ← <step> ← <source>
- Source: <file:line or component>

### Fix assessment: <user's fix | derived fix>
- Acts at: source (prevent) | symptom (mitigate) | process
- Seam: <owning component> — correct | wrong (<where it should be>)
- Blast radius: contained | module | cross-cutting (<callers checked>)
- Verification: fix applied → PASS; removed → FAIL; restored → PASS; related tests: <result> | not run (<reason>)

### Technical axis
- Debt quadrant: <cell> (<one-line reason>); interest: <what gets harder, or none>
- Regression test: <the reproduction becomes test X | none, why>

### UX axis
- Original bug severity: <0–4> (frequency: ..., impact: ..., persistence: ...)
- Fix-introduced UX change: none | <description>, severity <0–4>, latency <before → after vs 0.1/1/10 s>, states affected: <...>

### Verdict rationale
- Rules applied: <blocking rule numbers, or none>
- Strongest objection considered: <objection> — <why it holds / fails>
- Better alternative (MODIFY/REJECT): <exact change, at which seam>
- Follow-ups: <item, or none>
- Assumptions: <item, or none>
- Disagreement recorded: <user position vs verdict, or none>
- User decision: <only if the user overrode the verdict>

### Handoff brief
Change name: fix-<kebab-case>
Why: <mechanism and user impact, with severity>
What Changes: <the approved or modified fix, at which seam>
Capabilities: Modified: `<capability>` — <requirement change> | none (no requirement change)
Impact: <files, modules, callers, dependencies>
Acceptance criteria:
- [ ] <reproduction> fails before the change and passes after
- [ ] <named regression checks pass>
- [ ] <UX check, e.g. latency stays under 1 s>
Non-Goals: <follow-ups deliberately excluded>
Risks: <remaining risks, recorded disagreement>
Open questions: none | <deferred item — why safe to defer>
```

## Compressed report (trivial tier)

```markdown
## Fix Validation: <title>
**Verdict:** <VERDICT> · **Confidence:** <level> · **Tier:** trivial
- Reproduction: <check> → FAIL before; PASS with fix; FAIL without; PASS restored
- Source: <file:line> — <one-line mechanism>; <pre-existing | introduced in <commit>>
- Fix: <prevent | mitigate> at <seam>; UX: <none | change + severity>
- Strongest objection: <...> — <why it fails>
- Next: <implement directly | hand off>
```
