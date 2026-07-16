# AI Code Discovery Startup

This folder is temporary onboarding material for a repo.

## Sequence

1. Run `.agents/scripts/prepare-ai-code-discovery.ps1 -TargetPath <repo>`.
2. Ask an AI agent to follow `.agents/start/onboard-repo.prompt.md` in the target repo.
3. Review the generated or updated `AGENTS.md`.
4. Delete `.agents/start` from the target repo if you only needed it for setup.

Cocoindex installation is manual and out of scope. The prep script only checks for global tools, updates local ignore rules, copies these startup prompts, and runs `ccc index` when available unless `-SkipIndex` is used.
