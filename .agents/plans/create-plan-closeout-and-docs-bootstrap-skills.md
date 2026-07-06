# Create Plan Closeout and Docs Bootstrap Skills

## Feature Description

Create two repository-local Codex skills that formalize documentation lifecycle work for AI-maintained repositories:

1. `plan-closeout`: run after `plan-executor` completes an implementation plan. It archives the completed plan in `.agents/plans/archive`, records completion metadata, and updates relevant documentation based on actual repository changes.
2. `repo-docs-bootstrap`: run after a PRD is created, or on an existing repo with weak documentation, to establish durable project documentation for humans and future AI agents.

The skills must use `.agents` as the strict root for all agentic files. No new `.agent` paths may be introduced.

## User Value

The repo gains a durable PRD -> plan -> execution -> closeout -> archive lifecycle. Future agent sessions can survive context compaction by rediscovering completed work from Git history, archived plans, and maintained docs instead of relying on conversation memory.

## In Scope

- Create `.agents/skills/plan-closeout/SKILL.md`.
- Create `.agents/skills/repo-docs-bootstrap/SKILL.md`.
- Add supporting references/scripts only if they reduce repeated work or make behavior deterministic.
- Add or update skill metadata under each skill's `agents/openai.yaml` if the repo convention expects it.
- Update existing repo-local skills and guidance that still reference `.agent` for agentic paths.
- Define the canonical archive path as `.agents/plans/archive`.
- Define completed-plan metadata fields: status, completed date, commit hash, validation results, docs updated, and deviations.
- Define docs discovery rules for updating root docs, `docs/**`, `.agents/**` guidance, PRDs, architecture notes, and changelogs when present.
- Include a sub-agent research step before writing final skill instructions for `repo-docs-bootstrap`.
- Validate new skills by checking YAML frontmatter, trigger descriptions, path conventions, and a dry-run usage scenario.

## Out of Scope

- Implementing unrelated documentation rewrites beyond the skill lifecycle docs.
- Migrating non-agentic application docs unless directly needed to establish the new workflow.
- Creating a global documentation platform or external tool dependency.
- Rewriting all existing skills for style unless they conflict with `.agents` path conventions.
- Automatically committing changes.

## Constraints and Decisions

- All agentic files live under `.agents`.
- Archived plans live under `.agents/plans/archive`.
- The closeout skill name is `plan-closeout`.
- The bootstrap skill name is `repo-docs-bootstrap`.
- The skills must reconstruct state from the filesystem and Git rather than relying on current conversation context.
- The skills should prefer repo-local conventions over generic documentation templates.
- The implementation should not create `.agent` directories or references.
- Existing user changes must not be reverted.

## Existing Files to Read

- `.agents/skills/feature-planner/SKILL.md`: update planning output path and guardrails from `.agent` to `.agents`.
- `.agents/skills/plan-executor/SKILL.md`: align reporting contract with closeout metadata expectations if needed.
- `.agents/skills/prd-writer/SKILL.md`: align PRD output and post-PRD docs-bootstrap handoff.
- `.agents/skills/repo-primer/SKILL.md`: update archive exclusion rules from `.agent/plans/archive` to `.agents/plans/archive`.
- `.agents/skills/rules-template-author/SKILL.md`: update template path references if stale.
- `.agents/skills/skills-usage-guide.md`: update lifecycle documentation and add the two new skills.
- `.agents/templates/AGENTS-template.md`: update skill paths and agentic file convention.
- `.agents/reference/skill-download-requirements.md`: verify whether new skills need extra requirements; likely no.
- Existing skill folders under `.agents/skills/**`: copy local style for frontmatter, concise workflows, and optional `agents/openai.yaml`.

## New Files

- `.agents/skills/plan-closeout/SKILL.md`
- `.agents/skills/repo-docs-bootstrap/SKILL.md`
- `.agents/skills/plan-closeout/agents/openai.yaml` if metadata is used for this repo's local skills.
- `.agents/skills/repo-docs-bootstrap/agents/openai.yaml` if metadata is used for this repo's local skills.
- `.agents/skills/repo-docs-bootstrap/references/ai-maintained-docs.md` if the research output is valuable enough to preserve as reusable guidance.
- `.agents/plans/archive/.gitkeep` only if the archive directory needs to be present before the first archived plan.

