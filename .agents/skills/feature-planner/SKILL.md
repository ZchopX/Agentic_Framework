---
name: feature-planner
description: Research the existing repo, assess fit, and write a decision-complete implementation plan in `.agents/plans/{kebab-case-name}.md`. Use when the user asks to plan work before coding, especially for feature work, refactors, integrations, migrations, or changes that must fit existing architecture, docs, tests, and stack choices.
---

# Feature Planner

## Goal
Produce an evidence-backed plan another engineer or agent can execute without extra decisions.

## Workflow
1. Parse request into goal, scope, constraints, and acceptance criteria.
2. Run targeted discovery before planning:
   - Read durable context first when present: `AGENTS.md`, `README*`, `docs/**`, `.agents/PRD.md`, and active `.agents/plans/**`.
   - Inspect source-of-truth config needed for the change: manifests, lockfiles, framework/build/test/lint configs, CI/deploy configs, Docker files, schemas, migrations, and existing imports/usages in affected modules.
   - Search for existing features, similar flows, shared helpers, public commands, APIs/routes, UI patterns, tests, fixtures, docs, and generated artifacts that should be reused or extended.
   - Trace the affected path end to end: entrypoint, caller, core module/service, persistence or external integration, and tests.
3. Summarize discovery as evidence: files read, facts found, reusable pieces, current behavior, constraints, and unknowns.
4. Assess fit before choosing an approach:
   - State whether the user's initial approach fits repo reality, needs adjustment, or should be rejected.
   - Prefer existing runtimes, package managers, frameworks, databases, build systems, test tools, dependency patterns, and in-repo features.
   - When proposing a new technology, dependency category, runtime feature, package manager, database, build system, or framework, explain why the current stack is insufficient.
5. Resolve key decisions and tradeoffs. Ask the user only when the answer materially changes implementation; otherwise choose a default and record it as an assumption.
6. Write plan to `.agents/plans/<kebab-case-descriptive-name>.md`.

## Plan Requirements
- Feature description and user value
- In-scope and out-of-scope
- Discovery evidence: durable docs, configs, source files, tests, and searches used to ground the plan
- Existing system fit: how the change integrates with current architecture, commands, docs, and conventions
- Reuse opportunities: existing features, helpers, flows, tests, or docs to extend instead of replacing
- Decisions and tradeoffs: chosen approach, rejected alternatives, and why
- Open questions: only blocking questions whose answers materially change implementation
- Existing files to read or re-check during implementation with rationale
- New and updated files list
- Step-by-step ordered tasks (atomic)
- Test strategy (unit, integration, e2e as relevant)
- Validation commands
- Acceptance criteria checklist
- Risks, assumptions, and fallbacks
- Stack compatibility notes when the request proposes, changes, or depends on technology choices:
  - sources checked
  - compatibility with current stack
  - existing stack alternatives considered
  - `ADR required: yes/no` for new framework, runtime, database, package-manager, build-system, deployment, architecture, or major dependency-policy decisions
  - assumptions and verification steps when compatibility cannot be confirmed locally

For behavior-only plans with no stack or tooling impact, either omit the stack section or add one concise note: `No stack/tooling impact identified`.

## Guardrails
- Write planning artifacts under `.agents/...`; read repository docs and source-of-truth config as needed for compatibility checks.
- Reference existing project patterns instead of inventing new ones.
- Do not plan from the user's proposed implementation alone; verify it against repo reality first.
- Do not do full-repo reading by default. Use semantic search when available, `rg` for exact searches, and targeted file reads with evidence.
- Do not skip existing implementations. Search for sibling features, shared helpers, public commands, tests, and docs before proposing new code.
- If the user's proposed approach conflicts with architecture, docs, stack, or existing features, plan the better-fitting approach and explain the deviation.
- Include executable validation steps for each phase.
- Do not add token-heavy full-repo stack rediscovery when durable docs and targeted source-of-truth files are enough.
- Treat manifests, lockfiles, configs, and CI as authoritative when durable docs conflict with repository reality.
