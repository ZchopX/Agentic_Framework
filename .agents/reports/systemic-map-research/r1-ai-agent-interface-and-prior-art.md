<!-- verbatim subagent report, id a3e342852fe1b4aba; saved 2026-10-23 -->

# Systemic map: AI interface and prior art

Evidence: ~9 searches and 4 fetches. Star counts and benchmarks come from READMEs and are self-reported. Items marked UNVERIFIED are not confirmed. Part 1 is my design judgment, not researched fact.

## 1. Recommended agent-facing design

**Core decision: plain files in git are the source of truth, with a CLI as the only way the agent reads or writes them.** Skip the MCP server and the graph DB for v1.

Reasons:
- Files diff, review and merge in git, which is the point of a "what changed" tool.
- A skill with scripts costs no tool-schema tokens at session start. Codebase-Memory ships 17 MCP tools, and every tool schema is paid for in context ([repo](https://github.com/DeusData/codebase-memory-mcp)).
- Kuzu is a dead end. Its repo was archived on 2025-10-10 after Apple's acquisition. A fork, RyuGraph, exists ([puppygraph](https://www.puppygraph.com/blog/what-is-kuzudb), [heise](https://heise.de/-11177751), [ryugraph](https://blog.ryugraph.io/posts/introducing-predictable-labs-and-ryugraph)).
- SQLite is fine as a throwaway query cache built from the files. Never make it the source of truth.

**File layout (progressive disclosure):**
```
.map/
  index.yaml          # root + level-1 nodes only: id, one-line summary, child ids, owner. Keep under ~2k tokens.
  nodes/<id>.md       # one per node: YAML front-matter + short prose
  changes/<date>-<slug>.jsonl   # append-only touch log
  .cache/graph.sqlite # derived, gitignored; the renderer reads this
```

Per-node front-matter fields:
- `id`, `parent`, `kind`, `summary`
- `paths:` (globs of the code the node owns)
- `deps: [{to, type, why}]`
- `exceptions: []`
- `status` (a verified or stale marker; see the drift rules below)

**Why not one big file:**
- It blows up tokens when the agent has to read all of it.
- It makes merge conflicts certain.
- Per-node files plus an append-only change log (one JSONL line per touch) give merge-safe writes. Aider-style budgeting is the precedent for capping output ([agentpatterns](https://www.agentpatterns.ai/context-engineering/repository-map-pattern/)).

**CLI verbs** (one Python script, stdlib plus PyYAML):

| Verb | Behavior |
|---|---|
| `map show <id> [--depth N] [--budget TOKENS]` | Prints the node and N levels of children, truncating at the budget with a "+k more" hint. |
| `map neighbors <id> [--dir in|out] [--hops 1]` | Dependency neighbors. |
| `map find <text-or-path>` | Maps a file path to the owning node. |
| `map touch <id> --change "..." [--risk low|med|high]` | Appends to the change log. This is what makes the human view possible. |
| `map set <id> --field ...` | Validated edit. |
| `map check [--changed-since REF]` | Validates the map and checks it against the diff (see below). |
| `map render` | The deterministic renderer. |

Default output is compact, and the agent only ever pulls the subtree it needs.

**Validation that gives actionable errors.** Each error names the file, the field, and the exact fix command. Example: `nodes/billing.md: dep 'ledger' not found. Did you mean 'ledgers'? Run: map set billing --dep ledgers`.

Checks to run:
- JSON Schema on the front-matter.
- Unique ids.
- Parent exists.
- No cycles in the parent tree.
- Every dependency target exists.
- Every `paths:` glob matches at least one file.
- Every changed source file belongs to some node. Otherwise the error is "unmapped file X, run `map find` or `map add`".

**Failure-mode mitigations:**
- **Hallucinated edges.** Make `deps` machine-checkable where possible. Each dependency edge must carry evidence: an import statement, a call site, or a config reference, recorded as a path plus line. A tree-sitter or import scan in `map check` confirms that evidence exists. Edges without evidence get `confidence: declared` and render dashed. This is borrowed from the codebase-graph projects, which derive edges from static analysis rather than letting the LLM invent them.
- **Drift.** `map check --changed-since main` fails in CI or a pre-commit hook if code under a node's `paths` changed but the node has no entry in the change log for that range. Store `verified_at: <commit>` per node and mark it stale automatically. Understand-Anything uses tree-sitter fingerprints and a post-commit `--auto-update` hook for the same purpose ([repo](https://github.com/Lum1104/Understand-Anything)).
- **Token blowup.** Enforce hard caps in the schema: summary at most 200 chars, at most about 12 children per node (the validator forces splitting), prose at most about 150 words.
- **Merge conflicts.** One file per node, an append-only log, and sorted keys. `map check` also runs as a merge-driver sanity check.

## 2. Prior art

**Reuse or borrow:**

| Project | What it is | Take from it | Status |
|---|---|---|---|
| [Understand-Anything](https://github.com/Lum1104/Understand-Anything) | Claude Code and Codex plugin. Multi-agent `/understand` builds `.ua/knowledge-graph.json`. React dashboard. `/understand-diff` shows the impact of uncommitted changes. | Closest existing match. Take the diff-overlay idea and the dashboard UX. | 85.6k stars (README, so unverified), MIT, incremental updates. |
| [codebase-memory-mcp](https://github.com/DeusData/codebase-memory-mcp) | tree-sitter to SQLite graph, 17 MCP tools. Paper arXiv 2603.27277 claims 10x fewer tokens. | The evidence that a queryable graph beats file-by-file reading. | 46k stars, MIT. Benchmarks are self-reported. Its graph is code-level, not a human-level systemic model. |
| [Aider repo map](https://www.agentpatterns.ai/context-engineering/repository-map-pattern/) | PageRank over a tree-sitter symbol graph, with a binary search to a token budget (default 1,024). | The `--budget` mechanism. Ports include [repomap-mcp](https://images.glama.ai/mcp/servers/fl0w1nd/repomap-mcp). | Mature. |
| [LikeC4](https://github.com/likec4/likec4) | Architecture-as-code DSL with a zoomable renderer (`npx likec4 start`) and an MCP server (listed on mcp.so, [mcp.so](https://mcp.so/servers/mcp-likec4)). | Possible renderer, or a target for exporting the model. | 5.8k stars, MIT. I could not verify its MCP tool list or its validate command. Check likec4.dev. |
| [Google Code Wiki](https://infoq.com/news/2025/11/google-code-wiki/) and Devin [DeepWiki MCP](https://docs.devin.ai/work-with-devin/deepwiki-mcp.md) | Auto-regenerated wikis with diagrams and chat. DeepWiki's MCP tools are `read_wiki_structure`, `read_wiki_contents` and `ask_question`. | The "structure first, then contents" tool split, which is progressive disclosure. | Hosted, public repos only, no change-oriented view. |

**Not worth reusing:**
- **CodeSee:** the company shut down commercial operations (a founder post says Feb 22; the year is not stated) and was then acquired by GitKraken in May 2024 ([schneider.im](https://www.schneider.im/fr/gitkraken-acquiert-codesee/)). It is a cautionary tale about an SaaS-only approach.
- **Swimm:** I found no 2026 status. UNVERIFIED. Its last funding round I could find was 2021 ([techcrunch](https://techcrunch.com/2021/11/08/swimm-nabs-27-6m-series-a-to-include-up-to-date-documentation-in-every-release/)). Its idea of docs coupled to code snippets and flagged stale when the code changes is exactly the drift check above.
- **Mintlify:** not researched.

**Oversight and comprehension-debt literature** (practitioner essays, not rigorous studies):
- [O'Reilly Radar](https://www.oreilly.com/radar/comprehension-debt-the-hidden-cost-of-ai-generated-code/) and [Faros](https://www.faros.ai/blog/comprehension-debt-in-software-engineering). The term is credited to Jason Gorman (2025) and popularized by Addy Osmani (2026). Recommended practices: a named human author-of-record, no silent approvals of agent PRs, and treating known gaps as backlog items.
- It supports the product premise: tests do not close the understanding gap, and humans need a model of the change, not the code.
- I found no peer-reviewed work on map-based change summaries.

**Gap in the market.** I found no tool that combines all of these:
- a human-level hierarchy (systems and subsystems rather than functions);
- a map whose nodes are declared as exceptions or intent;
- an append-only record of what each agent touched;
- a zoomable change overlay.

Understand-Anything is closest but is auto-generated and code-level. This skill's niche is the curated model plus the touch log.

## 3. Suggested build order
1. Schema plus `map check`.
2. `show`, `neighbors`, `touch`.
3. A static-HTML renderer. Either borrow Understand-Anything's dashboard or emit LikeC4 or Mermaid first.
4. Evidence-based edge verification.
5. Only then consider an MCP wrapper, as a thin shell over the same CLI.