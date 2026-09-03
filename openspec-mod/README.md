# OpenSpec Verification Schema — Staged Files

This folder stages two files, built per `.agents/plans/openspec-verification-schema.md`,
to close a gap in OpenSpec's default `spec-driven` workflow: `opsx:apply` only checks
task boxes, and `opsx:archive` only checks that boxes are checked — there is no
independent-review step before archiving.

- `openspec-schemas/spec-driven-verified/` — a fork of the installed `spec-driven`
  schema with one added artifact, `verification`, gated on `tasks` being done.
- `claude-skills/openspec-verify/` — a new skill (adapted from `subagent-verify`,
  not an edit of it) that the `verification` artifact's instruction delegates to.

Nothing here is live until you run the copy commands below. This repo's own
`openspec/config.yaml` and change history are untouched by this plan.

## How it works

### The schema

OpenSpec's workflow is a dependency graph of "artifacts" (files an agent
produces), defined in a `schema.yaml`. The stock `spec-driven` schema has
four nodes: `proposal → {specs, design} → tasks`. `spec-driven-verified`
adds a fifth:

```
proposal → {specs, design} → tasks → verification
```

`verification` declares `requires: [tasks]`, so OpenSpec's artifact graph
won't mark it "ready" until `tasks` is done. It is deliberately **not**
added to the schema's top-level `apply:` block (`requires: [tasks]`,
unchanged from the stock schema), so it can never block implementation from
*starting* — only `tasks` gates `apply`, same as before the fork.

Once a repo's `openspec/config.yaml` sets `schema: spec-driven-verified` (or
a change is created with `--schema spec-driven-verified`), `openspec status
--change <name> --json` lists `verification` alongside the other four
artifacts. `openspec-archive-change`'s existing check — warn (non-blocking)
if any artifact is neither `done` nor `skipped` — already covers it
automatically; no change to that skill was needed for this to work, because
the check reads the *entire* artifact list from `status --json`, not a
hardcoded four.

### The skill

`verification`'s `instruction` field tells whichever agent reaches that
step not to write the file by hand, but to invoke the `openspec-verify`
skill. That skill (`claude-skills/openspec-verify/SKILL.md`) is a
standalone adaptation of `.agents/skills/subagent-verify/` — same
triage/fix/recheck loop, but speaking OpenSpec's CLI instead of
plan-executor's file conventions:

1. Resolves the change name, then runs `openspec status --change <name>
   --json` (for `changeRoot` and every artifact's `resolvedOutputPath` —
   the proposal/specs/design/tasks file locations) and `openspec
   instructions verification --change <name> --json` (for where to write
   the finished report). These two field names — `artifactPaths` and
   `resolvedOutputPath` — were confirmed against a live CLI run during
   implementation, not just documentation.
