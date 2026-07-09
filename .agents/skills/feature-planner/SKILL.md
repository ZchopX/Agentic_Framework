---
name: feature-planner
description: Turn a feature request into a decision-complete implementation plan in `.agents/plans/{kebab-case-name}.md`. Use when the user asks to plan work before coding.
---

# Feature Planner

## Goal
Produce a plan another engineer or agent can execute without extra decisions.

## Workflow
1. Parse request into goal, scope, constraints, and acceptance criteria.
2. Analyze existing code paths, related modules, and testing patterns.
3. Collect exact integration points and affected files.
4. Check stack and tooling compatibility before resolving tradeoffs:
   - Read durable stack context first when present: `docs/development.md`, `docs/architecture.md`, `docs/decisions/**`, `README*`, `AGENTS.md`, and `.agents/templates/AGENTS-template.md`.
   - If durable docs are missing, stale, or insufficient for the proposed change, inspect the minimum relevant source-of-truth files: manifests, lockfiles, framework/build/test/lint configs, CI/deploy configs, and existing imports/usages in affected modules.
   - Prefer existing runtimes, package managers, frameworks, databases, build systems, test tools, and dependency patterns.
   - When proposing a new technology, dependency category, runtime feature, package manager, database, build system, or framework, explain why the current stack is insufficient.
5. Resolve key tradeoffs before writing the plan.
6. Write plan to `.agents/plans/<kebab-case-descriptive-name>.md`.

## Plan Requirements
- Feature description and user value
- In-scope and out-of-scope
- Existing files to read with rationale
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
- Include executable validation steps for each phase.
- Do not add token-heavy full-repo stack rediscovery when durable docs and targeted source-of-truth files are enough.
- Treat manifests, lockfiles, configs, and CI as authoritative when durable docs conflict with repository reality.
