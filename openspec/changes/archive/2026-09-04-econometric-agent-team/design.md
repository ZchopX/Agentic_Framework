## Context

See proposal.md - Why. This design covers how the `econometric-verified` schema and the CEO-led subagent team implement the gate and failure-routing behavior specified in `specs/econometric-team/schema` and `specs/econometric-team/orchestration`.

## Goals / Non-Goals

Goals: a working `econometric-verified` schema; seven subagent definitions with correct tool scopes; a CEO routing loop driven entirely by `openspec status --json`; a triage classification loop with a retry cap.

Non-goals (restated from proposal, plus one design-level exclusion): no Librarian role, no cross-repo packaging, no Orca integration, no causal/cross-section/ML-adjacent methods, and no persistence of retry counters across separate conversation sessions (see Decisions).

## Decisions

**Schema location.** Fork directly to this repo's own `openspec/schemas/econometric-verified/` via `openspec schema fork spec-driven-verified econometric-verified` (project-local, no global install). Alternative considered: `openspec-mod/openspec-schemas/econometric-verified/` synced to `%LOCALAPPDATA%\openspec\schemas\` the way `spec-driven-verified` is. Rejected on implementation: that mechanism is a *machine-global* install (verified via `openspec schema which spec-driven-verified` → resolves from `%LOCALAPPDATA%`, not from `openspec-mod/` directly), which would make this schema available to every repo on the machine — directly contradicting the "not a distributed/installable bundle" non-goal — and would require an unplanned task to add a second sync target to `sync-openspec-skills.ps1`. A project-local fork needs neither. `openspec/config.yaml`'s default schema is not changed; `econometric-verified` is opt-in via `--schema` per change, same as before.

**Subagent definition location.** `.claude/agents/econ-*.md`, one file per role (`econ-ceo`, `econ-design`, `econ-package-scout`, `econ-estimation`, `econ-test-writer`, `econ-triage`, `econ-writer`), each with YAML frontmatter setting `model` and allowed tools, per this repo's existing subagent-definition convention (`.claude/agents/*.md`).

**Tool scope per role** (least privilege, matched to each role's job):
| Role | Model | Tools |
|---|---|---|
| `econ-ceo` | opus | Read, Grep, Glob, Bash (openspec CLI only), Agent |
| `econ-design` | opus | Read, Grep, Glob, WebSearch, Write |
| `econ-package-scout` | sonnet | Read, WebSearch, Bash (package/version checks), Write |
| `econ-estimation` | sonnet | Read, Write, Edit, Bash (Python/R execution) |
| `econ-test-writer` | sonnet | Read, Write, Edit, Bash (run tests) |
| `econ-triage` | opus | Read, Grep, Bash (re-run failing tests), Write |
| `econ-writer` | sonnet | Read, Write |

**CEO routing loop.** On each user turn, the CEO runs `openspec status --change <name> --json`, picks the first artifact whose status is `ready` in chain order (`identification → package-selection → tasks/specs → implementation-notes → verification → report`), and invokes the specialist that owns that artifact via the `Agent` tool, passing that artifact's `openspec instructions <id> --change <name> --json` output as the specialist's brief. After the specialist returns, the CEO verifies the artifact file exists, re-runs `status`, and continues. No separate CEO-side state machine — OpenSpec status is the only source of truth for "what's next."

**Triage's interim loop is not itself a new artifact per cycle.** `econ-test-writer` runs diagnostic tests; on failure, the CEO invokes `econ-triage` directly (not gated by a status artifact, since a failed test doesn't correspond to a missing file) with the identification artifact, implementation-notes, code, and failure output. Triage's classification determines the next specialist invocation. Once tests pass, `econ-triage` (or the CEO, once tests are green) writes the `verification` artifact reflecting the final passing state and the resolution history.

**Retry-cap tracking is conversation-scoped, not persisted.** The CEO counts retries per stage in its own working context for the current conversation only; it does not write a retry counter to disk. Alternative considered: persisting retry counts in the `verification` artifact or a sidecar file. Rejected as unneeded infrastructure for a one-off, single-project team (non-goal) — if a conversation is interrupted mid-loop, the user restarting fresh is an acceptable reset of the counter, not a correctness bug, since the underlying artifacts (identification, implementation-notes) are still on disk and nothing is lost.

## Risks / Trade-offs

- [Conversation-scoped retry counter resets on session restart, allowing more than 3 real attempts across sessions] → Mitigation: acceptable per Decisions above; each individual session still caps at 3, and the artifacts persist so no work is lost or repeated blindly.
- [Bash-executed Python/R code carries the same execution risk as any Claude Code Bash use] → Mitigation: relies on this repo's existing tool-permission prompting; no additional sandboxing is introduced or required by this change.
- [`econ-triage` (Opus) is itself unverified — a misclassification routes a fix to the wrong specialist] → Mitigation: the retry cap bounds the cost of a wrong classification (max 3 attempts per stage before surfacing to the user); a dedicated verifier-of-the-verifier role was considered and rejected as unneeded weight for a one-off team.

## Migration Plan

Net-new; no existing schema, agents, or specs are modified. `spec-driven-verified` and this repo's default schema (`spec-driven`) are unaffected.

## Open Questions

- Exact `Bash` allowlist patterns for `econ-package-scout`/`econ-estimation`/`econ-test-writer` (e.g., which specific R/Python invocations are pre-approved vs. prompted) can be tuned during implementation without changing this design or the task breakdown.
