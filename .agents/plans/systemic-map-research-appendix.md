# Systemic map: research appendix

Companion to [systemic-map-handoff.md](systemic-map-handoff.md). The handoff holds the decisions; this file holds the evidence behind them, with sources, verification status, and the places where the research disagreed with itself.

Built 2026-10-23 from the 11 subagent reports (saved verbatim in [.agents/reports/systemic-map-research/](../reports/systemic-map-research/)) and 56 experiment-run messages. Nothing here is new research. Where a claim has a tag, it is the tag the original agent gave it:

- **VERIFIED** = the agent fetched the page and read the stated content.
- **ABSTRACT** = only the abstract page was read.
- **SEARCH-ONLY** = seen in search summaries, source not fetched.
- **HANDS-ON** = the agent ran the tool on this machine (Windows 10, scratch folder).
- **UNVERIFIED / UNTESTED** = could not confirm / not run.

## 0. Saved reports (index)

| File | Round | Topic | Notes |
|---|---|---|---|
| [r1-text-formats-for-system-models.md](../reports/systemic-map-research/r1-text-formats-for-system-models.md) | 1 | YAML vs DSLs vs JSON for the model | Desk research; no tool run |
| [r1-interactive-zoomable-viewers.md](../reports/systemic-map-research/r1-interactive-zoomable-viewers.md) | 1 | Viewer library comparison | Recommended Cytoscape; **reversed by round 2** |
| [r1-auto-extraction-and-drift-check.md](../reports/systemic-map-research/r1-auto-extraction-and-drift-check.md) | 1 | Extractors, drift rules, diff→node | Recommended Graphify as base; **reversed by round 2** |
| [r1-ai-agent-interface-and-prior-art.md](../reports/systemic-map-research/r1-ai-agent-interface-and-prior-art.md) | 1 | CLI design, file layout, prior art | Source of the CLI verb list and validator checks |
| [r2-landscape-sweep.md](../reports/systemic-map-research/r2-landscape-sweep.md) | 2 | ~80 tools, 7 papers | Found the agent-era map tools round 1 missed |
| [r2-llm-and-graph-evidence-review.md](../reports/systemic-map-research/r2-llm-and-graph-evidence-review.md) | 2 | Papers on LLMs + graphs/edits/drift | Source of the evidence in §3 below |
| [r2-likec4-and-dsl-tools.md](../reports/systemic-map-research/r2-likec4-and-dsl-tools.md) | 2 | LikeC4, Structurizr, CALM hands-on | HANDS-ON |
| [r2-extractors-on-real-repos.md](../reports/systemic-map-research/r2-extractors-on-real-repos.md) | 2 | Graphify, DIY tree-sitter, grimp, GitNexus | HANDS-ON |
| [r2-viewer-prototypes-and-benchmarks.md](../reports/systemic-map-research/r2-viewer-prototypes-and-benchmarks.md) | 2 | Cytoscape vs D3 prototypes, timings | HANDS-ON |
| [r2-groma-archik-faultline.md](../reports/systemic-map-research/r2-groma-archik-faultline.md) | 2 | The three closest tools on pallets/click | HANDS-ON |
| [r2-blind-agent-interaction-experiment.md](../reports/systemic-map-research/r2-blind-agent-interaction-experiment.md) | 2 | 12 tasks × 4 representations | Reduced sample |
| [r2-experiment-run-handbacks.md](../reports/systemic-map-research/r2-experiment-run-handbacks.md) | 2 | Final message of each surviving run agent | 56 runs |

Not saved because they no longer exist: the opus runs and several repeats that died on the API limit (their reports were never produced). The scratch code and screenshots (`r2-*` under the session scratchpad, ~210 MB) are temp files; copy anything worth keeping before it is cleaned.

## 1. How the research changed its own mind

Round 2 overturned round 1 in four places. The handoff reflects round 2; this is the audit trail.

| Question | Round 1 said | Round 2 found | Why it changed |
|---|---|---|---|
| Viewer | Cytoscape.js + custom collapse (ranked 1), D3 as a complement | D3 canvas circle-pack wins; Cytoscape stutters at 5,000 nodes | Prototypes built and timed |
| Extractor base | Graphify first, DIY as fallback | DIY tree-sitter base; Graphify optional enrichment | Graphify has no hashes, no hierarchy, lossy IDs, 14 s vs 2 s |
| Model file layout | One file per node (`.map/nodes/<id>.md`) | Per-subsystem files (~220–260 lines) were cheapest to navigate in the experiment | Experiment measured reads; per-node files were never tested |
| Prior art | "No tool combines all of these" | Several agent-era map tools exist (groma.md, archik, faultline, CodeBoarding, Scryer…) but none covers the whole target | Round 1 missed everything after ~March 2026 |

