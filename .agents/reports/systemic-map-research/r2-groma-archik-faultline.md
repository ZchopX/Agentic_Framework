<!-- verbatim subagent report, id a8b08b8a6e023d12c; saved 2026-10-23 -->

## Round-2 hands-on: groma.md vs archik vs faultline

All three installed with `npm i` and ran on Windows 10 x64 (Node 26.3). Test repo: pallets/click shallow clone (~13k LOC, `src/click`), one copy per tool. Scratch root: `C:\Users\donat\AppData\Local\Temp\claude\C--PyProjects-Agentic-Framework\dfe5a4fa-a8f0-4f6e-9b1a-a6bbb971abee\scratchpad\r2-closest`. Screenshots are in `shots/`: `groma-0.png`, `groma-cmp1.png`, `archik-0.png`, `fault-0.png`, `fault-1.png`. Agentic_Framework was cloned read-only and could only be run lightly; see the end.

**Verdict in one line:** archik is the closest fit for the agent-edits-text part, groma.md is the best human map and history view, and faultline's change/diff/replay mechanics are the best to borrow. None is reusable as the base without major extensions.

### groma.md 0.6.6 (MIT)
- **Windows install:** works. The npm package has no install scripts and ships `groma.md-windows-x64` as an optional dependency. `groma --version` returned 0.6.6, and scan, web, view and lint all ran, so the README's macOS-Apple-Silicon note is irrelevant here. Friction:
  - `git clone` of the repo itself fails on Windows with "Filename too long" (backlog and test-fixture paths). Install from npm instead, or set `core.longpaths`.
  - `groma init` requires `--directory groma`. Scanners must be added separately with `groma scanner add @groma/scanner-python`.
  - `groma export` hung on all four attempts (plain, `--revision`, `--from/--revision`, timeout 60-100s) and left only `render.js` in the output dir. A shell `timeout` may not have killed the child process, so it needs root-causing. Treat static export as broken on this setup.
- **On-disk format:** one Markdown file per element with YAML front-matter (OKF 0.2 bundle). Sample, `groma/systems/click/components/core.md`:
  ```
  ---
  type: C4 Component
  title: Core
  status: stable
  groma: {id: core, parent: click, code: [{scanner: python, file: src/click/core.py}]}
  description: Core command model
  ---
  Command and Group classes.
  ## Relationships
  | Source | Target | Description | Technology |
  | [src/click/core.py](...) | [src/click/parser.py](...) | Core uses parser | python call |
  ```
  Other records: `groma/index.md`, `project.md`, `scanners.json`, `externals/shell.md`, `flows/*.md`.
- **Hierarchy depth:** fixed at 3 levels (system, container, component). The agent guide says groups and flows "add no C4 containment level". Source code (files, functions) appears as a viewer detail under a component, not as boxes. Deeper than 3 is not possible.
- **Zoom/drill-down:**
  - It is an isometric 3D map (Iso, 2D, Layers modes) with a hierarchy tree panel, search (Ctrl K) and a detail pane. Polished.
  - On click, the scan dumped loose components into a synthetic "Unidentified container", so the map was not a real hierarchy until curated.
  - I did not click-drill into 2D mode (script error), so zoom-to-container feel is UNTESTED beyond the screenshot and the tree.
- **Changed-node highlighting:**
  - The revision picker lists commits plus "compare 2 revisions". I compared "curated" against the working tree, got a CHANGES tab with per-node `+0 -0 ~` counts, and changed boxes were coloured in the iso view.
  - Noise: it showed +1 and ~30 for a model with one new file and one edited file. Root cause not investigated, so UNKNOWN. The scan "refreshed 32" documents each time.
  - History over time is real (compare any two commits, and browse an old revision with its source), but it is the same gated model-diff and is noisy.
  - Per-task highlighting is via Backlog.md task pins only. That is UNTESTED, as backlog.md was not installed.
