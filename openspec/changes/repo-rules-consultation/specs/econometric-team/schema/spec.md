## ADDED Requirements

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
