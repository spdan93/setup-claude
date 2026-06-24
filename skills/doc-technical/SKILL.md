---
name: doc-technical
description: Use when asked to produce technical documentation — architecture, module design, how the system works internally, or an architecture decision record (ADR).
---

# Technical Documentation

## Methodology

A good technical document answers three questions a reader could not answer by skimming the code alone: **what** the system is meant to do, **how** it achieves that, and **why** it was built this way rather than some other way.

### What a good technical doc covers

| Section | Purpose |
|---|---|
| **Purpose / Overview** | One-paragraph answer to "what problem does this solve and for whom?" — no jargon, no assumed context. |
| **Architecture** | High-level structure: layers, services, key files. A diagram description (even textual) beats prose alone. |
| **Key components & responsibilities** | One entry per significant module/class/service. What it owns, what it does NOT own. |
| **Data flow** | How data enters the system, transforms, and exits. Include happy-path and notable edge cases. |
| **Dependencies** | External services, libraries, and other internal modules this component relies on. Be explicit about direction. |
| **Trade-offs & decisions** | What was chosen and what was rejected — the most valuable content that is never visible in the code. |
| **Risks** | Known limitations, operational concerns, or areas where the design is intentionally incomplete. |

### What to ask the user before starting

- What is the intended audience? (new team member, ops team, external partner, future-self)
- What is the scope? (single module, cross-service flow, historical decision)
- Is there an existing doc to update, or is this new?
- Are there particular decisions or trade-offs the reader must understand?
- Is this an Architecture Decision Record (ADR) for a specific decision, or a broader technical design?

### Common pitfalls

| Pitfall | Avoidance |
|---|---|
| **Vague handwaving** — "the system handles errors gracefully" | Name the mechanism: which class, which retry policy, what the fallback is. |
| **Missing rationale** — explains *what*, never *why* | Every non-obvious decision needs a "because" sentence. |
| **Stale diagrams** | Read the actual code before writing. Do not paraphrase old docs. |
| **Invented APIs** | Only document interfaces that exist in the current codebase. |
| **Audience mismatch** | A doc for a new hire and one for an on-call responder are different docs. |

## Process

### 1. Gather context

- Read the relevant source files (use `grep` + `Read` — do not rely on memory).
- Read the project `CLAUDE.md` (repo root and any target-module level) for architectural conventions.
- Identify the key entry points, data models, and external contracts for the component in scope.
- Note any existing docs in `docs/` that overlap — avoid duplication, link instead.

### 2. Select a template

See **Template selection** below.

### 3. Fill grounded in real code

- Every claim about a component's behaviour must be traceable to a file and line you have read in this session.
- Decisions and trade-offs: if you cannot find the rationale in comments or commit messages, mark the section `<!-- TODO: rationale unknown — ask the original author -->` rather than inventing one.
- Diagrams: use plain text (ASCII, Mermaid) over embedded images.

### 4. Write to the output path and report it

Determine a slug for the document:

- Slug rules: kebab-case, lowercase, characters `[a-z0-9-]`, maximum 50 characters.
- Example: "Auth Module Architecture" → `auth-module-architecture`

Write the completed document to:

```
docs/technical/YYYY_MM_DD-{slug}.md
```

where `YYYY_MM_DD` is today's date (e.g., `2026_06_23`).

Report the exact path to the user when done.

## Template selection

```
1. If --template=<name> was given, use templates/<name>.
2. Else list templates/* (each template's first line is a one-line description):
   - 0 templates  → error: "no templates; add one to skills/doc-technical/templates/".
   - 1 template   → use it (no prompt).
   - ≥2 templates → AskUserQuestion showing each (name + one-line description); use the choice.
3. Users add custom templates by dropping files into skills/doc-technical/templates/.
```

## Quality gate

Before reporting the document as complete, verify each item:

- [ ] Every component or API described was read in the current session — not recalled from memory.
- [ ] Every non-obvious decision has an explicit rationale ("because…" or "trade-off: …").
- [ ] No APIs, endpoints, or behaviours are documented that do not exist in the current code.
- [ ] Output path matches `docs/technical/YYYY_MM_DD-{slug}.md` exactly (correct date, valid slug).
- [ ] Document language matches the project's convention (default: English).
- [ ] Slug is kebab-case, lowercase `[a-z0-9-]`, ≤50 characters.
