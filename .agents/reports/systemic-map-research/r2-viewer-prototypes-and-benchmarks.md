<!-- verbatim subagent report, id a58b9c6bf6a3abf14; saved 2026-10-23 -->

## Systemic map viewer prototypes: report

Prototype B (D3 canvas circle-pack) feels like exploring a map and is the clear winner. Prototype A (Cytoscape + fcose, my own expand/collapse and edge lifting) works but is crowded, overlaps, and gets slow at 5000 nodes. Prototype C was not built. Every measured and described result below is from headless Chromium via Playwright 1.60 on this machine.

All paths are under `C:\Users\donat\AppData\Local\Temp\claude\C--PyProjects-Agentic-Framework\dfe5a4fa-a8f0-4f6e-9b1a-a6bbb971abee\scratchpad\r2-viewer\`. I did not touch `C:\PyProjects\Agentic_Framework`.

### Files
- **Generator:** `gen.js` writes `data/graph-{100,1000,5000}.json` and `.js` (54 lines).
- **Shared code:** `common.js` and `common.css` hold the model, edge lifting, search, breadcrumbs, details panel and styles. Both prototypes load them (64 lines together).
- **Prototype A:** `protoA.html` (92 lines).
- **Prototype B:** `protoB.html` (82 lines).
- **Test scripts:** `dive.js` (wheel-driven dive, search, frame-time capture), `t1.js` and `st.js` (quick screenshots), `logA.txt` (Prototype A run log).
- **Screenshots:** `shots/`. The files `{A,B}_{100,1000,5000}_{0overview,dive1..3,zoomout,search_dropdown,search_result}.png` cover all three sizes for both prototypes. The `t1_*` files are earlier tuning shots. Note that `A_5000_search_result.png` was overwritten by the final fixed run.
- **Libraries:** vendored into `vendor/`: cytoscape 3.34.1 (published 2026-08-11), cytoscape-fcose 2.2.0 with cose-base and layout-base, d3 7.9.0. I installed them with `npm --ignore-scripts`.
- **Not self-contained yet:** the pages load `vendor/`, `data/` and `common.*` through relative script tags. The `n=` URL parameter picks the dataset. I did not write the build step that inlines everything into one file.
- **Prototype A gotcha:** its `-A` pages run correctly only from this folder.

### Generator output
Hierarchy depth is 4 (100 nodes) or 5 (1000 and 5000). Edges are about 2.2 per leaf, with kinds calls, imports, reads, writes and publishes plus weight and protocol metadata. Statuses added, changed and removed are clustered under a few random modules.

| Nodes | Leaves | Edges | Crossing top-level domains |
|---|---|---|---|
| 98 | 73 | 161 | 19% |
| 985 | 786 | 1729 | 18% |
| 5024 | 4357 | 9585 | 18% |

Crossing at the service level is 41 to 69%, so "~20% crossing" holds only at the domain level.

### Measured timings
**Prototype A (Cytoscape):**

| Nodes | Boot (root expanded, fcose) | Per-expand cost | Wheel behaviour |
|---|---|---|---|
| 100 | 120 to 145 ms | 15 to 130 ms | frame gaps p95 28 ms, max 99 ms |
| 1000 | ~200 ms | 30 to 180 ms | p95 36 ms, max 175 ms, 5 gaps over 100 ms |
| 5000 | ~295 ms | 40 to 265 ms | p95 62 ms, max 324 ms, 15 gaps over 100 ms |

- The first expand is the slowest; later ones are cheaper because the revealed groups are smaller.
- Part of each expand is rebuilding the aggregated edges, which touches all 9585 edges every time.
- At 5000 nodes the screen carried 1000 to 2200 aggregated edges, which is why wheel rendering stutters.

**Prototype B (D3 canvas):**
- Layout is one circle-pack: 9 ms (100), 19 ms (1000), 82 to 90 ms (5000). It never re-lays out on zoom, so expand and collapse cost nothing.
- Frame gaps while diving at all three sizes: p50 16.6 ms, p95 about 18 ms, max 33, 39 and 69 ms for 100, 1000 and 5000 nodes. No gap exceeded 100 ms.
- Draw time per frame is mostly 0.4 to 13 ms, with one 52 ms spike at 5000 nodes. I saw it once at k 1.78 and did not investigate.
- The edge top-70 cap hides over 1000 aggregated edges at some zoom levels.
- Search fly-to is a smooth ~900 ms animated zoom.

### What I saw in the screenshots
**Prototype B:**
- **Overview:** at 1000 and 5000 nodes the overview shows the ~10 domains as big circles with aggregated count labels and orange change pills.
- **Dependency overlay:** the overview is a dense all-to-all web (90 aggregated edges among 10 domains at 5000 nodes). The top-70 cap, alpha scaled by weight, and red highlighting of the selected node's edges keep it readable but busy.
- **Zooming in:** circles open into services, modules and leaves at roughly 400 px diameter, with a fade. Labels, edge counts and pills stay legible at every depth. Zoomed in on handler_147 it was clean.
- **Details and breadcrumbs:** click or search updates breadcrumbs (`system > analytics_1 > scheduler_117 > handler_147`) and the details panel (summary, path, external deps).
- **Weakness:** the layout ignores edges, so related nodes are not placed near each other and long edges cross the screen.

**Prototype A:**
- **100 nodes:** expanded compound boxes with fcose placement look like a real graph with nesting. Edge widths were too heavy until I reduced them.
- **1000 and 5000 nodes:** the overview after tuning shows 11 collapsed domains with 90 aggregated edges. Boxes overlap each other, because expanded compounds exceed their collapsed footprint and siblings are not re-spaced.
- **Deeper zoom:** a hairball of lifted edges, overlapping boxes, and thick edge lines. Edge width is in model units, so lines become giant bands when zoomed in.
- **Tuning:** the footprint multiplier and expand threshold took three tries, and the open threshold is tied to viewport height. It is dataset-sensitive.

### Diff overlay and badge
Both prototypes work.
- **Leaves:** coloured fill and border by status (green added, orange changed, red dashed removed).
- **Collapsed parents:** a pill showing `+a ~c -r` counts of changed descendants. In A it is an HTML overlay positioned each frame. In B it is drawn on the canvas.
- **Check:** I confirmed it in the screenshots, e.g. B at 5000 nodes shows `+8 ~25 -16` on reports_391.
- **Expanded parents:** only an orange outline, no pill.

### Zoom-triggered expansion (wheel, no double-click)
- **A, feasible but costly:** about 15 lines in `autoZoom`. It runs 150 ms after the last viewport event, expands on-screen leaves wider than 420 px and collapses compounds narrower than 168 px.
- **A, why it falls short:** it is not smooth. Each expand does a fcose layout (50 to 260 ms) plus edge rebuild, and the geometry jumps. It cascades if thresholds are mistuned.
- **A, test result:** my wheel-dive test never met its stop condition (180 wheel steps each run), so it did not cleanly show dive-to-depth-3. Zoom-out was not verified to collapse back. In the 100-node run it ended expanded.
- **B, essentially free:** whether a region is open is a function of its on-screen radius, evaluated each frame. Edge lifting reruns only when the set of open regions changes. The dive reached depth 3 in 7 to 8 wheel steps and zooming out collapsed everything with aggregated edges returning.
- **B, caveat:** the pack geometry is fixed, so there is no new layout based on dependencies.

### Ranked verdict
1. **Feels like a map: B, then A.** B is genuine semantic zoom with stable geometry and fades. A feels like clicking a tree with an auto-trigger.
2. **Scalability: B, then A.** B is smooth at 5000 nodes. A stutters at 5000 and costs 100 to 260 ms per expand. B's limit is the lift step rerunning over all edges when the open set changes, plus the one 52 ms spike.

### Untested
- **Prototype C** (G6 combos was the candidate; `@antv/g6` is at 5.3.1, 2026-05) was not built. The web search hit the session limit, so I did not research other candidates.
- **Environment:** only headless Chromium on Windows. No real GPU, no real mouse or touch input, no mobile.
- **Scale:** nothing above 5000 nodes (e.g. 50k).
- **A and edges:** A with elk was not tried. A's fcose quality setting was left at 'default', and no global relayout was tried to fix overlaps.
- **B and edges:** B with edge-aware sibling ordering was not tried. Hover, drag, selection highlight of changed nodes in A, and keyboard accessibility were not tested.
- **Overlay edge cases:** badge counts after a node's status changes; a diff of a real before/after pair (only synthetic statuses).
- **Persistence and polish:** URL state persistence; legend and search UX beyond the screenshots; devicePixelRatio above 1 (B sets 1).
- **Pure-CSS ceiling:** I did not test whether a plain SVG version of B would also hold up.