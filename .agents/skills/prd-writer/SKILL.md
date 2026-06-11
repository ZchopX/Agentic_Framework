---
name: prd-writer
description: Create or update a Product Requirements Document from conversation and repository context. Use when the user asks for a PRD or structured requirements specification.
---

# PRD Writer

## Goal
Deliver a complete, scannable PRD suitable for implementation planning.

## Default Output Path
`PRD.md` unless the user provides a different path.

## Required Sections
1. Executive Summary
2. Mission and Principles
3. Target Users
4. MVP Scope (in-scope and out-of-scope)
5. User Stories
6. Architecture and Technical Patterns
7. Feature Breakdown
8. Technology Stack
9. Security and Configuration
10. API and Data Contracts (if applicable)
11. Success Criteria
12. Implementation Phases
13. Future Considerations
14. Risks and Mitigations

## Guardrails
- Distinguish confirmed facts vs assumptions.
- Make requirements testable and measurable.
- Keep the document decision-oriented, not marketing-oriented.

