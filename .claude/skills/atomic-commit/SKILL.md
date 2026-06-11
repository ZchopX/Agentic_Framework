---
name: atomic-commit
description: Create one atomic commit for current uncommitted changes with a typed commit message (`feat`, `fix`, `docs`, `chore`, `refactor`, `test`). Use when the user asks to commit work.
---

# Atomic Commit

## Goal
Produce a clean, typed commit that matches the change set.

## Workflow
1. Confirm repository state:
   - `git status`
   - `git diff HEAD`
   - `git status --porcelain`
2. Review changed and untracked files and ensure they belong to one coherent commit.
3. Stage files required by the task.
4. Create one atomic commit with prefix tag such as:
   - `feat: ...`
   - `fix: ...`
   - `docs: ...`
   - `refactor: ...`
   - `test: ...`
   - `chore: ...`

## Guardrails
- If repository is not initialized, report that commit cannot be created.
- If changes are mixed and non-atomic, split by intent before committing.
- Do not use interactive git modes.

