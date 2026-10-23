# Handoff: Systemic map skill → `/opsx:propose`

Purpose: give a fresh session everything needed to run `openspec propose` without redoing the research. Written 2026-10-22, **updated 2026-10-23** with the explore-session decisions (§13 lists them; where §2–§8 conflict with §13, §13 wins). Work on branch `feat/systemic-map`. Facts below are from hands-on tests unless marked *opinion* or *untested*.

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
 AI ──direct edits + CLI──▶ model (text in git: .map/<area>.yaml) ──▶ viewer (one generated HTML)
                          │
          checker (drift) ┘      touch log (who changed which node, per change name)
          git diff ──▶ node mapping ──▶ "changed" overlay
```

- **Model** = source of truth, text files in git. Facts (existence, imports, hashes, what changed) come from the **extractor**; meaning (purpose, invariants, error paths) from the **AI**. AI-declared edges are marked `declared` (dashed in viewer) until the extractor confirms them.
- ~~CLI is the AI's only door.~~ **Superseded (§13.4):** AI may edit model files directly; the CLI handles cross-file ops and `check`/`fmt`. Both must work.
- **Viewer is generated**, never AI-authored.

### Node design
- ~~Path-based IDs~~ **Superseded (§13.2):** flat readable IDs (`invoice-retry`) plus a `parent` field. Explicit `renamed_from` for renames.
- Fields: `parent`, `kind`, `summary` (≤200 chars), `paths` (globs), `deps: [{to, kind, errors}]`, `exceptions` (classed, §13.3), `trust` (extracted/anchored/declared, §13.5), `anchors`, `status`. Content hashes live in a sidecar (§13.6), not `verified_at: <commit>`.
- Limits (*opinion*, partly experiment-backed): ≤10 children per node, depth ≤4, each file ≤~1,000 lines / 25 KB. Experiment used ≤5 children.
- Leaf-owns-paths / parent-owns-none rule caused a deadlock in the experiment: the CLI must allow the transition (see §5).

### CLI verbs (minimum)
`show <id> [--depth N] [--budget TOKENS]`, `neighbors <id>`, `find <path>`, `set`, `add`, `rm` (recursive), `move` (re-parent / cross-file), `rename` (rewrites inbound edges), `touch <id> --change <name>`, `check`, `fmt` (canonical rewrite so direct edits cause no diff noise), `scan` (run planned scanners), `render`.

### Drift rules (`check`)
1. orphan annotation (node points at nothing)
2. undocumented code (code with no node)
3. stale (body hash differs from the one at `verified_at`)
4. unmapped file
5. edge drift (declared vs extracted imports)
6. unscanned language (a language is present that the scanner plan does not cover)
7. stale anchor (a quoted text anchor no longer found in its file)
8. *optional, advisory only*: LLM claim-drift (does the summary still match the code)

### Per-task highlighting
`git diff -U0` hunks → smallest enclosing symbol → path globs → nodes → ancestors marked "contains changes". Skeleton diff (base vs HEAD) gives added/removed nodes. Touch log adds the OpenSpec change name so the viewer can group by change.

## 3. Component choices and why

### Viewer: D3 canvas circle-pack (winner)
- True semantic zoom; open/closed state is a function of on-screen radius; smooth at 5,000 nodes.
- Weakness: layout ignores dependency edges; overview edge web must be capped (tested: top 70 edges).
- Possible later hybrid: circle-pack for the map + Cytoscape node-link panel for a selected region.
- **Rejected:** Cytoscape+fcose as the main view (40–265 ms per expand at 5,000 nodes, overlapping boxes). LikeC4 (DSL-only input, no continuous zoom, a 2,000-element build did not finish in 400 s, one 250-node view hung validation), but its read-only MCP and static output are fine as a cheap fallback.

### Extractor: per-language scanners (see §13.1 for the multi-language plan; this is the Python part)
### Python: DIY tree-sitter (winner for Python)
- ~120 lines, Python only, 2 s on 213 files, byte-identical output across runs. Rename/move detection by body hash.
- Python stdlib `ast` also works with zero install and gives exact `raise`/`except`; choose between it and tree-sitter in design.
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
   - Model schema (flat IDs, parent, classed exceptions, derived seams, trust levels, area files) + CLI (`show/neighbors/find/set/add/rm/move/rename/touch/check/fmt/scan`) with baseline validation.
   - Scanner registry + census + saved scanner plan (`.map/scanners.yaml`), scanners for Python, PowerShell, JS, HTML, Rust (default tier), mention scan; common skeleton output format (§13.1).
   - Drift checker, git-diff→node mapping, multi-source change record (§13.7).
   - Capability spec(s) under `openspec/specs/` (suggest `systemic-map-model`, `systemic-map-cli`, `systemic-map-drift`). Check existing layout first; the installer spec lives under `openspec/specs/cross-repo-installer/`.
   - Success measure: replay ~100 simulated sessions, count stale references and wrong edges (the central unknown is rot).
2. **`systemic-map-viewer`**: generated single HTML, D3 circle-pack, changed-node overlay, history by change name, edge cap.
3. **`systemic-map-wiring`**: skill, AGENTS template rows, rule file, schema `tasks`/`verification` text, `openspec-verify` edit, config guidance, repo-primer step, installer behavior, optional pre-commit hook. Modifies the schema and installer, so it is a separate, later change.

Keep non-goals explicit in the proposal: no LLM claim-drift as a gate, no blocking hook by default, no Graphify dependency, no LikeC4, no SCIP/rust-analyzer by default (opt-in tier), no AI-chosen installs outside the vetted list. (Earlier "no non-Python extractors" is dropped, see §13.1.)

## 8. Open questions to settle before/while proposing

1. Where does the skill live: `.agents/skills/systemic-map/` in this repo (recommended; installer picks it up) vs its own repo?
2. Hard commit-time gate (pre-commit/CI), or soft verification gate only? *User has not answered.*
3. ~~Exceptions and junctions modeling~~ **Decided in direction, §13.3.** (Correction: the experiment covered more than a `raise` list: leaf `raises`, an exception registry, edge `errors` sets and handling enums.) Details still for `design.md`.
4. ~~File layout~~ **Decided: files by area, §13.2.**
5. ~~Touch log storage~~ **Decided: multi-source, §13.7.**
6. Whether to also publish the research synthesis as a shareable page (not done).

Still open after §13: see §13.8.

## 9. Untested / risks to carry into design.md

- Long-run rot of agent-maintained annotations; behavior/exception/junction modeling; non-Python languages; viewer on real (not synthetic) data; whether humans actually oversee better with it.
- Experiment was Sonnet-only, tiny sample, and its "don't read the model directly" rule was not enforced.
- Windows specifics: `git clone` of groma failed on long paths; Playwright Chromium (118 MB) was installed to `%LOCALAPPDATA%\ms-playwright` during testing.

## 10. Reference material

- Full transcript: `C:\Users\donat\.claude\projects\C--PyProjects-Agentic-Framework\dfe5a4fa-a8f0-4f6e-9b1a-a6bbb971abee.jsonl`
- Prototype scratch (viewers `protoA.html`/`protoB.html`, `diy_extract.py`, `diff_map.py`, experiment kit `src/gen.py`/`smap.py`/`exp.py`, LikeC4 `yaml2c4.py`): `C:\Users\donat\AppData\Local\Temp\claude\C--PyProjects-Agentic-Framework\dfe5a4fa-a8f0-4f6e-9b1a-a6bbb971abee\scratchpad\r2-*`. Temp folder, copy anything worth keeping.
- Prior art for the Repo-rules mechanism: `openspec/changes/archive/2026-10-14-repo-rules-consultation/`.

## 11. Suggested prompt for the new session

> Read `.agents/plans/systemic-map-handoff.md` (§13 overrides earlier sections). Run `/opsx:propose systemic-map-core` using §2–§5, §7 item 1 and §13. Settle the §13.8 open items with me first. Do not write code.

## 12. Sources and full research record

This file is a condensed synthesis. The sourced evidence lives in:
- [systemic-map-research-appendix.md](systemic-map-research-appendix.md): per-claim sources with verification status, hands-on numbers, the round-1 vs round-2 reversals, and the experiment tables.
- [.agents/reports/systemic-map-research/](../reports/systemic-map-research/): the 11 subagent reports saved verbatim, plus the final message of each of 56 experiment runs.

Read the appendix before quoting a number in a spec. The `r2-*` scratch code and screenshots (~210 MB) remain only in the session temp folder; copy anything worth keeping.

## 13. Explore-session decisions (2026-10-23): these override §2–§8 where they conflict

Reached in `/opsx:explore` with the user. Hands-on probe results are marked (tested).

### 13.1 Multi-language scanning + text anchors: do BOTH
User languages: Python, Rust, HTML, JS, PowerShell, maybe others. This repo is mostly prompts/schemas (Markdown 172 files, vendored XML schema 39, Python 38 mostly vendored, YAML 17, PowerShell 6, JSON 6, HTML 2, JS 2), so a Python-only extractor sees almost nothing here.

Flow:
```
scc census -> AI reads census + manifests -> PROPOSED scanner plan -> human approves installs
          -> .map/scanners.yaml (committed data) -> scanners run deterministically
