---
name: doc-test-plan
description: Use when asked to produce a test plan / caderno de testes — structured test scenarios and cases (steps, expected results).
---

# Test Plan

## Methodology

A good test plan is a communication artifact: it makes the intended coverage explicit before testing begins, so that gaps can be caught in review — not after a bug ships.

### What a good test plan covers

| Section | Purpose |
|---|---|
| **Scope** | Which features, flows, and requirements are under test. Explicit "out of scope" is equally important. |
| **Preconditions / Test Data** | System state required before tests can run: accounts, fixtures, environment flags, seed data. |
| **Test Scenarios** | Logical groupings of related behaviour (e.g., "happy path login", "invalid credentials"). |
| **Test Cases** | One row per atomic check: exact steps, expected result, priority, and traceability back to a requirement or TC-* tag. |
| **Traceability** | Each test case links to the requirement or specification it validates — in particular, to `[TC-N.M-NN]` tags when an Implementation Plan exists. |
| **Sign-off** | Who reviewed/approved the plan and when. |

### TC-* traceability (kit integration)

This kit's Implementation Plans (in `docs/plans/`) contain immutable test cases tagged `[TC-N.M-NN]` (e.g., `[TC-1.2-03]`). When the feature being planned has a corresponding Plan document:

1. Locate the Plan file under `docs/plans/` and extract all `[TC-N.M-NN]` entries.
2. Every TC-* tag must appear in the **Linked TC** column of at least one test case row in the plan.
3. A single TC-* may expand into multiple test case rows (positive + negative paths, boundary values).
4. If a test case has no TC-* parent (exploratory or regression), leave the Linked TC cell blank.

This ensures the test plan is a faithful, auditable expansion of the implementation spec rather than a free-form rewrite.

### docs/test-plans/ vs docs/test-evidence/

| Path | What it contains | When it is created |
|---|---|---|
| `docs/test-plans/` | **Planned** test cases — this skill's output. Created before testing. | By this skill (`doc-test-plan`) during planning. |
| `docs/test-evidence/` | **Run** reports — screenshots, logs, and pass/fail results from actual E2E test runs. | By the `/e2e` workflow after tests execute. |

Never place run evidence in `docs/test-plans/` and never place planned cases in `docs/test-evidence/`.

### What to ask the user before starting

- What feature or user story is being tested?
- Is there an Implementation Plan in `docs/plans/` with TC-* cases to trace?
- What environments and browsers/devices are in scope?
- What test data or accounts need to be set up in advance?
- Are there areas explicitly out of scope (e.g., third-party integrations, performance)?

### Common pitfalls

| Pitfall | Avoidance |
|---|---|
| **Vague expected results** — "the form works" | State the exact observable outcome: which element appears, what text is shown, what the HTTP status is. |
| **Missing TC-* links** | Always grep the Plan file for `TC-` tags and verify every one appears in Linked TC. |
| **Conflating plan with evidence** | A test plan is a script; evidence is its execution record. Keep them in separate directories. |
| **Invented preconditions** | Only list setup steps that actually exist in the project (seeds, fixtures, env flags). |
| **Priority inflation** | Not every case is P1. Reserve P1 for must-pass-before-any-release cases. |

## Process

### 1. Gather context

- Read the relevant feature spec, PRD, or ticket to understand what is being built.
- Search `docs/plans/` for an Implementation Plan for this feature; if found, extract all `[TC-N.M-NN]` tags — these are the required traceability anchors.
- Identify environments, test accounts, and any fixture data needed.
- Check `docs/test-plans/` for existing plans that overlap — avoid duplication, extend instead.

### 2. Select a template

See **Template selection** below.

### 3. Populate the plan grounded in requirements

- Write test scenarios that map to the acceptance criteria or TC-* cases from the Plan.
- For each TC-* found in step 1, produce at least one test case row with the TC tag in **Linked TC**.
- Write steps at the level of granularity a tester unfamiliar with the codebase can follow.
- Mark expected results precisely: visible UI text, HTTP codes, database state, or redirect URL — whichever is observable.
- Assign priority: **P1** (blocker), **P2** (important), **P3** (nice-to-have).

### 4. Write to the output path and report it

Determine a slug for the document:

- Slug rules: kebab-case, lowercase, characters `[a-z0-9-]`, maximum 50 characters.
- Example: "User Login Flow" → `user-login-flow`

Write the completed document to:

```
docs/test-plans/YYYY_MM_DD-{slug}.md
```

where `YYYY_MM_DD` is today's date (e.g., `2026_06_23`). The `docs/` directory lives at the repository root — never inside `.claude/`.

Report the exact path to the user when done.

## Template selection

```
1. If --template=<name> was given, use templates/<name>.
2. Else list templates/* (each template's first line is a one-line description):
   - 0 templates  → error: "no templates; add one to skills/doc-test-plan/templates/".
   - 1 template   → use it (no prompt).
   - ≥2 templates → AskUserQuestion showing each (name + one-line description); use the choice.
3. Users add custom templates by dropping files into skills/doc-test-plan/templates/.
```

**Examples:** `examples/` holds a filled reference per template (`examples/<template-basename>.example.<ext>`). Consult the matching example for depth/tone while filling; you may show it alongside the template when the user is choosing.

## Quality gate

Before reporting the document as complete, verify each item:

- [ ] Every TC-* tag found in the relevant Plan file appears in at least one test case's **Linked TC** column.
- [ ] Every expected result is observable and specific — no vague phrases like "it works" or "shows correctly".
- [ ] Preconditions list only setup steps that genuinely exist (seeds, env vars, accounts).
- [ ] Out of Scope section is filled — not left blank.
- [ ] Output path matches `docs/test-plans/YYYY_MM_DD-{slug}.md` exactly (correct date, valid slug).
- [ ] Document language matches the project's convention (default: English).
- [ ] Slug is kebab-case, lowercase `[a-z0-9-]`, ≤50 characters.
- [ ] Sign-off section names the reviewer and date.
