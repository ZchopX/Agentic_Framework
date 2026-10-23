# Handoff: Systemic map skill → `/opsx:propose`

Purpose: give a fresh session everything needed to run `openspec propose` without redoing the research. Written 2026-10-22 from a long research session. Work on a separate branch (suggested: `feat/systemic-map`). Facts below are from hands-on tests unless marked *opinion* or *untested*.

## 1. The problem (user's words, condensed)

AI does much of the manual work; the user cannot check it and does not know what was done or touched. They do not need minute detail. They need to know **how the system works** and **which parts were changed**.

Wanted:
- An **interactive zoomable map**, not a static picture: systems → subsystems → junctions/exceptions, navigable like a map of the earth (countries → cities → streets).
- A **text layer the AI reads and writes cheaply**, with an index/lists encoding dependencies. The text renders deterministically into the view, so the AI never generates visuals.
- Reuse existing tools where possible; decide how to glue them.

Answered scoping questions:
- Scope: **architecture plus behavior** (not just module structure).
- Source of truth: **hybrid with drift check** (auto-extracted skeleton + AI annotations + a check where map and code disagree).
- Viewer location: open to suggestions.
- Change view: **history over time AND highlight changed nodes per task**.

## 2. Architecture decided

```
code ──extractor──▶ skeleton (ids, paths, signature/body hashes, imports)
                          │
 AI ──CLI (only door)──▶ model (text in git: .map/*.yaml) ──▶ viewer (one generated HTML)
                          │
          checker (drift) ┘      touch log (who changed which node, per change name)
          git diff ──▶ node mapping ──▶ "changed" overlay
```

- **Model** = source of truth, text files in git. Facts (existence, imports, hashes, what changed) come from the **extractor**; meaning (purpose, invariants, error paths) from the **AI**. AI-declared edges are marked `declared` (dashed in viewer) until the extractor confirms them.
- **CLI is the AI's only read/write door.** No direct file edits of the model.
- **Viewer is generated**, never AI-authored.

### Node design
- Stable readable path-based IDs: `billing.invoice.retry`. Explicit `renamed_from` for renames.
- Fields: `parent`, `kind`, `summary` (≤200 chars), `paths` (globs), `deps: [{to, kind, errors}]`, `exceptions`, `verified_at`/`status`.
- Limits (*opinion*, partly experiment-backed): ≤10 children per node, depth ≤4, each file ≤~1,000 lines / 25 KB. Experiment used ≤5 children.
- Leaf-owns-paths / parent-owns-none rule caused a deadlock in the experiment: the CLI must allow the transition (see §5).

### CLI verbs (minimum)
`show <id> [--depth N] [--budget TOKENS]`, `neighbors <id>`, `find <path>`, `set`, `add`, `rm` (recursive), `move` (re-parent), `rename`, `touch <id> --change <name>`, `check`, `render`.

### Drift rules (`check`)
1. orphan annotation (node points at nothing)
2. undocumented code (code with no node)
3. stale (body hash differs from the one at `verified_at`)
4. unmapped file
5. edge drift (declared vs extracted imports)
6. *optional, advisory only*: LLM claim-drift (does the summary still match the code)

### Per-task highlighting
`git diff -U0` hunks → smallest enclosing symbol → path globs → nodes → ancestors marked "contains changes". Skeleton diff (base vs HEAD) gives added/removed nodes. Touch log adds the OpenSpec change name so the viewer can group by change.

## 3. Component choices and why

### Viewer: D3 canvas circle-pack (winner)
- True semantic zoom; open/closed state is a function of on-screen radius; smooth at 5,000 nodes.
- Weakness: layout ignores dependency edges; overview edge web must be capped (tested: top 70 edges).
- Possible later hybrid: circle-pack for the map + Cytoscape node-link panel for a selected region.
- **Rejected:** Cytoscape+fcose as the main view (40–265 ms per expand at 5,000 nodes, overlapping boxes). LikeC4 (DSL-only input, no continuous zoom, a 2,000-element build did not finish in 400 s, one 250-node view hung validation), but its read-only MCP and static output are fine as a cheap fallback.

### Extractor: DIY tree-sitter (winner for Python)
- ~120 lines, Python only, 2 s on 213 files, byte-identical output across runs. Rename/move detection by body hash.
- Known gaps: misses rename + body edit in one step. A class hash should be own-body + child hashes.
- **Graphify** (`graphifyy` on PyPI, double y; Graphify-Labs/graphify; Apache-2.0): deterministic, 29/30 edge precision on Python. But no hierarchy, no hashes, lossy slug IDs, 14 s on 40k LOC, ~1,560 open issues. Optional enrichment only.
- **grimp / import-linter**: use for the Python import graph and layer contracts.
- **Rejected:** GitNexus (PolyForm Noncommercial, flat binary DB). codebase-memory-mcp (could not run, Windows ACL on Temp). Understand-Anything (LLM-based, non-deterministic; design reference only).

