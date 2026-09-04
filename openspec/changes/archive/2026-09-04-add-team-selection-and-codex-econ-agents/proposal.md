## Why

The `econ-*` team currently only exists as Claude Code subagent definitions (`.claude/agents/econ-*.md`), so Codex CLI users get no equivalent. Separately, `install-agentic-framework.ps1` installs one fixed bundle into every target repo and always defaults the final "set default schema" prompt to `spec-driven-verified`, even for repos that only want the econometric team and its `econometric-verified` schema. Both gaps block using the econometric team outside this repo and outside Claude Code.

## What Changes

- Add a CLI-agnostic canonical copy of the seven `econ-*` agent definitions under `.agents/agents/econ-*.md`, with the `model:` frontmatter field translated to a Codex-equivalent model name (Claude model names are Claude-specific and meaningless to Codex) and the `tools:` field kept as-is where the tool names are generic enough for either CLI to interpret.
- `.claude/agents/econ-*.md` remain the files Claude Code actually discovers/invokes; `.agents/agents/econ-*.md` become the source of truth Codex reads (via AGENTS.md guidance, since Codex has no native subagent-dispatch mechanism equivalent to Claude Code's `Agent` tool).
- Rework `install-agentic-framework.ps1` to open by asking which team to install: **programming** or **econometric**.
  - **Programming**: current behavior (skill picker, no econ agents, no econ schema, no `model-test-pipeline` skill).
  - **Econometric**: additionally, unconditionally ("locked", not offered in the skill picker) installs the seven `.claude/agents/econ-*.md` and `.agents/agents/econ-*.md` files, the `model-test-pipeline` skill, and copies `openspec/schemas/econometric-verified/` into the target repo's `openspec/schemas/econometric-verified/` (project-local, matching how this repo hosts it - not a machine-global sync like `spec-driven-verified`).
- The existing "set default schema" prompt (currently hardcoded to offer `spec-driven-verified`) defaults its offered schema to `econometric-verified` when the econometric team was chosen (and only offers it once that schema has actually been copied into the target repo this run), otherwise keeps offering `spec-driven-verified` as today.
- `-Yes` non-interactive mode needs a `-Team` parameter (`Programming`/`Econometric`) since the team choice can no longer be inferred from "currently-installed skill set" the way skill selection is.

## Capabilities

### New Capabilities
- `econometric-team/dual-cli-agents`: canonical CLI-agnostic econ-* agent definitions exist and both Claude Code and Codex can be pointed at a usable copy.
- `cross-repo-installer/team-selection`: the installer asks which team to install and installs a different locked file set (and default-schema offer) per team.

### Modified Capabilities
(none - `econometric-team/schema` and `econometric-team/orchestration` behavior is unchanged; this only adds a second representation of the agents and a new distribution path)

## Impact

- `.agents/agents/` (new directory, 7 files)
- `.claude/agents/econ-*.md` (unchanged content, now documented as generated-from/mirrored-from `.agents/agents/`)
- `.agents/scripts/install-agentic-framework.ps1` (team-selection prompt, `-Team` param, conditional locked-file install, conditional default-schema offer)
- `.agents/scripts/tests/install-agentic-framework.*.Tests.ps1` (new/updated test cases for both team paths)
- `AGENTS.md` (pointer to `.agents/agents/` for Codex)
- `openspec/schemas/econometric-verified/` (unchanged; now also copied by the installer into target repos, project-local, when the econometric team is chosen)
