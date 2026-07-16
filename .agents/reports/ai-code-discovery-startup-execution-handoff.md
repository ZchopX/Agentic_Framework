# Execution Handoff

Plan: `.agents/plans/ai-code-discovery-startup.md`
User request: Implement the AI code discovery startup plan. Cocoindex installation is handled by the user and must not be scripted.
Final outcome: Implemented the lightweight repo preparation script, startup prompt, startup README, template guidance, and local ignore entries. After verification, added a warning path for installed but uninitialized cocoindex global settings.

## Plan Item Evidence

| Plan item | Status | Evidence |
|---|---|---|
| No cocoindex installation in plan implementation | done | `.agents/scripts/prepare-ai-code-discovery.ps1` only checks `ccc` and optionally runs `ccc index` |
| Script warns about missing global tools | done | `.agents/scripts/prepare-ai-code-discovery.ps1` tool check output |
| Script can target any git repo | done | `-TargetPath`, `git -C <TargetPath> rev-parse --show-toplevel` |
| Ignore `.cocoindex_code/` and `.serena/` without duplicates | done | `.gitignore`; `Add-IgnoreEntry` uses `-notcontains` |
| Startup prompt delegates repo-specific `AGENTS.md` creation to AI | done | `.agents/start/onboard-repo.prompt.md` |
| `AGENTS-template.md` includes AI code discovery rules | done | `.agents/templates/AGENTS-template.md` |
| No copied Claude plugin, cocoindex skill, or per-repo MCP config | done | no such files added |

## Changed Files

- `.agents/scripts/prepare-ai-code-discovery.ps1`: repo prep script, including missing/uninitialized cocoindex warnings.
- `.agents/start/onboard-repo.prompt.md`: AI onboarding prompt.
- `.agents/start/README.md`: startup sequence.
- `.agents/templates/AGENTS-template.md`: compact AI code discovery guidance.
- `.gitignore`: local index ignores.
- `.agents/reports/ai-code-discovery-startup-execution-handoff.md`: verification handoff.

## Validation Run

- `powershell -NoProfile -ExecutionPolicy Bypass -File .agents/scripts/prepare-ai-code-discovery.ps1 -TargetPath . -SkipIndex` - passed - detected `ccc` and `rg`, warned for optional missing `ast-grep`, skipped indexing.
- fresh temp git repo check - passed - copied startup files and added ignore entries.
- repeat temp repo check - passed - `.gitignore` entries were not duplicated.
- subagent verifier pass - passed - no required findings; suggested checking missing `ccc` and actual no-`-SkipIndex` behavior.
- temp repo with `ccc` removed from `PATH` - passed - warned about missing `ccc` and still prepared repo files.
- temp repo without `-SkipIndex` while cocoindex global settings were missing - passed after fix - warned to run `ccc init` and did not fail the repo prep.

## Deviations

- None.

## Risk Areas

- Actual `ccc index` execution remains untested until `ccc init` creates global settings.

## Follow-Up Pointers

- `.agents/plans/ai-code-discovery-startup.md`