2. Always applies the `plan-implementation-review.md` lens (the artifact
   before `verification` is always `tasks`, i.e. "implemented work against
   a plan"), plus `user-facing-review.md` when the change touched a
   user-facing surface.
3. Runs a read-only sub-agent reviewer against those pointers, triages
   findings, fixes valid ones, reruns checks.
4. Writes the result into the change's own `verification.md` — never into
   `.agents/reports/`, which is `subagent-verify`'s territory, not this
   skill's.

The gate stays **soft**: nothing forces a `verification.md` to exist before
archiving succeeds, it only produces a warning via the existing
`openspec-archive-change` check. A hard block would require editing that
generated skill directly, which would be overwritten by `openspec update` —
an explicitly rejected design (see the plan's Decision 4).

### Where each agent actually looks for this

Promoting the skill is agent-specific — there is no single shared "global
skills" location:

| Agent | Where it looks (global/personal) | Source |
|---|---|---|
| Claude Code | `~/.claude/skills/<name>/` | Claude Code skill loading convention |
| Codex CLI | `$HOME/.agents/skills/<name>/`, plus `.agents/skills/` searched upward from cwd to repo root, plus `/etc/codex/skills` (system-wide) | [Codex CLI skill discovery docs](https://learn.chatgpt.com/docs/build-skills) |

Codex does **not** read `~/.claude/skills/`, and Claude Code does not read
`$HOME/.agents/skills/` or project-local `.agents/skills/` the way Codex
does. Promoting for one agent does not promote for the other — both copy
steps below are independent and both are needed if you want both agents to
be able to invoke `openspec-verify`. (This repo's other `openspec-*`
skills already live at project-local `.agents/skills/`, which Codex reads
directly without any global-copy step — that convention doesn't apply to
`openspec-verify` here because it isn't meant to ship as part of *this*
repo's own `.agents/skills/`, only as a promotable, portable skill for any
repo that adopts `spec-driven-verified`.)

## Automated sync

Instead of running the copy commands in steps 1-2 by hand, one script checks
all three destinations, compares each against this repo's staged copy by
content (SHA256, not just presence or timestamp), and installs/updates only
what's missing or different. Safe to re-run any time; a no-op run touches
nothing.

```powershell
powershell -ExecutionPolicy Bypass -File .agents\scripts\sync-openspec-skills.ps1
# or, if you have PowerShell 7:
pwsh -ExecutionPolicy Bypass -File .agents\scripts\sync-openspec-skills.ps1
```

If you downloaded this script directly (rather than `git clone`d the repo), run
`Unblock-File .agents\scripts\sync-openspec-skills.ps1` first to remove the
Mark-of-the-Web that would otherwise block it even with `-ExecutionPolicy Bypass`.

Add `-WhatIf` to preview what would change without writing anything, or
`-Targets Schema|Claude|Codex` to sync only one destination.

## 1. Promote the schema

Copy the schema fork to OpenSpec's user-level schema folder (Windows):

```powershell
Copy-Item -Recurse -Force `
  "openspec-mod\openspec-schemas\spec-driven-verified" `
  "$env:LOCALAPPDATA\openspec\schemas\spec-driven-verified"
```

## 2. Promote the skill

Copy the skill to Claude Code's global skills folder:

```powershell
Copy-Item -Recurse -Force `
  "openspec-mod\claude-skills\openspec-verify" `
  "$HOME\.claude\skills\openspec-verify"
```

If your Claude Code skills live somewhere else, confirm the actual path first —
check for an existing `~/.claude/skills/<some-skill>/` directory, or run
`claude --help` / consult your Claude Code settings for the configured skills
root, and copy there instead.

**For Codex**, copy the same folder to Codex's personal skills location
instead (a separate location — see "Where each agent actually looks for
this" above):

```powershell
Copy-Item -Recurse -Force `
  "openspec-mod\claude-skills\openspec-verify" `
  "$HOME\.agents\skills\openspec-verify"
```

Only run the copies for the agent(s) you actually use with OpenSpec.

## 3. Use the forked schema

**Make it a repo's default** — in that repo's `openspec/config.yaml`:

```yaml
schema: spec-driven-verified
```

**Or select it per-change:**

```bash
openspec new change <name> --schema spec-driven-verified
```

## 4. Verify the copy worked

```bash
openspec schema which spec-driven-verified --all
```

should list it as a `user` schema (not just `package`).

Then, on a scratch change:

```bash
openspec new change scratch-verify-check --schema spec-driven-verified
openspec status --change scratch-verify-check --json
```

`artifacts` in the status output should list 5 entries — `proposal`, `specs`,
`design`, `tasks`, `verification` — not 4. Delete the scratch change afterward.

## Non-goal

Nothing in `openspec-mod/` is live until you run the copy commands above by
hand. The verification artifact is a **soft gate**: `openspec-archive-change`
already warns (non-blocking) on any incomplete artifact, so an unfinished
`verification` artifact produces a warning at archive time, not a hard block.
