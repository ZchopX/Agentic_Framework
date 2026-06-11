# Validation Output Review Prompt

Review work where the main deliverable is tests, CI, generated artifacts, reports, logs, or validation outputs.

Focus on:

- Whether the produced validation actually proves the intended behavior.
- Whether generated artifacts are complete, readable, and consistent with the request.
- Whether test assertions are meaningful rather than only checking that code runs.
- Whether failures, skipped checks, flaky behavior, or suspicious warnings were ignored.
- Whether important edge cases or integration paths remain untested.
- Whether artifact paths, report contents, screenshots, or logs need direct inspection.

Do not require exhaustive testing for low-risk changes. Match validation depth to risk and blast radius.

Return findings first, ordered by severity. Each finding must include:

- The insufficient validation or artifact issue.
- Why it matters for this task.
- The command, artifact check, test, or file inspection that should be run or fixed.

If validation is adequate and no concrete gaps are found, say `No findings`.
