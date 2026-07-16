# AGENTS.md Template

This template defines project guidance for Codex agents working in this repository.

## Project Overview

<!-- One short paragraph on product purpose and current status. -->

{Project purpose and scope}

## Tech Stack

| Technology | Purpose |
|------------|---------|
| {tech} | {reason it is used} |

Before proposing new frameworks, runtimes, databases, package managers, build systems, or major dependency-policy changes, check compatibility with this stack and the repository source-of-truth files. Prefer existing stack choices unless the current stack is insufficient and the tradeoff is recorded in an ADR.

## Standard Commands

```bash
# Development
{dev-command}

# Build
{build-command}

# Test
{test-command}

# Lint/Format
{lint-command}
```

## Repository Structure

```text
{root}/
  {dir}/  # {description}
  {dir}/  # {description}
  {dir}/  # {description}
```

## AI Code Discovery

- Use cocoindex semantic search before broad file reads when looking for code by concept, behavior, or feature area.
- Use `rg` for exact strings, filenames, config keys, and known symbols.
- Do not commit `.cocoindex_code/` or `.serena/`.
- Keep durable discoveries in docs or `.agents/reports/repo-primer.md`, not in chat history.

## Local Skills

Skills are stored in `.agents/skills/<skill-name>/SKILL.md`. Apply a skill when user intent matches its description.

| Skill | Use When | Path |
|------|---------|------|
| `atomic-commit` | User asks to create a commit from current changes | `.agents/skills/atomic-commit/SKILL.md` |
| `feature-planner` | User asks to plan a feature before coding | `.agents/skills/feature-planner/SKILL.md` |
| `model-test-pipeline` | User asks to research a repo/model first and then run universal econometric testing with generic checks plus auto profile checks | `.agents/skills/model-test-pipeline/SKILL.md` |
| `plan-closeout` | User asks to archive a completed plan, record completion metadata, and update affected docs | `.agents/skills/plan-closeout/SKILL.md` |
| `plan-executor` | User asks to implement from an existing plan | `.agents/skills/plan-executor/SKILL.md` |
| `prd-writer` | User asks for a PRD or requirements document | `.agents/skills/prd-writer/SKILL.md` |
| `project-bootstrap` | User asks to initialize local dev environment | `.agents/skills/project-bootstrap/SKILL.md` |
| `repo-docs-bootstrap` | User asks to establish durable docs after a PRD or in an under-documented repo | `.agents/skills/repo-docs-bootstrap/SKILL.md` |
| `repo-primer` | User asks for repo priming/onboarding/architecture summary | `.agents/skills/repo-primer/SKILL.md` |
| `rules-template-author` | User asks to create/refine `.agents/templates/AGENTS-template.md` | `.agents/skills/rules-template-author/SKILL.md` |

## Architecture Notes

<!-- Describe major runtime boundaries and data flow. -->

{Architecture summary}

## Coding Conventions

### Naming
- {naming convention}

### File Organization
- {organization rule}
- Do not split a small one-path change across extra files or modules unless a real reuse or boundary need exists.

### Error Handling
- {error handling pattern}
- Do not add indirection layers, wrapper exceptions, or helper functions solely to make error handling look more structured in otherwise small tasks.

### Python Simplicity
- Small Python tasks must default to the smallest coherent shape: one public function or one direct edit to the existing function with inline local logic.
- Treat a task as small when the change is confined to one file, has one primary execution path, or introduces logic with only one call site in the module.
- For a small task, edit the existing function directly instead of extracting helpers unless at least one allowed exception below clearly applies.
- Private helper functions must not be introduced for logic used once in one module when extraction is driven only by readability, symmetry, aesthetics, "clean code" preference, or keeping functions artificially short.
- Dataclasses, wrapper classes, and extra modules must not be introduced for small single-path workflows unless they represent a real cross-function contract, reuse point, or other concrete boundary.
- A helper function is allowed only when at least one of these is true:
  - the logic is reused in two or more places;
  - the helper isolates non-trivial validation or parsing at a risky contract boundary;
  - the helper isolates a materially complex algorithmic block that is harder to reason about inline;
  - the helper is required for a real public API boundary or test seam.
- If none of those conditions apply, the logic must stay inline.
- Agents must not introduce speculative abstraction, speculative reuse hooks, single-call wrappers around obvious built-ins, or one-line pass-through helpers.
- Larger refactors may use decomposition, but only after the code path no longer qualifies as small under the rules above.

### Python Type Hints
- All functions and methods in `.py` files must include type hints for parameters and return values.

### Notebook Readability
- (IF notebook format is used) Keep notebooks human-readable with clear section headers, markdown context, and logically grouped code cells.

## Testing Policy

- Run tests: `{test-command}`
- Test locations: `{test-directory}`
- Minimum requirement before merge: {policy}

## Validation Checklist

Run before merge:

```bash
{validation-commands}
```

## Key Files

| File | Purpose |
|------|---------|
| `{path}` | {why it matters} |

## Optional Context References

| Topic | File |
|-------|------|
| {topic} | `{path}` |

## Agent Output Conventions

- Every reference to a local repository file in user-facing output must use a workspace-relative Markdown link (example: `[.agents/AGENTS.md](.agents/AGENTS.md)`).
- This rule applies to plans, summaries, reviews, implementation notes, and any other response that references a repo file.
- Do not use plain text paths, absolute filesystem links, or `file://` links for local repository file references.
- When line precision is useful, add it after the path text in the sentence (example: `see [.agents/AGENTS.md](.agents/AGENTS.md):42`).

## Repository Notes

- {project-specific constraints}
- All agentic files belong under `.agents`; completed plans belong under `.agents/plans/archive`.
- All `.agents` Markdown files should be UTF-8 without BOM.
