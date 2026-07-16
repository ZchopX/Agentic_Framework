# AI Code Discovery Startup Plan

## Feature Description

Create a small reusable startup workflow for preparing repositories to use AI code discovery tools without adding heavy files, copied plugins, or generated indexes to each repo.

The workflow should help a user verify that global tools are available, prepare a target repo for local indexes, and give AI agents a short onboarding prompt/template for creating repo-specific `AGENTS.md` guidance.

## User Value

- Avoid repeated full-repo rediscovery by AI agents.
- Keep per-repo footprint tiny.
- Keep cocoindex installation manual and global.
- Avoid stale copied Claude plugin or MCP integration files.
- Make new repo startup repeatable enough to run on this user's projects.

## In Scope

- Add a lightweight repo preparation script that:
  - checks for expected global tools;
  - warns when tools are missing;
  - verifies the target path is a git repository;
  - creates minimal `.agents` folders when needed;
  - adds local index paths to `.gitignore`;
  - runs repo-level cocoindex setup/index only if `ccc` exists;
  - prints next steps for Claude/Codex integration without installing anything.
- Add a temporary startup prompt/template for AI onboarding.
- Update `AGENTS-template.md` with a short AI code discovery section.
- Document the intended start sequence.

## Out of Scope

- Installing cocoindex, Serena, Claude, Codex, `rg`, or `ast-grep`.
- Copying cocoindex Claude plugin files into each repo.
- Creating or maintaining local MCP config files in each repo.
- Auto-generating final `AGENTS.md` content from PowerShell.
- Committing generated indexes such as `.cocoindex_code/`.
- Adding Zoekt, Sourcegraph, Aider repo-map, or other heavier search systems.
- Making Serena a required dependency in the first version.

## Existing Files To Read

- `.agents/templates/AGENTS-template.md`: update the existing project guidance template instead of creating a second standard.
- `.gitignore`: preserve existing ignores and avoid duplicate entries.
- `.agents/skills/repo-docs-bootstrap/SKILL.md`: align the onboarding prompt with existing durable-doc guidance.
- `.agents/skills/repo-primer/SKILL.md`: reuse existing repo priming expectations when asking AI to inspect a repo.

## New Files

- `.agents/scripts/prepare-ai-code-discovery.ps1`
  - The only script needed for now.
  - Checks global commands and prepares a target repo.
- `.agents/start/onboard-repo.prompt.md`
  - Short prompt an AI agent can use after repo preparation to draft or update `AGENTS.md`.
- `.agents/start/README.md`
  - Minimal start sequence and cleanup guidance.

## Updated Files

- `.agents/templates/AGENTS-template.md`
  - Add a compact `AI Code Discovery` section.
- `.gitignore`
  - Add ignored local tool/index paths for this framework repo if missing:
    - `.cocoindex_code/`
    - `.serena/`

## Key Decisions

- Use upstream integrations globally:
  - Codex uses `codex mcp add cocoindex-code -- ccc mcp`.
  - Claude uses upstream cocoindex skill/plugin or MCP setup outside target repos.
- Per-repo setup is limited to ignore entries, optional `.agents/start` prompt files, and generated local indexes.
- PowerShell does not invent repository facts. AI drafts `AGENTS.md` only after reading the target repo.
- Serena is optional in this plan. Add later only if symbol/reference workflows repeatedly waste tokens.

## Implementation Tasks

1. Create `.agents/start/onboard-repo.prompt.md`.
   - Include instructions to read README/docs/build files/tests/CI/main entrypoints.
   - Require facts only, no invented setup commands.
   - Keep final `AGENTS.md` short.
   - Put uncertain items under `Open Questions`.
   - Tell the agent to use cocoindex semantic search before broad file reading when available.

2. Create `.agents/start/README.md`.
   - Explain the startup sequence:
     - run prepare script;
     - run AI onboarding prompt;
     - review `AGENTS.md`;
     - delete `.agents/start` from the target repo if copied temporarily.
   - State that cocoindex installation is manual and out of scope.

