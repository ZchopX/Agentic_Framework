## Context

See proposal.md - Why. Two independent pieces ship together because the installer's econometric path is what actually delivers the Codex-facing agent files to other repos: `.agents/agents/econ-*.md` (specs/econometric-team/dual-cli-agents) and the installer's team-selection/locked-file logic (specs/cross-repo-installer/team-selection).

Relevant existing conventions this design reuses rather than reinvents:
- `.agents/skills/*` is this repo's existing pattern for a CLI-agnostic canonical source that gets distributed differently per CLI (symlinked into `.claude/skills/`, copied to `~/.agents/skills/` for Codex via `sync-openspec-skills.ps1`).
- `install-agentic-framework.ps1` already has `Copy-DirectoryIfChanged` (hash-diffed directory sync) and `Add-IgnoreLine` helpers, and already conditionally offers `spec-driven-verified` as the default schema based on whether it's installed.
- `openspec/schemas/econometric-verified/` is a project-local fork (not machine-global), per the original econ-team design's explicit rejection of a global install for this schema.

## Goals / Non-Goals

**Goals:**
- One canonical, CLI-neutral copy of each econ role's persona/routing/tool-scope that a Codex session can act on without Claude-specific frontmatter.
- Installer asks team once, upfront, and the rest of the run follows from that answer with no further econometric-specific prompts (the "locked" set is not user-picked).
- Default-schema offer tracks the team choice instead of always assuming `spec-driven-verified`.

**Non-Goals:**
- No general Codex subagent-dispatch mechanism - Codex has none, and building one is out of scope. `.agents/agents/econ-*.md` is documentation Codex is told to read and act on manually, not a Codex-executed routing engine.
- No change to `econ-*` behavior, the `econometric-verified` schema's artifact chain, or the CEO routing/failure-loop logic (specs/econometric-team/schema and /orchestration are unmodified).
- No machine-global installation of `econometric-verified` - it stays project-local in every repo it's installed into, same as in this repo.
- No third team option beyond Programming/Econometric in this change.

## Decisions

**`.agents/agents/` holds the canonical Codex-facing copies; `.claude/agents/` stays as Claude Code's actual discovery path.** Claude Code only auto-discovers subagents from `.claude/agents/*.md`, so that location can't move. Rather than making `.claude/agents/econ-*.md` a symlink farm pointing at `.agents/agents/` (the skills pattern), each pair is a plain, separately-maintained copy: the two files differ in their `model:` field (Claude model name vs. Codex-equivalent) and potentially in the Claude-only frontmatter fields (like `model:` and `tools:` values that only make sense inside Claude Code's tool-permission model), so a byte-identical symlink isn't correct here the way it is for a skill's `SKILL.md`. `.agents/agents/econ-*.md` is documented in AGENTS.md as the file Codex should read; keeping both under version control side by side means a future edit to one that isn't mirrored to the other is visible in a diff/review, rather than silently drifting behind a symlink that only ever points at one variant.

**Model-name mapping for `.agents/agents/`:** `opus` → `gpt-5.1-codex-max` (highest-reasoning tier, matches the roles - `econ-ceo`, `econ-design`, `econ-triage` - that get `opus` today), `sonnet` → `gpt-5.1-codex` (standard tier, matches the `sonnet` roles). This is a literal string substitution per role, decided once here rather than left as an open question, since it only affects file content and not the spec, approach, or task breakdown - if Codex's model lineup changes later, updating these strings is a content edit, not a re-design.

**Locked file set is code, not a picker entry.** The skill picker (`$tagged`/`$selected` in the current script) stays exactly as-is for the general skill list. The econometric locked set (7 `.claude/agents/econ-*.md`, 7 `.agents/agents/econ-*.md`, `model-test-pipeline`, `openspec/schemas/econometric-verified/`) is copied in a separate step gated only on `$Team -eq 'Econometric'`, using the existing `Copy-DirectoryIfChanged` helper for each. `model-test-pipeline` is force-added to `$selected` (same mechanism the script already uses to force-add `todo`) rather than removed from the picker's candidate list, so a programming-team user who wants it can still pick it manually - only its *default/automatic* inclusion is team-gated.

**`-Team` parameter, default `Programming` under `-Yes`.** Team can't be inferred from "what's already installed" the way skill selection is (that inference works because the picker's pre-ticked set doubles as prior state; team choice has no equivalent artifact to read back before this change ships one - e.g., an installed `.agents/agents/` marker). Adding a `-Team` parameter (`ValidateSet('Programming','Econometric')`) mirrors the existing `-Yes` switch's role: a non-interactive override for the same question. Defaulting `-Yes` with no `-Team` to `Programming` keeps existing non-interactive callers' behavior unchanged (no econ files, `spec-driven-verified` default), matching this repo's own use of the script as an update mechanism for non-econometric repos.

**Default-schema step keys off `$Team`, not a second `Test-Path` guess.** Today's step 10 checks whether `spec-driven-verified` is present under `%LOCALAPPDATA%\openspec\schemas\`. For `econometric-verified`, the equivalent check is whether this run's step 5b copy of `openspec/schemas/econometric-verified/` into the target repo succeeded (project-local, not `%LOCALAPPDATA%`) - so the branch is driven by `$Team -eq 'Econometric'` plus that copy's result, not a path probe. `Programming` team keeps today's exact `spec-driven-verified` check and prompt untouched.

## Risks / Trade-offs

- [Two hand-maintained copies of each econ role (`.claude/agents/` and `.agents/agents/`) can drift out of sync] → Mitigation: both files live in the same repo and PR; a follow-up could add a lint/test asserting the persona/routing prose (excluding the model line) matches, but that's not required for this change to be correct - accepted as manual-review risk for now, same as any other doc pair in this repo.
- [Codex has no enforcement that it actually reads `.agents/agents/econ-*.md` before acting as an econ role - unlike Claude Code's `Agent` tool, nothing structurally requires it] → Mitigation: this is inherent to Codex lacking subagent dispatch; AGENTS.md instructs it, which is the same mechanism this repo already relies on for all other Codex guidance.
- [`-Team` default of `Programming` under `-Yes` means an existing non-interactive econometric-repo caller that predates this change would silently stop getting econ-file updates unless it adds `-Team Econometric`] → Mitigation: no such caller exists yet (this is the first version of the script to have a team concept); documented in the script's header comment alongside the existing `-Yes` usage example.

## Migration Plan

Net-new files and an additive script change; no existing `.claude/agents/econ-*.md`, schema, or spec content is modified. Repos that already ran a prior version of the installer are unaffected until they re-run it, at which point they'll be prompted for a team (or default to `Programming` under `-Yes`) same as a fresh install.
