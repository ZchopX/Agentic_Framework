<!-- verbatim subagent report, id a9812a56fa3f49204; saved 2026-10-23 -->

REPORT: systemic-map skeleton extraction, hands-on (2026-10-08, Windows 10, Python 3.13, Node 26). Scratch dir: C:\Users\donat\AppData\Local\Temp\claude\C--PyProjects-Agentic-Framework\dfe5a4fa-a8f0-4f6e-9b1a-a6bbb971abee\scratchpad\r2-extract. Agentic_Framework was only read, never modified.

Note on the interrupted run: the "\n got expanded" patch in diy_extract.py was already fixed (Edit tool), and the extractor ran afterwards. No finished work was redone.

VERDICT
- Use DIY tree-sitter (about 120 lines, in scratch) as the skeleton base.
- Add grimp for the module-level import graph and layer contracts, and the git-diff mapper for diff-to-node.
- Graphify is the best off-the-shelf option, but I would use it only as an optional call-edge enrichment layer, not as the base. Reasons:
  - It emits no hashes, no end lines and no hierarchy nodes.
  - Its ids are lossy slugs that can collide.
  - It takes 14 s on 40k LOC (the DIY extractor takes 2 s).
  - It is a very fast-moving 0.9.x project (about 1,560 open issues).
- GitNexus is non-commercial licensed and slow. Understand-Anything is an LLM pipeline and not deterministic. codebase-memory-mcp could not be run here.

1. GRAPHIFY

Identity and legitimacy (verified)
- The legitimate repo is Graphify-Labs/graphify. `safishamsi/graphify` redirects to it via GitHub API (same full_name returned).
- Stars 124,829, Apache-2.0, created 2026-04-03, last push 2026-10-07. Latest commits are the 0.9.80 release; about 1,559 open issues.
- The README says "Official package: PyPI `graphifyy` (double-y). Other graphify* packages are not affiliated". So `graphifyy` is the real package.
- `graphify` on PyPI returns 404; no package of that name exists. The double-y name looks like a typosquat but is the official one. Pin it and check the README every time.
- graphifyy 0.9.80 was uploaded 2026-10-07, as wheel and sdist.
- I unzipped the wheel and inspected it before running:
  - There is no setup.py and no .pth file.
  - HTTP code is confined to graphify/security.py (an SSRF-guarded urllib opener used for `graphify add <url>`), llm.py (LLM backends), and ingest/google_workspace.
  - Telemetry: querylog.py says "no-telemetry posture, OFF unless explicitly enabled". I found no analytics or sentry code.
  - NOT packet-traced.
- `extract --code-only` ran with no API keys set in the environment. `extract` without `--code-only` needs an LLM key (gemini|kimi|claude|openai|deepseek|ollama).
- The `tree` HTML output loads d3 from https://d3js.org at view time.

Install and commands
- `pip install graphifyy==0.9.80` into a venv-g inside scratch (the install was slow).
- `graphify extract <path> --code-only --no-cluster --out <dir>` produces `<dir>/graphify-out/graph.json`, `manifest.json` and a `cache/` dir.

Test targets and runtime
- (a) Python: Textualize/rich, depth-200 clone. 40.6k LOC across 394 code files (tests, examples and docs included).
- Runtimes (8 workers):
  - Forced runs: 14.8 s and 13.9 s.
  - Cached re-run, no change: 12.2 s.
  - Re-run after a one-file edit: 15.5 s.
  - So the cache gives no real speedup.
- Output: 3,311 nodes, 10,094 edges.
- (b) TS: sindresorhus/ky, 27k LOC. 14.2 s, 575 nodes, 1,328 edges.
- (c) Agentic_Framework (read-only input, output to scratch): 9.9 s, 329 nodes, 572 edges. It indexed js/json/ps1/py/toml.

Output schema (graph.json top level: nodes, edges, hyperedges, input_tokens, output_tokens)
- Node, file:
  `{"id":"benchmarks_benchmarks","label":"benchmarks.py","file_type":"code","source_file":"benchmarks/benchmarks.py","source_location":"L1","_origin":"ast"}`
- Node, method:
  `{"id":"rich_progress_progress_add_task","label":".add_task()","file_type":"code","source_file":"rich/progress.py","source_location":"L1600","_callable":true,"_origin":"ast"}`
- Edge:
  `{"source":"benchmarks_benchmarks","target":"benchmarks_init","relation":"imports_from","context":"import","confidence":"EXTRACTED","source_file":"benchmarks/benchmarks.py","source_location":"L3","weight":1.0,"_origin":"ast"}`