Also corrected: codebase-memory's "83% vs 92%" is answer quality of graph vs plain file exploration, not a win (§3.3). Graphify's star count was reported as 85.6k, then ~125k; the 124,829 figure was read from the GitHub API but star counts of new repos are not a quality signal.

## 2. Design inputs from round 1 not carried into the handoff

From the AI-interface report (a design judgment, not research):

- **Layout:** `index.yaml` (root + level-1 nodes only, under ~2k tokens), one file per node or subtree, `changes/<date>-<slug>.jsonl` as an append-only touch log, and a gitignored derived `graph.sqlite` cache that the renderer reads. SQLite is a throwaway cache, never the source of truth.
- **No MCP and no graph DB in v1.** A skill plus scripts costs no tool-schema tokens at session start (codebase-memory-mcp ships 17 tools). Kuzu is a dead end (archived 2025-10-10; fork RyuGraph exists).
- **`touch` takes a risk field:** `map touch <id> --change "..." [--risk low|med|high]`.
- **Edges need evidence.** Each dependency edge carries an import, call site or config reference as path + line; the checker confirms it exists. Edges without evidence get `confidence: declared` and render dashed.
- **Validator checks:** JSON Schema on front-matter; unique ids; parent exists; no parent cycles; every dep target exists; every `paths` glob matches ≥1 file; every changed source file belongs to some node ("unmapped file X, run `map find` or `map add`").
- **Error style:** name the file, the field, and the exact fix command, with a "did you mean" suggestion.
- **Caps:** summary ≤200 chars, ≤~12 children per node (validator forces a split), prose ≤~150 words.
- **Merge safety:** sorted keys, one record per line, append-only log.
- **Build order suggested:** schema + `check` → `show`/`neighbors`/`touch` → static HTML renderer → evidence-based edge verification → only then an MCP wrapper over the same CLI.
- **Format note from the text-format report:** custom YAML + JSON Schema gives the cheapest tokens and best error messages; renames must be explicit (`renamed_from`) or the model's git history breaks; sort keys and keep one fact per line.
- **Model file-format comparison** (LikeC4 DSL, Structurizr DSL, CALM, D2, Mermaid, PlantUML, DOT, ArchiMate, Arc42, Backstage, Cytoscape JSON, custom YAML): table in the report. No head-to-head LLM accuracy benchmark exists for any of them.

## 3. Evidence review, with sources

From [r2-llm-and-graph-evidence-review.md](../reports/systemic-map-research/r2-llm-and-graph-evidence-review.md). **Headline: no study tests the exact design** (a hierarchical text map edited by an agent over hundreds of sessions).

### 3.1 LLMs reading graphs in text

| Finding | Source | Status |
|---|---|---|
| Encoding choice moved accuracy 4.8%–61.8%; incident encoding won most tasks; PaLM 2 (old) | Talk like a Graph, arXiv 2310.04560 | VERIFIED |
| Graph reasoning is brittle | NLGraph, 2305.10037 | ABSTRACT |
| Accuracy <50% past ~120 nodes | GrAlgoBench, 2602.06319 | ABSTRACT |
| Collapse past ~60 nodes | GraphWiz, 2402.16029 | SEARCH-ONLY |
| Serialization labeling/order/syntax each matter | Lost in Serialization, 2511.10234 | ABSTRACT |
| **Edge hallucination is the dominant structural failure** | R2ABench, 2604.06683 | ABSTRACT |
| Dependency context improves LLM architecture recovery | ArchAgent, 2601.13007 | ABSTRACT |
| Edge list ~2.6k tokens vs JSON ~4.5k vs JSON-LD ~13.5k | KG-LLM-Bench | SEARCH-ONLY |

No DOT/Mermaid/GraphML/YAML head-to-head exists. The 30–50-node view cap is the agent's extrapolation from the 60/120 collapse points, not a measured lookup threshold.

### 3.2 Edit reliability

