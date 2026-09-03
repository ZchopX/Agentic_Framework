# Idea: wire custom skills into OpenSpec's outputs

**Status:** Concept note from an explore-mode discussion. Not repo-specific, not an
implementation plan — no tasks, nothing scheduled. Capturing the hypothesis and
the evidence behind it for later reference, in any project.

## The end goal

Custom skills (verification, commit, priming, planning, etc.) currently re-derive
project facts from scratch on every invocation — e.g. a verification skill
"discovers the stack" by grepping/globbing the repo each time it runs, with no
guarantee it lands on the same answer twice, and no connection to what an
earlier planning step already assumed.

OpenSpec, once initialized in a repo, holds a single canonical copy of those
facts and makes them available via its CLI as JSON. The idea: retrofit skills to
read from OpenSpec's outputs instead of rediscovering the same information,
using this pattern:

```
1. Add a step: run the relevant `openspec ... --json` command (or read a file
   under openspec/)
2. Parse what comes back — stack/conventions from `context`, requirement text
   from specs/, task list from a change
3. Use that instead of re-deriving the same information from scratch
```

Available read surfaces (none of this is gated or proprietary — a CLI writing
JSON to stdout and a folder of markdown files):

```
openspec context --json                                  -> project background/stack
openspec status --change <name> --json                    -> artifact completion state
openspec instructions <artifact> --change <name> --json    -> files to read + rules
openspec show <name> --json                                -> full change contents
openspec/specs/**/*.md  (plain file reads)                 -> current truth about system behavior
```

This is portable by construction: identical mechanism in every repo that has
run `openspec init`, no per-project special-casing needed.

## What OpenSpec actually hardcodes (and what it doesn't)

Important distinction that shaped this idea — verified by reading the installed
`@fission-ai/openspec` package source directly, not assumed:

- **Process/state, yes.** The artifact graph (`schema.yaml`: `id`, `generates`,
  `requires`) plus a topological sort (Kahn's algorithm, ~150 lines,
  `core/artifact-graph/graph.js`) computes what's ready/blocked/done. "Done" for
  most artifacts = does the file exist; for `tasks`, checkbox counting
  (`- [ ]` vs `- [x]`). No content understanding anywhere in this layer.
- **Spec-doc consistency, yes — and this is the real engineering.**
  `core/specs-apply.js` (~930 lines) + structural rules in `validate.js`
  (~500 lines) mechanically merge a change's delta spec (ADDED/MODIFIED/REMOVED/
  RENAMED requirements) into the main `openspec/specs/` tree, so the record of
  "what the system does" doesn't quietly rot into stale hand-edited prose the
  way a hand-maintained `ARCHITECTURE.md`/`STATUS.md` can.
- **Semantic/implementation correctness, no.** No dependency parsing, no stack
  detection, no code-quality or compatibility checking anywhere in the CLI.
  That layer is 100% prose-driven by design, in OpenSpec exactly as much as in
  a hand-written skill — moving a review skill into OpenSpec's schema does not
  make its judgment more rigorous, only its *presence* enforceable (`status`
  won't report a change `all_done` until the artifact's file exists).
- **The concrete integration point for the "stack" problem specifically:**
  `openspec/config.yaml`'s `context` field (≤50KB, `project-config.js`) is a
  single source of truth for stack/conventions/domain knowledge, and every
  built-in workflow step (`propose`, `apply`, `archive`) is contractually
  required to read and apply it before acting. A retrofitted skill reading the
  same field gets the same answer every other step already gets — no
  rediscovery, no drift between what different skills assume about the project.

## Candidate retrofits (illustrative — pattern generalizes beyond these)

- **Verification-style review skill:** read `context` (or run `openspec context
  --json`) instead of an ad hoc "discover the stack" step.
- **Repo-orientation skill:** open with `openspec context --json` for the
  already-tracked half, then still do its own codebase walk for what OpenSpec
  doesn't cover (entrypoints, test layout, live git state).
- **Commit skill:** pull the change name / task list from `openspec show
  <name> --json` to ground the commit message in the actual proposal, instead
  of inferring intent from the diff alone.
- **Requirements/PRD-style skill:** could become a project-local schema
  artifact (`openspec schema init`) with its own `instruction:` field, so its
  presence is tracked by `status` like any other artifact — no fork of the
  OpenSpec CLI required, project-local schemas resolve with highest priority.

## Open questions for later

- Retrofit skills one at a time as needed, or design a portable "starter kit"
  (a project-local schema + a `config.yaml` convention + the retrofitted
  skills) meant to be dropped into any project at `openspec init` time?
- For a verification-style skill: is the goal the process gate (can't be
  reported done without the file existing) or genuine mechanical checking
  (e.g. real dependency-version validation)? These are different projects —
  OpenSpec's schema only ever gives you the former.
