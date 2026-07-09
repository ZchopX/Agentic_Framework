---
name: repo-docs-bootstrap
description: Establish or refresh durable repository documentation after a PRD is created, when starting a new repo, or when an existing repo lacks reliable docs for humans and AI agents. Use to discover current docs, classify the repo, create the smallest useful README/docs/architecture/development/ADR/changelog/agent-guidance baseline, and preserve traceability from PRD to plans and implementation.
---

# Repo Docs Bootstrap

## Goal
Create a minimal, durable documentation system that future humans and AI agents can use without relying on chat history.

## Before Writing
1. Classify the repo type and maturity from files, config, entrypoints, tests, and recent commits.
2. Read the PRD when present or provided. If no PRD exists, infer only from repository facts and label assumptions.
3. Discover existing docs with `rg --files --hidden -g 'README*' -g 'AGENTS.md' -g 'CHANGELOG*' -g 'docs/**' -g '.agents/**' -g '!.git/**'`.
4. Read `.agents/skills/repo-docs-bootstrap/references/ai-maintained-docs.md` when choosing structure, traceability, ADR, changelog, or AI context rules.

## Workflow
1. Preserve existing docs. Update in place unless a missing document is clearly needed.
2. Choose the smallest useful baseline:
   - Tiny or early repo: root `README.md`, `.agents/skills/skills-usage-guide.md` update if agent workflows changed, and optional `docs/development.md`.
   - Application/library repo: `README.md`, `docs/architecture.md`, `docs/development.md`, optional `CHANGELOG.md`, and `docs/decisions/` when durable decisions exist.
   - Existing repo with partial docs: fill the highest-risk gaps first instead of creating a full template set.
3. Record PRD traceability when a PRD exists:
   - Link PRD to relevant plans.
   - Ensure new plans identify docs impact.
   - Add ADR links for decisions that future maintainers would otherwise rediscover.
4. Make docs fact-based:
   - Reference actual commands, config files, modules, tests, and entrypoints.
   - Mark unknowns as assumptions or open questions.
   - Prefer links and concise descriptions over duplicated implementation detail.
5. Maintain stack and tooling constraints in normal durable docs:
   - In `docs/development.md`, add or refresh a compact `Stack and Tooling Constraints` section when setup or planning would otherwise require rediscovery.
   - Cover supported runtimes, package manager, lockfiles, build/test/lint commands, dependency policy, forbidden substitutions, and source-of-truth files.
   - In `docs/architecture.md`, record architecture-level stack constraints such as frameworks, storage, messaging, deployment boundaries, and integration protocols.
   - Use ADRs for significant framework, runtime, database, package-manager, build-system, deployment, architecture, or major dependency-policy decisions.
   - Do not create `docs/stack.md` by default. Recommend it only for large or polyglot repos where stack constraints are too scattered for `docs/development.md` and `docs/architecture.md`.
6. Add AI-facing guidance only where useful:
   - Update `.agents/skills/skills-usage-guide.md` when skill workflows change.
   - Update `.agents/templates/AGENTS-template.md` or root `AGENTS.md` only when agent operating rules or read-first context changed.
7. Report created docs, updated docs, assumptions, unresolved gaps, and recommended follow-up validations.

## Baseline Documents
- `README.md`: purpose, quick start, core commands, repo map, links to durable docs.
- `docs/architecture.md`: system context, runtime flow, major boundaries, integrations, architecture-level stack constraints, risks/debt.
- `docs/development.md`: setup, local run, test/lint/build commands, stack and tooling constraints, common workflows, troubleshooting.
- `docs/decisions/NNNN-title.md`: ADRs for architecture, dependencies, public APIs, deployment, security, data models, and AI/tooling conventions.
- `CHANGELOG.md`: only when the repo has releases or user-visible changes worth tracking.
- `.agents/**`: agent workflow rules, skills, templates, and compact context pointers.

## Guardrails
- Do not create heavy documentation for a small repo. Prefer one clear doc over many empty templates.
- Do not create `docs/stack.md` by default; keep stack constraints in `docs/development.md`, `docs/architecture.md`, and ADRs unless repository scale justifies a separate reference.
- Do not overwrite user-written docs unless explicitly asked; merge and preserve useful content.
- Do not turn transient chat reasoning into durable truth unless it is backed by a PRD, plan, code, tests, or explicit user confirmation.
- Do not claim commands work unless they were run or clearly marked as discovered but unverified.
- Keep agentic files under `.agents` only.
