---
name: doc-api
description: Use when asked to document an API — REST endpoints and/or an OpenAPI/Swagger spec, generated from the code.
---

# API Documentation

## Methodology

Good API documentation answers the questions a consumer cannot answer by reading the source alone: **what routes exist**, **what they expect**, **what they return**, and **under what conditions they fail**.

### What a good API doc covers

| Section | Purpose |
|---|---|
| **Method + Path** | The HTTP verb and URL pattern that identifies the endpoint unambiguously. |
| **Description** | One sentence: what the endpoint does and who would call it. |
| **Authentication** | Required auth scheme (Bearer, API key, none) and any required scopes or roles. |
| **Path parameters** | Variable segments in the URL — name, type, constraints, and whether required. |
| **Query parameters** | Optional or required query-string parameters — same fields as path params. |
| **Request body** | Schema, content-type, and a concrete JSON/form example. |
| **Response examples** | One example per notable HTTP status code (200, 201, 400, 401, 404, 422, 500). |
| **Errors** | Enumerate error codes/messages the caller must handle; avoid "see 4xx". |

### What to ask the user before starting

- Which endpoints or controllers should be documented? (all, a module, a tag)
- What output format is needed: a Markdown reference doc, an OpenAPI spec, or both?
- Is there an existing `docs/api/openapi.yaml` to update, or should one be created from scratch?
- Who is the audience? (internal team, external partners, public API consumers)

### Common pitfalls

| Pitfall | Avoidance |
|---|---|
| **Invented routes** | Read the actual route definitions — do not document endpoints that do not exist. |
| **Missing error cases** | Every endpoint that can fail with a user-actionable error must list it. |
| **Stale examples** | Examples must match the current schema; copy from real request/response bodies. |
| **Vague auth** | Specify the scheme and token scope, not just "authenticated". |
| **Single-output confusion** | The Markdown template and the OpenAPI template serve different consumers — choose consciously. |

## Process

### 1. Discover routes

- Search the codebase for route definitions using `grep` + `Read`. Common patterns to look for:
  - Decorator-based frameworks: `@Get`, `@Post`, `@Put`, `@Delete`, `@Patch`, `@Route`
  - Functional routers: `router.get(`, `app.post(`, `express.Router`, `fastify.route`
  - OpenAPI annotations: `@ApiOperation`, `@swagger`, `@oas`
- Map each found route to its handler function and read the handler source.
- Identify request DTOs/schemas, response types, and guard/middleware decorators.
- Note any existing docs in `docs/api/` — update rather than duplicate.

### 2. Select a template

See **Template selection** below.

### 3. Fill grounded in real code

- Every endpoint listed must exist in the current codebase — read the file and line before documenting it.
- Request and response examples must reflect the actual schema types, not invented shapes.
- If an auth requirement is not explicit in the code (guard, middleware, annotation), mark it `<!-- TODO: auth requirement unclear — verify with team -->`.
- For the OpenAPI template: emit valid YAML conforming to `openapi: 3.x`. Validate structure before saving.

### 4. Write to the output path and report it

Choose the appropriate output path based on the selected template:

- **Markdown endpoint reference** → `docs/api/YYYY_MM_DD-{slug}.md`
  - Slug rules: kebab-case, lowercase, characters `[a-z0-9-]`, maximum 50 characters.
  - Example: "User Auth Endpoints" → `user-auth-endpoints`
- **OpenAPI spec** → `docs/api/openapi.yaml` (create if absent, update `paths:` if present)

Both paths live under `docs/api/` at the repository root. Never write inside `.claude/`.

Report the exact output path(s) to the user when done.

## Template selection

```
1. If --template=<name> was given, use templates/<name>.
2. Else list templates/* (each template's first line is a one-line description):
   - 0 templates  → error: "no templates; add one to skills/doc-api/templates/".
   - 1 template   → use it (no prompt).
   - ≥2 templates → AskUserQuestion showing each (name + one-line description); use the choice.
3. Users add custom templates by dropping files into skills/doc-api/templates/.
```

Note: the two built-in templates serve **different outputs**:

| Template | Output | When to use |
|---|---|---|
| `rest-endpoints.md` | `docs/api/YYYY_MM_DD-{slug}.md` | Human-readable Markdown reference, typically for team docs or wikis. |
| `openapi-swagger.yaml` | `docs/api/openapi.yaml` | Machine-readable OpenAPI 3.x spec, consumed by Swagger UI, code generators, or API gateways. |

If the user wants both, run the process twice — once per template.

## Quality gate

Before reporting the document as complete, verify each item:

- [ ] Every endpoint described was read in the current session — not recalled from memory.
- [ ] No routes, parameters, or response shapes are documented that do not exist in the current code.
- [ ] Every endpoint includes method, path, auth, parameters (if any), request example (if body), and at least one response example.
- [ ] Error responses list the specific status codes and messages a caller must handle.
- [ ] Output path matches the chosen template's convention exactly (correct date, valid slug, or `openapi.yaml`).
- [ ] The OpenAPI output (if produced) is valid YAML and declares `openapi: 3.0.x` or higher at the top level.
- [ ] Document language matches the project's convention (default: English).
- [ ] Slug (for Markdown output) is kebab-case, lowercase `[a-z0-9-]`, ≤50 characters.
