---
name: repo-primer
description: Build an actionable understanding of a repository before implementation. Use when the user asks to prime, onboard, audit structure, or summarize architecture, conventions, and current development state.
---

# Repo Primer

## Goal
Create a concise, implementation-ready repository briefing.

## Workflow
1. Map repository structure with fast file discovery. Preferred command: `rg --files --hidden -g '!.git' -g '!.agents/plans/archive/**'`. Fallback (if `rg` is unavailable): run an equivalent recursive file walk that excludes `.agents/plans/archive/`.
2. Read core context docs first: `AGENTS.md`, `.agents/templates/AGENTS-template.md`, root `README*`, `.agents/PRD.md`.
3. Inspect execution-critical config files for stack and tooling (`pyproject.toml`, `package.json`, `docker-compose.yml`, CI configs).
4. Identify entrypoints, key modules, and test layout.
5. If this is a git repo, capture branch, status, and recent commits. If not, report that explicitly.

## Output Format
Return sections in this order:
- Project Overview
- Architecture and Directory Map
- Toolchain and Commands
- Code Patterns and Conventions
- Current Working State
- Risks and Unknowns

## Guardrails
- Prefer facts from files over assumptions.
- Report missing files or ambiguities explicitly.
- Keep summary scannable and implementation-focused.
- Do not treat `.agents/plans/archive/**` as active planning scope; include it only when the user explicitly asks for archived plans.