- **Drift check:** there is no drift command. `groma lint` only reports possible duplicate functions. Drift is handled by scan reconciliation.
  - I deleted `src/click/globals.py` and rescanned. Output was `ok / created 0, refreshed 33 …` with no warning. The component `globals` silently lost its `code:` reference and stayed in the map as a ghost.
  - A manually corrupted `parent: nonexistent` gave `groma/systems/click/components/core.md: unknown parent id "nonexistent"` (printed by scan and view, exit not recorded).
- **Agent surface (CLI only, no MCP):**
  - `init [project-name] --directory`, `web --port`, `export <dir> [--url --revision --from]`, `view [target] [--plain]`, `scan [--watch]`, `scanner {settings,setup,check,discover,add,update,install}`, `lint`.
  - `draft <kind> <name> [target]`, `add <actor|external|draft|flow|relation|group>`, `remove`, `edit`, `accept`.
  - `instructions [guide]`, `agent-instructions [inspect|structure|describe|relationships|backlog]`.
  - `edit` options: `--title --overview --steps --description --technology --draft --group --ungroup --parent --combine --detach --id`.
  - Rules agents must follow: "do not edit Groma-owned files directly", relations need exact source-file endpoints plus `--technology`, and existing relationships cannot be removed.
  - Friction hit: `add relation` needs `--technology`, `add external` needs `--overview`, and flow steps need exact element links. I could not get a flow created, so flows are UNTESTED.
- **Determinism:** the Python scanner output was stable. Rescanning twice with no code change produced no git diff. The Python scanner is syntax-only: it found 0 relationships (`PYTHON_SYNTAX_ONLY`, "call targets are unresolved"), so the hierarchy is only folder and file structure until an agent adds relations by hand.
- **Phone home / keys:** no AI service and no keys. Its only network use is downloading scanner packages.
- **Issues:** the GitHub issue tracker is disabled, so there is no failure-mode signal. Repo pushed 2026-10-07, 172 stars.

### archik 0.19.5 (MIT)
- **Windows install:** clean. `archik init` also installs a Claude skill, 14 slash commands, an engineering-loop doc and a CLAUDE.md. Use `--no-skill --no-commands --no-loop` to avoid that.
- **On-disk format:** a single YAML file, `.archik/main.archik.yaml`, with `nodes` and `edges` and optional sub-files via `archikFile`. Sample from my click model:
  ```
  nodes:
   - {id: parse-fn, kind: function, name: OptionParser, parentId: parser, description: ..., sourcePath: src/click/parser.py}
  edges:
   - {id: core-parser, from: core, to: parser, relationship: uses}
  ```
  - Node kinds: 35. Edge relationships: only 16 fixed values (`http_call … uses`), and `calls` is rejected.
  - The schema also covers use cases, sequence diagrams (`realizes`), actors, constraints, owner, status (proposed/active/deprecated) and ECB stereotypes. Behaviour and flow modelling exists, but I did not exercise it, so it is UNTESTED.
- **Hierarchy depth:** unlimited via `parentId`. I built a 4-level chain (click, parser, OptionParser, deep leaf) and it rendered as nested boxes.
- **Zoom/drill-down:** nesting is shown in place, all expanded, in a dark, ELK-laid-out React Flow canvas with spacing, collapse/expand and fullscreen buttons. It is a diagram editor, not a semantic zoom. Pan/zoom feel beyond the screenshot is UNTESTED.
- **Changed-node highlighting:**
  - `archik affected --since HEAD~1` maps changed files to nodes by `sourcePath` prefix, and ancestors are included. After editing `parser.py` it listed `click, parser, parse-fn, parse-leaf`, and ended `1 changed file → 4 nodes, 0 slices across 0 use cases, 0 unmapped`.
  - `archik diff <ref> --out x.svg` writes a model diff (e.g. `~ node core / sourcePath: "src/click/core.py" → "src/click/gone.py"`).
  - I saw no in-canvas "changed this task" overlay in the README or UI, so that is UNTESTED and probably missing.