- Other fields: INFERRED edges also carry `confidence_score` (e.g. 0.95, weight 0.8). Re-exports carry `type_only`.
- file_type counts: code 2484, rationale 753 (docstring nodes), concept 74 (externals). Rationale nodes are not code symbols; filter them out.
- Relations: calls 2821, uses 1395, contains 1204, imports 1070, imports_from 968, references 888, method 802, rationale_for 753, inherits 122, indirect_call 66, re_exports 5.
- Confidence: 7,945 EXTRACTED and 2,149 INFERRED.
- Integrity: 0 dangling edges, 0 duplicate ids.
- Missing fields: no end line, no sig_hash or body_hash, no package or directory nodes.

Hierarchy
- Mostly flat graph.
- Only file -contains-> class/function and class -method-> method.
- Directories and packages are NOT nodes.
- `graphify tree` builds a collapsible D3 HTML hierarchy (dir > file > symbol) from `source_file` paths. It is a view only, not part of graph.json.
- Python gap: 45 files yielded no symbols (script files such as examples).
- JSON files yield key nodes (package.json gave `exports`, `types`, ...), which is noise for a code map.
- Id collision risk: `benchmarks/__init__.py` got id `benchmarks_init`. Ids are lowercased path slugs, so `a_b.py` and `a/b.py` can collide.

Determinism
- graph.json was byte-identical across 4 runs: 2 normal, 2 forced, into different out dirs.
- SHA256 5322EEFB5F46...1834.

Edge precision (hand-checked against source)
- Python: 30 random edges (seed 7), excluding contains/method/rationale_for.
  - 29 correct, 1 wrong, so 96.7%.
  - The wrong one: the builtin `input()` call at console.py:2189 was bound to the enclosing `Console.input` method (a self-edge).
  - Spot-checked INFERRED edges also looked right: `console.end_capture()` bound to `Console.end_capture`, and `highlighter.highlight()` bound to the right class.
- TS: 14 random edges sampled (seed 3), 8 verified by reading the cited line, all 8 correct.
  - It resolves imports through the barrel (`import {NetworkError} from '../source/index.js'` points at errors/NetworkError.ts).
  - The remaining 6 were not verified, so TS precision is UNTESTED beyond that small sample.
- Open issues show systematic gaps:
  - Python `self.m()` on base classes in other files gets no edge.
  - Same-named nested classes get merged.
  - Typed-receiver calls inside nested functions get no edge.
  - Constructor calls do not reach `__init__`.

Re-run after a one-file edit
- I appended a function to rich/palette.py and re-ran.
- Result: +5 nodes, -0 nodes; +7 edges, -14 edges.
- All 21 edge differences were in rich/palette.py, so changes are localized.
- But INFERRED `uses` edges in that file flipped, so heuristic noise appears even for a trivial add.
- The whole pipeline still re-ran, at 15.5 s.
- The rich clone was restored with `git checkout`.

2. DIY TREE-SITTER EXTRACTOR
- File: scratch\diy_extract.py, 120 lines.
- Deps: `tree-sitter` 0.26.0 and `tree-sitter-python` 0.25.0, run as `python -I diy_extract.py <root> <out.json>`.
- Emits sorted JSON with fields: id (`path::Qual.name`), kind (module/class/function/method), path, name, sig_hash, body_hash, imports, line.
- Hashes are over comment-free leaf tokens, so they ignore whitespace and comments.
- On rich (213 py files): 2,309 nodes (959 functions, 865 methods, 272 classes, 213 modules). 2.1 s per run. Output byte-identical across 3 runs (SHA256 5DA90A23...CFD7).
- Sample module node:
  `{"body_hash":"845cb9f54a6e","id":"rich/palette.py","imports":["ext:colorsys","ext:functools","ext:math","ext:typing","rich.color","rich.color_triplet","rich.console","rich.segment","rich.style","rich.table","rich.text"],"kind":"module","line":1,"name":"rich.palette","path":"rich/palette.py","sig_hash":""}`

Rename/move test (synthetic refactor, scratch\match.py, ref/old vs ref/new)
- Method rename `Palette.match` -> `Palette.find_nearest`: detected as RENAME. The nested function followed as well.
- Function `loop_first` moved to a new file, with an inserted comment and extra line: detected as MOVE with the same sig_hash.
- Body edit in place (`cell_len`): reported as modified.
- Rename plus body edit in the same change (`loop_last` -> `loop_final`): NOT matched. It shows as delete plus add. A fallback match on sig_hash plus same path would be needed.
- Container problem: a class body_hash includes its children, so `Palette` showed as modified when only a method was renamed. Use a Merkle-style own-body hash plus child hashes.

