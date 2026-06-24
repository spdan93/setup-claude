# Documentation System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an automatic per-commit changelog and an on-demand, template-driven documentation system (doc-type skills) to the `.claude` kit.

**Architecture:** Deliverables are **Markdown command/skill specs** (Claude Code primitives), not executable code. Part A adds changelog generation to `commands/commit.md` writing `docs/changelog/…` artifacts. Part B adds four `skills/doc-*/SKILL.md` (methodology + `templates/`) plus a rewritten `commands/documentation.md` router. Verification is **structural** (frontmatter parses, required sections present, references resolve, no project-specific leftovers) since there is no test runner for prompt specs.

**Tech Stack:** Markdown (commands/skills/templates), YAML frontmatter, bash + `jq`/`grep` for the changelog flow and for verification. Repo: `setup-claude` (git), branch `feat/documentation-system`.

## Global Constraints

- Spec: `docs/superpowers/specs/2026-06-23-documentation-system-design.md` (source of truth).
- Durable docs live at the **repo root** `docs/<category>/` (versioned) — NEVER inside `.claude/`.
- Naming: `docs/<category>/YYYY_MM_DD-{slug}.md`; changelog adds time: `YYYY_MM_DD-HHMM-{slug}.md`. `slug` = kebab-case, lowercase, `[a-z0-9-]`, ≤ 50 chars (same rule as `pipeline_id`).
- Categories: `docs/changelog/ · docs/technical/ · docs/functional/ · docs/test-plans/ · docs/api/` (coexist with existing `docs/prds/ · docs/plans/ · docs/test-evidence/`).
- Language: generated docs follow the project's dominant language (default English). Canonical template section headings in English.
- Skill frontmatter: `name`, `description` (per CONVENTIONS). Command frontmatter: `name`, `description`, optional `allowed-tools` (comma-separated, hyphenated).
- No project-specific leftovers (quiz/Linear/Codex/etc.). Issue IDs as `<ISSUE-ID>`.
- Doc-type skills are prefixed `doc-`. `doc-changelog` is **template-only** (no `SKILL.md`).
- Commit message body keeps the 5 sections (Cause/Changes/Consequence/Functionality/Gain) + `Developed-by` footer.
- Each task ends on its own commit on branch `feat/documentation-system`.

---

### Task 1: Per-commit changelog (template + `/commit` integration)

**Files:**
- Create: `skills/doc-changelog/templates/commit-entry.md`
- Modify: `commands/commit.md` (add a changelog-generation step before the commit; update the checklist)

**Interfaces:**
- Produces: the changelog convention `docs/changelog/YYYY_MM_DD-HHMM-{slug}.md` and the `commit-entry.md` template fields, consumed by Task 2 (`/ship`) and Task 8 (CONVENTIONS/docs).

- [ ] **Step 1: Create the changelog entry template**

`skills/doc-changelog/templates/commit-entry.md` — placeholders in `{{...}}`:

```markdown
---
date: {{YYYY-MM-DD}}
time: {{HH:MM}}
author: {{git config user.name}}
branch: {{branch}}
type: {{feat|fix|refactor|docs|...}}
scope: {{scope}}
commit_title: {{type(scope): title [ISSUE-ID?]}}
files_changed: {{N}}
issue: {{ISSUE-ID|null}}
---

# {{commit title}}

## Cause
{{why the change was necessary}}

## Changes
{{files / functions / components changed}}

## Consequence
{{impact / result}}

## Functionality
{{how it works}}

## Gain
{{technical or business benefit}}

## Files
{{- one bullet per changed file path}}
```

- [ ] **Step 2: Add the changelog step to `commands/commit.md`**

