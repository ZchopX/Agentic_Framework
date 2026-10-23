<!-- verbatim subagent report, id aeb0ee8a2d997a8aa; saved 2026-10-23 -->

Recommendation: use a custom YAML model (one file per subsystem plus a root index.yaml, validated by JSON Schema) as the source of truth, and export it to LikeC4 DSL for the interactive map. I did not run any tool or test LLM error rates. Facts marked (unverified) come from my background knowledge, not a source I checked.

## Verified facts (GitHub API, 2026-10-08)
| Tool | Latest release | License | Stars |
|---|---|---|---|
| LikeC4 (github.com/likec4/likec4) | v1.59.4 (2026-09-21) | MIT | 5.8k |
| FINOS CALM (github.com/finos/architecture-as-code) | cli-v1.61.0 (2026-10-07) | Apache-2.0 | 417 |
| Structurizr (github.com/structurizr/structurizr) | v2026.09.19 | Apache-2.0 | 445 |
| D2 (github.com/terrastruct/d2) | v0.9.0 (2026-09-07) | MPL-2.0 | 25.6k |
| Mermaid (github.com/mermaid-js/mermaid) | 12.x (2026-10-02) | MIT | 90.6k |
| PlantUML (github.com/plantuml/plantuml) | 1.2026.8 (2026-09-05) | LGPL-3.0 | 13.4k |
| Backstage (github.com/backstage/backstage) | v1.55.3 | Apache-2.0 | 34.6k |

All are actively maintained.
- Structurizr: the old CLI, Lite and cloud are end of life, replaced by one consolidated tool (https://docs.structurizr.com/eol).
- LikeC4: nested elements, drill-down views, git tracking and "diff & validation" (https://likec4.dev/). The v1.55 notes say the MCP server was extracted into its own package (https://newreleases.io/project/github/likec4/likec4/release/v1.55.0).
- CALM: CLI, VS Code plugin, "CALM AI" prompt tools and a Hub. Its schema covers nodes, relationships, flows and controls.

## Comparison
"Hierarchy" means native nesting and zoom levels. "Edge metadata" means relationships can carry exceptions or error paths.

| Format | Hierarchy | Edge metadata | Stable IDs | Diff | LLM fit and tooling |
|---|---|---|---|---|---|
| LikeC4 DSL | Native nested elements, drill-down views | Tags, metadata, properties (unverified detail); dynamic views for flows | Dotted element paths | Good (text) | Syntax made for AI; MCP server. Renderer, validate and JSON export. Small niche community. |
| Structurizr DSL | Native C4 (system, container, component), `!include` | Properties and tags; dynamic views | Identifiers, hierarchical option | Good | Java-based and being consolidated. Strictly C4 only. |
| CALM (JSON) | `composed-of` and `deployed-in` relationships, not true zoom | Controls, flows, metadata | `unique-id`, strong | JSON noise | JSON Schema validation. Verbose, so a high token cost. Built for compliance. |
| D2 | Nested containers | Labels and styles, not rich metadata | Dotted paths | Good | Compact and readable. Render-first; nothing is queryable. |
| Mermaid | Subgraphs, flat; C4 mode is experimental | Labels only | Node IDs | Good | LLMs know it best (most training data, unverified). Layout degrades at scale. No zoom. |
| PlantUML / C4-PlantUML | Includes and macros | Labels | Aliases | Good | Verbose; needs Java and Graphviz. |
| Graphviz DOT | Clusters | Arbitrary attributes | Node names | Good | Simple and universal. Poor interactivity. |
| ArchiMate / Archi (XML) | Rich | Rich | GUID | Poor | XML noise. Agents read it badly. |
| Arc42 | Prose template | None | None | Good | A document structure, not a model. |
| Backstage catalog-info.yaml | Flat (`subcomponentOf`, `dependsOn`) | Annotations | `kind:ns/name` | Good | Good YAML tooling. Weak hierarchy and no behavior. |
| JSON Graph / GraphML / Cytoscape JSON | Compound nodes | Arbitrary | Yes | Poor | A render or interchange format, not an authoring one. |
| Custom YAML or JSONL | You define it | You define it | You define it | Best if sorted | Cheapest tokens; validate with JSON Schema. |
| Obsidian markdown links | Folders and links | Frontmatter | Filenames | Good | Good for notes; weak structure. |

## Evidence on LLM error rates
- I found no benchmark that compares syntax-error rates across Mermaid, PlantUML, D2 and DSLs. MermaidSeqBench (https://arxiv.org/abs/2511.14967) covers only Mermaid sequence diagrams and uses an LLM judge. Its authors also say Mermaid and PlantUML evaluation is sparse.
- The practical answer is to validate with a parser in a loop. Custom YAML plus JSON Schema gives the cheapest, most precise error messages. The DSLs (LikeC4, Structurizr) have the parsers too.

## Existing agent-oriented projects
- Codebase-Memory (https://arxiv.org/abs/2603.27277, submitted 2026-03-28): a Tree-sitter knowledge graph exposed over MCP. Across 31 repositories it scored 83% answer quality against 92% for plain file exploration, with about 10x fewer tokens and 2.1x fewer tool calls. The repo is https://github.com/DeusData/codebase-memory-mcp (MIT, active).
- Graphify (https://github.com/Graphify-Labs/graphify): a skill for Claude Code, Cursor, Codex and Gemini CLI that builds a graph from code, docs and configs with deterministic AST parsing. It has 125k stars (very high, not independently checked). It is auto-extracted, so it is not a curated model you write and review.
- Takeaway: these tools derive the graph from code. Your skill needs the curated layer on top: intent, error paths and junctions. A hybrid could use extraction to propose edits and the curated model to hold them.

## Ranked recommendation (source of truth)
1. **Custom YAML**, with one file per subsystem and a root `index.yaml`.
   - One node per entry, with stable path IDs such as `billing.invoice.retry`.
   - Fields: `parent`, `kind`, `summary`, `deps: [{to, kind, errors: [...]}]`, `exceptions`, `code_refs`.
   - Sort keys and keep one line per fact so diffs stay clean.
   - Validate with a JSON Schema (`jsonschema` from PyPI).
   - Per-task highlighting is a separate `touched` list kept outside the model.
   - An agent can read only the index, then open one subsystem file. You control the token cost, and a deterministic render is easy in Python on Windows.
2. **LikeC4 DSL as the derived render layer.** Generate `.c4` files from the YAML, or adopt LikeC4 directly as the source if you accept its schema. Its nested hierarchy and drill-down views map closely to the earth, countries, cities, streets zoom you want. The MCP server is a bonus. The cost is a Node dependency.
3. **Structurizr DSL.** A good fit only if you want strict C4. It needs Java and the tooling is in flux.
4. **CALM.** Strong on schema and controls, but the JSON is verbose and it lacks zoom semantics. Choose it only for compliance needs.
5. **Mermaid or D2 as throwaway views per task.** Do not use them as the source of truth because they have no queryable structure.

## Caveats
- A custom schema means you maintain the schema, validator and renderer yourself. Keep the schema small.
- LikeC4 syntax details such as metadata and dynamic views come from likec4.dev plus my memory. Run a spike before committing to an export.
- The 125k-star count for Graphify and the Codebase-Memory marketing claims (158 languages against the paper's 66) are vendor figures.
- Diffs stay readable only with stable IDs and sorted output. Renames must be explicit (`renamed_from`), or git history of the model will break.