Honest limitations
- Imports: only static `import`/`from` statements.
- Dynamic imports (`importlib.import_module`, `__import__`) are not seen.
- Imports under `TYPE_CHECKING` or inside functions are treated as normal imports. Lazy imports are not flagged (grimp does flag them with `is_lazy`).
- Relative imports are resolved by my own logic and only lightly tested.
- Re-exports through `__init__` are not followed. `from pkg import X` maps to the package, or to the submodule only if `pkg.X` is a module.
- External imports are collapsed to `ext:<top>`.
- No call edges, so no behavioral dependencies.
- Only Python is implemented. TS, JS and others need a grammar plus a node-type map for each, which is the main cost.
- Nested functions are emitted as functions with a qualified name.

3. GRIMP / IMPORT-LINTER (grimp 3.17, import-linter 2.15, on the rich package only)
- `grimp.build_graph('rich', include_external_packages=True)`: 0.36 s, 153 modules (including externals).
- Queries (all returned sensible results):
  - `find_modules_directly_imported_by('rich.palette')` returned 11 modules.
  - `find_modules_that_directly_import('rich.cells')` returned 31.
  - `find_shortest_chain('rich.palette','rich.cells')` returned `('rich.palette','rich.segment','rich.cells')`.
  - `get_import_details(...)` returns line numbers, line contents and `is_lazy`.
- `lint-imports` took about 7 s end to end, analysing 153 files and 678 dependencies.
- Contract syntax, in `.importlinter`:
```
[importlinter]
root_package = rich
include_external_packages = True
[importlinter:contract:layers]
name = rich layering (deliberately wrong)
type = layers
layers =
    rich.console
    rich.text
    rich.style
    rich.color
```
- Verbatim violation output (excerpt):
```
rich layering (deliberately wrong) BROKEN
Contracts: 0 kept, 1 broken.
rich.style is not allowed to import rich.console:
- rich.style -> rich.terminal_theme (l.12)
  rich.terminal_theme -> rich.palette (l.4)
  rich.palette -> rich.console (l.79)
- rich.style -> rich.repr (l.11)
  rich.repr -> rich.console (l.134)
rich.color is not allowed to import rich.text:
- rich.color -> rich.table (l.596)
  rich.table -> rich.text (l.25)
- rich.color -> rich._palettes (l.8)
  rich._palettes -> rich.palette (l.1)
  rich.palette -> rich.segment (l.80)
  rich.segment -> rich.text (l.752)
```
- Fit: grimp gives a module-level graph with import chains, line numbers and enforceable layer contracts. It is Python only and needs an importable package root. It is a better source for module dependencies and layers than my DIY imports field.

4. GIT DIFF -> NODE MAPPING (scratch\diff_map.py, about 45 lines)
- It runs `git diff -U0 --no-renames A B -- '*.py'` and parses the hunks.
- New-side lines map to enclosing symbols on the tree at revision B, using `git show B:path`. Old-side lines map to the tree at A. The smallest enclosing def or class wins.
- Lines outside any def map to `<module>`. Results roll up to directories.
- Real range: rich `HEAD~12..HEAD`. Result: 10 files, 30 touched nodes.
- Output excerpt:
```
rich/ansi.py::AnsiDecoder.decode
rich/console.py::Console.print / save_html / save_svg / save_text
rich/file_proxy.py::FileProxy, FileProxy.isatty
rich/style.py::Style.__init__ / copy / from_meta / update_link / without_color
tests/test_file_proxy.py::test_isatty.TTYFile.isatty
dir_rollup(files): {".":10, "rich":6, "tests":4}
```
- Spot-check on style.py: git hunks at lines 202, 252, 490, 642, 688 matched `__init__`, `from_meta`, `without_color`, `copy`, `update_link`. The import-line hunks (lines 3, 6, 22) went to `<module>`, which is correct.
- Limits:
  - A deleted file is handled via the old side, but that path is not tested.
  - Renames are disabled (`--no-renames`), so a moved file shows as delete plus add. Combine with body_hash matching.
  - Only .py.
  - The rollup counts files per directory, not symbols per directory.

5. QUICK INSPECTION OF THE OTHER THREE TOOLS