| Finding | Source | Status |
|---|---|---|
| All four models scored lower with JSON-wrapped code | Aider "code in JSON", aider.chat/2024/08/14/code-in-json.html | VERIFIED |
| No line numbers; whole-block edits; flexible patching (disabling it → 9× errors) | Aider unified diffs, aider.chat/docs/unified-diffs.html | VERIFIED (old model) |
| **Line-range edits corrupted 99.1% of files after a one-line shift**; content-anchored edits fail cleanly; anchor-and-verify = 1 silent misapplication in 8,320 | Look Before You Leap, 2609.11957 | ABSTRACT |
| Model emits a structured field change; parser-position replacer edits raw text | Don't Let the Model Write the YAML, 2609.00227 (Kubernetes-specific) | ABSTRACT |
| Best diff format depends on model size and task | Diff-XYZ, 2510.12487 | ABSTRACT |
| Viewer + editor subagents: +2.1 points, −17.9% cost | SWE-Edit, 2604.26102 | ABSTRACT |
| `str_replace` requires a unique match | Anthropic text-editor tool docs | VERIFIED |
| Strict format constraints hurt reasoning | Let Me Speak Freely, 2408.02442 | SEARCH-ONLY |
| Hashline claims big gains from edit format | Can Bölük, Feb 2026 | UNVERIFIED |

### 3.3 Hierarchical retrieval and progressive disclosure

- **codebase-memory** (Vogel et al., arXiv 2603.27277; VERIFIED): tree-sitter graph over MCP vs an Explorer agent, both Claude Opus 4.6, 31 repos. Answer quality 0.83 vs 0.92 at ~1,000 vs ~10,000 tokens and 2.3 vs 4.8 calls. A trade-off. Authors admit: first author graded, one model, one repo per language, single run, static structure only. Worst case macro-heavy C (0.58 vs 1.00).
- Code Isn't Memory (2606.22417): structural index gave localization gain, lower cost per solve (ABSTRACT). LocAgent (2503.09089): 92.7% file localization, ~86% cheaper (ABSTRACT). Deep Agentic Search (2608.01507): semantic 65.2% vs grep subagent 46.2% (ABSTRACT).
- Cursor: semantic search +12.5% average (vendor, VERIFIED). Is Grep All You Need (2605.15184): grep beat vectors on conversational memory, not code (SEARCH-ONLY). CORE-Bench (2606.11864): embeddings do worse in agentic coding settings (ABSTRACT).
- GraphRAG/RAPTOR gains are for corpus QA, not software maps; graphs often lose to plain RAG on simple lookups (2506.05690, 2502.11371).
- Tree depth/fan-out: **no controlled study.** VecTree-RAG ablation: tree-only navigation 490k tokens vs 128k hybrid (SEARCH-ONLY). The "depth 2–3" recommendation is opinion.
- Anthropic guidance (VERIFIED, guidance not experiments): smallest set of high-signal tokens; SKILL.md body <500 lines; references one level deep (nested refs get partial reads); table of contents for files >100 lines. Readable IDs "significantly improve retrieval precision" (writing-tools-for-agents; magnitude not published).
- Context rot: Chroma, trychroma.com/research/context-rot (VERIFIED, 18 models); Lost in the Middle 2307.03172 (ABSTRACT); NoLiMa and IFScale (SEARCH-ONLY).

### 3.4 Documentation drift and LLM-written context

| Finding | Source | Status |
|---|---|---|
| LLM-generated context files lowered resolution ~0.5% (Lite) / ~2% (AgentBench); developer-written ~+4%; cost +20–23%; with docs removed LLM files helped ~2.7% | ETH "Evaluating AGENTS.md", 2602.11988 | VERIFIED. **Paper is internally inconsistent across versions; cite a specific version.** |
| With AGENTS.md: median runtime −28.64%, output tokens −16.58% | Lulla et al., 2601.20404 | ABSTRACT. Opposite direction from ETH because they measure different things |
| AGENTS.md smells: Lint Leakage 62%, Context Bloat 42%, Skill Leakage 35% | 2606.15828 | ABSTRACT |
| Most of 3,000+ GitHub projects have ≥1 outdated code-element reference | Tan, Wagner, Treude, 2212.01479 | SEARCH-ONLY |
| Repeated rewriting causes "context collapse"; use structured incremental updates (+10.6%) | ACE, 2510.04618 | ABSTRACT |
| Memory conflict resolution weak (HippoRAG-v2 54%, Mem0 18% single-hop) | 2608.15008 | SEARCH-ONLY |
| LLM architecture views are code-level not architectural; vision LLMs 48.1% exact on arrowheads | 2603.21178 | ABSTRACT / SEARCH-ONLY |

