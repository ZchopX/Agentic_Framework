# AI-Maintained Repository Documentation

Use docs as code: keep durable docs in the repo, in plain text, reviewed with code, versioned with code, and eligible for automated checks.

## Rules
1. Treat documentation as a maintained interface. Every code change should ask whether setup, behavior, architecture, decisions, operations, or user-visible changes were affected.
2. Keep durable context separate from transient planning. Durable docs record facts, contracts, decisions, workflows, and accepted assumptions. Plans record intended work.
3. Preserve PRD-to-plan traceability. PRDs should link to plans; plans should list affected modules, validation, docs impact, and changelog impact.
4. Use ADRs for decisions future maintainers would otherwise rediscover: architecture, dependencies, public APIs, deployment, security, data models, AI/tooling conventions, and rejected alternatives.
5. Keep changelogs curated. Use an `Unreleased` section and groups such as `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, and `Security` when a changelog is warranted.
6. Use lightweight architecture docs. Cover context, runtime flow, major boundaries, integrations, deployment, constraints, quality goals, risks/debt, and glossary only when relevant.
7. Organize docs by user need: tutorials for learning, how-to guides for tasks, reference for exact facts, and explanation for reasoning.
8. Prevent documentation rot with clear ownership signals where practical: status, last-reviewed date, source-of-truth, and update-when notes.
9. Design for context compaction. Keep AI-facing guidance compact and link to durable docs instead of duplicating them.
10. Define done as code plus docs plus verification, or explicitly record no docs impact.

## Minimal Templates

### PRD
```md
# PRD-0001: Title
Status:
Owner:
Date:
Problem:
Goals:
Non-goals:
Users / stakeholders:
Requirements:
Acceptance criteria:
Risks:
Linked plans:
Linked ADRs:
```

### Plan
```md
# PLAN-0001: Title
PRD:
Status:
Scope:
Implementation steps:
Affected modules:
Validation:
Docs to update:
Changelog entry:
Open questions:
```

### ADR
```md
# 0001-title
Status: proposed | accepted | superseded by 0002
Date:
Context:
Decision:
Consequences:
Links: PRD / plan / PR / issue
```

## Sources
- Write the Docs, docs as code: https://www.writethedocs.org/guide/docs-as-code/
- GitHub Docs, linking pull requests to issues: https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/linking-a-pull-request-to-an-issue
- Michael Nygard, architecture decision records: https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions
- MADR: https://adr.github.io/madr/
- Keep a Changelog: https://keepachangelog.com/en/1.1.0/
- C4 model: https://c4model.com/
- arc42: https://docs.arc42.org/home/
- Diataxis: https://diataxis.fr/
- Treude and Baltes, Context Rot: https://arxiv.org/abs/2606.09090

