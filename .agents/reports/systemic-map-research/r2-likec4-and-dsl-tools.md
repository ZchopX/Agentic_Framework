<!-- verbatim subagent report, id a603850c30646f396; saved 2026-10-23 -->

# LikeC4 / Structurizr / CALM hands-on evaluation (2026-10-08)

Scratch root: C:\Users\donat\AppData\Local\Temp\claude\C--PyProjects-Agentic-Framework\dfe5a4fa-a8f0-4f6e-9b1a-a6bbb971abee\scratchpad\r2-likec4
- work/ holds the models and builds, scripts/ holds my scripts, shots/ holds the screenshots, pw/ holds Playwright, struct/ and calm/ hold the other two tools.
- C:\PyProjects\Agentic_Framework was not touched.
- One side effect outside scratch: Playwright put Chromium (118 MB) in C:\Users\donat\AppData\Local\ms-playwright.

## Environment
node v26.3.0, npm 11.16, Python 3.13, java 23, uv 0.11. No docker, and dotnet is broken.

## 1. LikeC4 install
- Command: `npm install likec4` into the scratch dir. The result is likec4 1.59.4 (latest).
- Install took 54 s and node_modules is 106 MB.
- There were no Windows problems. All CLI commands ran under Git Bash and PowerShell.
- A Playwright `install chromium` took 4m45s on this connection. That is only my test harness.

## 2. Model, commands and timings
- I made a generator (`scripts/synth.py`) that writes YAML, plus `scripts/yaml2c4.py` for YAML to .c4.
- The 60-element model came out at 52 elements and 102 relationships, 4 levels deep (system > subsystem > component > part).
- About 1 in 5 relationships carries `metadata { errors 'Timeout; 5xx' }`, and each has technology HTTP.
- Specification kinds are system, subsystem, component and part. There is one view per non-leaf element, an index view, and a `changed` view.

| Command | Result |
|---|---|
| `npx likec4validate m60` | valid, 1.8 s |
| `npx likec4 build m60 -o out60` | 3.3 s build, 6.5 MB |
| `npx likec4 build m60 -o x --output-single-file` | 2.5 s, one 3.9 MB index.html |
| `npx likec4 export json m60 -o m60.json` | 1.7 s, 192 KB |

- Other export formats: png, jpg, drawio, markdown.
- `likec4 gen` produces react, webcomponent, ts, dot, d2, mermaid and plantuml output.
- The JSON export contains elements (with metadata and tags), relations (with metadata), laid-out views, and the specification.
- The build is a SPA. Plain `python -m http.server` returns 404 on `/view/index/`, so I rebuilt with `--use-hash-history` to serve it statically. The single-file build was not opened in a browser (UNTESTED).

Screenshots I looked at, all taken in headless Chromium:
- **01_index.png:** a gallery of view cards with a "Search Ctrl+K" box and a dark-mode toggle. The cards are thumbnails of each view.
- **05_b_hover.png:** the Landscape view with 4 system boxes and 12 dashed "calls [HTTP]" edges. On hover each node shows three buttons: "Navigate to view", "Browse relationships" and "Open details". A small red bar at the bottom of System 0 is the `changed` tag.
- **06_c_select.png:** the component view "Comp 0.0.0" as a dashed container holding 2 parts, with neighbouring elements and labelled edges around it.
- **08_0.png:** the search modal for "Part". It lists elements with highlighted matches, id chips and "N views". There is also a `#changed` tag chip and a Views column.
- **10_styled_index.png and 11_styled_changed.png:** System 0 and the changed-element boxes turned red.
- **12_500_s0.png:** a dense view (see section 3).

## 3. Verification

**Drill-down in the static build: works.**
- The "Navigate to view" button on a node went from `#/view/index/` to `#/view/v_s0/`.
- The node aria-label reads "Opens view v_s0".
- Deep links work, and there are back/forward buttons and a breadcrumb title.
- Drill-down only happens if a view exists for that element. Auto-generating one `view of X` per non-leaf element handles that.