```
- The AI step runs once and its output is saved as data, so later runs are repeatable. A static extension->scanner table needs no AI; the AI adds value for ignoring vendored/generated/historical dirs (`plans/`, `reports/`, vendored schemas), unusual languages and granularity.
- **Supply chain:** AI picks only from a vetted registry with pinned versions/checksums; anything else is proposed to the human, never installed (graphifyy typosquat precedent).
- Scanners emit one common skeleton format.
- Drift rule "unscanned language" flags a new language with no scanner.

Per-language tool results (tested unless noted):

| Language | Tool | Result | Cost |
|---|---|---|---|
| PowerShell | native `[System.Management.Automation.Language.Parser]::ParseFile` | 0 parse errors on the installer: 9 functions with ranges, 4 throw (149,169,262,447), 3 exit (211,218,253), 7 try (1 with catch), 3 Write-Error, command-call counts, external commands (git, npm, openspec, robocopy) | none (pwsh 7.6.8) |
| Python | stdlib `ast` + grimp | exact raise/except (known, not re-tested) | none |
| JavaScript | dependency-cruiser 18.7.0 | resolved import, dynamic import(), require, node core; **madge 8.0.0 silently missed a `require`** in a mixed ESM/CJS file. es-module-lexer / oxc-parser installed, not exercised. JS throw extraction untested | Node |
| HTML | stdlib `html.parser` | all link/script/a/img refs | none |
| Rust | tree-sitter (use/mod/fn/`panic!`/`?`) + `cargo metadata --no-deps` (crate graph <1 s, no linker) | works. Opt-in tier: `rust-analyzer scip` gives exact cross-file refs (56 s cold start on 3 files, 5 KB index). SCIP CLI has no Windows asset (decode needed own protobuf reader). cargo-modules has no prebuilt release (untested) | toolchain 637 MB; MSVC link failed on this machine (irrelevant for analysis) |
| Markdown/YAML/other | mention scan (full paths + distinctive names) | 355 candidate edges over 170 tracked text files (132 path, 223 name). Eyeballed 14: 6 real dependencies, 2 containment, 1 ambiguous basename, 5 historical-doc mentions. **Precision not measured.** | none |
| Census | `scc` 4.1.0 | whole-repo language table in one call. tokei v15 exists (not run); github-linguist needs Ruby | tiny exe |
| Universal fallback | `tree-sitter-language-pack` 1.22.1 (MIT, 372 langs) | Python/Rust imports+structure OK; HTML 0 refs; **PowerShell fails (3 parse errors, 0 symbols)**. Parsers download on first use (20 s, then ~0.4 s; 26 MB cache in `%LOCALAPPDATA%`), so CI/offline needs prefetch | Python pkg 5.7 MB |

Limits: `& $syncScript` (dynamic path built from variables, installer lines 505-508) can't be resolved by AST; the mention scan catches it by file name. Prior art: groma has scanner plugins (TS, JS, Angular, React, Vue, C#, Go, Java, Python, Rust, PHP, Swift + experimental) but **none for PowerShell or HTML**.

Default Rust tier: tree-sitter + `cargo metadata`; SCIP opt-in.

### 13.2 IDs and file layout
- **Flat readable IDs + `parent` field** (user decision). Move within an area changes only `parent`; across areas moves the record between files; edges elsewhere untouched. Collisions: tool suggests alternatives. Rename still rewrites inbound edges (rare).
- **Files separated by area** (one file per top-level area). id->file index derived at load, not stored.

### 13.3 Exceptions and junctions
- **Exception classes**, not just types (installer example): ABORT (exit 1; lines 211, 218, 253), THROW (clone try at line 258 has only `finally`, line 584; script dies with no summary), DEGRADE (note added to `$report`, continue: npm install, `openspec init`, cocoindex at line 535).
- **Junction = a seam between parts** (user decision), not a branch point. Mostly derived: roll up all edges crossing a subtree boundary (count, kinds, error types); optional AI note on the contract. Branch points inside flows (team selection lines 224-245; openspec/npm/consent 267-290) are modeled as flow steps, not junctions.
- Flow steps must follow existing dependency edges, so the AI cannot invent edges.

### 13.4 Who edits the model: BOTH (user decision)
AI may edit files directly (experiment: direct edits scored 100%; the CLI saved calls, 3 vs 16-17, but caused all the flaws). The CLI is required to work too: it owns cross-file ops (`rename`, `move`, `rm`), `fmt`, `check`. `check` is the referee for both. Skill rule: prose by hand, structural ops through the CLI.

### 13.5 Trust levels (how scanners and text anchors combine)
- **extracted**: a scanner saw it (highest).
- **anchored**: AI claim quoting a short distinctive string + file (e.g. `"git clone failed for"`); checker greps it; missing = stale.
- **declared**: AI claim, unchecked (lowest).
A scanner is never overridden by the AI; a claim is promoted to extracted when a scanner confirms it. Viewer draws the three differently (declared = dashed). Anchors are content-based, which matches the evidence for content-anchored edits.

### 13.6 Anchors and state
Use **content hashes**, not commit SHAs (`verified_at: <commit>` dies on squash/rebase). Keep machine state (hashes) in a sidecar to avoid diff churn.

### 13.7 Change record: all sources (user decision)
- Commits: `git diff` -> nodes while the range exists; optional `Map-Change: <name>` trailer.
- OpenSpec change: the *why* (proposal/design/tasks); survives archive.
- **Snapshot `map-touch.json`** inside `openspec/changes/<name>/`: CLI-computed touched nodes + one AI narrative line. (tested, openspec 1.11.0, stock `spec-driven` schema, throwaway repo): `openspec validate` -> valid, `openspec status` OK, `openspec archive <name> -y` moved the file into `archive/2026-10-23-<name>/` with the change. Join key = change name with date prefix stripped. **Not tested** with `spec-driven-verified` or the generated `openspec-archive-change` skill.
- Fallback for non-OpenSpec work: `.map/touches/<branch>.json`.
- Squash/rebase loses the diff range, hence the stored snapshot.

### 13.8 Decisions on the former open questions (user answers, 2026-10-23)

| # | Question | Answer |
|---|---|---|
| 1 | Scanner step shape | **Accepted**: census -> AI proposes plan from vetted registry -> human approves installs -> saved as `.map/scanners.yaml`. |
| 2 | Rust depth | Slow cold start is acceptable, so `rust-analyzer scip` may be on by default when a repo has Rust (one-time approval of the ~637 MB toolchain). Fallback stays tree-sitter + `cargo metadata`. |
| 3 | Skill location | `.agents/skills/systemic-map/` in this repo for now; move to a separate repo (pulled from there) if it grows too big. |
| 4 | Enforcement | Explained, **not yet decided**. Options: soft only / pre-commit warning / CI blocking / pre-commit blocking. Leaning: warn first, CI blocking after the replay harness shows a low false-positive rate. The new OpenSpec schema must do everything it can to make the AI follow the skill and build the map (see 13.10). |
| 5 | Research synthesis | Meant as an input to the build process, not a publication. Any visual rendering should be a human-readable scheme. No separate shareable page is required. |
| 6 | Seam storage | **Open, needs deeper research.** Constraint: a separate `seams.yaml` is rejected as likely to be ignored by the AI; prefer integration into OpenSpec (plus hooks if needed) or a better option. See 13.11. |
| 7 | Formats (`scanners.yaml`, skeleton) | Study available material on the web and pick the best; do not invent. |
| 8 | Python extractor | Use both `ast` and tree-sitter unless they conflict. Rule: `ast` wins for exceptions, tree-sitter for hashes. Start with `ast`; add tree-sitter when justified. |
| 9 | Snapshot with `spec-driven-verified` | Test during the build. |
| 10 | Mention-scan precision | Develop and measure cleanly during the build (label ~50 sampled edges). |
| 11 | JS `throw` extraction | Test during the build. |
| 12 | `tokei` vs `scc` | Test during the build. |
| 13 | `operationGuidance` surfacing | **Must be tested** (throwaway repo: add a guidance line, run `openspec instructions apply`). |
| 14-16 | Rot, human oversight, consumer skills | Risks accepted; observe during the build. |

### 13.10 Requirement: the new OpenSpec schema enforces the skill
The schema (and its `tasks`, `verification` instructions, `openspec-verify`, config guidance) must do everything possible to make the AI follow the systemic-map skill and keep the map current. The mechanisms are soft (a checkbox task, a verification step, guidance lines) unless a git/CI gate is added; the enforcement level (item 4) is still to be chosen. Every map instruction stays conditional on `.map/` existing.

### 13.11 Seam storage: research brief
Seam facts are derived (edges crossing a boundary). Only the optional *contract note* needs a home. Candidate to investigate first: express the contract as an OpenSpec requirement in `openspec/specs/<capability>/spec.md`, so delta specs, verify and archive already cover it, and the map links the seam to that requirement. Other candidates: a note on one node, derived-only. Decide in `design.md`.

### 13.9 Cleanup note
Probes left a 26 MB tree-sitter parser cache in `%LOCALAPPDATA%\tree-sitter-language-pack` and ~700 MB (mostly Rust toolchain) in the session scratchpad `...\scratchpad\r3-langs\`. Probe scripts there (`probe*.py`, `scipdump.py`, `mentions.py`, `meta.py`) are throwaway; copy any worth keeping.