Insert a new numbered section in the commit flow, **after** the 5-section message is composed and **before** the `git commit`, titled "Generate the changelog entry". It MUST instruct:
1. Resolve metadata: `AUTHOR=$(git config user.name)`, `DATE=$(date +%Y-%m-%d)`, `TIME=$(date +%H:%M)`, `STAMP=$(date +%Y_%m_%d-%H%M)`, `BRANCH=$(git branch --show-current)`, changed files via `git diff --cached --name-only` (or `git status --porcelain`), `type`/`scope` from the commit title, `issue` if linked.
2. `slug` = kebab-case of the commit title (≤50 chars).
3. Read `skills/doc-changelog/templates/commit-entry.md` (fall back to the inline format above if missing) and fill it.
4. Write to `docs/changelog/${STAMP}-${slug}.md`.
5. `git add -A` so the changelog file is included, **then** create the commit. The changelog ships inside the commit it describes.
6. (Optional) append a one-line entry to `docs/changelog/INDEX.md` (`- {{date}} {{time}} — {{title}} — {{author}}`). Mark this optional.

Update the commit `commands/commit.md` checklist to add: "Changelog entry written to `docs/changelog/` and staged".

- [ ] **Step 3: Verify structurally**

Run:
```bash
ls skills/doc-changelog/templates/commit-entry.md
grep -c "docs/changelog/" commands/commit.md
grep -ci "changelog" commands/commit.md
```
Expected: template file exists; `docs/changelog/` referenced ≥1; "changelog" appears in commit.md.

- [ ] **Step 4: Commit**

```bash
git add skills/doc-changelog/templates/commit-entry.md commands/commit.md
git commit -m "feat(docs): per-commit changelog artifacts in /commit"
```

---

### Task 2: Rework `/ship` (drop old changelog, new flow)

**Files:**
- Modify: `commands/ship.md`

**Interfaces:**
- Consumes: Task 1's `/commit` changelog behavior (ship delegates changelog to `/commit`).

- [ ] **Step 1: Remove the old changelog logic**

In `commands/ship.md`, delete section **1.2 Update Changelogs** (CHANGELOG.md / docs-site page) and any checklist items referencing CHANGELOG.md or the docs-site changelog page.

- [ ] **Step 2: Restate the ship flow**

Update the Overview/flow so `/ship` = `bump version → (optional) /documentation → /commit (which writes the changelog) → push`. Add a note: "The changelog is produced automatically by `/commit` (one artifact per commit under `docs/changelog/`) — `/ship` does not maintain a separate changelog." Add an optional step before commit: "If the change warrants formal docs, invoke `/documentation` to generate the relevant doc type."

- [ ] **Step 3: Verify**

Run:
```bash
grep -ci "CHANGELOG.md" commands/ship.md            # expect 0
grep -ci "changelog" commands/ship.md               # expect >=1 (the note)
grep -c "commit" commands/ship.md                   # still delegates to /commit
```
Expected: no `CHANGELOG.md` references; changelog note present; still calls `commit`.

- [ ] **Step 4: Commit**

```bash
git add commands/ship.md
git commit -m "refactor(docs): /ship delegates changelog to /commit"
```

---

### Task 3: `doc-technical` skill + templates

**Files:**
- Create: `skills/doc-technical/SKILL.md`
- Create: `skills/doc-technical/templates/technical-design.md`
- Create: `skills/doc-technical/templates/adr.md`

**Interfaces:**
- Produces: a doc-type skill discoverable by Task 7's router; output to `docs/technical/YYYY_MM_DD-{slug}.md`.

- [ ] **Step 1: Write `SKILL.md`**

Frontmatter:
```yaml
---
name: doc-technical
description: Use when asked to produce technical documentation — architecture, module design, how the system works internally, or an architecture decision record (ADR).
---
```
Body sections (English headings): `# Technical Documentation`, `## Methodology` (what a good technical doc covers: purpose, architecture, key components & responsibilities, data flow, dependencies, trade-offs/decisions; what to ask the user; pitfalls — vague handwaving, missing rationale), `## Process` (1. gather context: read the relevant code/modules, root + target CLAUDE.md; 2. **Select a template** — see the shared selection algorithm, reproduced below; 3. fill grounded in real code; 4. write to `docs/technical/YYYY_MM_DD-{slug}.md`; report the path), `## Template selection` (the algorithm, see below), `## Quality gate` (checklist: grounded in real code, decisions have rationale, no invented APIs, correct output path/naming, language matches project).