**No measured rot rate for LLM-maintained docs exists.** This is the central unknown the prototype must measure. Suggested first experiment: smallest edit tool + validator, replay 100+ simulated sessions on a real repo, measure stale-reference rate, silent misapplications and wrong edges, with a Tan-style dangling-reference checker as ground truth.

### 3.5 Human side

- CodeCity controlled experiment (Wettel, Lanza, Robbes, ICSE 2011): 41 participants, significantly better correctness and completion time vs Eclipse + spreadsheet (ABSTRACT; percentages not retrieved; baseline was weak). Merino 2018: 62% of visualization approaches lack strong evaluation (SEARCH-ONLY).
- Anthropic randomized trial, Jan 2026: 52 mostly junior engineers, 50% with AI vs 67% without, Cohen's d 0.738, p=0.01; full delegation 39%, conceptual questioning 65%+. **Status conflict:** the evidence report marked it VERIFIED (anthropic.com/research/AI-assistance-coding-skills); the landscape report marked the same figure UNVERIFIED against the original paper. Treat as "reported, source page read once".
- Trust-Calibrated Code Review (2606.01969; 17 practitioners + 43-person survey): reviewing LLM multi-file changes is a trust-calibration problem; three levels (overview, file, snippet) with zooming. ABSTRACT.
- LLM Agents Can See Code Repositories (2606.14061, ASE 2026): hybrid text + visual repo graphs cut input tokens up to 26%; vision-only hurts. Supports a text model with visuals as an extra. ABSTRACT.
- Towards Actionable Visualization (2608.22151, VISSOFT 2026), AI-Guided Exploration (2508.05799), Code2UML (2605.24453): position/prototype papers.
- **No controlled study** of a map or diagram helping a human understand agent-made changes. "Comprehension debt" is practitioner writing (Osmani, Gorman).

### 3.6 Decision table the evidence review produced

Evidence-supported: content-anchored validated edits; edit through a structured-operation tool; no JSON wrapping of text; readable IDs; small always-loaded context with detail behind links; don't restate code-derivable facts; never trust LLM-written dependency edges; incremental over regeneration; per-node neighbor lists; use search alongside the map.

Opinion only: YAML vs Markdown vs DSL; node size cap, depth 2–3, 30–50 node view cap; ID scheme specifics; provenance and last-verified fields; whether a human map improves oversight; one file vs many for long-run reliability.

## 4. Tool landscape (round 2 sweep + hands-on)

Full ~80-row table: [r2-landscape-sweep.md](../reports/systemic-map-research/r2-landscape-sweep.md). Repos, versions and license facts were read from the GitHub API on 2026-10-08. Most agent-era tools are <6 months old, one maintainer, v0.x.

### 4.1 Agent-era map tools (closest to the goal)

| Tool | Tested? | Verdict |
|---|---|---|
| groma.md 0.6.6, MIT, 172★ — github.com/MrLesk/groma.md | HANDS-ON on pallets/click | Best human map and revision compare. 3 fixed C4 levels. No drift check (deleted `globals.py` left a ghost component, no warning). `export` hung 4×. Python scanner found 0 relationships. Compare was noisy (+1/~30 for two edits). Issues disabled. Install via npm, not `git clone` (long paths). |
| archik 0.19.5, MIT, 12★ — github.com/bacharSalleh/archik | HANDS-ON | Closest for agent-edits-text. YAML `parentId`, unlimited depth. `drift` gives ORPHAN/UNMAPPED but directory-level only. `affected --since` maps files→nodes+ancestors. 27-tool MCP, suggest/accept workflow. Byte-identical renders. No semantic zoom, no in-canvas change overlay. 16 fixed edge relationships. Single YAML won't scale. `archik init` installs a skill, 14 commands and CLAUDE.md unless `--no-skill --no-commands --no-loop`. |
| faultline 0.5.1, MIT, 15★ — github.com/anzal1/faultline | HANDS-ON | Best change overlay, timeline slider, replay HTML, `fault check` exit code, 4-tool MCP. Flat, 2 levels, import-graph only, noisy diff. Own pilot (36 runs, builder-written tasks): forbidden-import crossings 0/6 with faultline vs 5/6 with the rule only in AGENTS.md. |
| CodeBoarding 0.14.2, MIT, 2.5k★ | desk | Static analysis + LLM naming; nested diagrams; PR review of changed components. Not deterministic; may send code to a model provider. |
| Scryer 0.4.21, license NOASSERTION, 117★ | desk | Responsibility model with tests and drift, MCP. Alpha. |
| oh-my-mermaid 0.2.0, MIT, 2.3k★ | desk | Folder tree = hierarchy; LLM-generated. Simplest agent-writable layout. |
| Others | desk | Birdview, ArchEyes, ontology-atlas (its own README: benchmark "has not measured a difference in answer quality … and Atlas was slower"), PR Lens, system-atlas, vibeX, StructSmith, ArchFlow, c4hero, C4InterFlow, Keadex Mina, DocHub, Stratify, Noodles, mindwalk (replays agent sessions on a 3D repo map), fallow, katana, Archify, drawio-skill. See report. |