**Search: exists.**
- It is Ctrl+K and covers element titles, ids, and views.
- It does not search metadata values. "team-0" and "c0.py" returned nothing.
- A `#changed` query returned tagged elements.
- "Part 1.0" returned nothing, though "Part" matched. Fuzzy matching on dotted numbers is poor.

**Arbitrary metadata: yes.** `metadata { key 'value' }` on elements and on relationships. Keys are free-form strings. They appear in the JSON export and in MCP results.

**Whether the viewer displays metadata: UNTESTED.** I did not open the details panel for an element or an edge.

**Tags: yes, and they drive styling.**
- Tags must be declared in `specification { tag changed }`.
- A tag declaration gives it an automatic colour, but that colour only shows on a tag chip and the small bar. The elements themselves stayed blue.
- To colour the elements, I used this global style, which worked:
  `global { style hl element.tag = #changed { color red; border solid } }` plus `global style hl` at the end of each view.
- Order inside a view body matters. `global style` before `title` or `include` is a parse error.
- Tags must come first inside an element body. A tag after `description` gives "Expecting token of type '}' but found `#`".

**One view auto-including everything with a tag: yes.** `view changed { include element.tag = #changed }` showed the 3 tagged elements, plus 2 ancestor containers drawn as dashed context.

**Scale.** The synthetic relationships are random and cross-system, so these are worst cases.

| Elements | Relationships | Views | Result |
|---|---|---|---|
| 510 | 850 | 201 (excluding one giant view) | validate with layout 13 s; build 8.9 s (27 s wall); 15 MB output |
| 2069 | 3400 | 806 | validate failed on syntax errors from my earlier bug (not timed); fixed model: static build did not finish in 400 s, killed |
| 2069 | 3400 | 806 | `export json` 3m13s, 11 MB JSON |

- A single view `include element.kind = component` (about 250 nodes, 850 edges) hung validate for more than 170 s at 510 elements. I killed it. The layout of one large view is the bottleneck, so per-level views are mandatory.
- The 500-scale `v_s0` view (13 nodes, 70 edges) opened and rendered in about 4 s. It is a spaghetti of mostly illegible labels at full zoom. The 13-node views are readable once zoomed in, but dense graphs are not readable at fit-to-screen.
- I did not take 2000-element screenshots (UNTESTED). The build did not finish, so a UI render of that model was never produced.

## 4. Error messages, verbatim
Command: `likec4 validate err` on a deliberately broken file. The "Line N:" format is how the tool reports each problem. Output was 18 errors:
```
Line 9: Could not resolve reference to Tag named '#chnaged'.
Line 12: Could not resolve reference to Referenceable named 'x'.
Line 12: Could not resolve reference to Referenceable named 'nope'.
Line 13: Could not resolve reference to Referenceable named 'bb'.
Line 14: Could not resolve reference to Referenceable named 'zz'.
Line 15: Invalid parent-child relationship
Line 7: Duplicate element name x (a.x)
Line 8: Duplicate element name x (a.x)
Line 12: Source not resolved
Line 18: Duplicate view 'v'
Line 18: Validation failed: Element "a.ghost" is not resolved
Line 20: Could not resolve reference to Referenceable named 'nosuch'.
```
I trimmed it to representative lines from the 18.

Assessment for an LLM:
- Every error has a line number and a clear class (unresolved, duplicate, parent-child).
- It does not echo the offending source text, gives no column, and gives no "did you mean".
- Errors cascade. The duplicate `x` caused "could not resolve x" on line 12, which hides the real cause.
- The parent-child rule is surprising: a relationship between an element and its own descendant is rejected. My first synthetic model hit it.
- Syntax errors are poor: "Expecting token of type '}' but found `#`. Expecting: one of these possible Token sequences: 1. [Dot] 2. [-[] ...". One mistake at 500 elements produced 477 errors.
- A build on an invalid model still produced output. It did not fail loudly in my stale-output run, so a CI gate must run `validate` separately.
- Overall: usable if the agent loops on validate, but weaker than Structurizr's.