3. Create `.agents/scripts/prepare-ai-code-discovery.ps1`.
   - Parameters:
     - `-TargetPath` defaulting to current directory.
     - `-SkipIndex` switch to avoid running `ccc index`.
     - `-Force` switch to overwrite existing startup files when explicitly requested.
   - Checks:
     - `git` exists;
     - target path exists;
     - target is inside a git worktree;
     - `ccc` exists;
     - `rg` exists;
     - optionally warn for `ast-grep`.
   - Repo root handling:
     - resolve the worktree root with `git -C <TargetPath> rev-parse --show-toplevel`;
     - perform all repo changes from that root, not from an arbitrary subdirectory;
     - run `ccc index` from that root.
   - Repo changes:
     - create `.agents/start` in target repo;
     - copy `onboard-repo.prompt.md` and `README.md`;
     - when a target startup file already exists and differs, warn and skip it by default;
     - overwrite differing startup files only when `-Force` is supplied;
     - add `.cocoindex_code/` and `.serena/` to target `.gitignore` if missing.
   - Conditional action:
     - if `ccc` exists and `-SkipIndex` is not set, run `ccc index` in target repo.
   - Output:
     - list installed/missing tools;
     - list files changed;
     - print manual global setup hints for missing tools;
     - print next prompt to run with an AI agent.

4. Update `.agents/templates/AGENTS-template.md`.
   - Add:
     - use cocoindex semantic search before broad file reads for conceptual code discovery;
     - use `rg` for exact strings, filenames, config keys, and known symbols;
     - do not commit `.cocoindex_code/` or `.serena/`;
     - keep durable discoveries in docs or `.agents/reports/repo-primer.md`.

5. Update root `.gitignore`.
   - Add `.cocoindex_code/` and `.serena/` if missing.
   - Preserve existing entries.

## Test Strategy

- No test framework needed.
- Use one PowerShell self-check path:
  - run the script against a temporary git repo;
  - confirm `.gitignore` entries are added once;
  - confirm `.agents/start` files are copied;
  - confirm missing `ccc` produces a warning instead of failure;
  - confirm `-SkipIndex` avoids running `ccc index`.

## Validation Commands

```powershell
# Syntax check
powershell -NoProfile -ExecutionPolicy Bypass -File .agents/scripts/prepare-ai-code-discovery.ps1 -TargetPath . -SkipIndex

# Manual temp-repo check
$tmp = Join-Path $env:TEMP "ai-discovery-check"
Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $tmp | Out-Null
git -C $tmp init
powershell -NoProfile -ExecutionPolicy Bypass -File .agents/scripts/prepare-ai-code-discovery.ps1 -TargetPath $tmp -SkipIndex
Get-Content "$tmp\.gitignore"
Get-ChildItem "$tmp\.agents\start"
```

## Acceptance Criteria

- [ ] The plan does not include cocoindex installation.
- [ ] The repo preparation script only warns about missing global tools.
- [ ] The script can be run against any target git repo.
- [ ] `.cocoindex_code/` and `.serena/` are ignored and not duplicated.
- [ ] Startup prompt exists and delegates repo-specific `AGENTS.md` creation to AI after reading repo facts.
- [ ] `AGENTS-template.md` includes a short AI code discovery section.
- [ ] No copied Claude plugin, copied cocoindex skill, or per-repo MCP config is introduced.

## Risks And Fallbacks

- Risk: `ccc index` command behavior changes.
  - Fallback: make indexing conditional and allow `-SkipIndex`; print manual command.
- Risk: target repo already has its own `.agents/start`.
  - Fallback: skip existing differing files and warn; allow replacement only with `-Force`.
- Risk: users mistake startup prompt for permanent docs.
  - Fallback: `README.md` states `.agents/start` is temporary and can be deleted after onboarding.
- Risk: Codex does not automatically choose MCP search.
  - Fallback: `AGENTS.md` guidance explicitly tells agents when to use semantic search.

## Stack Compatibility Notes

- Sources checked:
  - `.agents/templates/AGENTS-template.md`
  - `.agents/skills/feature-planner/SKILL.md`
  - `.agents/skills/repo-docs-bootstrap/SKILL.md`
- Compatibility:
  - Uses PowerShell, matching the current Windows workspace and user environment.
  - Adds no package manager, dependency, framework, runtime, or service.
- Existing alternatives considered:
  - Full installer script: rejected because the user will install cocoindex manually.
  - Auto-generated `AGENTS.md`: rejected because scripts cannot know repo-specific facts.
  - Vendored Claude plugin/skill: rejected because upstream global integration is smaller and less stale.
- ADR required: no.