Reproduce the **Template selection algorithm** verbatim in each doc skill:
```
1. If --template=<name> was given, use templates/<name>.
2. Else list templates/* (each template's first line is a one-line description):
   - 0 templates  → error: "no templates; add one to skills/doc-technical/templates/".
   - 1 template   → use it (no prompt).
   - ≥2 templates → AskUserQuestion showing each (name + one-line description); use the choice.
3. Users add custom templates by dropping files into skills/doc-technical/templates/.
```

- [ ] **Step 2: Write the two templates**

`technical-design.md` (first line a `<!-- one-line description -->`, then headings): Overview, Architecture, Components & Responsibilities, Data Flow, Dependencies, Key Decisions & Trade-offs, Risks, References.

`adr.md` (ADR format): first-line description comment, then: Title, Status (proposed/accepted/superseded), Context, Decision, Consequences, Alternatives Considered.

- [ ] **Step 3: Verify**

Run:
```bash
test -f skills/doc-technical/SKILL.md && jq -e . < /dev/null >/dev/null 2>&1; ls skills/doc-technical/templates/
head -3 skills/doc-technical/SKILL.md          # frontmatter present
grep -c "docs/technical/" skills/doc-technical/SKILL.md
grep -ci "Template selection" skills/doc-technical/SKILL.md
```
Expected: SKILL.md + 2 templates exist; frontmatter `name: doc-technical`; output path and selection algorithm referenced.

- [ ] **Step 4: Commit**

```bash
git add skills/doc-technical/
git commit -m "feat(docs): doc-technical skill + templates"
```

---

### Task 4: `doc-functional` skill + templates

**Files:**
- Create: `skills/doc-functional/SKILL.md`
- Create: `skills/doc-functional/templates/functional-spec.md`
- Create: `skills/doc-functional/templates/business-rules.md`

- [ ] **Step 1: Write `SKILL.md`**

Frontmatter `name: doc-functional`, description: "Use when asked to produce functional documentation — what the system does from a business/user perspective, business rules, functional flows." Body mirrors Task 3's structure (Methodology / Process / Template selection / Quality gate), output to `docs/functional/YYYY_MM_DD-{slug}.md`. Methodology focuses on: actors/personas, user-facing capabilities, business rules, functional flows (happy + alternate), acceptance from a business view; pitfalls — leaking implementation detail into a functional doc. Reproduce the Template selection algorithm (paths point to `skills/doc-functional/templates/`).

- [ ] **Step 2: Write the two templates**

`functional-spec.md`: one-line description comment + headings: Purpose, Actors, Functional Capabilities, Business Rules, Functional Flows, Edge Cases, Acceptance (business).
`business-rules.md`: description comment + a table format (Rule ID | Description | Condition | Outcome | Source) + a notes section.

- [ ] **Step 3: Verify**

Run:
```bash
ls skills/doc-functional/SKILL.md skills/doc-functional/templates/
grep -c "docs/functional/" skills/doc-functional/SKILL.md
grep -ci "Template selection" skills/doc-functional/SKILL.md
```
Expected: files exist; output path + selection algorithm present.

- [ ] **Step 4: Commit**

```bash
git add skills/doc-functional/
git commit -m "feat(docs): doc-functional skill + templates"
```

---

### Task 5: `doc-test-plan` skill + template

**Files:**
- Create: `skills/doc-test-plan/SKILL.md`
- Create: `skills/doc-test-plan/templates/test-plan.md`

- [ ] **Step 1: Write `SKILL.md`**

