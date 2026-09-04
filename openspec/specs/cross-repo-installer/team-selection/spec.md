# cross-repo-installer/team-selection Specification

## Purpose

Defines how `install-agentic-framework.ps1` chooses which locked file set to install into a target repo, based on an upfront team choice between the plain programming setup and the econometric analysis team.

## Requirements

### Requirement: Installer asks which team to install
Running the installer without `-Team` and without `-Yes` SHALL prompt the user to choose between `Programming` and `Econometric` before any file copying happens. Running with `-Yes` and no `-Team` SHALL default to `Programming`. Running with `-Team` (interactively or with `-Yes`) SHALL use the given value without prompting.

#### Scenario: Interactive run without -Team prompts for a team
- **WHEN** the installer is run without `-Yes` and without `-Team`
- **THEN** it prompts the user to choose `Programming` or `Econometric` before installing any skill, agent, or schema files

#### Scenario: Non-interactive run without -Team defaults to Programming
- **WHEN** the installer is run with `-Yes` and no `-Team` argument
- **THEN** it proceeds as if `-Team Programming` were given, without prompting

#### Scenario: -Team suppresses the prompt
- **WHEN** the installer is run with `-Team Econometric` (with or without `-Yes`)
- **THEN** it does not prompt for a team choice and installs the econometric locked file set

### Requirement: Econometric team installs a locked file set beyond the skill picker
When `Econometric` is selected, the installer SHALL install, unconditionally and without listing them in the interactive skill picker: the seven `.claude/agents/econ-*.md` files, the seven `.agents/agents/econ-*.md` files, the `model-test-pipeline` skill, and a project-local copy of `openspec/schemas/econometric-verified/` at the target repo's `openspec/schemas/econometric-verified/`.

#### Scenario: Econometric run installs the econ agents and schema
- **WHEN** the installer completes with `Econometric` selected
- **THEN** the target repo has `.claude/agents/econ-*.md`, `.agents/agents/econ-*.md`, the `model-test-pipeline` skill, and `openspec/schemas/econometric-verified/`, and none of the econ agent or schema files appeared as choices in the skill picker

#### Scenario: Econometric run does not overwrite unrelated files already in .claude/agents/ or .agents/agents/
- **WHEN** the target repo already has a file in `.claude/agents/` or `.agents/agents/` that is not one of the seven `econ-*.md` files
- **THEN** an `Econometric` run leaves that file untouched

### Requirement: Programming team installs none of the econometric-only files
When `Programming` is selected, the installer SHALL NOT install `.claude/agents/econ-*.md`, `.agents/agents/econ-*.md`, the `model-test-pipeline` skill (unless explicitly picked in the skill picker), or `openspec/schemas/econometric-verified/`.

#### Scenario: Programming run has no econ agents or schema
- **WHEN** the installer completes with `Programming` selected and the user did not explicitly pick `model-test-pipeline` in the skill picker
- **THEN** the target repo has no `.claude/agents/econ-*.md`, no `.agents/agents/`, no `model-test-pipeline` skill, and no `openspec/schemas/econometric-verified/`

### Requirement: Default-schema prompt offers the schema matching the chosen team
The installer's final "set default schema" step SHALL offer `econometric-verified` as the schema to set when `Econometric` was selected and that schema was copied into the target repo this run; otherwise it SHALL offer `spec-driven-verified` as it does today.

#### Scenario: Econometric run offers econometric-verified as the default schema
- **WHEN** the installer runs with `Econometric` selected and `openspec/schemas/econometric-verified/` was installed into the target repo
- **THEN** the "set default schema" prompt offers `econometric-verified`, not `spec-driven-verified`

#### Scenario: Programming run keeps offering spec-driven-verified
- **WHEN** the installer runs with `Programming` selected
- **THEN** the "set default schema" prompt behaves exactly as before this change, offering `spec-driven-verified`
