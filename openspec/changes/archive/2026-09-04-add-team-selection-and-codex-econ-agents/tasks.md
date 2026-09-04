## 1. Canonical Codex-facing econ agent files

- [x] 1.1 Create `.agents/agents/econ-ceo.md` through `.agents/agents/econ-writer.md` (7 files), copying persona/routing/tool-scope content from the corresponding `.claude/agents/econ-*.md`, and verify `.agents/agents/` has one same-named `.md` file per `.claude/agents/econ-*.md` file
- [x] 1.2 In each `.agents/agents/econ-*.md`, replace the `model:` value per design.md's mapping (`opus` → `gpt-5.1-codex-max`, `sonnet` → `gpt-5.1-codex`) and verify no file under `.agents/agents/econ-*.md` contains the literal strings `opus` or `sonnet`
- [x] 1.3 Update `AGENTS.md`'s "Econometric analysis team" section to add a link to `.agents/agents/` alongside the existing `.claude/agents/` link, stating Codex reads the former, and verify the section renders both links

## 2. Installer: team selection and locked file sets

- [x] 2.1 Add a `[ValidateSet('Programming','Econometric')][string]$Team = $null` parameter to `install-agentic-framework.ps1` and, when unset and `-Yes` is not passed, prompt the user to choose before any copy step runs; when unset and `-Yes` is passed, default to `Programming`. Verify by running the script interactively with no `-Team` and confirming the prompt appears before section 4 (OpenSpec init) executes
- [x] 2.2 Add an econometric locked-file copy step (gated on `$Team -eq 'Econometric'`) that uses `Copy-DirectoryIfChanged` to sync `.claude/agents/econ-*.md` and `.agents/agents/econ-*.md` from the cloned source into the target repo, and force-adds `model-test-pipeline` to `$selected` the same way `todo` is force-added today. Verify by running with `-Team Econometric -Yes` against a scratch target repo and confirming all 14 agent files and the `model-test-pipeline` skill are present
- [x] 2.3 Add a step copying `openspec/schemas/econometric-verified/` from the cloned source into the target repo's `openspec/schemas/econometric-verified/` (project-local, via `Copy-DirectoryIfChanged`), gated on `$Team -eq 'Econometric'`, and record its result (installed/updated/unchanged) in `$report`. Verify by running with `-Team Econometric -Yes` and confirming `openspec/schemas/econometric-verified/schema.yaml` exists in the target repo
- [x] 2.4 Verify a `-Team Programming` run (interactive and `-Yes`) installs none of: `.claude/agents/econ-*.md`, `.agents/agents/`, `openspec/schemas/econometric-verified/`, or an auto-added `model-test-pipeline` (manual pick of `model-test-pipeline` in the skill picker still works)

## 3. Installer: default-schema prompt follows team choice

- [x] 3.1 Update step 10 (default schema) so that when `$Team -eq 'Econometric'` and task 2.3's copy succeeded this run, it offers/sets `econometric-verified` instead of `spec-driven-verified` (same `ShouldContinue`/`-Yes` confirmation pattern as today), and verify by running `-Team Econometric -Yes` and inspecting the target repo's `openspec/config.yaml` for `schema: econometric-verified`
- [x] 3.2 Verify the `-Team Programming` path's step 10 is byte-for-byte unchanged in behavior (still checks/offers `spec-driven-verified`) by diffing the script's Programming-path output report against a pre-change run

## 4. Script header and tests

- [x] 4.1 Update the script's top-of-file comment block with a `-Team` usage example (mirroring the existing `-Yes` example) and verify the comment mentions both `Programming` and `Econometric`
- [x] 4.2 Add/update Pester cases in `.agents/scripts/tests/install-agentic-framework.Unit.Tests.ps1` and `.E2E.Tests.ps1` covering: interactive team prompt, `-Team Econometric -Yes` installs the locked set and schema, `-Team Programming -Yes` installs neither, and the default-schema branch for each team. Verify by running the existing Pester suite and confirming all new and pre-existing cases pass
