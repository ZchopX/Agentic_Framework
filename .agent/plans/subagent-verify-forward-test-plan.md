# Subagent Verify Forward-Test Plan

## Feature Description

Create a repeatable test plan for validating the `subagent-verify` skill on realistic workflows before treating it as complete. The plan covers dry-run task fixtures, scenario execution, and fresh sub-agent forward-tests.

## User Value

The skill should work when another Codex instance uses it under normal context pressure: after creating a plan, after implementing a plan, after making code changes without a plan, or after producing validation outputs. Testing these workflows reduces the chance that the skill only works because this conversation already explains its intended behavior.

## In Scope

- Create temporary test tasks under `.agent/tmp/subagent-verify-tests/`.
- Cover these four routes from `SKILL.md`:
  - `plan-created-review.md`
  - `plan-implementation-review.md`
  - `code-change-review.md`
  - `validation-output-review.md`
- Forward-test with fresh sub-agents using user-like prompts.
- Evaluate whether each route selects the right template, passes pointers instead of large copied context, returns actionable findings, and supports a fix-and-recheck loop.
- Record results in a temporary report outside the skill folder.

## Out of Scope

- Do not add test fixtures, reports, or evaluation notes inside `.agents/skills/subagent-verify/`.
- Do not modify production project code as part of the tests.
- Do not require live network access or external services.
- Do not test every possible repository technology stack.
- Do not use hidden expected answers inside sub-agent prompts.

## Existing Files to Read

- `.agents/skills/subagent-verify/SKILL.md`: route selection, main workflow, and final response rules.
- `.agents/skills/subagent-verify/references/plan-created-review.md`: expected behavior for newly created plan verification.
- `.agents/skills/subagent-verify/references/plan-implementation-review.md`: expected behavior for implemented written plans.
- `.agents/skills/subagent-verify/references/code-change-review.md`: expected behavior for code changes without a written plan.
- `.agents/skills/subagent-verify/references/validation-output-review.md`: expected behavior for validation/artifact-centered tasks.
- `.agents/skills/subagent-verify/agents/openai.yaml`: UI prompt metadata consistency check.

## New Files

- `.agent/plans/subagent-verify-forward-test-plan.md`: this plan.
- `.agent/tmp/subagent-verify-tests/README.md`: short index of generated test scenarios.
- `.agent/tmp/subagent-verify-tests/plan-created/`: fixture for a plan-only workflow.
- `.agent/tmp/subagent-verify-tests/plan-implementation/`: fixture for implemented-plan workflow.
- `.agent/tmp/subagent-verify-tests/code-change/`: fixture for code-change workflow.
- `.agent/tmp/subagent-verify-tests/validation-output/`: fixture for validation-output workflow.
- `.agent/tmp/subagent-verify-tests/evaluator-notes.md`: non-inspected evaluator notes with seeded issues and minimum expected evidence for each scenario.
- `.agent/tmp/subagent-verify-tests/results.md`: forward-test results and follow-up changes.

## Updated Files

- No `subagent-verify` skill files are updated unless a forward-test produces a concrete, reproducible skill defect.
- If a forward-test exposes a defect, update only the relevant `subagent-verify` skill file or reference template and rerun that scenario.

## Phase 1: Preflight Sub-Agent Capability

1. Use the `multi_agent_v1.spawn_agent` tool for forward-tests.
2. Invoke each forward-test with `fork_context: false`.
3. Pass the skill path and scenario artifact paths in the sub-agent prompt.
4. Record the spawned agent id, prompt summary, and completion status in `results.md`.
5. If `multi_agent_v1.spawn_agent` or `fork_context: false` is unavailable, stop and report the plan as blocked.
6. Do not replace forward-tests with manual review; manual review does not validate the skill's fresh-context behavior.

## Phase 2: Prepare Fixtures

1. Create `.agent/tmp/subagent-verify-tests/`.
2. Add a `README.md` that states the directory is disposable test material for the skill.
3. Create four isolated scenario folders.
4. For each scenario, include only small text/code artifacts needed for the route being tested.
5. Seed each scenario with at least one concrete issue the chosen template should catch.
6. Avoid writing expected findings into files the sub-agent will inspect.
7. Create `.agent/tmp/subagent-verify-tests/evaluator-notes.md` before running forward-tests.
8. In `evaluator-notes.md`, record each scenario's seeded issue, expected template route, and minimum acceptable evidence.
9. Do not include `evaluator-notes.md` in any sub-agent prompt or scenario README.

## Phase 3: Scenario Designs

### Scenario A: Plan Created

Goal: verify the skill chooses `plan-created-review.md`.

Fixture contents:

- A user request for a feature with multiple possible scopes.
- A created plan that misses one required decision or has weak acceptance criteria.
- Optional repo pointer file showing the relevant module or command.

Expected behavior:

- The sub-agent reviews plan readiness, not implementation code.
- Findings reference plan sections and explain why implementation would be ambiguous.
- Verdict is `Not ready to implement` or `Ready after minor plan edits`, depending on severity.

### Scenario B: Plan Implementation

Goal: verify the skill chooses `plan-implementation-review.md`.

Fixture contents:

- A written plan with steps and acceptance criteria.
- Small changed files representing an implementation.
- A validation note showing commands run and status.
- One seeded mismatch between plan and implementation, or one validation gap tied to an acceptance criterion.

Expected behavior:

- The sub-agent checks plan fidelity, implementation correctness, validation quality, and scope.
- Findings cite the plan item and changed file or command evidence.
- The main agent can triage the finding, patch the fixture, and rerun a narrow check.

### Scenario C: Code Change Without Plan

Goal: verify the skill chooses `code-change-review.md`.

Fixture contents:

- A small user request.
- A changed code file and related test or call site.
- One source-supported bug, integration mismatch, or missing focused validation.

Expected behavior:

- The sub-agent reconstructs requested behavior from the user request.
- Findings are limited to changed behavior and direct integrations.
- The sub-agent does not invent broad architecture concerns.

### Scenario D: Validation Output

Goal: verify the skill chooses `validation-output-review.md`.

Fixture contents:

- A task where the deliverable is tests, CI output, generated report, screenshot, log, or artifact.
- A validation artifact with one concrete defect, such as weak assertions, stale output, ignored failure, skipped test, or mismatch between claimed and actual report contents.

Expected behavior:

- The sub-agent reviews whether the validation proves the intended behavior.
- Findings cite the test, log, report, screenshot, or artifact path.
- Recommended checks are specific artifact inspections or commands.

## Phase 4: Forward-Test Prompts

Use fresh sub-agents with `fork_context: false`. Pass the skill path and a realistic user-like request. Do not include the intended findings.

Example prompt shape:

```text
Use $subagent-verify at C:\PyProjects\Agentic_Framework\.agents\skills\subagent-verify.

The main agent has just completed this task:
<scenario-specific user-like summary>

Use the artifacts under:
<scenario folder path>

Run the verification workflow the skill describes. Return the review output and any issues that would require the main agent to fix or recheck work.
```

Run one forward-test per scenario:

1. Plan-created scenario.
2. Plan-implementation scenario.
3. Code-change scenario.
4. Validation-output scenario.

Before starting each sub-agent, fill a route-specific evidence checklist. The prompt must include explicit pointers rather than only a scenario folder and summary.

Plan-created checklist:

- Repository root.
- User request.
- Plan path or inline plan source.
- Plan artifact path.
- Known repo pointers.
- Known constraints.
- Expected deliverable.

Plan-implementation checklist:

- Repository root.
- User request.
- Plan path.
- Changed file paths or explicit diff source.
- Validation commands already run and pass/fail status.
- Artifact paths, or `none`.
- Known constraints.
- Main-agent outcome.

Code-change checklist:

- Repository root.
- User request.
- Task outcome.
- Changed file paths or explicit diff source.
- Validation commands already run and pass/fail status.
- Artifact paths, or `none`.
- Known constraints.

Validation-output checklist:

- Repository root.
- User request.
- Task outcome.
- Validation files, commands, logs, reports, screenshots, or generated artifact paths.
- Claimed validation result.
- Known constraints.

## Phase 5: Evaluate Results

For each sub-agent result, record in `.agent/tmp/subagent-verify-tests/results.md`:

- Scenario name.
- Template route selected.
- Whether the prompt used pointers instead of copied large context.
- Whether the prompt filled every required pointer for the selected route.
- Findings returned.
- Whether the seeded issue from `evaluator-notes.md` was found.
- False positives or vague findings.
- Whether suggested checks were focused.
- Whether the output gives enough information for the main agent to fix and recheck.
- Skill file changes needed, if any.

## Phase 6: Apply Skill Improvements

1. Triage each failure as a skill defect, fixture defect, or acceptable limitation.
2. Patch only the relevant skill file or reference template.
3. Rerun the affected scenario after any substantial patch.
4. Keep successful fixtures and results in `.agent/tmp/` only while iterating.
5. Before deleting `.agent/tmp/subagent-verify-tests/`, ask the user whether to keep or remove the temporary fixtures and results.
6. If the user gives no cleanup preference, leave `.agent/tmp/subagent-verify-tests/` in place and report the path.

## Validation Commands

Run after editing skill files:

```powershell
python C:\Users\donat\.codex\skills\.system\skill-creator\scripts\quick_validate.py .agents\skills\subagent-verify
```

If the command fails because `yaml` is missing, record that official validation could not run and manually check:

- `SKILL.md` frontmatter contains only `name` and `description`.
- Skill folder name matches `name`.
- Reference paths named in `SKILL.md` exist.
- `agents/openai.yaml` still matches the skill purpose.

Optional structural checks:

```powershell
Get-ChildItem .agents\skills\subagent-verify -Recurse
Get-Content -Raw .agents\skills\subagent-verify\SKILL.md
```

## Acceptance Criteria

- Four scenario folders exist under `.agent/tmp/subagent-verify-tests/`.
- Each scenario maps to exactly one primary template route.
- Each scenario includes enough artifacts for a fresh sub-agent to inspect directly.
- `evaluator-notes.md` records each seeded issue, expected route, and minimum acceptable evidence before forward-tests run.
- No sub-agent prompt points to `evaluator-notes.md`.
- Forward-tests are run with `fork_context: false`.
- Results are recorded in `.agent/tmp/subagent-verify-tests/results.md`.
- Any skill changes are tied to concrete forward-test failures.
- If the validation-output route fails a forward-test because of insufficient template specificity, the relevant template is patched and that scenario is rerun.
- If any skill file is changed, official validation is run, or the missing dependency is explicitly recorded with manual validation results.
- If no skill files change, `results.md` records `not applicable: no skill files modified` for skill package validation.

## Risks and Fallbacks

- Risk: sub-agents may inherit too much context if spawned incorrectly.
  Fallback: always use `fork_context: false` and pass only scenario paths plus the skill path.

- Risk: fixtures may accidentally reveal expected findings.
  Fallback: keep expected results only in `evaluator-notes.md`, which must not be passed to sub-agents, and in `results.md` after each run.

- Risk: official validation fails because PyYAML is unavailable.
  Fallback: either install the dependency with approval or perform the manual checks listed above.

- Risk: forward-tests take longer than expected.
  Fallback: run one scenario first, patch the skill if needed, then continue with the remaining scenarios.