## Updated Files

- `.agents/skills/feature-planner/SKILL.md`
- `.agents/skills/plan-executor/SKILL.md`
- `.agents/skills/prd-writer/SKILL.md`
- `.agents/skills/repo-primer/SKILL.md`
- `.agents/skills/rules-template-author/SKILL.md`
- `.agents/skills/skills-usage-guide.md`
- `.agents/templates/AGENTS-template.md`
- `.agents/reference/skill-download-requirements.md` only if validation finds new requirements.

## Implementation Tasks

1. Inventory current `.agent` references.
   - Run `rg '\.agent([^sA-Za-z0-9_-]|$)' .agents -n` to find stale `.agent` paths without matching valid `.agents` paths.
   - Treat `.agents` matches as valid; only standalone `.agent` paths are violations.
   - Categorize references as path-convention docs, examples, code commands, or historical notes.
   - Only update references that describe active repo conventions or executable commands.

2. Run the research sub-agent.
   - Ask for practical documentation systems for AI-maintained repos.
   - Require coverage of durable context, PRD-to-plan traceability, ADRs, changelog discipline, architecture docs, avoiding documentation rot, and context compaction.
   - Save distilled reusable findings only if they are specific and useful for future executions.

3. Design the canonical documentation lifecycle.
   - Define `PRD -> repo-docs-bootstrap -> feature-planner -> plan-executor -> plan-closeout`.
   - Define when `repo-docs-bootstrap` applies to an existing repo without a fresh PRD.
   - Define when `plan-closeout` should run before or after `atomic-commit`; default should support both:
     - If a completion commit exists, record its hash.
     - If no commit exists yet, record pending status and instruct the user to rerun after commit or update metadata after commit.

4. Create `plan-closeout`.
   - Write frontmatter with a trigger-rich description for archiving completed plans and updating docs after implementation.
   - Workflow must:
     - read the completed plan in full;
     - inspect `git status`, recent commits, and relevant diffs;
     - identify completion date using the current date;
     - identify commit hash from user input, current `HEAD`, or recent commits;
     - update the plan with completion metadata;
     - move it to `.agents/plans/archive`;
     - discover docs with `rg --files` and targeted reads;
     - update docs that are directly affected by the implemented change;
     - report archived path, metadata, docs changed, and unresolved gaps.
   - Guardrails must prohibit relying on conversation memory as the only source of truth.
   - Guardrails must prohibit moving active or incomplete plans.

5. Create `repo-docs-bootstrap`.
   - Write frontmatter with a trigger-rich description for post-PRD documentation setup and documentation baseline creation in existing repos.
   - Workflow must:
     - classify repo type;
     - read PRD if present or user-provided;
     - discover current docs;
     - create a minimal durable doc set appropriate to the repo;
     - avoid heavy docs when the repo is small;
     - preserve existing docs and update rather than overwrite;
     - create AI-facing guidance under `.agents` when needed.
   - Recommended baseline docs:
     - root `README.md` if absent or clearly insufficient;
     - `docs/architecture.md` for architecture and integration points;
     - `docs/development.md` for setup, commands, tests, and workflows;
     - `docs/decisions/` for ADR-style decisions when meaningful;
     - `.agents/skills/skills-usage-guide.md` updates for agent workflows.
   - Guardrails must require docs to be based on discovered repo facts and explicit assumptions.

6. Update existing lifecycle skills.
   - Update `feature-planner` to write plans to `.agents/plans/<name>.md`.
   - Update `feature-planner` guardrails to use `.agents/...` paths only.
   - Update `plan-executor` reporting contract to include whether `plan-closeout` should be run.
   - Update `prd-writer` to mention `repo-docs-bootstrap` as the next step after PRD creation.
   - Update `repo-primer` archive exclusions and core context paths to `.agents`.
   - Update `rules-template-author` template path references to `.agents`.

