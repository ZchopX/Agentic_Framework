<!-- verbatim subagent report, id aa54dd5af961ebf43; saved 2026-10-23 -->

ROUND-2 LANDSCAPE REPORT (research date 2026-10-08)

Method: GitHub API via `gh` for repo metadata (pushed_at, license, stars, latest release), README reads, arXiv abstract pages, vendor docs via fetch. The session limit hit near the end, so a few vendor pages (Lattix, CodeScene) are UNVERIFIED. Scratch files are in C:\Users\donat\AppData\Local\Temp\claude\C--PyProjects-Agentic-Framework\dfe5a4fa-a8f0-4f6e-9b1a-a6bbb971abee\scratchpad\r2-landscape\ (dl\*.md has the READMEs, meta.sh is the metadata helper). Nothing in the repo was modified.

Big finding: since about March 2026 there is a wave of agent-era "living architecture map" tools that are close to the target skill. Round 1 missed all of them. The strongest are groma.md, CodeBoarding, faultline and archik (section 2).

=====================================================================
(1) CANDIDATE TABLE
=====================================================================
Column legend:
- Status: pushed = last push to default branch; rel = latest GitHub release.
- H+Z: hierarchy and zoom support.
- Text/det: text-defined and deterministic.
- AI: AI-friendliness.
- Verified: VERIFIED by primary source unless noted.

### A. Agent-era architecture-map tools (closest to the goal)

