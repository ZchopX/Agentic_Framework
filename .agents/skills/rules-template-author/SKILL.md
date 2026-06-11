---
name: rules-template-author
description: Generate or refine the Codex rules template at `.agent/templates/AGENTS-template.md` from repository analysis. Use when creating project-wide agent conventions.
---

# Rules Template Author

## Goal
Maintain a reusable AGENTS template tailored to this repository.

## Workflow
1. Analyze project type, stack, and repository layout.
2. Extract coding conventions, testing conventions, and validation commands.
3. Write or update `.agent/templates/AGENTS-template.md`.
4. Keep content concise and operational.

## Template Must Cover
- Project overview and architecture summary
- Standard commands (dev, test, lint, build)
- File and module organization rules
- Error handling and testing expectations
- Pre-merge validation checklist
- Key files and optional context links

## Guardrails
- Target Codex agents; avoid vendor-specific legacy behavior.
- Keep this as a template-first artifact (not mandatory generation of root `AGENTS.md`).
