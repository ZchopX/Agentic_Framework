# Repo Onboarding Prompt

You are preparing durable AI guidance for this repository.

Read facts first:
- Root `AGENTS.md`, if present.
- `README*`, `docs/**`, `.agents/PRD.md`, and active `.agents/plans/**`.
- Build, test, lint, package, dependency, Docker, and CI config files.
- Main entrypoints, key modules, and test layout.
- Recent git status and commits, if this is a git repo.

Use cocoindex semantic search before broad file reading when looking for code by concept, behavior, or feature area. Use `rg` for exact strings, filenames, config keys, and known symbols.

Create or update `AGENTS.md` with:
- Project purpose and current status.
- Actual tech stack and source-of-truth config files.
- Verified development, build, test, and lint commands.
- Compact repository map.
- Coding and testing conventions found in the repo.
- AI code discovery rules, including not committing `.cocoindex_code/` or `.serena/`.
- Key files future agents should read first.

Rules:
- Do not invent setup commands, architecture, dependencies, or conventions.
- Mark unverified commands as unverified.
- Put uncertain items under `Open Questions`.
- Keep `AGENTS.md` short enough to be read every session.
- Put longer discoveries in durable docs or `.agents/reports/repo-primer.md`.