| Tool | What it is | Status / license | H+Z | Text/det | AI | Link |
|---|---|---|---|---|---|---|
| **groma.md** | Deterministic scan of a repo into a C4 map, curated by human or agent. Stored as OKF Markdown, one file per element, in `groma/`. Local browser map. | pushed 2026-10-07; rel v0.6.6 (2026-10-05); MIT; 172 stars; README calls it an "early prototype" | Yes. Zoom from systems to containers to components, drafts (dashed), and nodes down to functions. | Scan is deterministic (fixed rules, no AI service). Model is plain Markdown in git. `groma export` writes a static site. | CLI-first (`groma agent-instructions`, `groma view --plain`, `groma view <file>` returns the owner of a file). Registers itself in AGENTS.md/CLAUDE.md. Tasks (Backlog.md) are pinned to components and highlight the nodes they touch. Revision browsing and commit-to-commit diff. GitHub Action posts before/after maps on PRs. | https://github.com/MrLesk/groma.md |
| **CodeBoarding** | Static analysis plus LLM naming into `analysis.json`; nested component diagrams; PR review that shows changed components and dependencies. | pushed 2026-10-08; rel v0.14.2 (2026-09-16); MIT; 2.5k stars | Yes. Expandable components and nested diagrams. | `analysis.json` is a file you can diff. The LLM only names and describes components, so output is not fully deterministic. Incremental update per component. | Can export Mermaid, MDX, HTML or rST; there is a GitHub Action; the README says to use the component descriptions in your coding agent's next prompt. | https://github.com/CodeBoarding/CodeBoarding |
| **faultline** | `faultline.yml` declares systems and rules. Live map shows what a change did to the structure. | pushed 2026-09-27; rel v0.5.1; MIT; 15 stars (very new) | Two levels. Systems view, then double-click to modules grouped by folder. Edges show the actual imports. | YAML declaration plus deterministic import analysis (oxc for JS/TS, adapters for ~15 other languages). Edges are tagged exact or inferred. | MCP, hooks, `fault diff main`, `fault check` (CI exit code). Answers cost about 50 tokens. Its own pilot of 36 runs (one repo, builder-written tasks) reports forbidden-import crossings of 0/6 with faultline vs 5/6 with the rule only in AGENTS.md. | https://github.com/anzal1/faultline |
| **archik** | Architecture as plain YAML (`.archik/*.yaml`), ELK auto-layout in the browser, no coordinates in the file. | pushed 2026-07-31; rel v0.19.5; MIT; 12 stars | Nesting exists (`notParent` rule, `archik complexity` flags deep nesting). `render --focus <id>` shows one node's neighbourhood. | Fully text-defined. `validate`, `drift` (vs source tree and TS/JS import graph), `affected --since main`. Also has sequence-diagram (behaviour) files. | Claude Code skill and `/archik:*` commands, MCP, staged diagram diffs shown green/red. | https://github.com/bacharSalleh/archik |
| **Scryer** | Model-driven development. A C4-style model of responsibilities, mapped to source lines and tests. The agent reads and writes it over MCP. | pushed 2026-10-02; rel v0.4.21; license NOASSERTION (README says "alpha"); 117 stars | Yes. Model tree, nodes down to symbols, groups. | Deterministic "observability layer": planned vs built, drift, test coverage. | MCP server for Claude Code, Codex and Copilot CLI. EARS-style claims. Test radius. | https://github.com/aklos/scryer |
| **oh-my-mermaid (omm)** | Skill `/omm-scan`. The agent writes a recursive tree of `.omm/**/{description.md,diagram.mmd}`. Viewer expands nested elements. | pushed 2026-04-07; rel v0.2.0; MIT; 2.3k stars | Filesystem tree is the hierarchy; the viewer shows expandable groups. | Text files, but the content is LLM-generated, so not deterministic. | Skills for Claude Code, Codex, Cursor and others. | https://github.com/oh-my-mermaid/oh-my-mermaid |
| **Birdview** | Skill that shows an architecture and constraints map plus the agent's declared change plan, waits for confirmation, then records verification. Standalone HTML. | pushed 2026-10-08; rel v0.3.1; MIT; 724 stars | Unverified in detail (README head only). | Standalone HTML. The README states it does not auto-observe agent actions. | Skill for coding agents. | https://github.com/Qiuner/birdview |
| **ArchEyes** | Agent renders an architecture graph; the human edits it; edits go back to the agent as node-ID instructions. Has a before/after diff view. | pushed 2026-07-28; rel v0.2.0; MIT; 8 stars | Groups are containers. | Edits return as structured IDs. | Claude Code plugin (`/archeyes:review`). | https://github.com/thisAAY/archeyes |
| **ontology-atlas** | `atlas/` folder of Markdown concepts (kind, uid, path) with an MCP server and a desktop/browser map. | pushed 2026-10-06; rel v1.6.1; MIT; 142 stars | Domains, capabilities, elements. Zoom not verified. | Markdown in git. | MCP for Claude Code, Codex, Cursor. Its own README says: "our benchmark has not measured a difference in answer quality with Atlas, and Atlas was slower." | https://github.com/wlsdks/ontology-atlas |
| **PR Lens** | Draws each PR as animated architecture/data-flow diagrams, posted in the PR. Skill via `npx skills add coldteadotai/pr-lens`. | pushed 2026-10-04; rel v0.13.0; MIT; 1.9k stars; "free for open source" | Shows blast radius on a system diagram. | Custom renderer. The README does not say whether it is deterministic. | Skill plus GitHub app. | https://github.com/coldteadotai/pr-lens |
| **system-atlas** | Skill that builds an isometric clickable atlas as one HTML file. Progressive-disclosure chapters, "go inside" a structure, and a generated `SYSTEM.md` text twin. | pushed 2026-09-01; MIT; 429 stars | Chapters plus drill-in. | One data file, text twin generated from it. | Agent skill. | https://github.com/inkboard/system-atlas |
| **vibeX** | Skill and CLI. Validated JSON specs (c4, lifecycle, links) render to one standalone HTML. Claims fail CI when the code drifts. | pushed 2026-10-06; rel v0.2.1; MIT; 388 stars | Nested boundaries (c4). | The spec is the artifact; the HTML is disposable. Mermaid export. | Skill for Claude Code and Codex. | https://github.com/Raja0sama/vibex |
| **StructSmith** | Local-first Structurizr alternative. Semantic model in SQLite, React Flow editor, MCP built in. | pushed 2026-10-08; rel v1.14.1; MIT; 22 stars | C4-style groups with drill-in. | Model is in a DB, not text files. | MCP and REST on the same domain layer. | https://github.com/dziksu/StructSmith |
| **ArchFlow** | Self-hosted IcePanel clone. C4 levels L1-L3, drafts and forks, version snapshots. | pushed 2026-05-18; rel v1.0.0; AGPL-3.0; 19 stars | Yes (L1 to L3). | DB-backed, not text-first. | None found. | https://github.com/TheAlexPG/ArchFlow |
| **c4hero** | Local-first browser C4 editor that saves plain `.dsl` files. | pushed 2026-10-07; rel v0.7.0; Apache-2.0; 56 stars | C4. | Text DSL. | Not checked. | https://github.com/c4hero/c4hero |
| **C4InterFlow** | Architecture-as-Code framework in C#. | pushed 2026-09-28; rel 2.6.0; MIT; 273 stars | C4 plus flows. | Code-defined. | Not checked. | https://github.com/SlavaVedernikov/C4InterFlow |
| **Keadex Mina** | C4 modeling tool, PlantUML-based. | pushed 2026-10-05; MIT; 204 stars | C4 drill-down (from the project description; not verified). | Not checked. | Not checked. | https://github.com/keadex/keadex |
| **DocHub** | Architecture-as-code from YAML manifests, PlantUML, Markdown. | pushed 2026-03-18; rel v3.15.0 (2025-08-10); Apache-2.0; 379 stars | Not checked. | YAML manifests. | Not checked. | https://github.com/DocHubTeam/DocHub |
| **Stratify** | Code maps (source, C4, IaC) rendered via DGML, CodeCharta or 3D Dep-Tree. Has architecture checks. | pushed 2026-02-15; rel v0.5.0; MIT; 114 stars | DGML supports collapse and expand of hierarchy. | Deterministic. | CLI. | https://github.com/dundalek/stratify |
| **Noodles (unslop)** | tree-sitter call graph, then LLM, then Mermaid. Interactive viewer with pan, zoom and drill into sub-diagrams. PR analyzer. | pushed 2026-03-13; MIT; 1.4k stars | Drill into sub-diagrams. | Needs an LLM key. | Python CLI. | https://github.com/unslop-xyz/noodles |
| **mindwalk** | Replays coding-agent sessions (Claude Code, Codex, pi) as light on a 3D map of the repo. Shows the agent's footprint. | pushed 2026-08-10; rel v0.5.0; MIT; 1.4k stars | 3D map. | Reads session logs. | Local Go binary. | https://github.com/cosmtrek/mindwalk |
| **fallow** | Rust codebase intelligence for TS/JS: health, boundaries, dead code, duplication, "one graph". | pushed 2026-10-08; rel v3.32.0; MIT; 5k stars | Not a map UI (not checked). | Deterministic. | Has an agent-skills repo (fallow-skills). | https://github.com/fallow-rs/fallow |
| **katana** | Source-free architecture maps for agents, plus deterministic refactoring. | pushed 2026-09-24; rel v0.2.0; Apache-2.0; 12 stars | File-level maps. | Deterministic. | Aimed at agents. | https://github.com/vgmakeev/katana |
| **Archify** | Skill that turns ideas, plans or repos into interactive HTML. Claims 79.6k stars and 5.3k forks (repo created 2026-04-15). | pushed 2026-10-08; rel v3.0.1; MIT | General purpose. | LLM-generated HTML. | Skill for Claude Code, Cursor and Codex. | https://github.com/tt-a1i/archify |
| **drawio-skill (Agents365-ai)** | Skill that turns text, code, Terraform and OpenAPI into draw.io files. | pushed 2026-10-02; rel v3.4.0; MIT; 10k stars | Draw.io pages. | `.drawio` XML. | Skill. | https://github.com/Agents365-ai/drawio-skill |
| **Other small or less-checked tools** | gitdiagram (18k stars, MIT), codeflow (5.4k), Voicetree (markdown-node graph plus agent terminals, license NOASSERTION), Aegis (method pack, not a map), agent-vis (0 stars, no license), CodeWiki (FSoft, ACL 2026, MIT), DeepWiki-open (18k, MIT), isobar and code-flow ("what your agent changed", 0-1 stars), coderadius (24 stars, v0.1.0). | all pushed 2026 | not assessed | not assessed | not assessed | gh search results |

