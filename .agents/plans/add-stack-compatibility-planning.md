# Add Stack Compatibility Planning

## Feature Description
Improve the planning workflow so AI agents do not propose dependencies, frameworks, runtime features, package managers, databases, build tools, or testing tools that conflict with the repository's current stack.

The change should avoid token-heavy full-repo rediscovery on every plan. Instead, it should make agents read durable docs first, then inspect only the minimum relevant machine-readable files when the docs are missing or insufficient.

## User Value
- Plans become safer to execute because proposed technical choices are checked against the existing stack.
- Planning remains efficient on large projects because stack facts are read from maintained docs and source-of-truth config instead of rediscovered exhaustively.
- Stack-changing proposals become explicit and traceable through ADR requirements.

## In Scope
- Update `.agents/skills/feature-planner/SKILL.md` with a mandatory stack compatibility gate.
- Update `.agents/skills/repo-docs-bootstrap/SKILL.md` so durable docs include a compact stack/tooling constraints section when useful.
- Update `.agents/skills/repo-primer/SKILL.md` so stack/tooling facts are surfaced clearly for later planning.
- Update `.agents/skills/skills-usage-guide.md` to document the new compatibility workflow.
- Keep the default recommendation as `docs/development.md` plus `docs/architecture.md` plus ADRs, not a new `docs/stack.md`.

## Out of Scope
- Do not create `docs/stack.md` by default.
- Do not generate root project docs in this plan unless the user separately asks to run `repo-docs-bootstrap`.
- Do not add CI/dependency-bot enforcement in this plan.
- Do not change non-agent application code.

## Existing Files To Read
- `.agents/skills/feature-planner/SKILL.md`: primary workflow to enforce compatibility before writing plans.
- `.agents/skills/repo-docs-bootstrap/SKILL.md`: durable docs workflow that should maintain stack/tooling constraints.
- `.agents/skills/repo-docs-bootstrap/references/ai-maintained-docs.md`: docs-as-code rules and templates; update only if the bootstrap skill needs reusable reference wording.
- `.agents/skills/repo-primer/SKILL.md`: repo briefing workflow that already inspects execution-critical config files.
- `.agents/skills/skills-usage-guide.md`: user-facing guide for skill sequencing and expected outputs.
- `.agents/templates/AGENTS-template.md`: inspect before deciding whether agent-wide read-first rules should be added now or left to `rules-template-author`.

## New And Updated Files
- Update `.agents/skills/feature-planner/SKILL.md`.
- Update `.agents/skills/repo-docs-bootstrap/SKILL.md`.
- Update `.agents/skills/repo-primer/SKILL.md`.
- Update `.agents/skills/skills-usage-guide.md`.
- Optional update: `.agents/skills/repo-docs-bootstrap/references/ai-maintained-docs.md`, only if shared documentation policy wording would reduce duplication.
- Optional update: `.agents/templates/AGENTS-template.md`, only if the implementation decides the rule must apply outside the planning skill.

## Stack Compatibility Design
Use a layered source hierarchy:

1. Durable docs first:
   - `docs/development.md`
   - `docs/architecture.md`
   - `docs/decisions/**`
   - `README*`
   - `AGENTS.md` or `.agents/templates/AGENTS-template.md` when present
2. Machine-readable source of truth when docs are absent or insufficient:
   - package manifests and lockfiles
   - framework, build, lint, formatter, and test configs
   - CI/deploy configs
   - existing imports/usages in affected modules
3. Planning output:
   - include a short compatibility note only when the plan proposes or touches technology choices
   - list sources checked
   - prefer existing stack pieces
   - mark stack-changing choices as requiring an ADR

Do not make `docs/stack.md` the default. Add it only as a fallback recommendation for large or polyglot repos where stack constraints are too scattered for `docs/development.md` and `docs/architecture.md`.

## Ordered Tasks
1. Inspect `.agents/templates/AGENTS-template.md` and decide whether stack compatibility belongs only in skills or also in generated project rules.
2. Update `feature-planner` workflow:
   - add a step to check stack/tooling compatibility before resolving tradeoffs
   - require reading durable stack docs first
   - require minimum targeted config inspection when docs are missing or insufficient
   - require new technology proposals to explain why existing stack choices are insufficient
3. Update `feature-planner` plan requirements:
   - add `Stack compatibility notes` only when the request proposes, changes, or depends on technology choices
   - allow a one-line `No stack/tooling impact identified` note, or omission when the skill wording permits it, for behavior-neutral plans
   - require `ADR required: yes/no` for new framework/runtime/database/package-manager/build-system decisions
   - require assumptions and verification steps when compatibility cannot be confirmed locally
