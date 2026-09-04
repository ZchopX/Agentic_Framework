# econometric-team/schema Specification

## Purpose

Defines the `econometric-verified` OpenSpec schema: a project-local artifact chain that structurally gates econometric analysis work so identification/design is always settled before implementation, and implementation is always verified before a result is reported.

## Requirements

### Requirement: Econometric-verified schema exists as an independent project-local schema
The system SHALL provide a project-local OpenSpec schema named `econometric-verified`, forked from `spec-driven-verified`, without modifying `spec-driven-verified` itself.

#### Scenario: Schema validates independently
- **WHEN** `openspec schema validate econometric-verified` is run
- **THEN** it reports the schema as valid, and `openspec schema validate spec-driven-verified` continues to report the pre-existing schema as valid and unchanged

### Requirement: Schema defines a gated artifact chain for econometric analysis
The `econometric-verified` schema SHALL define the artifact chain `proposal → identification → package-selection → specs/tasks → implementation-notes → verification → report`, where each artifact's `requires` edges block it until its dependencies exist.

#### Scenario: Identification is blocked until proposal exists
- **WHEN** a change using this schema has a `proposal` artifact but no `identification` artifact
- **THEN** `openspec status --change <name> --json` reports `identification` as `blocked` with `proposal` satisfied, and reports it `ready` once `proposal` is `done`

#### Scenario: Package-selection is blocked until identification exists
- **WHEN** a change has `identification` but not `package-selection`
- **THEN** `openspec status --change <name> --json` reports `package-selection` as `blocked` until `identification` is `done`, and `ready` afterward

#### Scenario: Implementation-notes is blocked until package-selection and tasks exist
- **WHEN** a change has `package-selection` and `tasks` but not `implementation-notes`
- **THEN** `openspec status --change <name> --json` reports `implementation-notes` as `blocked` until both dependencies are `done`, and `ready` afterward

#### Scenario: Verification is blocked until implementation-notes exists
- **WHEN** a change has `implementation-notes` but not `verification`
- **THEN** `openspec status --change <name> --json` reports `verification` as `blocked` until `implementation-notes` is `done`, and `ready` afterward

#### Scenario: Report is blocked until verification exists
- **WHEN** a change has `verification` but not `report`
- **THEN** `openspec status --change <name> --json` reports `report` as `blocked` until `verification` is `done`, and `ready` afterward
