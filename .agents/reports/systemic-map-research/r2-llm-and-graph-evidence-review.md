<!-- verbatim subagent report, id a54f6f2f2bdef2025; saved 2026-10-23 -->

RESEARCH REPORT: what makes LLM<->graph/text-map interaction reliable (done 2026-10-08, ~65 searches/fetches; nothing in C:\PyProjects\Agentic_Framework was modified)

Tags: VERIFIED = I fetched the page and read the stated content. VERIFIED-ABSTRACT = abstract page only. SEARCH-ONLY = seen only in search-result summaries, source not fetched. UNVERIFIED = could not confirm.

Bottom line: no study tests your exact design (a hierarchical text map edited by an agent over hundreds of sessions). The best-supported choices are:
- content-anchored, validated, tool-mediated edits;
- readable IDs;
- a small always-loaded context with detail behind links;
- keeping code-derivable facts out of the map;
- never trusting LLM-written dependency edges.

## 1. How LLMs read graphs in text

Evidence:
- Talk like a Graph (Fatemi et al., Google, arXiv 2310.04560, Oct 2023): encoder choice changed accuracy by 4.8% to 61.8%. Incident encoding won most tasks and adjacency was close on counting tasks. Integer node names helped integer-answer tasks and named nodes helped non-integer answers. Graph shape mattered a lot (cycle check 91.7% on complete graphs vs 5.9% on path graphs). Edge-existence stayed near the majority baseline (about 40-50%). Models were PaLM 2, so this is old. VERIFIED: https://arxiv.org/abs/2310.04560 , https://ar5iv.labs.arxiv.org/html/2310.04560 , https://research.google/blog/talk-like-a-graph-encoding-graphs-for-large-language-models/
- NLGraph (arXiv 2305.10037): preliminary graph reasoning, brittle to spurious correlations, prompting tricks gain 3-17%. VERIFIED-ABSTRACT: https://arxiv.org/abs/2305.10037
- Scale limits: GrAlgoBench says accuracy falls below 50% past about 120 nodes even for reasoning models (VERIFIED-ABSTRACT: https://arxiv.org/abs/2602.06319). GraphWiz says it collapses past about 60 nodes (SEARCH-ONLY: https://arxiv.org/abs/2402.16029). GraphArena says large NP-hard graph tasks score under 10% (SEARCH-ONLY: https://arxiv.org/pdf/2407.00379).
- Format comparisons:
  - GraphArena: on GPT-4o the edge list was the most stable of edge list, adjacency list and adjacency matrix (SEARCH-ONLY).
  - Lost in Serialization (arXiv 2511.10234): labeling, edge order and syntax each matter, and larger non-fine-tuned models are more robust (VERIFIED-ABSTRACT: https://arxiv.org/abs/2511.10234).
  - GraphOmni (arXiv 2504.12764): serialization, graph type and prompt interact strongly, and open vs closed models respond differently. Per-format numbers not read (VERIFIED-ABSTRACT).
  - KG-LLM-Bench: edge list about 2.6k tokens vs JSON about 4.5k vs JSON-LD about 13.5k. Accuracy per format not extracted (SEARCH-ONLY).
- DOT, Mermaid, GraphML, YAML: I found NO head-to-head LLM accuracy study for any of them as graph-reading formats. LLM-written Mermaid needs render-and-retry (one pipeline went 70% to 95%; SEARCH-ONLY).
- R2ABench (arXiv 2604.06683, 2026): component identification is strong, edge recovery is weak, and "edge hallucination is the dominant structural failure mode". VERIFIED-ABSTRACT: https://arxiv.org/abs/2604.06683

Design implications:
- Store per-node records that list neighbors (incident/adjacency form). Do not make the agent scan a global edge list.
- Keep any single view to roughly 30-50 nodes. This is my extrapolation from the 60 and 120 node collapse points, not a measured threshold for lookup tasks.
- Keep syntax light. Treat DOT and Mermaid as render targets, not the source of truth.
- Do not let the LLM infer dependency edges. Derive them with static analysis. ArchAgent's ablation says dependency context improves LLM architecture recovery (VERIFIED-ABSTRACT: https://arxiv.org/abs/2601.13007).

Missing: no benchmark covers "find parent, deps and exceptions of node X in a 300-node hierarchy in format Y". No clean YAML/JSON/Markdown/DOT/Mermaid comparison on current models. Winners vary by model. These benchmarks test graph algorithms, not navigation.

## 2. Structured output and edit reliability

Format evidence:
- Let Me Speak Freely (Tam et al., EMNLP Industry 2024, arXiv 2408.02442): strict format constraints hurt reasoning, looser formats help, key order interferes (SEARCH-ONLY: https://arxiv.org/abs/2408.02442).
- Aider "code in JSON" (Aug 2024): all four models (Sonnet 3.5, DeepSeek-Coder V2, two GPT-4o versions) scored lower with JSON-wrapped code. Escaping errors appeared, and Sonnet scored lower with no syntax errors. Strict mode did not help. VERIFIED: https://aider.chat/2024/08/14/code-in-json.html
- He et al. (arXiv 2411.10541): prompt format moved GPT-3.5 by up to 40%, GPT-4 was more robust, no universal winner (SEARCH-ONLY).
- Sui et al. (WSDM 2024): HTML beat delimiter formats by 6.76% on tables. No YAML comparison (SEARCH-ONLY).
- StructEval (TMLR 2026, arXiv 2505.20139): generation is harder than conversion. No per-format JSON vs YAML numbers found (SEARCH-ONLY).

Edit-protocol evidence:
- Aider unified diffs (Dec 2023, GPT-4 Turbo): SEARCH/REPLACE 20% vs unified diff 61%. Lessons: no line numbers, high-level whole-block edits (without them editing errors rose 30-50%), and flexible patching (disabling it raised errors 9x). VERIFIED: https://aider.chat/docs/unified-diffs.html . The model is outdated.
- Diff-XYZ (arXiv 2510.12487, Oct 2025): search-replace is best for larger models, and the best format depends on model size and task. VERIFIED-ABSTRACT: https://arxiv.org/abs/2510.12487
- Multi-turn study (arXiv 2510.13859): whole-file output was "more stable overall", and diff formats have similar single-turn correctness. SEARCH-ONLY.
- Look Before You Leap (arXiv 2609.11957, Aug 2026): 640 edits across 224 files. Content-anchored edits fail cleanly. Line-range edits corrupted 99.1% of files after a one-line shift. Function-name anchors hit the wrong function 12.7% of the time. An anchor-and-verify applier produced 1 silent misapplication in 8,320 trials. VERIFIED-ABSTRACT: https://arxiv.org/abs/2609.11957
- Don't Let the Model Write the YAML (arXiv 2609.00227, Aug 2026): model-written diffs can silently misapply, and full-file rewrites are wrong for small models or non-deterministic for frontier ones. Fix: the model emits only a structured field change and a parser-position replacer edits the raw text. Kubernetes-specific, and only claims faithful application of a known change. VERIFIED-ABSTRACT: https://arxiv.org/abs/2609.00227
- SWE-Edit (arXiv 2604.26102): separate viewer and editor subagents gave +2.1 points resolve and -17.9% cost. VERIFIED-ABSTRACT: https://arxiv.org/abs/2604.26102
- Sweep telemetry: str_replace about 13% error rate, 77% of failures were "old string not found". Single vendor, secondhand (SEARCH-ONLY).
- Hashline (Can Bölük, Feb 2026) claims big gains from the edit format alone. Self-reported, primary post not found. UNVERIFIED.
- Anthropic's str_replace requires a unique match and errors otherwise. VERIFIED: https://platform.claude.com/docs/en/agents-and-tools/tool-use/text-editor-tool

Design implications:
- Do not use JSON as the edit surface for text.
- Do not let the agent hand-edit whole map files. Give it a small CLI/tool that takes structured operations (node ID, field, new value), applies them to the raw text, and rejects anything that does not apply cleanly.
- Anchor on node ID plus an old-value or hash check. Never anchor on line numbers.
- One record per node with stable field order. Run a validator after every edit. Anthropic's skill guidance recommends validator loops and plan-validate-execute for batch changes (VERIFIED: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices).

Missing: no measurement of edit error rate vs file size on structured YAML/markdown with a current model. Diff vs whole-file results conflict across eras and models.

## 3. Hierarchical retrieval and progressive disclosure

codebase-memory (arXiv 2603.27277, 28 Mar 2026, Vogel et al.; VERIFIED: https://arxiv.org/abs/2603.27277 and https://arxiv.org/html/2603.27277):
- Setup: a Tree-Sitter knowledge graph served over MCP (14 tools, 66 languages) vs an Explorer agent that reads and greps. Both ran on Claude Opus 4.6. 12 question categories, one repo per language across 31 languages, 78 to 49,398 nodes.
- The 83% vs 92% result is mean answer quality 0.83 (graph agent) vs 0.92 (Explorer). The graph agent used about 1,000 vs 10,000 tokens per question and 2.3 vs 4.8 tool calls.
- It matched or beat the Explorer on hub detection and caller ranking in 19 of 31 languages. The Explorer led on full source context (16/31). Worst case was macro-heavy C (0.58 vs 1.00).
- What it really shows: a precomputed graph trades about 10 quality points for about 10x fewer tokens on structural questions. It does not show the graph is better.
- Caveats the authors admit: the first author graded everything, one model, one repo per language, single run with no variance or significance testing, no embedding or LSP baseline, static structure only.

Other evidence:
- Code Isn't Memory (arXiv 2606.22417, Jun 2026): with Opus 4.7 on SWE-PolyBench Verified and SWE-bench Pro, 3 seeds, a structural index gave a large localization gain and a resolve gain, did not regress vs agentic grep, and lowered cost per solve. Abstract only. VERIFIED-ABSTRACT: https://arxiv.org/abs/2606.22417
- LocAgent (arXiv 2503.09089): 92.7% file-level localization, about 86% cheaper. VERIFIED-ABSTRACT: https://arxiv.org/abs/2503.09089
- RepoGraph (ICLR 2025, arXiv 2410.14684): boosted all four SWE-bench systems tested. Percentages unverified (SEARCH-ONLY).
- Cursor: semantic search +12.5% average offline accuracy (range 6.5-23.5%), +2.6% retention on codebases of 1,000+ files. Cursor says grep plus semantic search is best. Vendor source. VERIFIED: https://cursor.com/blog/semsearch
- Is Grep All You Need? (arXiv 2605.15184): grep beat vectors on LongMemEval conversational memory, not on code, and the authors say code semantics may differ (SEARCH-ONLY: https://arxiv.org/pdf/2605.15184).
- Deep Agentic Search (arXiv 2608.01507, Aug 2026): on SWE-QA, semantic search got 65.2% vs 46.2% for subagent grep search at under half the cost per correct answer. 41.8% of the agentic failures were silent handoff errors. VERIFIED-ABSTRACT: https://arxiv.org/abs/2608.01507
- CORE-Bench (arXiv 2606.11864, EMNLP 2026): embedding models do much worse in agentic coding settings than on classic code search. VERIFIED-ABSTRACT: https://arxiv.org/abs/2606.11864
- "Claude Code dropped its vector DB because agentic search worked better" is Boris Cherny's claim, repeated via secondary sources. No public controlled data. SEARCH-ONLY.
- RAPTOR (arXiv 2401.18059): +20% absolute on QuALITY (VERIFIED-ABSTRACT). GraphRAG (arXiv 2404.16130): better comprehensiveness and diversity on global sensemaking over about 1M tokens (VERIFIED-ABSTRACT). GraphRAG-Bench (arXiv 2506.05690, ICLR 2026) and RAG-vs-GraphRAG (arXiv 2502.11371) say graphs often underperform plain RAG on simple lookups and win on multi-hop or synthesis.
- Tree navigation: PageIndex's 98.7% is vendor-reported. VecTree-RAG's ablation found tree-only navigation cost 490k tokens vs 128k and scored 0.811 vs 0.925 against its hybrid. No controlled depth/fan-out study found. SEARCH-ONLY.
- Aider repo map: tree-sitter symbols plus PageRank within a token budget (default 1,024). A design precedent, not an evaluation. SEARCH-ONLY.
- Anthropic: "smallest possible set of high-signal tokens", just-in-time loading via lightweight identifiers, progressive disclosure, structured note-taking (VERIFIED: https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents). Skills use three levels (VERIFIED: https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills). Best practices: SKILL.md body under 500 lines, references one level deep because nested refs get partial reads (head -100), table of contents for files over 100 lines (VERIFIED, best-practices URL above). These are guidance, not experiments.
- Long-context degradation: Chroma Context Rot (Jul 2025, 18 models: degradation with length, distractors hurt, coherent haystacks did worse than shuffled; VERIFIED: https://www.trychroma.com/research/context-rot). Lost in the Middle (arXiv 2307.03172; VERIFIED-ABSTRACT). NoLiMa (ICML 2025: GPT-4o 99.3% to 69.7% at 32K; SEARCH-ONLY). IFScale (arXiv 2507.11538: best models 68% at 500 instructions; SEARCH-ONLY).

Design implications:
- A router root under about 100 lines, then one file or section per subsystem, linking directly to leaves.
- Node and file sizes of a few hundred tokens per node and at most 500 lines per file. This is my judgment anchored on Anthropic guidance and context rot, not a measured optimum.
- Depth of 2-3 levels from the root is opinion. The only support is the one-level-deep rule and the VecTree cost finding.
- Keep derivable structure (callers, imports) generated by tools, and pair the map with grep. Combined approaches are favored by Cursor and the localization papers.

Missing: grep vs embeddings vs structural index flips by task and harness. No evidence on optimal tree depth, fan-out or node size. GraphRAG and RAPTOR gains are for corpus QA, not software maps.

## 4. Documentation drift and LLM-generated context

- ETH "Evaluating AGENTS.md" (Gloaguen et al., arXiv 2602.11988, Feb 2026; VERIFIED: https://arxiv.org/abs/2602.11988 , https://arxiv.org/html/2602.11988v1): tested on SWE-bench Lite and AgentBench (138 tasks). LLM-generated context files lowered resolution by about 0.5% (Lite) and 2% (AgentBench). Developer-written files gave about +4% on average. Cost rose about 20-23%. Overviews did not reduce steps to the first file edited. With existing docs removed, LLM files helped about 2.7%, so they mostly duplicate docs. The abstract says "does not generally improve"; a later version reads more negatively; the paper's own numbers are internally inconsistent, so cite a specific version. Authors say context files are useful for non-standard practices only.
- Opposite efficiency finding: Lulla et al. (arXiv 2601.20404): with AGENTS.md, median runtime -28.64% and output tokens -16.58%, comparable completion (10 repos, 124 PRs). VERIFIED-ABSTRACT: https://arxiv.org/abs/2601.20404
- Configuration smells in AGENTS.md (arXiv 2606.15828, SCAM 2026, 100 repos): Lint Leakage 62%, Context Bloat 42%, Skill Leakage 35%. VERIFIED-ABSTRACT: https://arxiv.org/abs/2606.15828
- Doc staleness generally: Tan, Wagner, Treude (Empirical Software Engineering 2024): most of 3,000+ GitHub projects have at least one outdated code-element reference at some point (SEARCH-ONLY: https://arxiv.org/abs/2212.01479). Older work shows code changes often skip comment updates.
- No measured rot rate for LLM-maintained docs or memory files exists in what I found. Only tools (docrot, stalebrain). UNVERIFIED.
- ACE (arXiv 2510.04618, ICLR 2026): repeated rewriting causes "context collapse" and brevity bias, so structured incremental updates are used (+10.6% on agent benchmarks). VERIFIED-ABSTRACT: https://arxiv.org/abs/2510.04618
- Memory conflict resolution is weak: a June 2026 preprint reports HippoRAG-v2 54%, Mem0 18% on single-hop FactConsolidation, multi-hop near zero; deterministic timestamp rules roughly tie LLM judgment (n=45). SEARCH-ONLY: https://arxiv.org/pdf/2608.15008
- LLM architecture recovery: views study (arXiv 2603.21178; 340 repos, 4,137 views): valid syntax but code-level rather than architectural abstraction, small prompting gains (VERIFIED-ABSTRACT: https://arxiv.org/abs/2603.21178). Vision LLMs reached 48.1% exact match counting arrowheads in architecture diagrams (SEARCH-ONLY). G-Retriever reports only 12% valid edges in one setting (SEARCH-ONLY).

Design implications:
- The map should hold only what code and existing docs do not show cheaply: purpose, invariants, exceptions, cross-cutting behavior, decisions.
- Give each node a pointer to its code (path or symbol) and a last-verified commit, and run a deterministic checker for dangling references (Tan et al. style).
- Use incremental edits, never whole-map regeneration.
- Keep LLM-written dependency edges out, or verify them against code.
- Provenance fields (who wrote it, when, from which commit) are my suggestion and untested.

Missing: no rot rate for agent-edited maps over hundreds of sessions (the central unknown). ETH and Lulla et al. disagree because they measure different things. No measured hallucinated-edge rate for real repos with current models.

## 5. Human side

- CodeCity (Wettel, Lanza, Robbes, ICSE 2011): 41 participants, four sites, three countries. Statistically significant gains in correctness and reduced completion time vs Eclipse plus a spreadsheet. Percentages not retrieved. VERIFIED-ABSTRACT: https://2011.icse-conferences.org/content/software-systems-cities-controlled-experiment.html
- Merino et al. 2018: 62% of proposed visualization approaches lack strong evaluation. One graph-visualization study found +21.45% correctness but no time saving (20 students). SEARCH-ONLY: https://scg.unibe.ch/research/softvis-eval
- DSM studies (MacCormack, Rusnak, Baldwin 2006; Lagerström et al. 2019): coupling measured by DSM predicts change cost. They are about modularity and change cost, not comprehension. SEARCH-ONLY.
- Anthropic randomized trial (Jan 2026): 52 mostly junior engineers learning a Python library scored 50% with AI vs 67% without (Cohen's d = 0.738, p = 0.01). Largest gap was debugging, speed difference not significant. Full delegation scored 39%, conceptual questioning 65%+. Small sample, immediate quiz. VERIFIED: https://www.anthropic.com/research/AI-assistance-coding-skills
- "Comprehension debt" is practitioner writing (Osmani). A qualitative study of SE-agent builders (arXiv 2607.10856) describes code accepted before developers can explain it. SEARCH-ONLY.
- Diff visual vs text summary: no controlled study found. Closest is arXiv 2505.16339 (10 developers, summary-first vs on-demand AI review). SEARCH-ONLY: https://arxiv.org/abs/2505.16339

Implications: a rendered map has precedent, but evidence is for novices exploring metric-heavy structure, not for following session-to-session change. Showing the human what changed in the map each session, with reasons, is suggestive from the Anthropic trial only. Rendering from the same parsed data the agent edits follows from the determinism argument and is untested. Missing: whether an agent-maintained map improves human comprehension of change over time. CodeCity's baseline was weak (no good text docs).

## Decisions

Evidence-supported:
1. Content-anchored edits with deterministic validation, not line numbers or whole-file rewrites (Pre-Action paper, Aider, Anthropic str_replace).
2. Agent edits through a tool taking structured operations (Kubernetes paper, narrow claim, plus the Pre-Action result).
3. No JSON wrapping of text content (Aider, four models; Speak Freely).
4. Readable IDs over opaque ones. Anthropic says swapping opaque IDs for readable names "significantly improves Claude's precision in retrieval tasks by reducing hallucinations" (VERIFIED: https://www.anthropic.com/engineering/writing-tools-for-agents). Magnitude not published, other support is blog-level, and Anthropic's tool-design post suggests even 0-indexed IDs as a fallback, while a blog warns numbered IDs invite guessing.
5. Small always-loaded context with detail behind links (context rot, Lost in the Middle, NoLiMa, Anthropic guidance). The 500-line and one-level-deep numbers are guidance, not measured.
6. Don't restate code-derivable or already-documented facts (ETH).
7. Never trust LLM-written dependency edges (R2ABench, architecture-views study; ArchAgent ablation).
8. Incremental edits over regeneration (ACE).
9. Per-node neighbor lists over global edge scans, with global graph reasoning breaking at 60-120 nodes (Talk like a Graph, GrAlgoBench, GraphWiz). Applicability to lookup tasks is an extrapolation.
10. Use search alongside the map (Cursor, localization papers).

Opinion only:
- YAML vs markdown vs custom DSL for the map file.
- Specific node size cap, depth of 2-3, and the 30-50 node view cap.
- ID scheme specifics (prefixes, hierarchy-encoded paths, hash suffixes). Only "readable beats opaque" is supported.
- Provenance and last-verified fields.
- Whether the human map improves oversight of agent changes.
- One map file vs many for reliability over hundreds of sessions. Nothing measures long-horizon rot.

Suggested first experiment: build the smallest edit tool plus validator, then replay 100+ simulated sessions against a real repo, measuring stale-reference rate, silent misapplications and wrong edges, with a Tan et al. style dangling-reference checker as ground truth.