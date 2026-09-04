## Purpose

Defines a CLI-agnostic canonical representation of the `econ-*` agent team so that Codex, not only Claude Code, has a usable copy of each role's persona, routing responsibility, and tool scope.

## ADDED Requirements

### Requirement: Canonical CLI-agnostic agent definitions exist
The system SHALL maintain one canonical Markdown file per `econ-*` role (`econ-ceo`, `econ-design`, `econ-package-scout`, `econ-estimation`, `econ-test-writer`, `econ-triage`, `econ-writer`) under `.agents/agents/`, containing the same persona, routing/ownership description, and tool scope as the corresponding `.claude/agents/econ-*.md` file.

#### Scenario: Every econ role has a canonical counterpart
- **WHEN** the seven files under `.claude/agents/econ-*.md` are listed
- **THEN** `.agents/agents/` contains a same-named `.md` file for each one

### Requirement: Canonical definitions use CLI-neutral model identifiers
Each file under `.agents/agents/econ-*.md` SHALL express its model assignment using a model name meaningful outside Claude Code (a Codex-equivalent identifier), not a bare Claude model name (`opus`/`sonnet`/`haiku`).

#### Scenario: Model field is not a Claude-only name
- **WHEN** the frontmatter (or equivalent metadata) of a `.agents/agents/econ-*.md` file is read
- **THEN** its model field does not contain a bare Claude model name and instead names a model a Codex user can act on

### Requirement: Codex is pointed at the canonical definitions
The repository's Codex-facing guidance (`AGENTS.md`) SHALL reference `.agents/agents/econ-*.md` as the source Codex uses to adopt each econ role's persona and routing responsibility, since Codex has no native subagent-dispatch mechanism equivalent to Claude Code's `Agent` tool.

#### Scenario: AGENTS.md documents the Codex path for the econ team
- **WHEN** `AGENTS.md`'s econometric analysis team section is read
- **THEN** it links to `.agents/agents/` alongside the existing `.claude/agents/` link, and states that Codex reads the former