Frontmatter `name: doc-test-plan`, description: "Use when asked to produce a test plan / caderno de testes — structured test scenarios and cases (steps, expected results)." Body mirrors Task 3. Methodology: scope, test scenarios, cases with steps + expected result, data/preconditions, traceability. **Integration note**: when the feature has a Plan with `[TC-N.M-NN]` cases, derive/trace cases from those TC-* (the kit's immutable test cases) — link each plan TC to one or more plan-of-test cases. Output to `docs/test-plans/YYYY_MM_DD-{slug}.md`. Reproduce the Template selection algorithm (paths → `skills/doc-test-plan/templates/`). Clarify in the methodology that `docs/test-plans/` (planned cases) is distinct from `docs/test-evidence/` (E2E run reports).

- [ ] **Step 2: Write the template**

`test-plan.md`: description comment + headings: Scope, Preconditions / Test Data, Test Scenarios, then a Test Cases table (Case ID | Linked TC | Steps | Expected Result | Priority), Out of Scope, Sign-off.

- [ ] **Step 3: Verify**

Run:
```bash
ls skills/doc-test-plan/SKILL.md skills/doc-test-plan/templates/test-plan.md
grep -c "docs/test-plans/" skills/doc-test-plan/SKILL.md
grep -ci "TC-" skills/doc-test-plan/SKILL.md          # TC-* traceability mentioned
```
Expected: files exist; output path present; TC-* traceability referenced.

- [ ] **Step 4: Commit**

```bash
git add skills/doc-test-plan/
git commit -m "feat(docs): doc-test-plan skill + template"
```

---

### Task 6: `doc-api` skill + templates

**Files:**
- Create: `skills/doc-api/SKILL.md`
- Create: `skills/doc-api/templates/rest-endpoints.md`
- Create: `skills/doc-api/templates/openapi-swagger.yaml`

- [ ] **Step 1: Write `SKILL.md`**

Frontmatter `name: doc-api`, description: "Use when asked to document an API — REST endpoints and/or an OpenAPI/Swagger spec, generated from the code." Body mirrors Task 3. Methodology: discover routes/controllers/handlers in the codebase, document method/path/params/request/response/auth/errors per endpoint; for the OpenAPI template, emit a valid `openapi: 3.x` spec. Output: markdown → `docs/api/YYYY_MM_DD-{slug}.md`; OpenAPI spec → `docs/api/openapi.yaml` (create or update). Reproduce the Template selection algorithm (paths → `skills/doc-api/templates/`). Note the two templates serve different outputs (md doc vs yaml spec).

- [ ] **Step 2: Write the templates**

`rest-endpoints.md`: description comment + per-endpoint block: `### METHOD /path`, Description, Auth, Path/Query/Body params (tables), Request example, Response examples (by status), Errors.
`openapi-swagger.yaml`: description comment (`# one-line`) + a minimal valid skeleton: `openapi: 3.0.3`, `info` (title/version), `servers`, `paths: {}` with one example path showing parameters/requestBody/responses, `components: { schemas: {} }`.

- [ ] **Step 3: Verify**

Run:
```bash
ls skills/doc-api/SKILL.md skills/doc-api/templates/
grep -c "docs/api/" skills/doc-api/SKILL.md
grep -c "openapi" skills/doc-api/templates/openapi-swagger.yaml
```
Expected: files exist; output path present; the yaml template declares `openapi`.

- [ ] **Step 4: Commit**

```bash
git add skills/doc-api/
git commit -m "feat(docs): doc-api skill + templates"
```

---

### Task 7: Rewrite `/documentation` as the router

**Files:**
- Modify (rewrite): `commands/documentation.md`

**Interfaces:**
- Consumes: the `doc-technical`, `doc-functional`, `doc-test-plan`, `doc-api` skills (Tasks 3-6).

- [ ] **Step 1: Rewrite `commands/documentation.md`**

Replace the 4-mode body with a router spec:
- Frontmatter `name: documentation`, description: "Route a documentation request to the right doc-type skill (technical, functional, test plan, API)."
- Usage: `/documentation` · `/documentation <type> [--template=<name>] [path/feature]`.
- Process:
  1. Determine the type. If given as an arg, use it. Else **discover** types by listing `skills/doc-*` directories that contain a `SKILL.md` (exclude `doc-changelog`, which is template-only — the changelog is automatic in `/commit`). Present them via `AskUserQuestion` (label = type, description = the skill's `description`).
  2. Invoke `Skill("doc-<type>")`, passing any `--template` and the path/feature hint.
  3. The skill handles template selection, context gathering, generation, and writes the artifact; surface its output path to the user.
- Add a "Retired modes" note: feature docs → pick technical/functional; changelog → automatic in `/commit`; free command → just talk to Claude.

- [ ] **Step 2: Verify**

Run:
```bash
grep -ci "router\|AskUserQuestion\|Skill(\"doc-" commands/documentation.md   # routing logic present
grep -ci "doc-changelog" commands/documentation.md                          # mentions the exclusion
grep -ci "Mode 1\|Mode 4\|Free Command" commands/documentation.md           # expect 0 (old modes gone)
```
Expected: routing logic present; doc-changelog exclusion noted; no old "Mode N" content.

- [ ] **Step 3: Commit**

```bash
git add commands/documentation.md
git commit -m "feat(docs): rewrite /documentation as doc-type router"
```

---

### Task 8: Wire-up — CONVENTIONS, README, USAGE, INSTALL, VERSION

**Files:**
- Modify: `CONVENTIONS.md`, `README.md`, `USAGE.md`, `INSTALL.md`, `VERSION`

- [ ] **Step 1: Update `CONVENTIONS.md`**

Add to the artifacts/paths table: `docs/changelog/YYYY_MM_DD-HHMM-{slug}.md` (per-commit), `docs/technical/`, `docs/functional/`, `docs/test-plans/`, `docs/api/` (+ `docs/api/openapi.yaml`). Add a "Documentation types" subsection: each type is `skills/doc-<type>/SKILL.md` + `templates/`; template selection algorithm (1 line); how to add a new type (create `skills/doc-<new>/` with SKILL.md + templates — auto-discovered by `/documentation`, auto-triggers by description). Note `doc-changelog` is template-only.

- [ ] **Step 2: Update `README.md` Skills section**

In the `## Skills` table, add the doc-type skills (`doc-technical`, `doc-functional`, `doc-test-plan`, `doc-api`) as a new group ("documentação, sob demanda"). In the Estrutura tree, add `skills/doc-*/` and `docs/changelog · technical · functional · test-plans · api`. Briefly note the per-commit changelog under the commit/ship description if present.

- [ ] **Step 3: Update `USAGE.md`**

Add a "Commit & docs" note that `/commit` now writes a `docs/changelog/` entry per commit; add `/documentation <type>` usage and list the doc types; add 1-2 receitas (e.g. "Gerar caderno de testes → `/documentation test-plan`", "Documentar a API → `/documentation api`").

- [ ] **Step 4: Update `INSTALL.md` structure tree**

Add `skills/doc-*` to the tree note (commands/agents/skills line) — keep it brief; the full layout already references CONVENTIONS.

- [ ] **Step 5: Bump VERSION**

```bash
printf '1.2.0\n' > VERSION
```

- [ ] **Step 6: Verify (full sweep)**

Run:
```bash
ls skills/doc-*/SKILL.md | wc -l                 # expect 4 (technical, functional, test-plan, api)
grep -rl "docs/changelog/" CONVENTIONS.md README.md commands/commit.md
cat VERSION                                       # 1.2.0
grep -rin -e "quiz" -e "linear" -e "codex" --include=SKILL.md skills/doc-* || echo "CLEAN (no specifics)"
```
Expected: 4 doc SKILL.md; changelog referenced in conventions/readme/commit; VERSION 1.2.0; no project-specifics in the new skills.

- [ ] **Step 7: Commit**

```bash
git add CONVENTIONS.md README.md USAGE.md INSTALL.md VERSION
git commit -m "docs: wire documentation system into conventions/readme/usage + bump 1.2.0"
```

---

## Self-Review

**Spec coverage:**
- Part A changelog (trigger/location/content/template/flow/ship) → Tasks 1, 2. ✓
- Part B doc-type skills (4 types, methodology+templates, selection) → Tasks 3-6. ✓
- `/documentation` router → Task 7. ✓
- Conventions / docs / VERSION → Task 8. ✓
- Extensibility (add a new type) → documented in Task 8 / CONVENTIONS. ✓
- Optional `docs/changelog/INDEX.md` → Task 1 Step 2 (marked optional). ✓

**Placeholder scan:** Template files intentionally contain `{{...}}` placeholders — those are the deliverable's content (a fill-in template), not plan placeholders. All plan steps specify concrete files, sections, and verification commands.

**Type/name consistency:** Skill names `doc-technical|functional|test-plan|api|changelog`, output dirs `docs/technical|functional|test-plans|api|changelog`, and the Template selection algorithm are used identically across Tasks 3-8. `doc-changelog` is template-only everywhere (Tasks 1, 7, 8).
