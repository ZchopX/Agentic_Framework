---
name: subagent-verify
description: Use after completing an implementation plan, feature-planner plan, or plan-executor task when Codex should ask an independent sub-agent to review the work, validate plan compliance, inspect tests, and drive a fix-and-recheck loop. Use when the user asks for sub-agent verification, independent review after implementation, plan compliance checking, test validation review, or automatic fixing of valid review findings.
---

# Subagent Verify

## Purpose

Run an independent verification pass after implementation work, then use the findings to improve the work before giving the final answer.

Use a sub-agent as a fresh reviewer. The main agent remains responsible for judging the findings, fixing valid issues, rerunning relevant checks, and reporting the final state.

## Workflow

1. Gather pointers, not full context:
   - Record the plan path if one was used.
   - Record changed file paths from `git status`, `git diff --name-only`, PR metadata, or the active task context.
   - Record validation commands already run and their pass/fail status.
   - Record artifact paths that need review, such as generated documents, reports, screenshots, logs, or build outputs.
   - Avoid loading large diffs, plans, logs, or generated artifacts into the main context unless needed to fix a specific issue.

2. Select the verification mode by the job just completed:
   - If the main agent just created a feature plan or implementation plan, read `references/plan-created-review.md`.
   - If the main agent just implemented a written plan, read `references/plan-implementation-review.md`.
   - If the main agent made code changes without a written plan, read `references/code-change-review.md`.
   - If the main agent only produced or updated tests, CI, generated artifacts, reports, or validation outputs, read `references/validation-output-review.md`.
   - If the task does not fit one mode cleanly, choose the mode that matches the user's requested deliverable, then add only the extra pointers needed for the second concern.

3. Build and start the sub-agent review when sub-agent tools are available:
   - Read the selected reference file as a prompt template.
   - Fill the template with task-local pointers before sending it: repository root, plan path if any, changed file paths or PR/diff source, validation commands already run with pass/fail status, artifact paths that need inspection, and the user's requested outcome.
   - Keep the filled prompt evidence-oriented: ask the sub-agent to inspect files, diffs, plans, tests, and artifacts directly.
   - Do not include the main agent's intended fixes, suspected conclusions, or self-evaluation.

4. Triage the sub-agent output:
   - Classify each finding as `valid-fix-now`, `valid-but-out-of-scope`, `needs-source-check`, or `reject`.
   - Treat concrete, reproducible findings as actionable.
   - Inspect only the source evidence needed to judge `needs-source-check` findings.
   - Reject vague style preferences, unsupported speculation, duplicate findings, or requests outside the user's scope.
   - Keep a short private note of accepted and rejected findings so the final answer can be precise without copying the whole review.

5. Apply valid corrections automatically:
   - For plan-created review, revise the plan so it is clearer, more complete, and ready to implement.
   - For plan-implementation review, fix valid plan fidelity, code correctness, and validation gaps.
   - For code-change review, fix valid bugs, regressions, integration issues, and missing focused tests.
   - For validation-output review, fix invalid tests, rerun relevant checks, regenerate broken artifacts, or inspect outputs directly.
   - Avoid unrelated refactors and preserve user changes and dirty worktree contents.
   - If a valid finding requires a scope expansion, destructive action, external approval, or product decision, do not silently implement it; report it as blocked or out of scope.

6. Recheck the corrected work:
   - Rerun the narrowest relevant tests, linters, builds, migrations, or artifact checks when feasible.
   - Update changed-file, command, and artifact pointers if the corrections changed them.
   - If the correction was substantial or high risk, run one targeted second sub-agent pass using the same job mode and the updated pointers.
   - If a check cannot be run, state why in the final answer.

7. Final response:
   - State the verification mode used and what evidence the sub-agent checked.
   - Summarize valid findings fixed.
   - Mention rejected or out-of-scope findings only when they affect user decisions or residual risk.
   - Report tests, commands, or artifact checks run after fixes.
   - State remaining risk or blockers, if any.

## Sub-Agent Prompt Rules

Prefer one job-based template per sub-agent pass. The template may include several review lenses when that job naturally requires them. For example, `plan-implementation-review.md` checks plan fidelity, code correctness, and validation quality together because those are inseparable after implementing a plan.

## Filled Prompt Shape

The filled sub-agent prompt should contain:

- Review mode: the selected template name.
- Task outcome: what the main agent just completed.
- Evidence pointers: paths, commands, and artifact names instead of copied large content.
- Review instructions: the selected template content.
- Output contract: findings first, severity order, file references when possible, suggested checks, or `No findings`.

When building the sub-agent prompt, include:

- Repository root.
- Plan path, if any.
- Changed file paths or PR/diff source.
- Commands already run and their result, if known.
- Artifact paths that need inspection, if any.
- The selected job template.

Require the sub-agent to return:

- Findings ordered by severity.
- File and line references when possible.
- A short explanation of why each finding matters.
- Suggested validation or test commands.
- "No findings" if nothing concrete is found.

## Fallback

If sub-agent tools are unavailable, perform the same review loop manually using the selected reference file. State in the final response that no sub-agent tool was available.
