# Codex Skills Usage Guide (for former Claude command workflow)

This guide explains how to work with the new Codex-native skill system in this repository.

It is written for your migration case: you previously used command-style prompts (like `/prime`, `/plan-feature`, `/execute`) and now use skills.

## 1. Mental Model Shift: Claude Commands -> Codex Skills

## What changed
- Before: You invoked behavior through command docs.
- Now: You ask in plain language and Codex selects the right skill by matching intent to skill `description`.

## What stayed the same
- You still have the same core workflows:
  - understand repo
  - plan
  - implement
  - close out completed plans
  - maintain docs
  - write PRD
  - generate rules
  - bootstrap
  - commit

## Practical difference
- Old style: `/plan-feature add X`
- New style: `Plan feature X and save the plan in .agents/plans.`

You do not need slash commands anymore.

## 2. How Skills Work Overall

## Skill anatomy
Each skill is a folder under `.agents/skills/<skill-name>/` with a required `SKILL.md`.

Each `SKILL.md` has:
1. YAML frontmatter:
   - `name`
   - `description`
2. Body:
   - workflow
   - guardrails
   - output expectations

## Triggering behavior
Codex uses skill descriptions to decide when to apply a skill.

You can trigger skills in two ways:
1. Explicit:
   - `Use feature-planner to plan ...`
2. Intent-based:
   - `Create a detailed implementation plan for ...`

## Usage pattern
1. State your goal clearly.
2. Include output location if you care about path/file name.
3. Include constraints (deadline, testing depth, no schema changes, etc.).
4. Ask for artifacts directly (`write the plan`, `update template`, `run validation`).

## File conventions in this repo
- Active skill workflows: `.agents/skills/`
- Planning outputs: `.agents/plans/`
- Guidance templates: `.agents/templates/`
- Supporting docs: `.agents/reference/`
- Legacy archived command docs: `.agents/legacy/claude-commands/`

## Encoding convention
Active `.agents` Markdown files should be UTF-8 without BOM.

## 3. Recommended End-to-End Flow

For most feature work, use this sequence:

1. `repo-primer`
2. `prd-writer` when requirements are not already settled
3. `repo-docs-bootstrap` after a new PRD or when durable docs are missing
4. `feature-planner`
5. `plan-executor`
6. `atomic-commit`
7. `plan-closeout`

Optional before/after:
- `rules-template-author` (if project conventions changed)
- `project-bootstrap` (for local setup)

## 4. Skill-by-Skill Guide

## A) `repo-primer`
Path: `.agents/skills/repo-primer/SKILL.md`

Use when:
- You want a fast architecture/context briefing before changes.

What it does:
- Scans structure, configs, key files, and current repo state.
- Surfaces stack/tooling facts, source-of-truth configs, and unknowns for later planning.
- Produces a concise implementation-oriented summary.

Typical prompt:
- `Prime this repository and summarize architecture, conventions, and current state.`

Expected output:
- Briefing with sections:
  - Project Overview
  - Architecture and Directory Map
  - Toolchain and Commands
  - Code Patterns
  - Current State
  - Risks

Claude-era equivalent:
- roughly `/prime`

## B) `feature-planner`
Path: `.agents/skills/feature-planner/SKILL.md`

Use when:
- You want a decision-complete implementation plan before coding.

What it does:
- Analyzes current code patterns and integration points.
- Checks stack and tooling compatibility before proposing new technology.
- Reads durable docs first, then inspects only targeted source-of-truth config when needed.
- Writes plan file under `.agents/plans/`.

Typical prompt:
- `Create a decision-complete plan for adding X. Save it as .agents/plans/add-x.md.`

Expected output:
- Plan with scope, tasks, tests, validations, risks, acceptance criteria, and stack compatibility notes when technology choices are involved.

Claude-era equivalent:
- roughly `/plan-feature`

## C) `plan-executor`
Path: `.agents/skills/plan-executor/SKILL.md`

Use when:
- You already have a plan file and want implementation.

What it does:
- Executes ordered tasks from the plan.
- Reports completed work, validations, and deviations.

