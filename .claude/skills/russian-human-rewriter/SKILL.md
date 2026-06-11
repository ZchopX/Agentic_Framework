---
name: russian-human-rewriter
description: Rewrite Russian academic or dissertation prose so it sounds human-written, native, and non-template-like. Use when the user asks to humanize, clean up, de-AI, remove English calques, improve Russian academic style, polish dissertation chapters, rewrite a text fragment, or apply a human-writing pass to Russian prose.
---

# Russian Human Rewriter

## Purpose

Rewrite Russian academic prose without changing the argument. Prioritize native Russian sentence movement, clear dissertation style, and removal of recognizable AI patterns.

Use this skill for full sections, paragraphs, or selected fragments. If the user asks for a mock, keep edits in a separate file. If the user asks to insert into a chapter, edit the target file directly.

## Workflow

### 1. Build Minimal Context

- Read the target text fully.
- If it belongs to a chapter, read the preceding and following headings or paragraphs so the rewrite does not break continuity.
- Preserve the author’s claims, order of ideas, caveats, and level of assertiveness.
- Do not add new literature, facts, citations, policy claims, or empirical numbers unless the user explicitly asks.

### 2. Diagnose Before Rewriting

Look for these problems before editing:

- AI-balanced constructions: `не только ..., но и ...`, `с одной стороны ..., с другой стороны ...`, `речь идет не о ..., а о ...`.
- Template academic openers: `полученные результаты важны`, `главный вывод состоит в том`, `таким образом, проведенный анализ позволяет`.
- Mechanical sequencing: `прежде всего / не менее важно / наконец` when every paragraph has the same shape.
- Repetitive importance markers: `особенно важно`, `крайне важно`, `важно отметить`, `необходимо`, `следует подчеркнуть`, especially when several appear in one section.
- English calques in structure: abstract framing followed by immediate explanation, repeated thesis-restatement, and over-explicit causal stitching.
- Heavy noun chains: `результативность реализации политики`, `условия функционирования режима`, `каналы трансформации шока`.
- Over-explanation: a sentence states a result, then the next sentence restates its obvious meaning.

Do not report this diagnosis unless the user asks. Use it to guide the rewrite.

### 3. Structural Rewrite

Perform one full rewrite pass focused on paragraph movement:

- Replace mirrored constructions with direct claims.
- Let paragraphs begin from the substantive point, not from generic framing.
- Vary paragraph openings naturally.
- Break over-balanced sentences into more natural Russian syntax.
- Remove repeated importance markers. If emphasis is needed, make the sentence itself carry the emphasis instead of adding `особенно важно` or `крайне необходимо`.
- Keep the dissertation register, but avoid bureaucratic or translated phrasing.
- Preserve useful academic caution, especially around causality.

Prefer:

```text
После марта 2022 г. валютный курс в российской экономике не утратил значения как источник инфляционного давления.
```

Avoid:

```text
Главный содержательный вывод работы состоит в том, что после марта 2022 г. валютный курс...
```

Prefer:

```text
Практический вывод отсюда достаточно прямой.
```

Avoid:

```text
Из этого вытекают и практические выводы.
```

### 4. Human-Writing Polish

Do one final polish pass after the structural rewrite:

- Smooth rhythm and sentence length.
- Remove remaining duplicated connectors.
- Replace stiff transitions only when they sound template-like.
- Keep strong sentences intact; do not paraphrase for its own sake.
- Avoid making the prose casual or journalistic.

This pass should be smaller than the structural rewrite. If it changes the meaning, undo it.

### 5. Sub-Agent Checks

Use sub-agents only when the user explicitly asks for sub-agents, a second check, or an independent pass.

When using a sub-agent, assign one narrow role:

- **Calque pass:** find English-shaped Russian syntax and rewrite it natively.
- **Human-writing pass:** improve rhythm and naturalness without changing substance.
- **AI-pattern pass:** remove template constructions and overly symmetrical argument structure.

Do not ask multiple sub-agents to perform the same vague “polish.” Generic polish passes tend to produce synonym swaps. Give each pass one clear failure mode to fix.

After a sub-agent returns, review critically:

- Apply only improvements that genuinely improve Russian style.
- Reject changes that are merely cosmetic or weaken precision.
- If the sub-agent only changes vocabulary, do the structural edit locally.

## Output Rules

- Preserve Markdown headings unless the user asks otherwise.
- If editing a file, use `apply_patch`.
- If creating a mock, use a clearly named file near the source text, for example `*_mock.md` or `*_rewrite_mock.md`.
- Keep final user-facing summaries short and mention which file changed.
- Do not include a long changelog unless requested.

## Quality Checklist

Before finalizing, verify that the rewritten text:

- does not contain obvious `не только ..., но и ...` patterns unless genuinely needed;
- does not rely on `таким образом`, `иначе говоря`, `главный вывод состоит в том`, or similar stock bridges in every transition;
- does not repeatedly use `особенно важно`, `важно отметить`, `крайне важно`, `необходимо`, or similar emphasis fillers;
- has varied paragraph openings;
- sounds like Russian academic prose rather than translated English;
- keeps the original claims and caution level;
- reads as a section of a dissertation, not as a generic policy memo.