### Closest existing tools (none reusable as a base; borrow ideas)
- **groma.md** (MIT): per-element Markdown format, 3 fixed C4 levels, polished 3D map. No drift check (left a ghost node after file deletion), `export` hung, CLI-only.
- **archik**: YAML `parentId`, unlimited depth, validate/drift (directory-level only), 27-tool MCP, suggest/accept workflow. No semantic zoom or overlay.
- **faultline**: best change overlay/timeline/replay, `check` exit code, MCP. Flat file, 2 levels, noisy diff.
- All missing: behavior/exception paths, junctions, low-noise history, drift that catches deleted/renamed files.

## 4. Evidence summary (what the research supports)

Supported:
- Content-anchored, validated, tool-mediated edits (line-number edits corrupted 99.1% of files after a one-line shift).
- Do not wrap text content in JSON.
- Readable IDs; small always-loaded context with detail behind links.
- Don't restate code-derivable facts (ETH study: LLM-generated context files slightly hurt; developer-written ones helped ~4%).
- **Never trust LLM-written dependency edges** (edge hallucination was the dominant failure).
- Per-node neighbor lists; incremental, not regenerative, updates; keep search alongside the map.

Not measured / unknown:
- YAML vs Markdown, depth/size caps.
- **Long-run rot of an agent-maintained map (central unknown).**
- Whether the map actually improves human oversight.
- The codebase-memory paper shows 0.83 vs 0.92 quality at ~10× fewer tokens: a trade-off, not a win.

## 5. Blind experiment results (small, Sonnet only, 124-node fictional system, 4 representations)

- ~65 of 68 runs at ceiling; 0 invented nodes/edges.
- CLI cut rename/move to **3 tool calls vs 16–17** for direct edits.
- Single 2,933-line JSON model was most expensive to read (78k tokens).
- **CLI flaws the proposal must fix:**
  - Whole-model validation blocked drift repair (37 rejected calls; agents created fake stub files). → Validate against a **baseline**: pre-existing problems are non-blocking, only new ones fail.
  - Missing verbs (e.g. removing a raise/exception).
  - Leaf-must-own-paths vs parent-must-not deadlock.
  - Errors must name file, field, and fix. No pressure to fake stub files.
  - One drift task failed from ambiguous wording (IDs vs file stems): keep node IDs distinct from file names in docs/prompts.

## 6. How the AI learns to use it (integration, verified against repo files)

Five layers; the full procedure lives only in the skill, never copied into consumers.

1. **`systemic-map` skill** at `.agents/skills/systemic-map/SKILL.md` holds the procedure. The installer discovers skills generically from `.agents/skills/*/SKILL.md`. With `-Yes` it only refreshes already-installed skills, so a new skill reaches other repos only via the interactive pick.
2. **AGENTS pointer** (3–5 lines) in [AGENTS-template.md](../templates/AGENTS-template.md): map pointer under "AI Code Discovery" (map answers "what is the structure and what changed"; cocoindex answers "where is this code"), one "Repo rules" row, one "Local Skills" row.
3. **Repo rule file** in `.agents/reference/` (ships with the installer, no installer change). "Applies when: `.map/` exists and the change touches mapped code." Read-only use in proposal/design: name affected nodes in Impact.
4. **OpenSpec wiring** (schema `spec-driven-verified`, file `openspec-mod/openspec-schemas/spec-driven-verified/schema.yaml`):
   - `tasks` instruction: final task "update the map: run `map check`, fix drift, `touch` with the change name", verified by "`map check` passes". A checkbox is the strongest in-flow mechanism because the apply skill treats `- [ ]` items as work.
   - `verification` instruction + `openspec-verify` skill (`openspec-mod/claude-skills/openspec-verify/SKILL.md`): run `map check`, confirm touched nodes have `touch` entries. Verify already passes cited rule files to its reviewer.
   - `openspec/config.yaml` `operations.apply.guidance` / `operations.archive.guidance`: short advisory lines only (backup). The apply skill calls guidance "prompt-level behavior contracts, not enforceable checks". *Untested:* whether `openspec instructions apply` actually surfaces `operationGuidance` here.
   - **Do not edit generated skills** (`openspec-apply-change` etc.); `openspec update` overwrites them (see [openspec-mod/README.md](../../openspec-mod/README.md)).
   - Every map instruction must be conditional on "if `.map/` exists": the schema is machine-wide (synced to `%LOCALAPPDATA%\openspec\schemas`).
5. **Enforcement**: the OpenSpec gate is soft (archive only warns). The only hard gate is git pre-commit/CI running `map check`, optionally a Claude Code stop hook. False positives must be avoidable via baseline + a documented bypass. **Open decision for the user** (§8).

Consumers:
- `repo-primer`: add step "if `.map/` exists, read root index (`map show root --depth 2`) for Architecture and Directory Map; offer to bootstrap if missing".
- `idea-critic` / `fix-validator` / `feature-planner`: read-only (`neighbors`, `find` for blast radius). Not opened this session; check before editing.
- `atomic-commit`: run `map check`. Not opened this session.