Typical prompt:
- `Execute .agents/plans/add-x.md end-to-end, including tests and validations.`

Expected output:
- Implemented code changes + execution report.
- Note on documentation impact and whether `plan-closeout` should run.

Claude-era equivalent:
- roughly `/execute`

## D) `plan-closeout`
Path: `.agents/skills/plan-closeout/SKILL.md`

Use when:
- A plan has been implemented and should be archived.
- You need completion metadata and affected docs updated from actual Git/filesystem changes.

What it does:
- Reads the completed plan and repo state.
- Records status, completion date, commit hash or pending-commit state, validation results, docs updated, and deviations.
- Moves the plan to `.agents/plans/archive/`.
- Updates docs directly affected by the completed work.

Typical prompt:
- `Use plan-closeout on .agents/plans/add-x.md after the implementation commit.`

Expected output:
- Archived plan path, metadata, docs changed, validation summary, and unresolved gaps.

## E) `prd-writer`
Path: `.agents/skills/prd-writer/SKILL.md`

Use when:
- You need a structured PRD before planning or implementation.

What it does:
- Produces/updates PRD sections: goals, scope, users, architecture, risks, phases, criteria.

Typical prompt:
- `Write a PRD for feature X to .agents/PRD.md based on this discussion.`

Expected output:
- Decision-oriented PRD in markdown.
- Handoff recommendation to `repo-docs-bootstrap` when durable docs should be established before planning.

Claude-era equivalent:
- roughly `/create-prd`

## F) `repo-docs-bootstrap`
Path: `.agents/skills/repo-docs-bootstrap/SKILL.md`

Use when:
- A PRD has just been created and the repo needs durable docs before feature planning.
- An existing repo lacks reliable README, architecture, development, decision, changelog, or AI-facing docs.

What it does:
- Classifies the repo and discovers existing docs.
- Creates or updates the smallest useful documentation baseline.
- Maintains compact stack/tooling constraints in `docs/development.md`, `docs/architecture.md`, and ADRs rather than creating `docs/stack.md` by default.
- Preserves PRD-to-plan traceability and AI context handoff rules.

Typical prompt:
- `Use repo-docs-bootstrap after .agents/PRD.md to establish durable docs for this repo.`

Expected output:
- Created/updated docs, assumptions, unresolved gaps, and follow-up validations.

## G) `rules-template-author`
Path: `.agents/skills/rules-template-author/SKILL.md`

Use when:
- You want to update project-wide agent rules template.

What it does:
- Generates/refines `.agents/templates/AGENTS-template.md` based on repository patterns.

Typical prompt:
- `Update .agents/templates/AGENTS-template.md from current codebase conventions.`

Expected output:
- Refined AGENTS template (template-first approach).

Claude-era equivalent:
- roughly `/create-rules`

## H) `project-bootstrap`
Path: `.agents/skills/project-bootstrap/SKILL.md`

Use when:
- You need environment setup and health checks.

What it does:
- Runs setup sequence (`uv sync`, db start, migrations, app start, health verification).

Typical prompt:
- `Bootstrap this project locally and verify health endpoints.`

Expected output:
- Setup status with pass/fail and blockers/remediation if needed.

Claude-era equivalent:
- roughly `/init-project`

## I) `atomic-commit`
Path: `.agents/skills/atomic-commit/SKILL.md`

Use when:
- You want one clean commit from current changes.

What it does:
- Reviews working state, ensures atomicity, commits with typed message (`feat`, `fix`, etc.).

Typical prompt:
- `Create one atomic commit for current uncommitted changes with an appropriate typed message.`

Expected output:
- Commit created (or reason why not).

Claude-era equivalent:
- roughly `/commit`

## J) `model-test-pipeline`
Path: `.agents/skills/model-test-pipeline/SKILL.md`

Use when:
- You want a research-first, universal econometric testing workflow.

What it does:
- Launches three parallel research sub-agents (`Repo`, `Data`, `Risk`) before running tests.
- Builds a task queue from research findings, then runs generic checks first and auto profile checks second.
- Applies only critical blocker fixes (one attempt per blocker), then reports outcomes.