### B. Established commercial and OSS modeling and diagram tools

| Tool | What it is | Status / license | H+Z | Text/det | AI | Link |
|---|---|---|---|---|---|---|
| **Ilograph** | YAML diagrams (resources tree, perspectives, sequences, contexts). Zoom and "instant focus" in the viewer. | Proprietary SaaS plus Desktop. Pricing sources disagree, so UNVERIFIED. Free tier and Pro exist. HTML export is on Pro, Desktop and Team. Spec page: "Copyright 2025 Ilograph LLC". | Yes. Tree is shared across perspectives; sub-sequences are zoomable. Per the vendor, zoom shows fine detail. | Text (YAML). Layout is automatic. | Official `ilograph/skills` repo (/generate-ilograph, /update-ilograph; Apache-2.0; pushed 2026-09-10; 9 stars). Community: ilograph-mcp-server (MIT, 3 stars, v1.0.3 2025-06-16) and ilograph-cli (validates and edits YAML). | https://www.ilograph.com/docs/spec/ ; https://github.com/ilograph/skills |
| **IcePanel** | SaaS C4 modeling with layered zoom. | Proprietary, paid plans only for MCP. | Yes (C4 levels). | Not text-first (SaaS model). | Remote MCP at mcp.icepanel.io: read and write of objects, connections, ADRs. Cannot create diagrams. OAuth. Tested with Claude, Claude Code, Codex, Cursor and VS Code. | https://docs.icepanel.io/experiments/mcp-server-beta |
| **Eraser** | Diagram-as-code SaaS with AI generation. | Proprietary. API on Starter and above. | Folders and files, not semantic zoom. | Text code. | Remote MCP with about 30 tools. `manually_*` tools write code verbatim without AI. | https://docs.eraser.io/docs/mcp |
| **Archi (ArchiMate)** | Open-source ArchiMate modeler. jArchi scripting, coArchi for git collaboration. | pushed 2026-10-07; MIT; 1.3k stars; no GitHub releases listed. Latest Archi version UNVERIFIED (5.5.0 in March 2025 via a packaging repo; secondary). | Layers and nested views. | XML model; scripting via jArchi (pushed 2026-09-28). | No MCP found. | https://github.com/archimatetool/archi |
| **Sparx Enterprise Architect** | Commercial UML/ArchiMate suite. | Latest EA 17.1.1716 (third-party tracker). Sparx press: Kernaro AI in beta (May 2026) and Trerado (April 2026). No MCP found. | Yes (UML packages). | Binary or DB model. | Kernaro AI beta. | https://sparxsystems.com/press/newsletter/2026-05.html (search snippet only) |
| **Structure101** | Structural analysis, DSM-like. | VERIFIED: acquired by Sonar; "products are no longer for sale"; to be folded into SonarQube. Date: acquisition announced October 2024 (secondary sources). | n/a | n/a | n/a | https://www.sonarsource.com/structure101/ |
| **Sonargraph** | Architecture DSL, dependency visualization. Editions: Architect, Build, Developer, Enterprise, Explorer (free). | Commercial. Latest version not stated on the page. | Visualization hierarchy not stated. | Architecture DSL (Groovy scripting). | VERIFIED on vendor page: "Zügel MCP Server" that understands the DSL and guides agents. | https://www.hello2morrow.com/products/sonargraph |
| **Lattix** | DSM-based architecture tool. | Site still lists Team and Enterprise editions. Status UNVERIFIED (vendor page returned HTTP 403; I found no dated release info). | DSM. | Not checked. | Not checked. | https://www.lattix.com/products |
| **CodeCharta** | 3D software-city map from metrics (`.cc.json`). Has a delta view between two revisions. | rel ana-2.1.0 (2026-10-05); pushed 2026-10-07; BSD-3-Clause; 544 stars | Folder tree with a structure modifier; city metaphor. | Deterministic importers: Sonar, Tokei, git log, CSV, DependaCharta and others. | None mentioned. | https://github.com/MaibornWolff/codecharta |
| **CodeScene** | Behavioral code analysis (hotspots, CodeHealth). | MCP server repo `codescene-oss/codescene-mcp-server` rel MCP-1.5.9 (2026-10-08), license NOASSERTION. MCP launch 2026-04-29 (Product Hunt, secondary). Runs locally per vendor. The vendor page itself was not fetched (session limit). | Not a map. | Deterministic metrics. | MCP for agents. | https://github.com/codescene-oss/codescene-mcp-server |
| **Glamorous Toolkit / Moose** | Moldable development environment. | gtoolkit rel v1.1.613 (2026-10-07); MIT; 1.6k stars. Moose pushed 2026-10-07, MIT. | Custom inspectors and views, built by you. | Smalltalk image, not plain text. | gt4llm exists (16 stars). README says "explore faster with AI". | https://github.com/feenkcom/gtoolkit |
| **Backstage** | Software catalog, TechDocs, and the `catalog-graph` plugin (relations graph card and page). | Apache-2.0; rel v1.55.3 (2026-09-29); 34.6k stars | Entity relation graph; it is not a semantic-zoom architecture map. | Catalog YAML. | Not checked. | https://github.com/backstage/backstage/tree/master/plugins/catalog-graph |
| **Cartography (CNCF)** | Infra and asset graph in Neo4j. | rel 0.142.0 (2026-10-07); Apache-2.0; CNCF sandbox | Graph only. | Ingestion is deterministic. | Not checked. | https://github.com/cartography-cncf/cartography |
| **Sourcegraph** | Code search and intelligence. | Public repo archived (pushed 2024-09-02); the code went proprietary (secondary source). Cody was split off. SCIP moved to an independent project with open governance in March 2026 (Sourcegraph blog, via search snippet). `scip-code/scip` rel v0.10.0 (2026-09-03). Zoekt (Apache-2.0) is still active. | n/a | n/a | n/a | https://github.com/scip-code/scip |
| **CodeSee** | Codebase maps SaaS. | Acquired by GitKraken in 2024 (secondary). I could not confirm its current status. | n/a | n/a | n/a | https://www.schneider.im/gitkraken-acquired-codesee/ |
| **draw.io / diagrams.net** | Diagram editor with page links and layers. | rel v32.3.0 (2026-10-07); Apache-2.0; 8.6k stars. Official `jgraph/drawio-mcp` (Apache-2.0, 5.6k stars, pushed 2026-10-03) hosted at mcp.draw.io. | Drill-down only via manual links or pages. | `.drawio` XML. | MCP and plugins for Claude Code, Codex and Copilot. | https://github.com/jgraph/drawio-mcp |
| **Excalidraw** | Whiteboard. | v0.18.1 (2026-04-21); MIT; 133k stars. `excalidraw/excalidraw-mcp` v0.3.2, no license. | No hierarchy. | JSON. | MCP. | https://github.com/excalidraw/excalidraw-mcp |
| **Kumu** | Relationship and systems mapping SaaS. | Pricing from a third-party site only (UNVERIFIED). | Hierarchy and zoom not covered in the docs I read. | JSON "blueprints": `elements` and `connections` arrays, importable from a URL. | No API found. | https://docs.kumu.io/guides/import/blueprints |
| **Mermaid MCPs** | mcp-mermaid (hustcc, MIT, 642 stars, rel 0.4.1 on 2026-02-12), claude-mermaid (215 stars), nereid (67 stars). | all pushed 2026 | None. | Text. | MCP. | https://github.com/hustcc/mcp-mermaid |
| **Obsidian / Foam / Logseq / Dendron** | Note tools with graph views. | Obsidian v1.14.4 (closed source). Foam vscode@0.46.0 (2026-09-30). Logseq 2.0.2 (2026-10-07; AGPL-3.0). Dendron pushed 2025-11-13, no release, effectively dormant. | Flat graph; Breadcrumbs plugin adds hierarchy. | Markdown links. | n/a | https://github.com/foambubble/foam |
| **Sprotty / Eclipse GLSP** | Diagramming frameworks (TS). | Sprotty rel v1.4.0 (2024-12-17), pushed 2026-10-04, EPL-2.0. GLSP v2.8.0 (2026-08-28). | A semantic-zoom prototype exists (De Carlo et al., MODELS 2022; see section 4). It is not a core Sprotty feature. | Model-driven. | None. | https://github.com/eclipse-sprotty/sprotty |
| **JointJS / JointJS+ (Rappid)** | Diagram library. | Core MPL-2.0 (v4.3.3 router package, 2026-09-04). JointJS+ is commercial (about $3,490/licence, third-party listing, UNVERIFIED). | Embedding, plus a collapse/expand demo (docs). | Programmatic. | None. | https://github.com/clientIO/joint |
| **Ogma (Linkurious)** | Commercial graph-viz JS library. | Price not public; vendor listed as "Linkurious (A Nuix company)" on Capterra. | Not checked. | n/a | n/a | capterra listing (search) |
| **Cosmograph / cosmos.gl** | GPU WebGL force graph. | `cosmosgl/graph` rel v3.5.0 (2026-10-05); MIT. | Flat. No hierarchy; it has point clustering forces only. | Data-driven. | n/a | https://github.com/cosmosgl/graph |
| **Neo4j Bloom / NeoDash** | Graph exploration and dashboards. | Bloom 2.37.0 listed 2026-09-23 (search snippet of Neo4j release notes). NeoDash rel 2.4.11 (2025-08-04); Apache-2.0. | Flat graph. | Cypher. | n/a | https://neo4j.com/release-notes/bloom/ |
| **Memgraph Lab** | Graph UI with GraphChat (LLM). | Memgraph core is NOASSERTION. Lab is in the Community tier per docs (secondary). | Flat. | Cypher. | GraphChat. | https://memgraph.com/docs/memgraph-lab/features |
| **GraphXR (Kineviz)** | 3D graph SaaS. | Proprietary, free personal tier; price UNVERIFIED. | 3D, flat. | n/a | n/a | alternativeto listing (search) |
| **InfraNodus** | Text-network analysis with an MCP server (30 tools). | MIT MCP repo. | n/a | Text to graph. | Yes. Not about software architecture, so low relevance. | https://infranodus.com/api/mcp |
| **Emerge** | Interactive codebase dependency visualization (YAML config). | pushed 2026-08-07; rel 2.0.7 (2024-07-12); MIT; 1.2k stars | Filesystem graph, clusters. | Deterministic. | None. | https://github.com/glato/emerge |
| **Gource / gitlogue** | Git history animation. | Gource gource-0.56 (2026-03-06; GPL-3.0). gitlogue pushed 2026-10-08. | n/a | Deterministic. | n/a | https://github.com/acaudwell/Gource |
| **JSCity / Sourcetrail** | Code city (JS), and code explorer. | JSCity last pushed 2019 (GPL-2.0). Sourcetrail archived, last release 2021.4.19. Both dead. | n/a | n/a | n/a | https://github.com/CoatiSoftware/Sourcetrail |
| **Doxygen / Sphinx / pyreverse / Madge / pydeps** | Classic doc and graph generators. | Doxygen 1.18.0 (2026-08-13; GPL-2.0). Sphinx v9.1.0 (2025-12-31). pylint v4.1.2 (2026-10-02; GPL-2.0), which contains pyreverse. pydeps v3.0.9 (2026-10-01; BSD-2). Madge pushed 2026-01-21 (MIT), but its README shows no release and the maintainer note says it is a free-time project with the last donation in 2021. | Flat dependency or class graphs. | Deterministic (dot/svg). | None. | https://github.com/pahen/madge |
| **DSM tools** | Dependency Structure Matrix. | Tiny and dead (dtangler 2012; lein-topology 2019; rust-dsm 2026, 0 stars). Real DSM support is in the commercial Lattix and Sonargraph. | DSM is hierarchical by nature. | Deterministic. | n/a | n/a |
| **jQAssistant** | Scans a codebase into Neo4j and checks architecture rules. | rel 2.9.1 (2026-02-17); GPL-3.0; 297 stars | Graph. | Deterministic. | n/a | https://github.com/jQAssistant/jqassistant |
| **ArchUnit / dep-tree** | Test-based architecture rules. 3D dependency view. | ArchUnit v1.5.1 (2026-09-25; Apache-2.0). dep-tree v0.23.4 (2025-03-22; MIT). | n/a | Deterministic. | n/a | https://github.com/TNG/ArchUnit |
| **Claude skills for C4** | softaworks/agent-toolkit c4-architecture (Mermaid; MIT; 2.5k stars; pushed 2026-03-05). jrjsmrtn/c4-skills (Structurizr DSL; MIT; 0 stars; pushed 2026-09-30). cheriftj/c4-model-skill (v2.0.0, 2026-04-24; MIT; 43 stars). JosiahSiegel c4-model (LikeC4; MIT). | | C4 levels. | Text. | They are skills. | https://github.com/jrjsmrtn/c4-skills |

