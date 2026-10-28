<!-- verbatim subagent report, id ab3b7b5b02ecb9f3c; saved 2026-10-23 -->

VIEW LAYER REPORT (2026-10-08). "V" = verified this session from the cited page; "K" = my prior knowledge, not re-verified (flagged).

**Comparison**

| Tool | Hierarchy drill-down | Collapse + edge aggregation | Search / diff overlay | Generate from JSON/text | Single-file HTML | Scale | License / status |
|---|---|---|---|---|---|---|---|
| LikeC4 | Yes, but per authored view: a scoped view is the default click-through for its element (V: likec4.dev/dsl/views). Not one continuous zoom canvas. | Done by view predicates, not by a collapse toggle. | Search is built in (K). No diff feature (V: nothing in model-API or views docs). You would add tags/custom styling yourself. | Yes. DSL files, or a TS builder `@likec4/core/builder` (V: likec4.dev/tooling/model-api/). JSON input is not documented. | Yes: `likec4 build --output-single-file` (V: likec4.dev/tooling/cli/). | Views are meant to be small, hundreds of nodes at most (K). | MIT, 5.8k stars, active: v1.59.x in 2026 (V: github.com/likec4/likec4; newreleases.io/project/github/likec4/likec4/release/v1.59.3). |
| Structurizr | C4 views, one view per level. | None. | None. | DSL or JSON workspace. | No. Static site export exists but renders diagrams only (V: docs.structurizr.com/static). | Small. | Lite is end of life, replaced by vNext (V: docs.structurizr.com/eol). Avoid. |
| Cytoscape.js | Compound nodes are native. | The expand-collapse extension does edge aggregation (meta-edges). The README says it is no longer maintained, last npm release 4.1.1 (V: github.com/iVis-at-Bilkent/cytoscape.js-expand-collapse). Successor: cytoscape.js-complexity-management. | Search and classes/styles for highlighting are trivial. Diff is done by adding a class per node. | Plain JSON elements. | Yes, a hand-written HTML with inlined JS. | Canvas renderer. A few thousand visible nodes is fine (K). Keep the collapsed view small. | MIT. Core is active: v3.34.3 (V: github.com/cytoscape/cytoscape.js/releases). |
| Sigma.js + graphology | No compound nodes (V: not mentioned). | You would build aggregation yourself on a collapsed graph. | Good for search and highlighting. | JSON via graphology. | Yes. | Best for 10k+ nodes, WebGL (V: github.com/jacomyal/sigma.js). | MIT. v4 is alpha. |
| vis-network | Clustering API (K). | Cluster edges are aggregated automatically (K). | Basic. | JSON. | Yes. | Ok to about 1-2k nodes (K). | MIT. Community-maintained (K). |
| D3 (zoomable treemap / circle-pack / sunburst) | Strongest true geometric semantic zoom. This is the "map of the earth" feel. | Shows only a tree, no cross-edges. Dependencies need a separate overlay (bundled edges). | Roll your own. | JSON hierarchy. | Yes. | Fine with canvas. SVG gets slow past a few thousand elements. | ISC, stable (K). |
| React Flow / xyflow | Sub-flows exist via `parentId` (V: reactflow.dev/learn/layouting/sub-flows). That page says nothing about collapse. | You would write collapse and aggregation yourself. | Easy, nodes are React components. | JSON. | Needs a Vite single-file build plugin. | Weak past a few thousand nodes without virtualization (K). | MIT. Active: @xyflow/react 12.12.0, 24 Sep (V: github.com/xyflow/xyflow/releases). |
| ELK.js / dagre | Layout only. ELK handles hierarchical (compound) graphs (K). | Not applicable. | Not applicable. | JSON in, JSON out. | Yes. Web workers are supported (V: github.com/kieler/elkjs). | ELK is slow on big graphs (K). | ELK is EPL-2.0 (K). dagre is unmaintained and has weak compound support (K). |
| yFiles | Excellent: grouping and folding with edge aggregation are built in (K). | Built in. | Built in. | Yes. | Yes. | Excellent. | Commercial, one-time purchase. Single-developer and project licenses; prices only via their tool (V: yfiles.com/pricing). |
| G6 (AntV) v5 | Combos with a collapse-expand behavior (V: g6.antv.antgroup.com/en/manual/behavior/collapse-expand). | Built in. | Some. | JSON. | Yes. | Open issues report slow expansion at about 1,000 nodes in a combo (V: antvis/G6 issue #6730 and #6143). I found no 10k benchmark. | MIT (K). Documentation is mostly Chinese-first. |
| Mermaid | Subgraphs only, static. | None. | None. | Text. | Yes. | Poor above about 100 nodes. | MIT. Good as a fallback export. |
| D2 | Containers. Interactivity is only tooltips and links, and they do not work in static exports (V: d2lang.com/releases/0.1.4). | None. | None. | Text. | SVG. | Small. | MPL-2.0 (K). |
| Excalidraw / tldraw | Manual canvases. Not generated. | None. | Little. | Awkward. | Not really. | Small. | tldraw's license is restrictive for production (K). Skip both. |
| Gephi / Kumu / Obsidian graph | Desktop or SaaS. Flat graphs, no hierarchy drill-down. | None. | Some. | Import only. | No. | Gephi is good at large graphs. | Not suited to a generated, versioned artifact. |
| CodeSee | Dead. The company announced closure and was reportedly acquired by GitKraken (V: search result, a LinkedIn post and CB Insights, not a primary source). | | | | | | Do not depend on it. |
| Sourcetrail | Dead. Archived Dec 2021, community forks only (V: search results, AlternativeTo). | | | | | | Do not depend on it. |
| CodeScene / Backstage | CodeScene is a commercial SaaS for hotspots and behavior. Backstage is a service catalog and needs a server. | Not applicable. | Not applicable. | Not applicable. | No. | Not applicable. | Neither is a map renderer. Not verified this session (K). |

**Ranked recommendation**

1. **Cytoscape.js with a custom collapse layer, in one self-contained HTML file.** It is the only option that fits every hard requirement together: compound nodes, deterministic JSON input, arbitrary per-node classes for diff, built-in search through selectors, offline single file, MIT, and an actively maintained core. Its extension for collapsing is unmaintained, so I recommend writing the ~100 lines yourself instead of relying on it.
2. **LikeC4.** Use it if the audience is architects and you want ready-made polish quickly. Python emits `.c4` or `.likec4` text, then `likec4 build --output-single-file` produces the HTML. It gives real drill-down and good-looking C4 views. Its weaknesses are no continuous zoom, no diff, and weak scale.
3. **D3 zoomable circle-pack or treemap as a "world" overview.** It is the best "map of the earth" metaphor and could sit in front of Cytoscape. It does not draw dependencies well, so it is a complement, not the main renderer.
4. Sigma.js, only if you must render more than 10k nodes flat.
5. yFiles, only if you can pay for a license.

I would drop Structurizr, CodeSee and Sourcetrail because they are end of life or dead.

**Minimal glue for the top 2**

*Cytoscape.js (about 300 lines total):*
- A Python script reads the model, flattens it to `{nodes:[{data:{id,parent,label,kind,level}}], edges:[{data:{id,source,target,kind}}]}`, and inlines that JSON with the vendored `cytoscape.min.js` and a layout plugin (`cytoscape-fcose`, or `elkjs` for layered layout) into one HTML template.
- JS collapse logic:
  - Keep a set of expanded nodes. Start with only the top level expanded.
  - For every edge, lift each endpoint to its nearest visible ancestor. Skip the edge if both ends lift to the same node. Group lifted edges by (source, target) and draw one edge with a count label. Rebuild this on every toggle, which is about 40 lines.
  - Double-click on a node toggles it. Breadcrumbs and "focus subtree" give the drill-down. Re-run the layout on the expanded subtree only.
- Search box: a selector like `node[label *= "x"]`, then expand its ancestors and `cy.fit`.
- Diff overlay: Python marks each node `status` as added, changed or removed, comparing two model versions by stable ID. In JS, apply a class per status. A parent node is "dirty" if any descendant changed, so collapsed regions still show a change badge. A version dropdown can swap in embedded JSON for each snapshot. About 30 lines.
- A stable ID scheme (path-based) is the one thing the text model must guarantee.

*LikeC4 (about 100 lines of Python):*
- Emit `specification`, `model` (nested elements and `->` relations) and one `view` per system, subsystem and component (`view of X { include *, X.* }`), so click-through drill-down is automatic.
- Mark changed nodes with `#changed` / `#added` tags and a style rule, or a per-task view with `include element.tag = #changed`. A version comparison would be one extra view per diff, generated by Python. There is no native side-by-side diff.
- Run `likec4 build --output-single-file`. This needs Node installed.

**Gaps I could not verify (check before committing):**
- LikeC4 scale limits.
- elkjs license and release date.
- Whether LikeC4 can ingest JSON or only DSL and the TS builder.
- G6 performance at 10k nodes.
- The CodeSee outcome, which comes from search snippets, not primary sources.