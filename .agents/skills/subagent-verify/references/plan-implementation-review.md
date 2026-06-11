# Plan Implementation Review Prompt

Review work that implemented a written plan.

Use the plan, changed files, tests, and artifacts directly. Do not rely only on the main agent's summary.

Check in this order:

1. Plan fidelity:
   - Plan steps that were skipped, partially implemented, or implemented differently without justification.
   - Acceptance criteria that are not satisfied or cannot be verified.
   - Required docs, migrations, artifacts, or configuration updates that are missing.

2. Implementation correctness:
   - Bugs, regressions, broken edge cases, integration issues, or incorrect assumptions.
   - API, CLI, schema, persistence, error-handling, or user-visible behavior mismatches.
   - Security, privacy, data loss, or reliability risks when relevant.

3. Validation quality:
   - Whether the right tests, linters, builds, migrations, or artifact checks were run.
   - Whether changed behavior has meaningful coverage.
   - Missing checks that could hide likely regressions.

Return findings first, ordered by severity. Each finding must include:

- Category: `plan`, `bug`, `validation`, or `scope`.
- File and line reference when possible, or the relevant plan item.
- Why it matters.
- Suggested fix or verification.

After findings, include a short list of checks you recommend running.

If there are no concrete findings, say `No findings`.
