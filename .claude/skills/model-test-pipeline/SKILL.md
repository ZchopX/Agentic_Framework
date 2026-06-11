---
name: model-test-pipeline
description: Run universal econometric model testing with a research-first workflow. Use when the user asks to research a repo/model first, then execute staged validation for VAR/BVAR/ARIMA/state-space/ML econometric pipelines, including robustness, artifacts, and output consistency checks.
---

# Model Test Pipeline

## Goal
Run end-to-end econometric validation by first researching the repository in parallel, then executing a task-tracked test pipeline derived from those findings.

## Required Context
1. Read repo-level guidance and runnable commands.
2. Read model/data docs that define assumptions, outputs, and acceptance rules.
3. Read current tests, scripts, and environment files to discover executable checks.

## Execution Policy
- Use research-first orchestration, not hardcoded test paths.
- Run generic econometric checks first, then auto-enable family profile checks when detected.
- Auto-fix only critical execution blockers that stop full pipeline execution.
- Allow one minimal unblock fix attempt per blocker, then rerun the failed step once.
- Do not fix non-blocking quality findings (logic quality, calibration quality, or methodology quality).
- Treat optional tooling as non-blocking:
  - If R/TRAMO-SEATS or CmdStan tooling is unavailable, warn and skip dependent checks.

## Workflow

### Phase 0: Preflight
1. Detect runnable stack, available test commands, data assets, and optional tooling.
2. Classify repo maturity (planning-only, partial, fully runnable) to prevent false failures.
3. Record all discovered commands and constraints before testing starts.

### Phase 1: Parallel Research (Mandatory)
Launch three sub-agents in parallel and wait for all to complete.

#### Sub-agent 1: Repo Surface
Return:
1. How to install deps and run tests/models.
2. Test entrypoints and command matrix.
3. Model execution surfaces (scripts, notebooks, CLIs, modules).
4. Candidate output paths and artifacts.

#### Sub-agent 2: Data and Method Contracts
Return:
1. Data sources, input schemas, and preprocessing/transformation assumptions.
2. Model-family signals (VAR/BVAR/ARIMA/state-space/other).
3. Identification and robustness constraints documented in repo references.
4. Expected outputs and metrics to validate.

#### Sub-agent 3: Risk and Gap Scan
Return:
1. Blocker risks that could stop execution.
2. Test gaps and flaky/high-risk zones.
3. Logic/data integrity risks and likely failure points.
4. Prioritized findings with file references when possible.

### Phase 2: Task Queue Construction
1. Convert research outputs into explicit test tasks.
2. Use statuses: `pending`, `in_progress`, `completed`, `blocked`.
3. Group tasks into:
   - Generic econometric checks (always first).
   - Auto-profile checks (enabled by detected model family).
   - Final consistency review task.

### Phase 3: Execution (Generic Checks First)
Run generic checks in dependency order:
1. Environment and smoke checks.
2. Reproducibility and run-command sanity.
3. Data integrity and transformation sanity.
4. Model-run sanity and test-suite integrity.
5. Artifact integrity and output consistency.

When a blocker appears:
1. Apply one minimal unblock fix only if it is critical to continue execution.
2. Rerun the failed step once.
3. If still blocked, mark task `blocked` and continue remaining runnable tasks.

### Phase 4: Auto Profile Checks
1. Detect model family from code/docs/tests.
2. If VAR/BVAR profile is detected, append VAR/BVAR checks after generic checks.
3. If no specific profile is detected, keep generic-only validation.
4. Optional tooling dependent checks must warn+skip when tooling is missing.

### Phase 5: Reporting and Export
Always output an inline summary with:
- `Checks run`
- `Checks skipped`
- `Failures`
- `Warnings`
- `Evidence paths`
- `Blocked-by-missing-tooling`
- `Blockers fixed`
- `Blockers unresolved`

Then ask whether to export a full report.
If yes, write `model-test-report.md` at repo root.

## Guardrails
- Do not apply non-critical fixes.
- Do not run repeated repair loops beyond one retry per blocker.
- Do not report skipped checks as failures.
- Keep evidence concrete: command, outcome, and file path.
- Keep testing tasks derived from research outputs, not static assumptions.
