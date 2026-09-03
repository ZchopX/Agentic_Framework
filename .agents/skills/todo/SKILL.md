---
name: todo
description: Show or update this repo's to-do.md backlog. Use when the user runs `/todo`, `/todo <anything>`, or in plain language asks to note something down for later, list open to-dos, mark one done, or see what's been finished in the past.
---

# Todo

## Goal
Keep one uniform, per-repo backlog file, always named exactly `to-do.md`, in the repo root. The user-facing surface is just `/todo` and `/todo <text>` — there is no subcommand syntax to remember. Everything below is how *you* (the agent) figure out what that text means and act on it; the user never has to phrase a request in a specific way.

## Storage format

The file must be named **exactly** `to-do.md` (hyphenated, lowercase) at the repo root — not `TODO.md`, `todo.md` without the hyphen, or any nested path. This spelling is load-bearing: always look for that literal filename.

Create it with this header if missing:

```md
# To-Do
```

Each entry is one line:

```md
- [ ] <text> (added YYYY-MM-DD)
```

Every line in the file is open by construction. Nothing is ever marked `- [x]` and left in place — a finished item's line is deleted, not flipped. This keeps the file self-bounding (it only ever holds however many things are currently undone) and keeps every read of it, by a person or by you, cheap: there's never unbounded historical cruft to scan past. Completed items are not lost — they live in git history (see below) — just not in the live file.

## Interpreting `/todo <text>`

There's one entry point with an argument; classify intent from the text itself before acting:

1. **A history/status question** ("what have we finished", "when did we add X", "show me completed items", "what did we do last month") → this is not answerable from `to-do.md` itself, since finished items are deleted from it. Run:
   ```bash
   git log -p -- to-do.md
   ```
   (narrow with `-n <count>` or `--since`/`--until` if the question implies a range). In the diff, a `-` line was removed (completed, or edited) and a `+` line was added. Answer the user's actual question from that, don't just dump the raw log. If `to-do.md` isn't tracked yet or has no commits, say so plainly instead of guessing.

2. **A reference to something already on the list, framed as finished** ("done with X", "X is fixed now", "remove the dark-mode item", "cross off Y") → find the open line matching that topic/intent (not necessarily exact wording). If exactly one line matches, delete it and confirm what was removed. If several could match, list them and ask which. If none match, say so — never delete an unrelated line on a guess.

3. **Anything else** → treat it as a new backlog item to add:
   - Compare it against every existing line for a likely duplicate (same topic/intent, not necessarily the same words).
   - If a close match exists, show it and ask whether to add anyway, skip, or merge into the existing line instead of creating a new one — don't add silently on top of an unresolved likely duplicate.
   - Otherwise append `- [ ] <text> (added <today's date>)` (creating the file with its header first if needed) and confirm what was added.

## `/todo` with no argument
If `to-do.md` doesn't exist, report the backlog is empty (don't create the file just to show it empty). Otherwise read and print it as-is — the whole file, since every line in it is by definition still open.

## Guardrails
- Never rewrite, reorder, or bulk-edit existing lines beyond the one add/delete the request calls for.
- Keep entries as single lines; don't invent categories, priority fields, or tags unless the user asks for them.
- Never mark a line `- [x]` as a resting state — completion always means deleting the line.
- Never create a second file (archive, log, backup) to hold completed items — `git log -p -- to-do.md` is the archive.
- This is a per-repo file: always resolve `to-do.md` relative to the current repo root, never a global/user-level path.
- If intent is genuinely ambiguous between "add this" and "mark this done," ask rather than guessing.
