## Why

Econometric analysis work (panel data, time series) currently has no repeatable, gated workflow in this repo: nothing stops implementation from starting before the identification strategy is settled, and nothing structurally separates "the code doesn't match the spec" from "the spec itself is wrong" when a model fails its diagnostics. A CEO-led team of role-specialized Claude Code subagents, backed by an OpenSpec schema that encodes the gates as an artifact graph, gives one conversational entry point (the CEO) while keeping design-before-implementation and root-cause-correct failure routing structurally enforced rather than relied on as convention.

## What Changes

- Add a new project-local OpenSpec schema, `econometric-verified` (forked from `openspec-mod/openspec-schemas/spec-driven-verified`, not modifying it), with a custom artifact chain: `proposal → identification → package-selection → specs/tasks → implementation-notes → verification → report`. Verified technically feasible in this repo via `openspec schema fork` + custom artifact ids + `openspec schema validate` + `openspec status --json`.
- Add CEO and specialist subagent definitions under `.claude/agents/`:
  - `econ-ceo` (Opus): parses requests, routes to specialists, reads `openspec status --change <name> --json` to enforce gates, is the sole role the user talks to directly.
  - `econ-design` (Opus): research question → identification strategy, required diagnostics, expected error-structure requirements. Writes the `identification` artifact. Hard gate before any modeling.
  - `econ-package-scout` (Sonnet): compares Python vs R candidate packages for the chosen identification strategy, picks one with rationale. Writes the `package-selection` artifact.
  - `econ-estimation` (Sonnet): implements the model in the chosen language/package (Python or R, both executable in this environment); writes `implementation-notes` mapping code to the identification spec.
  - `econ-test-writer` (Sonnet): writes statistical/diagnostic tests from the identification artifact's required-diagnostics list, runs them.
  - `econ-triage` (Opus): on test failure, reads the identification spec, implementation notes, code, and failure output; classifies as CODE_BUG (→ back to `econ-estimation`), SPEC_GAP (→ back to `econ-estimation` with a spec addendum), or DESIGN_FLAW (→ back to `econ-design`, gate reopens). Writes/updates the `verification` artifact.
  - `econ-writer` (Sonnet): final synthesis memo, writes the `report` artifact.
- Add the CEO's routing/gating logic: read OpenSpec status to determine which specialist to invoke next; enforce a 2-3 retry cap per stage in the Triage failure loop, after which the CEO stops looping and reports to the user instead of continuing silently.
- Scope of the team's econometric coverage for this change: panel data and time series methods only (not causal inference, cross-section, or ML-adjacent methods - those are explicit non-goals for now).

**Non-goals (explicit):**
- No new "Librarian" subagent/role — retrieval of past artifacts/docs is a file-path convention plus this repo's existing cocoindex search.
- Not packaged as a distributable/installable bundle across repos (unlike this repo's existing skills) — this is a one-off setup for this project.
- No Orca ADE orchestration integration — Claude Code subagents only.
- No causal inference (IV/DiD/RDD), cross-section, or ML-adjacent (double ML, forecasting) econometric methods in this change.

## Capabilities

### New Capabilities
- `econometric-team/schema`: The `econometric-verified` OpenSpec schema — its artifact graph, gating (`requires` edges), and per-artifact instructions for identification, package-selection, implementation-notes, verification, and report artifacts.
- `econometric-team/orchestration`: The CEO-led subagent team's behavior — request routing, the design-before-implementation gate, the Triage classification and retry-capped failure loop, and role/model assignment.

### Modified Capabilities
(none — first capabilities in this repo)

## Impact

- New files under `.claude/agents/` (subagent definitions) and `openspec-mod/openspec-schemas/econometric-verified/` or an equivalent project-local schema location (schema.yaml + templates).
- New `openspec/config.yaml` schema availability (does not change the repo's default schema; `econometric-verified` is opt-in per change via `--schema`).
- No changes to existing skills, the installer script, or the `spec-driven-verified` schema.
