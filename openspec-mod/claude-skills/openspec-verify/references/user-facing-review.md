# User-Facing Review Lens

Use this lens only when a plan or change affects UI, CLI prompts, reports, generated docs, notifications, or user workflows. If no user-facing surface is affected, report `No user-facing surface found` and skip this lens.

## Check

- Primary journey: the user can complete the requested task without unnecessary steps, dead ends, or hidden prerequisites.
- States: loading, empty, error, success, disabled, long content, and partial-data states are handled when reachable.
- Consistency: the change reuses existing UI, command, report, document, copy, spacing, navigation, and interaction patterns.
- Accessibility basics: keyboard path, visible focus, labels/name-role-value, contrast, touch/click target size, and no color-only meaning where relevant.
- Responsive and layout behavior: narrow and wide views avoid clipped text, overlap, broken scrolling, or hidden primary actions.
- Copy and recovery: user-facing text is plain, specific, and tells the user how to recover from errors.
- Evidence: screenshot, manual flow note, UI test, artifact inspection, or explicit not-run reason exists for user-facing changes.

## Finding Rules

Report only concrete issues that affect task completion, accessibility, recovery, readability, validation proof, or consistency with existing user-facing patterns.

Do not report subjective visual polish, alternate designs, preference-only wording, or missing exhaustive UX testing when the primary changed journey is already validated.

Severity:

- critical/high: primary journey fails, data can be lost, accessibility basics block use, errors hide recovery, or layout makes core content unusable.
- medium: reachable state, responsive case, copy, or validation gap could confuse users or hide a regression.
- low: narrow user-facing mismatch with limited impact.