- **Drift and validation, verbatim after breaking the model:**
  - `archik validate` on `sourcePath: src/click/gone.py`:
    ```
    ✗ .archik\main.archik.yaml
      • nodes.1.sourcePath: node "core" sourcePath "src/click/gone.py" does not exist on disk ...
    exit 1
    ```
  - `archik drift` after adding `src/newpkg/` and removing a file:
    ```
    1 ORPHAN — nodes with no matching code
      ✗ core   sourcePath src/click/gone.py not found
    1 UNMAPPED — code with no matching node
      ✗ src/newpkg/
    archik drift: 2 issues found   (exit 1)
    ```
    `--json` is also available.
  - A deleted file inside a mapped directory (`src/click/globals.py`) was not flagged. Drift is directory-level.
  - Invalid relationship, verbatim: `edges.0.relationship: Invalid option: expected one of "http_call"|"grpc"|...|"uses"`.
  - Healthy case: `✓ No drift detected — diagram matches source tree.`
- **Agent surface:**
  - CLI: `init, import (compose|mermaid), dev, start, stop, status, validate, render, watch, q (describe|deps|dependents|list|edges|impact|stats), schema, diff, suggest (show|set|accept|reject), merge-driver, hooks (pre-commit, --with-drift), otel check, owners (CODEOWNERS), drift, affected, trace, alpha, evolution, patterns, mcp`.
  - MCP, verbatim tools/list (27 tools, only the stdio server answered, not a full agent session): `archik_schema, archik_describe, archik_deps, archik_dependents, archik_impact, archik_list_nodes, archik_list_edges, archik_stats, archik_usecases, archik_describe_usecase, archik_actors, archik_sequences, archik_trace, archik_validate, archik_drift, archik_affected, archik_suggest_show, archik_suggest_set, archik_suggest_accept, archik_suggest_reject, archik_evolution_status, archik_evolution_reflect, archik_evolution_proposals, archik_evolution_propose, archik_evolution_report, archik_patterns_list, archik_patterns_show`.
  - It has a suggest, then human-accept, sidecar workflow: the agent proposes and the human accepts.
- **Determinism:** `archik render --out` run twice gave byte-identical SVGs (`cmp` OK). `drift` and `affected` are pure functions of the YAML plus the file tree.
- **Phone home / keys:** none found. The one `fetch` is a local HEAD ping in `daemon.ts`. The evolution feature is local-only and opt-in.
- **Issues:** none. All 12 open items are dependabot PRs. 12 stars, last push 2026-07-31, so it is young and single-maintainer.

### faultline 0.5.1 (`@anzalabidi/faultline`, CLI `fault`)
- **Windows install:** clean, 58s for the three tools together. Dependencies include `@anthropic-ai/sdk`, but it is only used by the optional `fault init --ai` with `ANTHROPIC_API_KEY`. I did not use it.
- **On-disk format:** `faultline.yml`, flat list of systems:
  ```
  systems:
   - {id: platform, name: Platform, paths: [src/click/_compat.py, ...]}
  rules:
   - {deny: "platform -> core", reason: "platform must stay leaf"}
  ignore: [...]
  ```
  Systems map to path globs, and the dependency graph is derived from import statements. `fault init` auto-proposed a single system `src/click/**`.
- **Hierarchy depth:** no nesting in the model. The map has system boxes, and double-clicking one shows its modules grouped by folder (`fault-1.png`). That is 2 levels, so deeper than 3 is not possible.
- **Zoom/drill-down:** works smoothly. Breadcrumb "All systems / Platform", callers on the left and dependencies on the right.
- **Changed-node highlighting:** this is the strongest of the three.
  - After my one-file edit, the live map showed the Platform box with an orange outline and a `~1` badge, green edges for new dependencies and a red dashed edge for the fault line. A "WHAT CHANGED" panel and a session timeline slider ("Since start / This step / Mark step") sit on the right.
  - `fault replay HEAD~3 HEAD -o replay.html` produced a 0.2 MB standalone timeline: "3 commits, 2 changed the architecture". I did not open it in the browser, so its feel is UNTESTED.
  - Noise: after adding one import, the diff also reported a `Platform → Unmapped` "new dependency" and a pile of "now uses os / re / sys" lines from imports that already existed. `fault overview` showed an empty "Depends on" list while the diff did show edges.
