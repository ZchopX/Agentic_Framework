# econometric-team/orchestration Specification

## Purpose

Defines the CEO-led econometric subagent team's behavior: the single conversational entry point, the design-before-implementation gate, and the failure-classification loop that routes a failing model to the specialist who actually owns the fix.

## Requirements

### Requirement: CEO is the sole user-facing entry point
The user SHALL interact only with the CEO role; the CEO SHALL determine which specialist subagent to invoke next by reading `openspec status --change <name> --json` for the active change rather than tracking state itself.

#### Scenario: User request is routed without the user naming a specialist
- **WHEN** the user describes an econometric analysis request to the CEO
- **THEN** the CEO determines the next unblocked artifact from OpenSpec status and invokes the specialist responsible for producing it, without the user needing to name that specialist

### Requirement: Implementation is gated behind identification
No specialist SHALL produce the `package-selection`, `tasks`, or `implementation-notes` artifacts until the `identification` artifact is `done` for that change.

#### Scenario: Estimation cannot start before identification is complete
- **WHEN** the CEO is asked to proceed to model estimation for a change whose `identification` artifact is not yet `done`
- **THEN** the CEO invokes the design/identification specialist instead of the estimation specialist, and reports to the user that the identification gate is not yet satisfied

### Requirement: Triage classifies a failing model into exactly one root-cause category
When diagnostic tests fail for a change, a triage step SHALL read the `identification` artifact, the `implementation-notes` artifact, the implementation, and the failing test output, and SHALL classify the failure as exactly one of: `CODE_BUG` (implementation does not match `implementation-notes`), `SPEC_GAP` (implementation matches `implementation-notes` but a required technical element, such as a robust error specification, is missing from the spec), or `DESIGN_FLAW` (the identification strategy itself is inadequate).

#### Scenario: Code-level bug is routed back to estimation without reopening identification
- **WHEN** triage classifies a failure as `CODE_BUG`
- **THEN** the CEO routes back to the estimation specialist with the specific discrepancy, and the `identification` artifact is not reopened

#### Scenario: Spec gap is routed back to estimation with an addendum
- **WHEN** triage classifies a failure as `SPEC_GAP`
- **THEN** the CEO routes back to the estimation specialist with a spec addendum describing the missing technical element, and the `identification` artifact is not reopened

#### Scenario: Design flaw reopens the identification gate
- **WHEN** triage classifies a failure as `DESIGN_FLAW`
- **THEN** the CEO routes back to the design/identification specialist, and the `identification` gate is treated as unsatisfied until a revised `identification` artifact is produced

### Requirement: Failure loop is capped and surfaces to the user when exceeded
For a given change, the CEO SHALL cap automatic retries at a single stage (estimation, or identification via a `DESIGN_FLAW` reopen) to no more than 3 attempts before stopping the loop and reporting the unresolved failure to the user instead of continuing to route automatically.

#### Scenario: Retry cap is reached
- **WHEN** the same stage has failed and been retried 3 times without producing a passing result
- **THEN** the CEO stops routing automatically for that stage and reports the failure history to the user for a decision