Missing from all three hands-on tools: behavior/exception paths, junctions, low-noise history across many tasks, drift that sees deleted or renamed files.

### 4.2 Established tools

Ilograph (proprietary; the only mature semantic zoom over a YAML model; official `ilograph/skills`; UX reference only), IcePanel (SaaS, MCP), Eraser, Archi, Sparx EA, Structure101 (acquired by Sonar, no longer for sale), Sonargraph (MCP server), Lattix (status UNVERIFIED), CodeCharta (deterministic city + revision delta), CodeScene, Backstage, Cartography, Sourcegraph (repo archived, SCIP moved to scip-code/scip), CodeSee (acquired by GitKraken), draw.io, Excalidraw, Kumu, Obsidian/Foam/Logseq (flat graphs), Sprotty/GLSP (semantic-zoom prototype: De Carlo et al., MODELS 2022), JointJS, Cosmograph, Neo4j Bloom, Emerge, Gource, Sourcetrail (dead), classic generators (Doxygen, Sphinx, pyreverse, Madge, pydeps).

**Searches that returned nothing useful (don't repeat):** gh topic searches `codebase-knowledge-graph`, `software-city`; multi-word `gh search repos` with `--updated`; Lattix 2026 status; Kumu API; Sonargraph release; the pyreverse docs page.

## 5. Format hands-on: LikeC4, Structurizr, CALM

From [r2-likec4-and-dsl-tools.md](../reports/systemic-map-research/r2-likec4-and-dsl-tools.md) (HANDS-ON, LikeC4 1.59.4). **Verdict: LikeC4 is a viewer, not the source of truth.**

| Fact | Detail |
|---|---|
| Install | `npm install likec4`, 54 s, 106 MB. Windows fine. |
| 60-element model | validate 1.8 s; build 3.3 s (6.5 MB); single-file build 2.5 s (3.9 MB, **not opened in a browser**); `export json` 1.7 s |
| 510 elements / 850 rels / 201 views | build 8.9 s, 15 MB |
| 2,069 elements / 3,400 rels / 806 views | static build **did not finish in 400 s**; `export json` 3m13s, 11 MB |
| Single ~250-node view | hung `validate` >170 s. Per-level views are mandatory; cap views ~15–30 nodes |
| Input | **DSL only.** No JSON/YAML source. A 45-line YAML→.c4 generator round-tripped 52/52 elements and 102/102 relations |
| MCP | 20 tools, **all read-only** except layout. Nothing writes the model |
| Drill-down | Works in the static build via "Navigate to view", only if a view exists for that element |
| Search | Ctrl+K over titles/ids/views; does not search metadata values; poor fuzzy on dotted numbers |
| Tags/changed | `view changed { include element.tag = #changed }` is two lines; elements need a `global style` to be colored; ordering rules inside bodies are strict |
| Errors | Line number and class, no column, no echoed source, no "did you mean"; errors cascade (477 errors from one slip at 500 elements); a build on an invalid model still produced output, so CI must run `validate` separately |
| Quirks | Relationship between an element and its own descendant is rejected |
| Not tested | UI display of metadata; single-file build in a browser; 2,000-element render; LikeC4 version history; TS builder API |
| Side effect | Playwright Chromium 118 MB in `%LOCALAPPDATA%\ms-playwright` |

Structurizr (old CLI v2025.11.09 only; consolidated tool needs Docker, UNTESTED): errors echo the offending source line — more LLM-friendly than LikeC4. Flat identifiers unless `!identifiers hierarchical`. Old CLI, Lite and cloud are end of life.

CALM (`@finos/calm-cli` 1.61.0, 285 MB): validates JSON directly; errors are machine-readable JSON with code, severity, JSON path, line and column — **the most actionable error format of the three, and the model for our own CLI's errors**. Verbose JSON, no zoom semantics, render not run.

## 6. Extractors hands-on

From [r2-extractors-on-real-repos.md](../reports/systemic-map-research/r2-extractors-on-real-repos.md). Test targets: Textualize/rich (40.6k LOC, 394 files), sindresorhus/ky (27k LOC TS), Agentic_Framework (read-only).

**Graphify 0.9.80** (`graphifyy` double-y; Graphify-Labs/graphify; Apache-2.0; ~124.8k★; ~1,559 open issues)
- Legitimacy: `safishamsi/graphify` redirects to Graphify-Labs. README names `graphifyy` as the only official package; `graphify` on PyPI is a 404. Wheel unzipped and inspected: no setup.py, no .pth, HTTP code confined to an SSRF-guarded opener, LLM backends, and Google ingest; querylog says "no-telemetry posture". Not packet-traced. Pin the version.
- `extract --code-only` needs no API key; without `--code-only` it needs an LLM key.
- Speed: 14.8 s / 13.9 s forced; 12.2 s cached (no speedup); 15.5 s after a one-file edit. rich: 3,311 nodes, 10,094 edges. ky: 14.2 s, 575 nodes. Agentic_Framework: 9.9 s, 329 nodes.
- Deterministic: `graph.json` byte-identical over 4 runs.
- Edge precision: Python 29/30 (96.7%); TS 8/8 verified of 14 sampled (the other 6 unchecked).
- Gaps: no end line, no hash, no package/directory nodes; ids are lowercased path slugs and can collide (`a_b.py` vs `a/b.py`); rationale/docstring nodes (753) and JSON-key nodes are noise; one-file append flipped INFERRED edges (+7/−14, all in that file); open issues: `self.m()` on cross-file base classes, same-named nested classes merged, constructor calls not reaching `__init__`.
- `graphify tree` HTML loads d3 from d3js.org at view time.

**DIY tree-sitter** (`tree-sitter` 0.26.0 + `tree-sitter-python` 0.25.0, 120 lines, `python -I`)
- rich: 2,309 nodes, 2.1 s, byte-identical over 3 runs. Hashes over comment-free leaf tokens.
- Rename/move test: method rename detected; function moved with an inserted comment detected; in-place edit = modified; **rename + body edit in one change NOT matched** (fallback: sig_hash + same path).
- **Container bug:** class `body_hash` includes children, so renaming a method marks the class modified. Use own-body hash + child hashes (Merkle).
- Limits: static `import`/`from` only; dynamic imports invisible; `TYPE_CHECKING`/in-function imports treated as normal; re-exports through `__init__` not followed; no call edges; Python only.

**grimp 3.17 / import-linter 2.15** (rich): graph build 0.36 s (153 modules); queries for direct importers/imports, shortest chain, line numbers and `is_lazy`; `lint-imports` ~7 s; layered contracts report violating chains with line numbers. Python only, needs an importable package root.

**Git diff → node mapper** (45 lines): `git diff -U0 --no-renames A B -- '*.py'`; new-side lines map via `git show B:path`, old-side via A; smallest enclosing def/class; module-level lines → `<module>`. rich `HEAD~12..HEAD` → 10 files, 30 nodes; spot-check on style.py matched. Deleted-file path untested; renames disabled (moved file = delete + add, so combine with body-hash matching); rollup counts files not symbols.

**Rejected / not usable**
- GitNexus (47.8k★, PolyForm Noncommercial; 73.8 s on rich; flat binary LadybugDB; log said "247 of 447 candidate entry points never ranked", edges dropped; issue #3500 external evaluation "no measurable accuracy gain… usually increased cost"; npm package pulls `@scarf/scarf` analytics; wrote `~/.gitnexus`, since deleted).
- codebase-memory-mcp (DeusData, MIT, 46k★, v0.11.0): **could not run** — refuses to start because `%LOCALAPPDATA%\Temp` ACL grants rights to CodexSandboxUsers ("DACL entry 0 grants mutation rights 0x00010112 to untrusted identity"). Fixing needs an ACL change or a different cache dir. Output format untested.
- Understand-Anything (Egonex-AI, MIT, 85.6k★): LLM pipeline, non-deterministic, not run. Closest in shape (hierarchy + AI summaries over a structural skeleton; 27 node types, 38 edge types, `layers`, structural fingerprints). Design reference.
- Round-1 desk notes: stack-graphs archived; tree-sitter-graph stale since ~Dec 2024; SCIP indexers need heavy toolchains per language (SCIP symbol strings are good stable IDs if cross-language precision is needed later); LSIF superseded; dependency-cruiser for JS/TS; ast-grep for pattern rules; Semgrep/CodeQL overkill; Joern, Potpie, cocoindex-code not evaluated.

## 7. Viewer prototypes

From [r2-viewer-prototypes-and-benchmarks.md](../reports/systemic-map-research/r2-viewer-prototypes-and-benchmarks.md). Headless Chromium via Playwright 1.60; synthetic graphs of 100 / 1,000 / 5,000 nodes (98/985/5,024 nodes; 161/1,729/9,585 edges; ~18–19% edges cross top-level domains, 41–69% at service level).

| | A: Cytoscape 3.34.1 + fcose 2.2.0 | B: D3 7.9.0 canvas circle-pack |
|---|---|---|
| Layout/boot | 120–145 ms (100) → ~295 ms (5,000) | 9 ms (100) → 82–90 ms (5,000), computed once |
| Per expand | 15–130 ms (100), 40–265 ms (5,000) | free (open/closed = function of on-screen radius) |
| Wheel frame gaps | p95 62 ms, max 324 ms, 15 gaps >100 ms at 5,000 | p95 ~18 ms, max 69 ms at 5,000; none >100 ms |
| Feels like | clicking a tree with an auto trigger | exploring a map; search fly-to ~900 ms |
| Problems | siblings overlap; edge widths become giant bands when zoomed; thresholds dataset-sensitive; 1,000–2,200 aggregated edges on screen at 5,000 | layout ignores dependency edges; overview is a busy all-to-all web (90 aggregated edges among 10 domains), top-70 cap hides >1,000 at some zooms; one 52 ms draw spike at 5,000 |

Diff overlay worked in both: leaf fill/border by status (green added, orange changed, red dashed removed), collapsed parents show a `+a ~c -r` pill (e.g. `+8 ~25 -16` on reports_391).

Not tested: prototype C (G6 combos), >5,000 nodes (e.g. 50k), real GPU/mouse/touch, mobile, edge-aware sibling ordering, accessibility, URL state, devicePixelRatio >1, a real before/after pair (statuses were synthetic), plain-SVG variant. Pages are not yet self-contained (relative script tags; `n=` URL parameter picks the dataset).

Round-1 desk notes on libraries: Sigma.js (WebGL, 10k+ flat, no compound nodes), vis-network (clustering, ~1–2k nodes), React Flow (sub-flows via `parentId`, no collapse), ELK.js (layout only, EPL-2.0), dagre (unmaintained), yFiles (best-in-class, commercial), G6 v5 (combos; GitHub issues #6730/#6143 report slow expansion ~1,000 nodes), cytoscape-expand-collapse (README says no longer maintained), Mermaid/D2 (static), Excalidraw/tldraw (manual canvases).

## 8. Blind interaction experiment

From [r2-blind-agent-interaction-experiment.md](../reports/systemic-map-research/r2-blind-agent-interaction-experiment.md) and [r2-experiment-run-handbacks.md](../reports/systemic-map-research/r2-experiment-run-handbacks.md).

**Setup:** fictional system of 124 nodes (6 subsystems, 24 components, 72 modules, 22 submodules; depth 4), 82 leaves, 229 edges (45 with error paths), 25 leaves with raises, 8 exception types. Four representations: R1 YAML with direct Read/Edit (38 KB over 7 files), R2 same YAML + a Python CLI, R3 LikeC4 `.c4` (49 KB / 1,253 lines), R4 single JSON (70 KB / 2,933 lines). R2b = R2 with incremental validation + a `raise rm` verb. Fresh `general-purpose` agents on Sonnet, told only to read `PROMPT.md`. Seed 7; rerun kit in the scratchpad (`src/gen.py`, `smap.py`, `exp.py`).

**Tasks:** T1–T4 read (transitive dependents + error path; exception origins; file-path owners; subtree + ancestors), T5–T9 update (add module, rename leaf with 10 inbound edges, move 8-node component, append error path, cycle trap), T10–T12 drift (5–6 changed files each).

**Results (Sonnet, n=1 per cell except T10/T12 n=2): tokens / tool calls**

| Task | R1 | R2 CLI | R3 .c4 | R4 JSON |
|---|---|---|---|---|
| T1 impact | 64k/11 | 44k/4 | 57k/6 | 78k/9 |
| T6 rename | 53k/16 | 43k/**3** | 47k/17 | 44k/6 |
| T7 move | 54k/9 | 43k/**3** | 50k/9 | 44k/4 |
| T9 cycle trap | pass | pass | pass | pass |
| T10 drift A | 0/2 strict (2/2 lenient) | 0/1 strict (1/1 lenient) | 0/2 strict (2/2 lenient) | 0/1 strict (0/1 lenient) |
| T11 drift B | pass | pass | pass | pass |
| T12 drift C | 2/2 | 1/2 | 2/2 | 2/2 |

All read and update tasks passed in every representation. 65 of 68 usable scored runs were at or near ceiling. **0 invented nodes or edges.** The sample cannot rank representations on correctness; it only shows cost and the CLI's flaws.

**Failures:**
1. T10 strict failures (all 6 runs): agents renamed the node id when a file was renamed because the task text said "ids are file stems". Task-wording ambiguity, not a representation effect. The R4 run also edited a summary (collateral change), failing even leniently.
2. R2 whole-model validation broke drift work: after code changed the model was already invalid, so every write was rejected (T10: 37 rejected calls; T12: 9 and 15). Agents created stub files to get past it ("I briefly created empty stub files… deleted both once the edits went through"; "check passes … only because I left a stub file in code/"). That T12 run ended partial (score 0.7).
3. Missing verb to remove a raise: an agent ran `raise … --remove`, which added a junk entry; both agents deleted and recreated the node.
4. Parent/child path deadlock ("A parent with no paths is rejected as a leaf, and a parent with paths is rejected once it has a child"). R2b fixed #2 (1 rejection vs 37) but not #4 (12 rejections on T12). `rm` needs a recursive option.
5. In most R1/R3/R4 update runs agents did not run a validator; the final state was still correct.

**Does CLI-gating beat direct edits?** Not on correctness (direct editors also passed everything and invented nothing; they traced the T9 cycle by hand). The gate's measured benefit is cost (3 calls vs 16–17 for rename/move) and not leaving garbage; its cost was the drift blockade and missing verbs. *A gate only helps if it never blocks legitimate repair work.*

**Validator must catch:** duplicate/missing ids; unknown parent; kind/depth mismatch; dangling dep targets and stale FQNs; self-deps; cycles (print the path); leaf-only deps; dep kind and handling enums; exception registry; path glob matching zero files; one owner per file; summary length. **And must:** treat pre-existing problems as non-blocking (baseline compare); allow recursive delete/re-parent atomically; have a verb for every operation; never encourage faking stubs (make the filesystem ownership check a warning in drift mode).

**Caps (judgment):** summary ≤200 chars; ≤10 children (experiment used ≤5); depth ≤4; single file ≤~1,000 lines / 25 KB. The 2,933-line JSON forced offset reads and was the most expensive read.

**Caveats (the authors'):** one run per cell; Sonnet only; short fresh sessions with the full format spec in the prompt, not long drifting sessions; tasks mostly at ceiling; 124 nodes is small; drift change sets were regenerated stubs, not real git diffs; "no scripts / no direct reads" rules unenforced. Opus runs and several repeats (T10 n2/n3, T12 n2/n3, T11 R2b, ×8 opus) died on the API limit and are excluded. 166 run directories were prepared, ~100 never run.

## 9. Open items the research left

Carried into the handoff as §8/§9, plus these smaller ones:
- Whether the single-file LikeC4 build opens in a browser and shows metadata (UNTESTED).
- TS/JS extraction (only 8 Graphify edges verified; DIY has no TS grammar wired).
- Windows: codebase-memory-mcp ACL failure; groma `git clone` long paths; groma `export` hang root cause not investigated.
- Graphify network egress was code-read, not packet-traced.
- `archik`/`groma` behavior and flow modeling were not exercised, so "junctions/exceptions as text" has no tested reference implementation anywhere.
- Hunting for a drift check that sees renamed/deleted files: none of the tools had one; the DIY body-hash rename detection is the only tested approach.