Typical prompt:
- `Run model-test-pipeline to research this repo first, then execute universal econometric model testing and report blockers, failures, and warnings.`

Expected output:
- Inline validation summary and optional detailed markdown report (`model-test-report.md`).

## 5. Quick Mapping Table

| Old command habit | New skill | Suggested prompt |
|---|---|---|
| `/prime` | `repo-primer` | `Prime this repo and summarize architecture and conventions.` |
| `/plan-feature` | `feature-planner` | `Plan feature X and save under .agents/plans/...` |
| `/execute` | `plan-executor` | `Execute .agents/plans/<file>.md completely.` |
| `/docs-update` or closeout habit | `plan-closeout` | `Close out .agents/plans/<file>.md, archive it, and update affected docs.` |
| `/create-prd` | `prd-writer` | `Create/update PRD for X at <path>.` |
| post-PRD docs setup | `repo-docs-bootstrap` | `Bootstrap durable docs from this PRD and current repo state.` |
| `/create-rules` | `rules-template-author` | `Update AGENTS template from current repo patterns.` |
| `/init-project` | `project-bootstrap` | `Bootstrap local environment and run health checks.` |
| `/commit` | `atomic-commit` | `Create a single atomic typed commit for current changes.` |

## 6. Prompting Tips That Work Well

1. Include exact output file path.
2. State quality bar explicitly:
   - `decision-complete`
   - `include test plan`
   - `run validation commands`
3. State constraints:
   - `no DB schema change`
   - `backward compatible`
   - `no new dependencies`
   - `ADR required for stack changes`
4. Ask for a summary at the end:
   - `List files changed and validation results.`

## 7. Common Mistakes During Migration

1. Using old slash syntax.
- Fix: Write plain-language requests.

2. Forgetting output path.
- Fix: Always include target file path for plan/PRD/template artifacts.

3. Mixing planning and execution unintentionally.
- Fix: First request `feature-planner`, then request `plan-executor`.

4. Skipping docs after implementation.
- Fix: Use `plan-closeout` after execution and commit, or record `completion_commit: pending` before the commit exists.

5. Using legacy folder as active source.
- Fix: Treat `.agents/legacy/claude-commands/` as archive only.

6. Treating archived plans as active planning context during priming.
- Fix: Exclude `.agents/plans/archive/` from default priming scope; include it only when explicitly requested.

## K) `docx`
Path: `.agents/skills/docx/SKILL.md`

Use when:
- You need to create, read, edit, or manipulate Word documents (.docx files).

Typical prompt:
- `Create a Word report for X at output/report.docx.`

## L) `pptx`
Path: `.agents/skills/pptx/SKILL.md`

Use when:
- Any .pptx file is involved — creating, editing, reading, or extracting content from presentations.

Typical prompt:
- `Create a presentation on X and save it as output/slides.pptx.`

Expected output:
- .pptx file with QA cycle completed (content + visual verification).

Dependencies (install before first use):
- `pip install "markitdown[pptx]"` — text extraction
- `pip install Pillow` — thumbnail grids
- `npm install -g pptxgenjs` — creating from scratch
- LibreOffice (`soffice`) — PDF conversion
- Poppler (`pdftoppm`) — PDF to images

## M) `statquest-ultimate`
Path: `.agents/skills/statquest-ultimate/SKILL.md`

Use when:
- You want a technical concept explained with a high-energy, intuition-first, example-before-formula teaching rhythm.

Typical prompt:
- `Use statquest-ultimate to explain impulse response functions in plain English with a small example and frequent recap lines.`

## 8. Current Repository Note

You currently have these active skills:
- `repo-primer`
- `feature-planner`
- `model-test-pipeline`
- `plan-closeout`
- `plan-executor`
- `prd-writer`
- `repo-docs-bootstrap`
- `rules-template-author`
- `project-bootstrap`
- `atomic-commit`
- `docx`
- `pptx`
- `statquest-ultimate`

The file `.agents/skills/e2e-test/SKILL.md` is not present in the current repository state. Use `model-test-pipeline` for econometric-model validation workflows.
