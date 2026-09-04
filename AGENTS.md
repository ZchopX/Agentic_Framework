# AGENTS.md

Root-level agent guidance for this repository. See [.agents/templates/AGENTS-template.md](.agents/templates/AGENTS-template.md) for the template this repo ships to install into other repos, and [.agents/skills/skills-usage-guide.md](.agents/skills/skills-usage-guide.md) for this repo's own skills.

## Econometric analysis team (`econ-*`)

A CEO-led team of subagents for panel-data and time-series econometric analysis, gated by a dedicated OpenSpec schema so identification/design is always settled before modeling, and a failed model is always routed to whoever actually owns the fix.

- **Entry point:** [.claude/agents/econ-ceo.md](.claude/agents/econ-ceo.md) - talk to this role; it routes to the rest of the team.
- **Team:** `econ-design`, `econ-package-scout`, `econ-estimation`, `econ-test-writer`, `econ-triage`, `econ-writer` under [.claude/agents/](.claude/agents/).
- **Codex:** Claude Code auto-discovers subagents from `.claude/agents/`; Codex has no equivalent dispatch mechanism, so the same seven roles are mirrored as CLI-agnostic Markdown under [.agents/agents/](.agents/agents/) (same persona/routing, Codex-equivalent model names instead of Claude model names). A Codex session should read the relevant file there and adopt that role directly rather than expecting a separate subagent to be invoked.
- **Schema:** [openspec/schemas/econometric-verified/schema.yaml](openspec/schemas/econometric-verified/schema.yaml) (project-local, not globally installed) - defines the gated artifact chain `proposal → identification → package-selection → specs/tasks → implementation-notes → verification → report`. Start an analysis with `openspec new change "<name>" --schema econometric-verified`.
- **Origin:** planned and built via [openspec/changes/archive/2026-09-04-econometric-agent-team/](openspec/changes/archive/2026-09-04-econometric-agent-team/) - see its `proposal.md` and `design.md` for scope, non-goals, and the decisions behind this layout. The team's behavior contract lives at [openspec/specs/econometric-team/](openspec/specs/econometric-team/).