Facts about this repo:
- Installer: `.agents/scripts/install-agentic-framework.ps1`. It installs no Python dependencies, so the map CLI needs its own bootstrap (e.g. a script run with `uv`; tree-sitter + PyYAML). It refuses to run inside Agentic_Framework itself, so testing an install needs a second repo.
- `sync-openspec-skills.ps1` propagates `openspec-mod/` changes.
- This repo's own `AGENTS.md` has **no "Repo rules" section** (only the econ team block), so the rule mechanism only works in repos built from the template.
- `openspec/config.yaml` currently contains only `schema: spec-driven-verified` plus commented slots.
- `econometric-verified` schema has the same Repo rules lines; analysis code is a weak fit for a component map. Low priority.
- Installer-managed things (rule files, AGENTS rows, config guidance) are not handled by the installer today.

## 7. Recommended OpenSpec change split

The whole thing is too big for one change. Propose in this order; each is its own change and branch-sized:

1. **`systemic-map-core`** *(start here; this is the first `/opsx:propose`)*
   - Model schema + CLI (`show/neighbors/find/set/add/rm/move/rename/touch/check`) with baseline validation.
   - Python tree-sitter extractor (skeleton + hashes), drift checker, git-diff→node mapping.
   - Capability spec(s) under `openspec/specs/` (suggest `systemic-map-model`, `systemic-map-cli`, `systemic-map-drift`). Check existing layout first; the installer spec lives under `openspec/specs/cross-repo-installer/`.
   - Success measure: replay ~100 simulated sessions, count stale references and wrong edges (the central unknown is rot).
2. **`systemic-map-viewer`**: generated single HTML, D3 circle-pack, changed-node overlay, history by change name, edge cap.
3. **`systemic-map-wiring`**: skill, AGENTS template rows, rule file, schema `tasks`/`verification` text, `openspec-verify` edit, config guidance, repo-primer step, installer behavior, optional pre-commit hook. Modifies the schema and installer, so it is a separate, later change.

Keep non-goals explicit in the proposal: no non-Python extractors yet, no LLM claim-drift as a gate, no blocking hook by default, no Graphify dependency, no LikeC4.

## 8. Open questions to settle before/while proposing

1. Where does the skill live: `.agents/skills/systemic-map/` in this repo (recommended; installer picks it up) vs its own repo?
2. Hard commit-time gate (pre-commit/CI), or soft verification gate only? *User has not answered.*
3. Modeling of **exceptions and junctions**: how to represent them in the node/edge schema (not yet designed; the experiment only covered a `raise` list). Needs a design decision in `design.md`.
4. Model file layout: single file vs one file per node/subtree (single 2,933-line file was the costliest to read; per-subtree files recommended).
5. How the touch log is stored and merged across branches (append-only file vs per-change file).
6. Whether to also publish the research synthesis as a shareable page (not done).

## 9. Untested / risks to carry into design.md

- Long-run rot of agent-maintained annotations; behavior/exception/junction modeling; non-Python languages; viewer on real (not synthetic) data; whether humans actually oversee better with it.
- Experiment was Sonnet-only, tiny sample, and its "don't read the model directly" rule was not enforced.
- Windows specifics: `git clone` of groma failed on long paths; Playwright Chromium (118 MB) was installed to `%LOCALAPPDATA%\ms-playwright` during testing.

## 10. Reference material

- Full transcript: `C:\Users\donat\.claude\projects\C--PyProjects-Agentic-Framework\dfe5a4fa-a8f0-4f6e-9b1a-a6bbb971abee.jsonl`
- Prototype scratch (viewers `protoA.html`/`protoB.html`, `diy_extract.py`, `diff_map.py`, experiment kit `src/gen.py`/`smap.py`/`exp.py`, LikeC4 `yaml2c4.py`): `C:\Users\donat\AppData\Local\Temp\claude\C--PyProjects-Agentic-Framework\dfe5a4fa-a8f0-4f6e-9b1a-a6bbb971abee\scratchpad\r2-*`. Temp folder, copy anything worth keeping.
- Prior art for the Repo-rules mechanism: `openspec/changes/archive/2026-10-14-repo-rules-consultation/`.

## 11. Suggested prompt for the new session

> Read `.agents/plans/systemic-map-handoff.md`. Run `/opsx:propose systemic-map-core` using §2–§5 and §7 item 1. Resolve §8 questions 3–5 with me first. Do not write code.

## 12. Sources and full research record

This file is a condensed synthesis. The sourced evidence lives in:
- [systemic-map-research-appendix.md](systemic-map-research-appendix.md): per-claim sources with verification status, hands-on numbers, the round-1 vs round-2 reversals, and the experiment tables.
- [.agents/reports/systemic-map-research/](../reports/systemic-map-research/): the 11 subagent reports saved verbatim, plus the final message of each of 56 experiment runs.

Read the appendix before quoting a number in a spec. The `r2-*` scratch code and screenshots (~210 MB) remain only in the session temp folder; copy anything worth keeping.
