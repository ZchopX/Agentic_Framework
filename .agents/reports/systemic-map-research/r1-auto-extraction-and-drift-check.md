<!-- verbatim subagent report, id aef4199b024eeebfd; saved 2026-10-23 -->

## Systemic-map skill: extraction, drift and change tracking

Verified this session (fetched pages): Graphify, GitNexus, import-linter, dependency-cruiser, LikeC4, SCIP indexer list, stack-graphs status. The rest is from my background knowledge and was not re-checked today. Verify those items before you depend on them. I mark them "(unverified)".

### Bottom line
No existing project does the whole job (skeleton + AI annotations + drift check). The nearest is Graphify. It is a deterministic skeleton plus provenance tags, but it has no annotation-versus-code drift check. Build a thin layer yourself, and borrow the extractor and the diff-to-symbol impact idea from existing tools.

### Existing end-to-end projects

| Project | Languages / output | License | Fit |
|---|---|---|---|
| **Graphify** (https://github.com/safishamsi/graphify; the owner is shown as Graphify-Labs in some sources, so check it) | 37 tree-sitter grammars, AST-only so no LLM is called for code. Writes `graphify-out/graph.json` (with `schema_version`), `GRAPH_REPORT.md` and `graph.html`. Edges are tagged EXTRACTED / INFERRED / AMBIGUOUS. | Apache-2.0 or MIT | Best base. `graphify update` re-extracts changed files. `graphify hook install` adds post-commit and post-checkout hooks and a merge driver for `graph.json`. It auto-detects Claude Code on Windows. No documented diff or drift command. `reflect` lessons get a "re-verify" flag when their source changes, which is the nearest thing to a drift signal. |
| **GitNexus** (https://github.com/abhigyanpatwari/GitNexus) | TS, JS, Python, Java, Kotlin, C#, Go, Rust, PHP, Ruby, Swift, C/C++ and others. Index in `.gitnexus/` (LadybugDB). Has an MCP server and generates AGENTS.md / CLAUDE.md. | **PolyForm Noncommercial** | `detect_changes` maps a git diff to affected processes, `impact` gives symbol blast radius, `check` runs structural checks, and `--watch` refreshes incrementally. This is the closest to the "what did this task touch" feature. The noncommercial license limits reuse, so treat it as a design reference. |
| **Code-Graph-RAG** (https://gitee.com/gitstr/code-graph-rag) | tree-sitter into Memgraph, queried by natural language via Cypher. | not checked | Needs a graph database. Too heavy for a text map. |
| Potpie, Joern, cocoindex-code | not researched | unknown | Not evaluated. Joern is a heavy JVM code-property-graph tool. cocoindex-code is semantic search, not a map. |

### Extraction tools

| Tool | Notes |
|---|---|
| **tree-sitter** (https://tree-sitter.github.io) | The base layer. Fast, deterministic, MIT, 100+ grammars. On Windows, `pip install tree-sitter tree-sitter-language-pack` gives prebuilt wheels (unverified). It gives syntax only (defs, imports), not resolved references. |
| **stack-graphs** (https://github.com/github/stack-graphs) | **Archived and read-only.** Avoid it. tree-sitter-graph (https://github.com/tree-sitter/tree-sitter-graph) still exists, but its last push was around Dec 2024, so don't build on it. |
| **SCIP** (https://github.com/sourcegraph/scip) | Protobuf format with precise definition and reference symbols. Indexers exist for Java/Scala/Kotlin, TS/JS, Rust (rust-analyzer), C/C++, Ruby, Python, .NET, Dart and PHP. Each indexer needs a working toolchain or build (node for scip-python, JDK for scip-java), so the install is heavy on Windows. The symbol strings (`scheme manager pkg version descriptor`) are good stable IDs. Use it only if you need precise cross-file references. The repo may have moved to scip-code/scip, which I could not confirm. |
| **LSIF** | Superseded by SCIP. Skip. |
| **universal-ctags** (https://ctags.io) | Tags-only output, no hierarchy. Works on Windows via a release zip or `choco`. Good enough as a fallback for rare languages (unverified). |
| **Aider repo-map** (https://aider.chat/docs/repomap.html) | tree-sitter tags plus PageRank, producing a token-budgeted ranking, not a persistent model. Borrow the idea (rank by reference count to pick which nodes to annotate first), not the code (unverified). |
| **grimp** (https://github.com/seddonym/grimp) and **import-linter** (https://github.com/seddonym/import-linter) | Python import graph and contracts (layers, forbidden, independence). BSD-2. Pure Python, pip-installable, Python only. Use grimp for the Python module dependency edges. I did not verify the contract types from the page, but I know them. |
| **dependency-cruiser** (https://github.com/sverweij/dependency-cruiser) | JS/TS/Vue/Svelte. MIT. `forbidden` rules, JSON, mermaid and dot output. Needs Node. Maintained (2.4k commits). |
| jdeps | JDK built-in, class and package level. Use it only for Java. |
| ast-grep (https://ast-grep.github.io) | tree-sitter pattern queries, single binary, MIT. Useful for convention-based rules such as "all routes", but it is not a skeleton extractor (unverified). |
| Semgrep / CodeQL | Semgrep is LGPL (rules have separate licenses) and CodeQL is free only for open source (unverified). Both are overkill for a skeleton. |
| Doxygen, Structure101 | Doxygen is mostly C/C++, and Structure101 is proprietary and has been discontinued as far as I know (unverified). Skip both. |
| **LikeC4** (https://likec4.dev) | MIT. Models the architecture as text and offers "Diff & Validation", but the page does not say it validates against code. Use it as a model format only if you want diagrams. It will not do your drift check. |
| ArchUnit | JVM only (unverified). |

### Recommended pipeline

**1. Skeleton extraction (deterministic, no LLM)**
- Try Graphify first. Run `uv tool install graphifyy`, then `graphify .`. It gives you `graph.json` with files, symbols and edges. Pin the version and read `schema_version`.
- Fall back to your own ~150-line script with `tree-sitter-language-pack` if Graphify's schema is too unstable or noisy. Emit sorted JSON, one record per file or symbol: `{id, kind, path, name, sig_hash, imports[]}`. Sorting the output makes it deterministic and diffable.
- For hierarchy, use three levels. Directory/package is the top level (system, then subsystem), file/module is the middle, and top-level class or function is the bottom.
- Commit `skeleton.json` and the annotation file together. Git then gives you history for free.

**2. Node-to-code mapping (stable IDs)**
- Skeleton IDs are path-derived: `py:pkg/mod.py::Class.method` or `dir:src/billing`. Language prefix, repo-relative POSIX path, then qualified name. Do not use line numbers.
- Annotation file, one YAML or Markdown block per node: `id`, `purpose`, `behavior`, `exceptions`, and `anchor`. The anchor holds `sig_hash` (hash of the normalized signature) and `body_hash` (hash of the AST with comments and whitespace stripped), captured when the annotation was written.
- Rename handling: if an ID disappears and a new ID has the same `body_hash`, treat it as a move and rewrite the key. Fall back to `git log --follow -M`.
- For coarse nodes, use CODEOWNERS-style globs: `node: billing → src/billing/**, tests/billing/**`. Last matching glob wins. Every file must map to exactly one node, and an unmapped file is itself a finding.
- If you need precise cross-language symbols later, adopt SCIP symbol strings as IDs.

**3. Drift rules (all cheap and deterministic, no LLM)**
- ORPHAN-ANNOTATION: the annotation points to an ID that no longer exists, with no body-hash match to explain a move.
- UNDOCUMENTED: a skeleton node above a size or visibility threshold has no annotation. Report it as coverage.
- STALE: the node exists but its `body_hash` or `sig_hash` differs from the anchor. The code changed after the annotation was written. For a directory node, use a hash of its children's hashes.
- UNMAPPED-FILE: a file matches no glob.
- EDGE-DRIFT: the map declares "A depends on B" or "A must not depend on B" and the extracted import edges disagree. For Python, express the forbidden or layered rules as import-linter contracts. For JS, use dependency-cruiser `forbidden` rules.
- CLAIM-DRIFT (optional, LLM): for STALE nodes only, ask the model "does this annotation still describe this code?" and attach the answer. Keep it advisory so the CI check stays deterministic.
- Fix flow: re-annotating a node refreshes its anchor.

**4. Per-task changed-node highlighting**
- Get the task's range: `git diff --name-status -M <base>..HEAD` plus `git diff -U0` for hunks.
- Map each file to its node through the globs. Map each hunk to the smallest enclosing symbol by intersecting the hunk's line range with symbol line spans from the fresh tree-sitter extraction.
- Roll up so the parent nodes light up: touched (symbol changed), contains-touched (ancestor), and added or removed (ID set difference between old and new skeleton).
- Better still, diff the skeleton at the base and at HEAD, so you see ID additions and removals and changed hashes. This also feeds the drift check and the history view.
- Output a list of node IDs plus the hunk count per node. The renderer marks those nodes. Optionally also dump a 1-hop neighbor set, like GitNexus `impact`.
- History: `git log -p -- skeleton.json annotations/`, or store the touched-node list per commit in the commit trailer or a notes file.

### Windows notes
Graphify installs via uv and winget. Use `graphify .` rather than `/graphify` in PowerShell. Prebuilt tree-sitter wheels avoid a C compiler. For the git hook, re-run `graphify hook install` after upgrading Python, because it embeds the interpreter path. Normalize paths to forward slashes in all IDs.

### What I could not confirm
- Graphify's field-level `graph.json` schema (see docs.graphify.com).
- GitNexus release cadence.
- Any currently maintained tool that checks hand-written architecture annotations against code. I found none, so the drift layer above is yours to build.
- Potpie, Joern and cocoindex-code were not evaluated.