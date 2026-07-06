---
name: plan-closeout
description: Close a completed implementation plan after plan-executor work by archiving it under `.agents/plans/archive`, recording completion date, commit hash or pending-commit state, validation results, docs updated, deviations, and updating directly affected repository docs from Git and filesystem evidence. Use when a plan has been implemented, when the user asks to close out/archive a plan, or when docs must be refreshed after implementation.
---

# Plan Closeout

## Goal
Turn completed implementation work into durable repo history: archived plan metadata plus documentation updates based on actual changes.

## Workflow
1. Read the completed plan in full from the user-provided path or the active plan under `.agents/plans/`.
2. Verify the plan is complete enough to archive by checking the plan acceptance criteria, `git status --short`, recent commits, changed files, and validation evidence from the current work.
3. Determine completion metadata:
   - `status`: `completed` or `completed-pending-commit`.
   - `completed_date`: current local date in `YYYY-MM-DD`.
   - `completion_commit`: explicit user-provided hash, current `HEAD`, or `pending` when no completion commit exists yet.
   - `validation_results`: commands run and outcomes.
   - `docs_updated`: docs changed by closeout.
   - `deviations`: plan deviations or `none`.
4. Insert a concise `## Completion Metadata` section near the top of the plan, preserving existing plan content.
5. Create `.agents/plans/archive/` if needed and move the completed plan there. Do not archive to any other path.
6. Discover documentation before editing:
   - List docs with `rg --files --hidden -g 'README*' -g 'AGENTS.md' -g 'CHANGELOG*' -g 'docs/**' -g '.agents/**' -g '!.git/**'`.
   - Read docs that match changed components, commands, setup, architecture, public behavior, skill usage, PRDs, plans, decisions, or changelog entries.
   - Inspect `git diff --stat`, `git diff --name-only`, and recent commits to understand what actually changed.
7. Update only docs directly affected by the completed work. Prefer small factual edits, links to source files, and explicit "no docs impact" reporting over broad rewrites.
8. Report archived path, completion metadata, docs changed, validations, unresolved gaps, and whether another commit is needed.

## Documentation Impact Rules
- Update root `README*` when setup, usage, project purpose, public commands, or user-facing behavior changed.
- Update `docs/**` when architecture, development workflow, operations, decisions, APIs, data contracts, or release process changed.
- Update `.agents/**` when agent workflows, skills, templates, repo conventions, PRD/plan lifecycle, or context handoff rules changed.
- Update `CHANGELOG*` when the repo maintains one and the change is user-visible, operationally meaningful, breaking, security-related, or release-relevant.
- Update PRDs or architecture notes when implementation changed requirements, accepted constraints, or durable design decisions.

## Commit Handling
- If the user supplies a completion commit, validate it exists with `git rev-parse --verify <hash>`.
- If no commit is supplied and `HEAD` appears to contain the completed work, record `HEAD`.
- If work is uncommitted, record `completion_commit: pending` and `status: completed-pending-commit`; tell the user to commit and rerun closeout or update the archived plan metadata afterward.

## Guardrails
- Do not rely on conversation memory as the only source of truth; reconstruct from the plan, Git, filesystem, tests, and docs.
- Do not archive active, incomplete, blocked, or ambiguous plans. Ask for clarification only when repository evidence cannot establish completion.
- Do not move plans outside `.agents/plans/archive`.
- Do not overwrite existing docs wholesale when targeted updates are enough.
- Do not invent validation results, commit hashes, or completion dates.
