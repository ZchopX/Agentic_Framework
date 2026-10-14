## Context

See proposal.md - Why. Current state, from the files:

- `/opsx:propose` is the generated `openspec-propose` skill; `openspec update` regenerates it. What a repo can durably shape is the per-artifact `instruction` text in the schema, which the skill hands to the agent for each artifact. Nothing in either schema mentions repo rules.
- Two schemas exist. `spec-driven-verified` (programming) is staged in `openspec-mod/openspec-schemas/spec-driven-verified/` and deployed by `.agents/scripts/sync-openspec-skills.ps1` to `%LOCALAPPDATA%\openspec\schemas\`; the deployed copy is identical to the staged one apart from line endings, so the staged copy is the source. `econometric-verified` is project-local in `openspec/schemas/econometric-verified/` and reaches other repos through the installer, not the sync script. All schema, template, skill and spec files involved use LF.
- `econometric-verified` has no `design` artifact. Its design-like artifact is `identification`; it also has `package-selection`, `implementation-notes` and `report`, which are out of scope here.
- Both schemas' `verification` artifact tells the agent to invoke the `openspec-verify` skill, whose sub-agent prompt is built from the proposal, specs, design and tasks paths, so a reviewer is never told to look at repo rules.
- `.agents/templates/AGENTS-template.md` is copied into target repos by the installer (`Copy-DirectoryIfChanged` on `.agents/templates`); it does not edit a repo's existing AGENTS.md.

## Goals / Non-Goals

**Goals:**
- An agent writing a proposal, design or tasks consults the rules that match the change, applies them, and shows how.
- A repo opts in by having the AGENTS.md section; the schema stays generic and repo-agnostic.
- Verification can catch a violation of a cited rule.

**Non-Goals:**
- A repo's actual rules or its index (Second_Brain's AGENTS.md is a separate follow-up).
- `openspec/config.yaml`, the `specs`, `package-selection`, `implementation-notes` and `report` artifacts, `/opsx:apply`, and the installer.
- Mechanical enforcement: nothing parses the "Rules applied" statement; verification reviews it.

## Decisions

1. **The hook is the schema's artifact instructions.** Alternatives: `config.yaml` (per repo, and the owner wants it to stay technical) and the generated `openspec-propose` skill (overwritten by `openspec update`). Schema instructions are read at the moment each artifact is written, apply to every repo using the schema, and survive CLI updates.
2. **One generic step, same wording in both schemas.** Text added to the end of the `proposal`, `design` and `tasks` instructions in `spec-driven-verified`, and `proposal`, `identification` and `tasks` in `econometric-verified`:
   > Repo rules: if the repository's AGENTS.md has a "Repo rules" section, read in full every rule file whose "Applies when" condition matches this change. Treat each as a constraint on this artifact: let it shape the content, not just appear in it. End the artifact with a "Rules applied" section listing `<rule file> → <how it shaped this artifact>`, or `none apply: <why>`. If AGENTS.md has no "Repo rules" section, skip this step.
   `specs` is left out on purpose: behavior rules reach the specs through the proposal and design they derive from, and the owner scoped this to proposal, design and tasks. `identification` stands in for `design` in the econometric schema because it is where that schema decides how the work is done.
3. **"Rules applied" is a template slot, placed last.** Each of the three templates per schema ends with a `## Rules applied` section holding `- <rule file> → <how>` or `- none apply: <why>`. It goes last so the checkbox lines in `tasks.md` stay first; the apply phase tracks only `- [ ]` lines, and a plain-bullet trailing section is not one. A task verifies the task count is unchanged.
4. **Triggers are observable conditions.** The template section tells the author to write "Applies when" as a condition a reader can test against a change ("touches files under `<path>`", "adds or edits `<API or construct>`"), not a topic ("UI changes"). The vague form is how a rule gets skipped.
5. **Template section content and placement.** A `## Repo rules` section right after Project Overview, holding: the table `| Rule file | Summary | Applies when |`, and the requirement in consult-and-apply form: "Before writing a proposal, design or tasks, read every rule file whose 'Applies when' matches the change, constrain the artifact by it, and state in the artifact how it was applied (a 'Rules applied' section)." Putting the requirement in each repo's own AGENTS.md means the obligation is also visible to agents not using OpenSpec.
6. **Verification: schema line plus one skill line.** Each `verification` instruction, and each `verification.md` template (as a `### Rules Conformance` section), adds: "If the change's artifacts have a 'Rules applied' section, also confirm each cited rule was followed." That line alone reaches the main agent but not the reviewer sub-agent, whose prompt is built by the `openspec-verify` skill. So `openspec-mod/claude-skills/openspec-verify/SKILL.md` step 3 gets one clause: when building the review prompt, if any artifact has "Rules applied", add each cited rule file to "Artifacts to inspect" and "Known constraints". Alternative of no skill edit was rejected: the reviewer would never read the rule files. The same skill is synced to the Claude and Codex locations by the existing script.
7. **Deploy is the last task, with owner confirmation.** The staged schema and skill are copied by `sync-openspec-skills.ps1` (`-WhatIf`, then the real run), which writes outside the repo. `econometric-verified` needs no sync; it travels with the installer.
8. **No README edit.** `openspec-mod/README.md` describes mechanism and deploy commands, neither of which changes.

## Risks / Trade-offs

- [The agent writes "none apply" without checking] → The statement must give a reason, and verification reviews it; a repo can tighten triggers when a rule is missed.
- [A cited rule is only decoration in the artifact] → The wording asks that it shape the content; verification checks the implemented change against it, not just the citation.
- [Existing repos do not get the section] → Accepted; they copy it from the template when they want it, and without it nothing changes for them.
- [Staged and deployed schema drift] → The sync script is the only path to the deployed copy; the last task runs it.
- [The `tasks.md` trailing section confuses the apply phase] → Covered by the task-count check in tasks.md.

## Open Questions

- None that change the specs, approach or tasks.
