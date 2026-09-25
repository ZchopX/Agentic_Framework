# UX Heuristics

## Contents
- Nielsen's 10 heuristics, applied to GUI, CLI, API, and agent surfaces
- Response-time limits
- States to check
- Accessibility basics (GUI)

## Nielsen's 10 heuristics by surface

Use the column that matches the surface being changed. A finding names the heuristic number and the concrete violation.

| # | Heuristic | GUI | CLI | API | Agent / AI workflow |
|---|---|---|---|---|---|
| 1 | Visibility of system status | Loading, progress, and saved indicators | Progress output for long work, meaningful exit codes | Correct status codes, a status endpoint for async jobs | Announces what it is doing and shows progress on long tasks |
| 2 | Match between system and the real world | User vocabulary, natural order | Flags and messages in domain terms | Resource names in domain terms | Uses the user's vocabulary, not internal jargon |
| 3 | User control and freedom | Undo, cancel, back | `--dry-run`, confirmation before destructive actions, safe Ctrl-C | Idempotent retries, cancellation | Approval gate before side effects; the user can stop or redirect |
| 4 | Consistency and standards | Platform conventions | `--help`, `--version`, conventional flag style, consistent with sibling commands | Consistent naming, pagination, error shape | Consistent output format across runs |
| 5 | Error prevention | Constraints, confirmations | Validate input before side effects | Schema validation, typed inputs | Confirms before irreversible actions; checks facts before claiming them |
| 6 | Recognition rather than recall | Visible options | Examples in `--help`, sensible defaults, completion | Self-describing responses, published schema | Offers a recommended answer instead of asking open questions |
| 7 | Flexibility and efficiency of use | Shortcuts | Non-interactive flags (`-y`), machine-readable output (`--json`) | Batch operations, filtering | Batches questions; "ok" accepts all recommendations |
| 8 | Aesthetic and minimalist design | No clutter | Quiet by default, signal over noise | Minimal payloads | Concise output; no filler |
| 9 | Help users recognize, diagnose, and recover from errors | Plain-language errors with a next step | Error says what happened and how to fix it; non-zero exit | Structured error body: code, message, remediation | On failure, says what failed and what to do next |
| 10 | Help and documentation | Contextual help | `--help`, examples | Reference docs with examples | Clear description of when to use it and what it produces |

## Response-time limits (NN/g)

| Delay | Perception | Required feedback |
|---|---|---|
| ≤ 0.1 s | Instantaneous | None |
| ≤ 1 s | Flow of thought uninterrupted; the delay is noticed | None beyond the result, but avoid anything slower in interactive paths |
| 1–10 s | Attention holds, but the flow breaks | A busy indicator |
| > 10 s | Attention lost | A percent-done indicator plus a way to cancel; let the user do something else meanwhile |

A change that moves an interactive action across a boundary (for example, from under 1 s to over 1 s) is a UX regression, even if it fixes a bug.

## States to check

For any changed flow, check: loading, empty, error, success, disabled, and partial data. Note which states the change creates, removes, or alters.

## Accessibility basics (GUI)

Keyboard operability, visible focus, text contrast, accessible names on controls, and no information carried by color alone.