GitNexus (abhigyanpatwari/GitNexus)
- 47.8k stars, license PolyForm-Noncommercial-1.0.0 (GitHub shows NOASSERTION). Pushed 2026-10-08, about 300 open issues.
- npm `gitnexus` 1.6.12 is 230 MB unpacked and depends on `@scarf/scarf` (an analytics-ping package). I set `SCARF_ANALYTICS=false`.
- The npm install ran with install scripts blocked by npm's allow-scripts, and the native tree-sitter prebuilds still worked.
- Test: `analyze` on a copy of the rich repo (in scratch) with `--skip-agents-md --skip-skills --index-only` succeeded in 73.8 s. Result: 4,090 nodes, 10,819 edges, 192 clusters, 326 flows.
- Output is a binary LadybugDB graph file (`.gitnexus/lbug`, 90 MB) plus a JSON meta file. It is queried through MCP/CLI tools, not a plain nodes/edges JSON. A flat graph with communities and flows, not a package > module > symbol tree. Not in a form that feeds a hierarchical map easily.
- Side effect: analyze wrote `~/.gitnexus/registry.json` (outside scratch). It did not exist before, so I deleted that directory.
- Failure modes seen in the log: 'whole flows are MISSING: 247 of 447 candidate entry points never ranked in...' and a repeated warning that the candidate set exceeded the cap, so no CALLS edges were emitted for those call sites.
- Open issues:
  - #3500, an external evaluation: "no measurable accuracy gain for coding agents and usually increased their cost".
  - #3526, graph write collapses to about 9% of edges on low-RAM hosts.
  - #3497 to #3499, Python call-edge gaps.
- The license rules it out as a base for any tool you might distribute commercially.

codebase-memory-mcp (DeusData, MIT)
- 46k stars, C binary, v0.11.0 (2026-09-15). I downloaded the Windows zip; its sha256 matched checksums.txt, which is an integrity check against the same release rather than an independent trust check.
- It states it is 100% local, with no telemetry. Output is SQLite (an optional zstd-compressed `graph.db.zst` snapshot) plus 17 MCP tools, including Cypher-like queries.
- I could NOT run it. `cli index_repository` failed with: `secure CLI coordination could not be created (cache-private): C:\Users\donat\AppData\Local\Temp: DACL entry 0 grants mutation rights 0x00010112 to untrusted identity`.
  - It refuses to start when an ancestor directory has an ACL granting rights to another account. The Temp folder grants rights to CodexSandboxUsers.
  - Fixing this needs an ACL change or a cache dir outside scratch. I did neither.
- Indexing output and graph format are therefore UNTESTED. Everything else here is from the README and issue titles.
- Issues:
  - #2533, a watcher reindex loop regression in v0.11.0.
  - #2559, JSX edges dropped.
  - #2558, relative imports of non-JS files do not resolve.
  - #2540 and #2538, missing HTTP_CALLS edges.
- The daemon and watcher behavior is a risk for CI use.

Understand-Anything (Egonex-AI, MIT)
- 85.6k stars, a Claude Code plugin that drives a multi-agent LLM pipeline. Not run, UNTESTED: it needs an LLM session, and its output is not deterministic.
- From the source: `KnowledgeGraph` has `{version, kind, project{gitCommitHash,...}, nodes, edges, layers, tour}`.
  - Nodes: `{id,type,name,filePath,lineRange,summary,tags,complexity}`.
  - 27 node types and 38 edge types.
  - It has a first-class `layers` grouping.
  - `build-fingerprints.mjs` makes structural fingerprints for incremental updates.
  - Deterministic helper scripts exist (extract-structure.mjs, extract-import-map.mjs).
- That is the closest in shape to your design (a hierarchy, with AI summaries on top of a structural skeleton).
- Its extractor gaps (open issues): TS path aliases, Python in-function imports, C++ include guards.
- Other open issues: #704 (incremental update fails on Kotlin projects with a stale dist), #697 (dashboard 404s).
- Security-related issues were also filed (#661, #656).
- Use it as a design reference only.

UNTESTED / not done
- Windows binary indexing for codebase-memory-mcp.
- Understand-Anything end to end.
- TS precision beyond 8 verified edges.
- Network egress for Graphify (code reading only, no packet capture).
- DIY extractor on TS/JS (no grammars wired).
- Graphify `--no-gitignore` and the other options.

Other: the venvs and clones (venv-g, venv-d, repos, work, gn, cbm, gwheel) are all in scratch and can be deleted. One stray artifact outside scratch was created and removed (`~/.gitnexus`).