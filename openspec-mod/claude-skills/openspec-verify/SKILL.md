---
name: openspec-verify
description: Independent review of an OpenSpec change's implemented tasks before archiving. Use as the `verification` artifact's delegate in the `spec-driven-verified` schema, or whenever the user asks to verify an OpenSpec change before archiving it.
allowed-tools: Bash(openspec:*)
---

# OpenSpec Verify

## Purpose

Run an independent verification pass over an OpenSpec change's implemented tasks, then use the findings to improve the work before the change is archived.

Use a sub-agent as a fresh reviewer. The main agent remains responsible for judging the findings, fixing valid issues, rerunning relevant checks, and writing the change's `verification.md`.

This is a standalone copy adapted for the OpenSpec filing system. It is not an edit of `subagent-verify`; `.agents/skills/subagent-verify/**` is never read or written by this skill.

## Workflow

1. Gather pointers, not full context:
   - Resolve the change name using the same selection convention as `openspec-apply-change`: explicit arg → conversation context → sole active change → run `openspec list --json` and ask the user to select one.
   - Announce: "Using change: <name>".
   - Run `openspec status --change "<name>" --json`. Record `planningHome`, `changeRoot`, and `artifactPaths` (each artifact's `resolvedOutputPath`/`existingOutputPaths` - this is the proposal/specs/design/tasks evidence index, the OpenSpec equivalent of an execution handoff).
   - Run `openspec instructions verification --change "<name>" --json`. Record its `resolvedOutputPath` - this is where the finished `verification.md` gets written.
   - Record changed files via `git status`/`git diff --name-only`, scoped to what changed since this change's tasks began.
   - Record validation commands already run and their pass/fail status, from the tasks.md checkbox trail or conversation context.
   - There is no execution-handoff file in this flow (OpenSpec has no equivalent artifact): the `artifactPaths` proposal/specs/design/tasks paths from `status --json` are the evidence index instead. Pass `Execution handoff: none` into the review template.
   - Avoid loading large diffs, plans, logs, or generated artifacts into the main context unless needed to fix a specific issue.

2. Select the verification mode:
   - Always read `references/plan-implementation-review.md` - the artifact preceding `verification` in this schema is always `tasks` (an implementation checklist), so the work being reviewed is always "implemented tasks against a plan."
   - If the change touched UI, CLI prompts, reports, generated docs, notifications, or user workflows, also read `references/user-facing-review.md` and include it as a focused review lens. Otherwise note `No user-facing surface found`.

3. Build and start the sub-agent review when sub-agent tools are available:
   - Read `references/plan-implementation-review.md` as the prompt template.
   - Fill it with: repository root, `changeRoot`, the change's `proposal.md`/`specs/`/`design.md`/`tasks.md` paths (from `artifactPaths`) in place of "Plan path", `Execution handoff: none`, changed file paths, validation commands already run with pass/fail status, artifact paths that need inspection, and the user's requested outcome.
   - Keep the filled prompt evidence-oriented: ask the sub-agent to inspect files, diffs, the proposal/specs/design/tasks, and artifacts directly.
   - Make the sub-agent role explicitly read-only. The sub-agent must not modify files, rewrite artifacts, run formatters that change files, or apply fixes. Only the main agent triages findings and applies valid corrections.
   - Do not include the main agent's intended fixes, suspected conclusions, or self-evaluation.

4. Triage the sub-agent output:
   - Classify each finding as `valid-fix-now`, `valid-but-out-of-scope`, `needs-source-check`, or `reject`.
   - Treat concrete, reproducible findings as actionable.
   - Inspect only the source evidence needed to judge `needs-source-check` findings.
   - Reject vague style preferences, unsupported speculation, duplicate findings, or requests outside the user's scope.
   - Keep a short private note of accepted and rejected findings so the final report can be precise without copying the whole review.

5. Apply valid corrections automatically:
   - Fix valid plan fidelity, code correctness, and validation gaps.
   - Avoid unrelated refactors and preserve user changes and dirty worktree contents.
   - If a valid finding requires a scope expansion, destructive action, external approval, or product decision, do not silently implement it; report it as blocked or out of scope instead.

6. Recheck the corrected work:
   - Rerun the narrowest relevant tests, linters, builds, or artifact checks when feasible.
   - Update changed-file and artifact pointers if the corrections changed them.
   - If the correction was substantial or high risk, run one targeted second sub-agent pass using the same review mode and the updated pointers.
   - If a check cannot be run, state why in the final report.

7. Write the verification report:
   - Use the template at the change's schema (`verification.md`'s template, i.e. `## Verification` / `**Result:**` / `Findings Fixed` / `Findings Rejected / Out of Scope` / `Checks Run` / `Residual Risk`).
   - Write the finished report to `resolvedOutputPath` from step 1's `openspec instructions verification --json` call - the change's `verification.md` inside `changeRoot`. Do not write it to `.agents/reports/`.
   - Set **Result** to `pass` (no findings, or only rejected/out-of-scope ones), `pass with notes` (fixed findings, no blockers left), or `blocked` (a valid finding needs a scope/approval/product decision the main agent cannot make).

8. Final response:
   - State the verification mode used and what evidence the sub-agent checked.
   - Summarize valid findings fixed.
   - Mention rejected or out-of-scope findings only when they affect user decisions or residual risk.
   - Report tests, commands, or artifact checks run after fixes.
   - State remaining risk or blockers, if any.
   - Confirm the path `verification.md` was written to.

## Fallback

If sub-agent tools are unavailable, perform the same review loop manually using `references/plan-implementation-review.md` (and `references/user-facing-review.md` when applicable). State in the final report that no sub-agent tool was available.

If this skill itself is not installed when the schema's `verification` artifact instruction is reached, state clearly that verification was skipped and why; do not fabricate a review or write a `verification.md` without actually reviewing the work.