## 5. Programmatic route and MCP
Command: `likec4 mcp --stdio <dir>` (also `--http`, `-p`). I drove it over raw JSON-RPC; the server is "LikeC4" 1.59.4. `tools/list` returned these 20 tools:

| Tool | Does |
|---|---|
| list-projects | lists projects in the workspace |
| read-project-summary | reads a project summary |
| read-element | reads detailed information about an element |
| read-deployment | reads a deployment node or deployed instance |
| read-view | reads detailed information about a view |
| search-element | searches elements and deployment nodes across projects |
| find-relationships | finds relationships between two elements |
| find-relationship-paths | finds multi-hop relationship chains between two elements |
| query-graph | queries element hierarchy and relationships |
| query-incomers-graph | recursive upstream graph of a target |
| query-outgoers-graph | recursive downstream graph of a target |
| query-by-metadata | filters by metadata key, with exact, contains or exists modes |
| query-by-tags | filters with allOf, anyOf, noneOf |
| query-by-tag-pattern | tag prefix or substring match |
| batch-read-elements | reads many elements in one call |
| element-diff | side-by-side diff of two elements |
| subgraph-summary | table summary of a parent's descendants |
| apply-semantic-layout | applies a semantic layout to a view |
| render-view | renders a view inline as a diagram |
| preview-view | previews DSL text against the real model without saving |

- All 19 others are annotated read-only. `apply-semantic-layout` is the only one without a read-only hint, and it is layout only (not exercised, UNTESTED).
- **Nothing writes the model.** The agent must edit .c4 text itself.
- I ran three calls and one failed. `search-element` for "Comp 0.0.0" returned the element with its metadata and the views it appears in. `query-by-tags` with `anyOf ['changed']` returned the 3 tagged elements (s0, s1.u1.c0.p0, s3.u0). `query-by-metadata` failed with "expected string, received undefined" at path `key`, because I passed the wrong arguments.
- Metadata queries via MCP are therefore possible (argument shape: `key`, `value`, `matchMode`). I did not get a successful result.
- Other programmatic options exist but were not exercised: `gen model` (TS, UNTESTED), `gen react` and the npm `@likec4/core`. A TS builder API was not tested (UNTESTED).

## 6. JSON/YAML as input
- Only the DSL is accepted. The CLI help and the tool's file discovery gave no JSON or YAML source path.
- The JSON is output only. I did not test feeding it back, and `likec4 build` has no flag for it (UNTESTED beyond that).
- Generator: `scripts/yaml2c4.py` is about 45 lines (more than the 50-line budget in spirit, but it covers kinds, tags, metadata, relations and auto views). It reads YAML (nested `children`, `meta`, `tags`; a flat `relations` list with `errors`/`tech`) and writes .c4.
- Round trip verified by `scripts/rt.py`. YAML to .c4 to `likec4 export json` gave 52 of 52 elements with matching title, kind and metadata, and 102 of 102 relations matching source, target and errors. Tags matched (s0, s1.u1.c0.p0, s3.u0).
- Costs of this route:
  - Every YAML edit needs a regenerate plus a validate.
  - YAML cannot express LikeC4-only things such as custom styles unless I add them to the generator.
  - Identifier rules (dotted paths, no ancestor-descendant relationships) must be enforced in the generator.

## Structurizr (quick pass)
- **Current tool.** The repo `structurizr/structurizr` (release v2026.09.19, no downloadable assets) is the consolidated tool. It runs through Docker (`structurizr/structurizr`) or the web playground. Docker is not installed here, so the consolidated tool was UNTESTED.
- **What I ran.** `structurizr-cli` v2025.11.09, the older CLI zip (105 MB, runs on java 23). Command: `java -cp 'cli/lib/*' com.structurizr.cli.StructurizrCliApplication validate -w ok2.dsl`. It is the old CLI, not the consolidated tool.
- **Model.** About 14 elements (person, 2 systems, 3 containers, 2 components) and 3 views. Tags, properties and styles all worked.
- **Behaviours.**
  - Valid file: validate printed nothing (exit 0).
  - Flat identifiers by default. `u -> s1.api` failed until I added `!identifiers hierarchical`.
  - Inline `{ ... }` blocks must be multi-line.