- **Check output, verbatim:**
  ```
  ✖ Crosses a fault line: Platform → Core
    platform must stay leaf. utils.py imports Command from core.py. Rule: deny platform -> core.
  ...
  ✖ fault check failed: this change crosses a declared fault line.   (exit 1)
  ```
  A clean tree gives `✓ fault check passed`, exit 0. `--format text|markdown|json|agent` is available, with a `--strict` flag for cycles.
- **Agent surface:**
  - CLI: `init [--outline|--ai], map, diff, check [--staged --strict --quiet --allow-loosening], sync [--apply], export, replay, setup [--agent claude,cursor,codex,copilot,gemini,kiro,zed,opencode], mcp, overview, footprint, place, plan, hook`.
  - MCP, verbatim tools/list: `map, place, check, plan`. Only 4 tools, with compact answers.
- **Determinism:** `fault diff --format json` run twice was byte-identical (`cmp` OK).
- **Phone home / keys:** no keys needed for normal use. The only runtime `fetch` is the hook posting to `127.0.0.1`. Anthropic is called only if you run `--ai`.
- **Issues:** 0 issues and 15 stars. Last push 2026-09-27.

### Agentic_Framework
Only a partial test: `git clone --depth 1` from the local repo reported a failed checkout (Windows long paths), so the copy is incomplete.
- `fault init` printed "No source files found in any supported language."
- `groma scanner discover` only found React, Python and JavaScript declarations, from the files that did check out. I did not scan or curate it.
- `archik drift` ran but is meaningless on a bare scaffold.

All three are weak for a prompt, Markdown and YAML heavy repo like this one.

### Decision: what to reuse and what is missing
- **Reuse as the base:** none. No tool covers the target end to end.
- **groma.md: borrow the format and ideas.**
  - Take the one-file-per-element OKF layout (git-diff friendly, readable without a tool), the rule that agents only edit via CLI, the scan-preserves-curation rule, the revision compare, and the reconciliation behaviour after scans.
  - Missing: depth beyond 3 levels, behaviour or exception paths (flows are only an ordered table of existing relationships), junctions, a real drift check (deleted code leaves silent ghosts), an MCP server, working static export on Windows, and a clear per-task highlight outside Backlog.md.
  - Weak points: noisy compare, and a syntax-only Python scanner with 0 relationships. Issues are disabled.
- **archik: borrow the format and drift logic.**
  - The ideas worth taking are single-file YAML with `parentId` (unlimited depth), `sourcePath` validation, `drift` with ORPHAN/UNMAPPED (verbatim, with `--json`), `affected` (file to ancestor nodes), the suggest/accept sidecar, the 27-tool MCP surface, deterministic renders, and use-case and sequence structures that might cover behaviour.
  - Missing: a semantic zoom UI (everything is nested and expanded), changed-node highlighting in the canvas, a history view, junction modelling (UNTESTED), and a fixed edge-relationship vocabulary. Drift is only directory-level.
  - A single YAML file will not scale well for a big model.
- **faultline: borrow ideas, not format.**
  - Take the structural diff to coloured map, with a session or commit timeline slider, replay as a standalone HTML, and `check` with an exit code. Also the MCP trio `map/place/check` and `fault setup` registering hooks for many agents.
  - Missing: hierarchy (flat, 2 levels), any free-form or semantic model (it is import-graph only), behaviour paths, and junctions. Its diff is noisy in places.
- **Missing in all three versus the target:** behaviour and exception paths, junctions, a history view with changes across many tasks that is not noisy, and a drift check that sees deleted or renamed files and not just directories.