---
name: doc-functional
description: Use when asked to produce functional documentation — what the system does from a business/user perspective, business rules, functional flows.
---

# Functional Documentation

## Methodology

A good functional document answers three questions a non-technical stakeholder could not answer by reading a requirements ticket alone: **who** uses the system and what they need, **what** the system allows them to do, and **under what conditions** that behaviour changes.

### What a good functional doc covers

| Section | Purpose |
|---|---|
| **Purpose** | One-paragraph answer to "what business problem does this solve and for whom?" — no implementation detail, no technology stack. |
| **Actors** | Named roles or personas who interact with the feature. Include systems acting as actors (e.g., a scheduler, a payment gateway) only when they have observable business behaviour. |
| **Functional Capabilities** | What users can do, expressed as verifiable statements ("A Manager can approve or reject a submitted expense"). One capability per line. |
| **Business Rules** | Constraints that govern behaviour regardless of implementation (e.g., "An order cannot be placed if the customer's account is suspended"). Each rule has a unique ID for traceability. |
| **Functional Flows** | Step-by-step narrative of the happy path, then each significant alternate or exception path. Written from the user's viewpoint. |
| **Edge Cases** | Boundary conditions with observable, agreed-upon outcomes. |
| **Acceptance (business)** | Criteria a product owner or domain expert can evaluate without reading code — no mentions of classes, endpoints, or databases. |

### What to ask the user before starting

- Who is the intended reader? (product owner, business analyst, QA, support team, auditor)
- What is the scope? (single feature, end-to-end flow, regulatory requirement)
- Is there an existing functional spec to update, or is this new?
- Are there known business rules that must be captured explicitly?
- Are there regulatory or compliance constraints the doc must reflect?

### Common pitfalls

| Pitfall | Avoidance |
|---|---|
| **Leaking implementation detail** — "the system calls the `/payments/charge` endpoint" | Describe observable outcome: "the system attempts to charge the customer's saved payment method". |
| **Actor-free flows** — steps with no named subject | Begin every flow step with the actor: "The Customer clicks …", "The System sends …". |
| **Invisible business rules** — rules buried inside flow prose | Extract every rule into the Business Rules section with a unique Rule ID; reference the ID in flows. |
| **Acceptance criteria that require code access** — "the database field `status` equals `approved`" | Reframe in observable terms: "the order appears in the Approved tab". |
| **Missing alternate paths** — only the happy path documented | Enumerate at least: what happens when input is invalid, when the actor lacks permission, and when a dependency is unavailable. |

## Process

### 1. Gather context

- Read the relevant source files, existing specs, or user stories (use `grep` + `Read` — do not rely on memory).
- Read the project `CLAUDE.md` (repo root and any feature-level) for domain terminology and naming conventions.
- Identify the actors, entry points, and observable outcomes for the scope in question.
- Note any existing docs in `docs/` that overlap — avoid duplication, link instead.

### 2. Select a template and output language

See **Template selection** and **Output language** below. Resolve both before writing.

### 3. Fill grounded in observable behaviour

- Every capability or rule must be traceable to source files, acceptance tests, or user stories you have read in this session.
- Business rules: if you cannot determine the rule's authority (who owns it, what triggered it), mark the row `<!-- TODO: source unknown — confirm with product owner -->` rather than inventing one.
- Flows: write from the actor's perspective. Do not name internal components, database tables, or API routes.

### 4. Write to the output path and report it

Determine a slug for the document:

- Slug rules: kebab-case, lowercase, characters `[a-z0-9-]`, maximum 50 characters.
- Example: "Customer Checkout Flow" → `customer-checkout-flow`

Write the completed document to:

```
docs/functional/YYYY_MM_DD-{slug}.md
```

where `YYYY_MM_DD` is today's date (e.g., `2026_06_23`).

Report the exact path to the user when done.

## Output language

```
1. If --lang=<code> was given, use that language code.
2. Else, if the user has already stated a preferred language in this conversation, use it.
3. Else → AskUserQuestion:
   "What language should the artifact be written in?
    1. pt-BR (default)
    2. en-US
    3. es"
   Use the choice; default to pt-BR if the user skips or presses Enter.
4. Write the entire artifact — body text AND section headings — in the chosen language.
```

## Template selection

```
1. If --template=<name> was given, use templates/<name>.
2. Else list templates/* (each template's first line is a one-line description):
   - 0 templates  → error: "no templates; add one to skills/doc-functional/templates/".
   - 1 template   → use it (no prompt).
   - ≥2 templates → AskUserQuestion showing each (name + one-line description); use the choice.
3. Users add custom templates by dropping files into skills/doc-functional/templates/.
```

> When both a template choice AND a language choice are needed (≥2 templates and no prior language signal), combine both into a **single** `AskUserQuestion` call.

> **Examples:** `examples/` holds a filled reference per template (`examples/<template-basename>.example.md`). Consult the matching example for depth/tone while filling; you may show it alongside the template when the user is choosing.

## Quality gate

Before reporting the document as complete, verify each item:

- [ ] Every actor, capability, and rule described was derived from source material read in the current session — not recalled from memory.
- [ ] No implementation detail (class names, endpoint paths, database columns) appears in the document.
- [ ] Every business rule has a unique Rule ID and is referenced by ID in flows where it applies.
- [ ] Every functional flow names its actor at each step.
- [ ] Acceptance criteria are verifiable by a non-technical reviewer without access to the codebase.
- [ ] Output path matches `docs/functional/YYYY_MM_DD-{slug}.md` exactly (correct date, valid slug).
- [ ] Artifact is written entirely in the user-selected language (default pt-BR).
- [ ] Slug is kebab-case, lowercase `[a-z0-9-]`, ≤50 characters.