=====================================================================
(2) TOP 5 ADDITIONS ROUND 1 MISSED
=====================================================================

1. **groma.md** (https://github.com/MrLesk/groma.md). VERIFIED from the README.
   - Deterministic scan into C4 elements, stored as OKF Markdown (Google Cloud's "Open Knowledge Format" v0.2: plain Markdown with YAML frontmatter; spec repo GoogleCloudPlatform/open-knowledge-format, Apache-2.0, pushed 2026-08-21).
   - Later scans refresh only code references and keep the curated names, descriptions and relationships. That is the "living model" property.
   - `groma view <file>` resolves a file to the element that owns it. Task pins highlight the components a task touches.
   - Past revisions can be opened with their source. `groma export --from <base> --revision <head>` produces a comparison site. A GitHub Action posts PR diffs.
   - Caveats: "early prototype" per its README; C4 levels only (system, container, component, plus symbols); macOS needs Apple Silicon; the only licence is MIT.
   - It covers nearly every stated goal. Study its file contract (docs/component-markdown.md) and its scan-versus-curation split.

2. **CodeBoarding** (https://github.com/CodeBoarding/CodeBoarding). VERIFIED.
   - Static analysis plus LLM naming into `analysis.json`; nested component diagrams; PR review showing changed components and dependencies; incremental per-component updates; MIT; released v0.14.2 on 2026-09-16.
   - It is the closest prior art for "what did the agent change, shown on the architecture".
   - Trade-offs: the LLM names components, so the output is not deterministic; analysis can send code to a model provider.

3. **faultline** (https://github.com/anzal1/faultline). VERIFIED.
   - Declared systems in YAML, deterministic edges with exact vs inferred tags, a map that "never moves", a timeline and replay of commits and agent turns, and a token-cost table.
   - It is the best model for "changed-node highlighting" and "history over time": new edges green, crossed rules red, changed systems amber.
   - Only two zoom levels. Very young (15 stars). The pilot study is the builder's own and is small.

4. **archik** (https://github.com/bacharSalleh/archik). VERIFIED.
   - Pure-YAML model with no coordinates (ELK lays it out), so diffs stay meaningful.
   - A validator checks internal consistency, drift against the source, and edges against the import graph; it can also check against OpenTelemetry service graphs.
   - It also covers the behavior side (sequence YAML, use cases with test paths).
   - Closest match to "exception paths and junctions as text", because behaviour is a first-class file type.

5. **Ilograph, plus the official `ilograph/skills` repo** (https://github.com/ilograph/skills). VERIFIED.
   - The only mature tool I found that actually offers semantic zoom over a text-defined (YAML) model: a shared resource tree, multiple perspectives, and zoomable sub-sequences. It also exports to self-contained HTML (Pro, Desktop, Team).
   - Because it is SaaS and proprietary, treat it as a UX reference and a possible export target rather than a dependency.
   - The vendor itself now ships agent skills that generate `ilograph.yaml` from a codebase with code citations, plus an `/update-ilograph` command that keeps it in sync.

Honorable mentions:
- **Scryer** (responsibility model with tests and drift).
- **mindwalk** (agent footprint replay).
- **CodeCharta**: its delta view and `.cc.json` hierarchy are the only mature, deterministic "software city plus compare revisions" setup.
- **oh-my-mermaid**: its on-disk layout (nested folders = hierarchy) is the simplest agent-writable format.

=====================================================================
(3) SEARCHES THAT RETURNED NOTHING USEFUL (do not repeat)
=====================================================================
- gh topic searches: `topic:codebase-knowledge-graph`, `topic:software-city`.
- `gh search repos` with several words plus `--updated` filter: "architecture map coding agents", "codebase map agent skill", "c4 mcp", "semantic zoom architecture", "software city visualization", "hierarchical architecture diagrams codebase" and "backstage catalog graph" returned nothing. The same queries with fewer words, or without `--updated`, did return results.
- gh searches for "linkurious ogma", "dependency structure matrix" (only dead repos), "obsidian graph" (flat-graph plugins only), "semantic-zoom" (unrelated).
- WebSearch "Sonargraph latest release 2026" returned only SonarQube pages.
- WebSearch for Lattix 2026 status returned only 2007-era press.
- WebSearch for a Kumu API found nothing; GraphXR pricing came only from aggregator sites.
- WebFetch `lattix.com/products` returned HTTP 403; `ilograph.com/pricing` returned 404; `codescene.com/product/mcp-server` was blocked by the session limit.
- The pyreverse docs page was only navigation text; I got no options from it.
- "Whiteboard" (devdotfast, YC W26) was only found in secondary write-ups; I could not find its GitHub repo. UNVERIFIED.
- `c4mjs/c4mjs` is archived (the repo is now `c4mjs-old`, last push 2023-01-04), so it is not usable.

=====================================================================
(4) RESEARCH PAPERS (all VERIFIED from arxiv abs pages unless noted)
=====================================================================
- **LLM Agents Can See Code Repositories**, arXiv 2606.14061 (first submitted 2026-06-12; ASE 2026). Hybrid text plus visual repository graphs cut input tokens by up to 26% with accuracy the same or better. Vision-only hurts. Supports giving agents a text model, with visuals only as an extra. https://arxiv.org/abs/2606.14061
- **Trust-Calibrated Code Review**, arXiv 2606.01969 (2026-06-01, JetBrains collaboration; 17 practitioners, then a 43-person survey). Reviewing LLM multi-file changes is "a trust-calibration problem rather than a diffing problem". The workflow has three levels (overview, file, snippet) and a "zooming in/out" construct. https://arxiv.org/abs/2606.01969
- **Towards Actionable Visualization**, Merino, Ghafari and Nierstrasz, arXiv 2608.22151 (2026-08-23; VISSOFT 2026). Generative AI pushes the cost of visualization toward zero; the open problem is helping people understand large systems and agent reasoning. https://arxiv.org/abs/2608.22151
- **AI-Guided Exploration of Large-Scale Codebases**, arXiv 2508.05799 (2025-08-07). Hybrid of deterministic reverse engineering and LLM-guided exploration; Java prototype only, no empirical evaluation yet. https://arxiv.org/abs/2508.05799
- **Code2UML**, arXiv 2605.24453 (2026-05-23). Deterministic compaction into diagram-specific views before the LLM. Entity recall is only 0.313, which the authors say is deliberate (they keep only the architecturally important elements). https://arxiv.org/abs/2605.24453
- **Software Systems as Cities: A Controlled Experiment**, Wettel, Lanza and Robbes, ICSE 2011. 41 participants; the city metaphor gave significantly higher task correctness and lower completion time. Source: search snippet and ICSE 2011 listing (abstract only, not full text). https://www.inf.unibz.it/~rrobbes/p/ICSE2011-codecity.pdf
- **Semantic Zoom and Off-Screen Elements in GLSP**, De Carlo, Langer and Bork, MODELS 2022, pp. 221-231, DOI 10.1145/3550355.3552412 (open access via the TU Wien repository). It is the only academic semantic-zoom implementation for web modeling I found. Source: search result pages, not read in full.
- UNVERIFIED: arXiv 2603.21178 (LLM architecture-view generation over 340 repos) and 2601.13007 (ArchAgent). I saw only search summaries.
- I found no controlled study measuring how any map or diagram helps a human understand agent-made changes. The evidence is qualitative, vendor-side or position papers. The "comprehension debt" literature is mostly essays; the one RCT figure (52 engineers, 50% vs 67% on a quiz) is a blog's report of a study, UNVERIFIED against the original paper.

=====================================================================
Caveats for the caller
=====================================================================
- Star counts of new repos (especially Archify at 79.6k in 6 months) are not a quality signal. I did not audit them.
- Most agent-era tools are less than 6 months old and mostly maintained by one person (versions 0.x). Several carry "alpha" or "prototype" warnings in their own READMEs.
- Where the table says "not checked" I only read the head of the README; that does not mean the feature is absent.