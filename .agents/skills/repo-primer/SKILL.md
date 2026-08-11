---
name: repo-primer
description: Build an actionable understanding of a repository before implementation. Use when the user asks to prime, onboard, audit structure, or summarize architecture, conventions, and current development state.
---

# Repo Primer

## Goal
Create a concise, implementation-ready repository briefing.

## Workflow
1. Map repository structure with fast file discovery. Preferred command: `rg --files --hidden -g '!.git' -g '!.agents/plans/archive/**'`. Fallback (if `rg` is unavailable): run an equivalent recursive file walk that excludes `.agents/plans/archive/`.
2. Use cocoindex semantic search when available for conceptual code discovery: feature areas, behavior, architecture, cross-file flows, or unknown implementation names. Use `rg` for exact strings, filenames, config keys, known symbols, and agent docs under `.agents/**`.
3. Read core context docs first: `AGENTS.md`, `.agents/templates/AGENTS-template.md`, root `README*`, `.agents/PRD.md`.
4. Inspect execution-critical config files for stack and tooling (`pyproject.toml`, `package.json`, lockfiles, framework/build/test/lint configs, `docker-compose.yml`, CI/deploy configs).
5. Identify entrypoints, key modules, and test layout.
6. If this is a git repo, capture branch, status, and recent commits. If not, report that explicitly.

## Output Format
Return sections in this order:
- Project Overview
- Architecture and Directory Map
- Toolchain and Commands
- Code Patterns and Conventions
- Current Working State
- Risks and Unknowns

`Toolchain and Commands` must be concise and fact-based. Include detected runtimes, package managers, lockfiles, build/test/lint tools, CI/deploy clues, source-of-truth config files, and stack unknowns that could affect later planning.

## Guardrails
- Prefer facts from files over assumptions.
- Report missing files or ambiguities explicitly.
- If cocoindex returns sparse or irrelevant results, report that as an index/config gap and fall back to `rg` plus targeted file reads.
- Keep summary scannable and implementation-focused.
- Do not do full-repo dependency rediscovery when docs and targeted config files answer the stack question.
- Do not treat `.agents/plans/archive/**` as active planning scope; include it only when the user explicitly asks for archived plans.