7. Update user-facing skill documentation.
   - Rewrite active path conventions in `.agents/skills/skills-usage-guide.md`.
   - Add `repo-docs-bootstrap` and `plan-closeout` to the recommended end-to-end flow.
   - Update the mapping table and examples.
   - Update `.agents/templates/AGENTS-template.md` skill table and path conventions.

8. Validate the skills.
   - Check each new `SKILL.md` has only `name` and `description` in YAML frontmatter.
   - Check names are lowercase hyphenated and match folder names.
   - Run `rg '\.agent([^sA-Za-z0-9_-]|$)' .agents -n` and verify no active convention still points at standalone `.agent` paths.
   - Confirm valid `.agents` paths are not counted as stale `.agent` violations.
   - Dry-run mentally or with a temporary scratch plan:
     - completed plan with commit hash available;
     - completed plan before commit;
     - existing repo with no PRD;
     - repo with PRD but partial docs.

9. Report completion.
   - List created and updated files.
   - Summarize remaining `.agent` references, if any, and why they remain.
   - State validation commands and outcomes.

## Test Strategy

- Static validation:
  - Confirm required skill frontmatter is valid YAML.
  - Confirm folder names match `name`.
  - Confirm descriptions contain concrete trigger contexts.
  - Confirm no new `.agent` paths are introduced.

- Workflow validation:
  - Use a sample plan path under `.agents/plans/` to verify `plan-closeout` instructions are sufficient for another agent.
  - Use a simulated repo-docs scenario to verify `repo-docs-bootstrap` can choose docs without needing conversation history.

- Regression validation:
  - Existing skills still describe the same core workflows.
  - The recommended lifecycle remains understandable: PRD, bootstrap docs, plan, execute, closeout, commit as needed.

## Validation Commands

```powershell
rg '\.agent([^sA-Za-z0-9_-]|$)' .agents -n
rg "plan-closeout|repo-docs-bootstrap" .agents -n
rg --files .agents/skills/plan-closeout .agents/skills/repo-docs-bootstrap
git diff -- .agents
```

If a skill validation script becomes available, also run it against both new skill folders.

## Acceptance Criteria

- [ ] `.agents/skills/plan-closeout/SKILL.md` exists and defines the full closeout workflow.
- [ ] `.agents/skills/repo-docs-bootstrap/SKILL.md` exists and defines the full docs bootstrap workflow.
- [ ] `plan-closeout` archives completed plans only under `.agents/plans/archive`.
- [ ] `plan-closeout` records completion date and commit hash or a clear pending-commit state.
- [ ] `plan-closeout` discovers recent changes from Git and filesystem state.
- [ ] `plan-closeout` discovers and updates relevant docs rather than using a fixed list only.
- [ ] `repo-docs-bootstrap` supports both post-PRD setup and existing repos.
- [ ] `repo-docs-bootstrap` includes guidance from the research sub-agent.
- [ ] Existing lifecycle docs mention both new skills in the correct order.
- [ ] Active `.agent` path references are replaced with `.agents`.
- [ ] Validation commands complete with understood results.

## Risks and Fallbacks

- Risk: The research step produces generic advice.
  - Fallback: Preserve only concrete workflow rules and do not add a bulky reference file.

- Risk: Some `.agent` references are historical examples rather than active conventions.
  - Fallback: Leave them only if clearly labeled historical; otherwise update to `.agents`.

- Risk: `plan-closeout` cannot reliably infer the correct completion commit.
  - Fallback: Require explicit user confirmation or record `commit: pending` with a rerun/update instruction.

- Risk: `repo-docs-bootstrap` creates too much documentation.
  - Fallback: Require repo classification and choose the smallest useful baseline.

- Risk: No local skill initialization or validation scripts exist.
  - Fallback: Create folders manually with `SKILL.md`, then validate frontmatter and names with direct inspection and search commands.

## Assumptions

- `.agents` is the canonical agentic root for this repo and future generated docs.
- `.agents/plans/archive` is the only archive location for completed implementation plans.
- The existing skill format is sufficient: folder plus `SKILL.md`, with optional `agents/openai.yaml`.
- The user wants a plan only in this step; implementation will happen separately through `plan-executor`.
