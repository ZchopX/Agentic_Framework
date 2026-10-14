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

### Requirement: Schema directs the agent to consult and apply matching repo rules
The `econometric-verified` schema SHALL direct the agent, when it writes the `proposal`, `identification` and `tasks` artifacts, to follow the repository's AGENTS.md "Repo rules" section when one exists: read every rule file whose "Applies when" condition matches the change, treat each as a constraint on the artifact being written, and state in that artifact which rule was applied and how it shaped the content, or that no rule applies and why. The `verification` step SHALL check that every rule cited in those artifacts was followed. When the repository has no "Repo rules" section, the schema SHALL add no obligation and the artifacts SHALL be produced as before.

#### Scenario: Matching rule shapes the artifact
- **WHEN** an agent writes the `tasks` artifact for a change that matches a rule's "Applies when" condition
- **THEN** the artifact states that rule and how it constrains the tasks, and the tasks reflect it

#### Scenario: No rule matches
- **WHEN** an agent writes an artifact for a change that matches no rule's condition
- **THEN** the artifact states that no rule applies and why, instead of omitting the statement

#### Scenario: Repository has no Repo rules section
- **WHEN** the repository's AGENTS.md has no "Repo rules" section
- **THEN** the agent writes the artifacts exactly as before, with no consultation step and no "Rules applied" statement

#### Scenario: Verification checks cited rules
- **WHEN** an artifact cites a rule as applied and the implemented change violates it
- **THEN** the `verification` step reports that violation as a finding