- **Error messages (verbatim shape).** They carry the line number and echo the offending source line, which is more LLM-friendly than LikeC4:
  - `The destination element "s1.dbx" does not exist at line 21 of ...bad.dsl: s1.api.c1 -> s1.dbx "reads" "SQL"`
  - `Too many tokens, expected: component <name> [description] [tags] at line 7 of ...: c1 = component "Auth" { properties ...`
- **Export.** `export -f json` and `-f mermaid` produced `ok2.json` and 3 .mmd files.
- **Viewer.** An interactive zoomable viewer needs the Structurizr server or Docker. It was not run (UNTESTED), so there is no screenshot and no comparison on drill-down, search or tag highlighting.
- **Scale.** UNTESTED.

## CALM (quick pass)
- `npm i @finos/calm-cli` took 48 s and node_modules is 285 MB (v1.61.0). Commands include generate, validate, template, docify (docs website), diff, timeline, init-ai and hub.
- I wrote a 3-node JSON architecture with a bad reference, and `npx calm validate -a arch.json` printed this (trimmed):
```
code "connects-relationship-references-existing-nodes-in-architecture", severity "error",
message "'dbx' does not refer to the unique-id of an existing node.",
path "/relationships/r2/relationship-type/connects/destination/node",
line_start 10, character_start 101, hasErrors true
```
- That is machine-readable JSON with a path, line and column, and it is the most actionable of the three.
- It validates JSON directly, so no DSL is needed.
- I did not run `docify`, so rendering and drill-down are UNTESTED. It has no interactive zoomable map comparable to LikeC4's (UNTESTED).

## Verdict on LikeC4
**(a) viewer: yes. (b) source of truth: no. Pick (a), with the agent-facing model kept elsewhere.**

Why a viewer:
- It is fast to install (54 s, 106 MB).
- It builds a static site in about 3 s for roughly 50 elements and about 9 s for 500 elements, or a single self-contained HTML (3.9 MB).
- It has click-through drill-down, Ctrl+K search and tag-driven highlighting.
- A `changed` view that auto-includes everything with a tag is two lines of DSL.
- Metadata and tags survive in the JSON export and over MCP.

Why not the source of truth:
- It accepts DSL only. A YAML or JSON source needs my own generator, which round-tripped correctly (52 of 52 elements, 102 of 102 relations).
- The MCP is read-only, so an agent has no write API.
- Syntax errors cascade (477 errors from one slip at 500 elements) and have no column.
- The tool rejects ancestor-descendant relationships, and ordering rules inside bodies are strict.
- Layout cost grows quickly. One 250-node view hung for more than 170 s. 2000 elements took 3m13s for `export json`, and the full static build did not finish in 400 s.

Recommended shape for the project:
1. Keep a YAML or JSON source of truth that the agent edits, validated by your own schema. Its errors should be like CALM's JSON path, line and column output.
2. Use a ~50-line generator to emit .c4 with tags per task (`task_N`, `changed`) and one view per non-leaf element, then run `likec4 validate` as a gate.
3. Ship the static build for the human.
4. Version history comes from git on the YAML, not from LikeC4. LikeC4 has no built-in version history that I tested (UNTESTED).
5. Never ask for an "everything" view. Cap views at about 15-30 nodes.
6. Check whether a single-file build is acceptable on a server, since the SPA needs hash history or rewrite rules.

## Not done
- UI display of element and relationship metadata, the single-file build opened in a browser, and 2000-element rendering.
- Version history in LikeC4.
- The consolidated Structurizr tool (needs Docker) and any CALM render.
- The TS builder / model API.