4. Update `repo-docs-bootstrap` workflow:
   - add `Stack and Tooling Constraints` to `docs/development.md` when durable docs are created or refreshed
   - include supported runtimes, package manager, build/test/lint commands, dependency policy, forbidden substitutions, and source-of-truth files
   - add architecture-level stack constraints to `docs/architecture.md`
   - use ADRs for significant stack decisions
5. Update `repo-primer` output expectations:
   - make `Toolchain and Commands` include detected runtimes, package managers, lockfiles, test/build/lint tools, CI/deploy clues, and stack unknowns
   - keep the output concise and fact-based
6. Update `skills-usage-guide`:
   - document that `repo-docs-bootstrap` maintains stack/tooling constraints in durable docs
   - document that `feature-planner` checks compatibility before proposing new technology
   - add a prompting tip: ask for `no new dependencies` or `ADR required for stack changes` when relevant
7. Run a text review of the edited skill files for contradictions, excessive token bloat, and stale references.
8. Validate by reading the final files and confirming:
   - `feature-planner` has a mandatory compatibility gate
   - `repo-docs-bootstrap` maintains stack constraints without defaulting to `docs/stack.md`
   - `repo-primer` surfaces stack facts
   - the usage guide reflects the new workflow

## Test Strategy
- No unit tests are required because this is a documentation/skill behavior change.
- Use deterministic file checks:
  - verify required phrases/sections exist with `rg`
  - inspect final markdown manually for clear workflow order
  - confirm no new docs file is created by default

## Validation Commands
```powershell
rg -n "stack|compatib|ADR|dependencies|framework|runtime" .agents/skills/feature-planner/SKILL.md
rg -n "Stack and Tooling|stack|tooling|ADR|development.md|architecture.md" .agents/skills/repo-docs-bootstrap/SKILL.md
rg -n "Toolchain and Commands|runtime|package manager|lockfile|CI" .agents/skills/repo-primer/SKILL.md
rg -n "compatib|stack|ADR|dependencies" .agents/skills/skills-usage-guide.md
git diff -- .agents/skills/feature-planner/SKILL.md .agents/skills/repo-docs-bootstrap/SKILL.md .agents/skills/repo-primer/SKILL.md .agents/skills/skills-usage-guide.md
```

If implementation edits optional files, include them in the same review:

```powershell
rg -n "stack|tooling|compatib|ADR|dependencies" .agents/skills/repo-docs-bootstrap/references/ai-maintained-docs.md .agents/templates/AGENTS-template.md
git diff -- .agents/skills/repo-docs-bootstrap/references/ai-maintained-docs.md .agents/templates/AGENTS-template.md
```

## Acceptance Criteria
- [ ] `feature-planner` requires stack compatibility checks before plans propose new technology.
- [ ] `feature-planner` reads durable docs first and falls back to targeted config inspection only when needed.
- [ ] `feature-planner` requires ADR signaling for significant stack-changing decisions.
- [ ] `repo-docs-bootstrap` maintains compact stack/tooling constraints in normal durable docs.
- [ ] `repo-docs-bootstrap` does not create `docs/stack.md` by default.
- [ ] `repo-primer` clearly surfaces stack/tooling facts and unknowns.
- [ ] `skills-usage-guide` explains the revised workflow.
- [ ] Validation commands pass or their output is reviewed and accepted.

## Risks, Assumptions, And Fallbacks
- Risk: The new instructions may add token overhead to every plan.
  - Fallback: Keep compatibility notes short and only require detailed analysis when proposing new technology.
- Risk: Durable docs can become stale.
  - Fallback: Treat manifests, lockfiles, configs, and CI as source of truth when docs disagree.
- Risk: Agents may overuse ADR requirements for minor dependency additions.
  - Fallback: Limit ADR requirement to framework, runtime, database, package manager, build system, deployment, architecture, or major dependency-policy changes.
- Assumption: The project wants compatibility guidance embedded in existing skills rather than a new standalone skill.
- Assumption: `docs/development.md` and `docs/architecture.md` are the preferred homes for stack constraints when durable project docs exist.

## Docs Impact
- This plan updates skill documentation only.
- Future `repo-docs-bootstrap` runs should create or update project docs using the revised stack/tooling guidance.

## Changelog Entry
Not required unless this repository starts maintaining a changelog for skill workflow changes.
