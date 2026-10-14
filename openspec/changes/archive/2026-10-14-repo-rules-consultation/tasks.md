## 1. AGENTS template

- [x] 1.1 Add a `## Repo rules` section to `.agents/templates/AGENTS-template.md` right after `## Project Overview`: the table `| Rule file | Summary | Applies when |` with one placeholder row, guidance that "Applies when" is an observable condition (touches files under a path, adds or edits a named API or construct) and not a topic, and the consult-and-apply requirement from design.md decision 5; verify with grep that the heading sits between Project Overview and Tech Stack and the three table columns and the words "constrain the artifact" are present

## 2. spec-driven-verified (staged source)

- [x] 2.1 In `openspec-mod/openspec-schemas/spec-driven-verified/schema.yaml`, append the generic Repo rules step (design.md decision 2) to the `proposal`, `design` and `tasks` instructions; verify with a Python YAML load that the file still parses and exactly those three instructions contain "Repo rules"
- [x] 2.2 Append a `## Rules applied` section (`- <rule file> → <how>` or `- none apply: <why>`) to the end of `templates/proposal.md`, `templates/design.md` and `templates/tasks.md` in that schema folder; verify each file ends with that section and `tasks.md` still starts with its checkbox group
- [x] 2.3 Add the conformance line to the `verification` instruction ("If the change's artifacts have a 'Rules applied' section, also confirm each cited rule was followed") and a `### Rules Conformance` section (`- <rule file> — <followed | violated: what>`, or `None cited`) to `templates/verification.md`; verify by YAML load and by reading the template

## 3. econometric-verified (project-local)

- [x] 3.1 In `openspec/schemas/econometric-verified/schema.yaml`, append the same Repo rules step to the `proposal`, `identification` and `tasks` instructions; verify by YAML load that exactly those three instructions contain "Repo rules"
- [x] 3.2 Append `## Rules applied` to the end of `templates/proposal.md`, `templates/identification.md` and `templates/tasks.md`, and the conformance line and `### Rules Conformance` section to the `verification` instruction and template; verify each template ends with its new section
- [x] 3.3 Verify with `openspec schema validate econometric-verified` that the schema is still valid

## 4. Skills

- [x] 4.1 Add "Repo rules section (index of rule files with 'Applies when' triggers) and its consult-and-apply requirement" to the "Template Must Cover" list in `.agents/skills/rules-template-author/SKILL.md`; verify with grep
- [x] 4.2 In `openspec-mod/claude-skills/openspec-verify/SKILL.md` step 3, add one clause: if any artifact has a "Rules applied" section, add each cited rule file to "Artifacts to inspect" and "Known constraints" so the reviewer checks the change against it; verify with grep and confirm no other line of the skill changed (`git diff`)

## 5. Spec and regression checks

- [x] 5.1 Run `openspec validate repo-rules-consultation --strict` and verify it passes
- [x] 5.2 Verify the trailing `## Rules applied` section does not change task tracking: record the task count from `openspec instructions apply --change repo-rules-consultation --json`, temporarily append `## Rules applied` with a plain bullet to this change's `tasks.md`, confirm the count is identical, then remove the section again

## 6. Deploy (needs owner confirmation first)

- [x] 6.1 Run `pwsh -File .agents\scripts\sync-openspec-skills.ps1 -WhatIf` and verify it lists only the `spec-driven-verified` schema and `openspec-verify` skill copies as changing
- [x] 6.2 Ask the owner to confirm, then run the sync script for real (it writes outside this repo); verify with `diff -r --strip-trailing-cr` that the deployed schema and skill match the staged ones, and that `openspec instructions proposal --change repo-rules-consultation --json` now contains the Repo rules step
