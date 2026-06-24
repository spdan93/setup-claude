---
name: documentation
description: Route a documentation request to the right doc-type skill (technical, functional, test plan, API).
---

# Documentation Command

Thin router: determines the doc type, then delegates to the matching skill.

## Usage

```
/documentation
/documentation <type> [--template=<name>] [path/feature]
```

**Types**: `technical` · `functional` · `test-plan` · `api`

## Process

### 1. Determine the doc type

**If a type was given as an argument** — use it directly.

**If no type was given** — discover available types by listing `skills/doc-*` directories that contain a `SKILL.md`:

```bash
for d in skills/doc-*/; do [ -f "${d}SKILL.md" ] && echo "$d"; done
```

Exclude `doc-changelog` (template-only; changelog is produced automatically by `/commit`, not here).

Present the discovered types to the user via `AskUserQuestion`:

| Label | Description (from skill's `description` frontmatter) |
|-------|------------------------------------------------------|
| `technical` | Architecture, module design, ADRs — how the system works internally. |
| `functional` | What the system does from a business/user perspective, business rules, functional flows. |
| `test-plan` | Structured test scenarios and cases (steps, expected results). |
| `api` | REST endpoints and/or OpenAPI/Swagger spec, generated from the code. |

### 2. Invoke the skill

```
Skill("doc-<type>")
```

Forward any `--template=<name>` flag and the path/feature hint to the skill unchanged.

The skill handles everything from here: template selection, context gathering, generation, and writing the artifact.

### 3. Surface the output

Return the artifact path reported by the skill to the user.

---

## Arguments

| Arg | Required | Description |
|-----|----------|-------------|
| `<type>` | No | One of `technical`, `functional`, `test-plan`, `api`. Prompted if omitted. |
| `--template=<name>` | No | Template name to pass to the skill. |
| `path/feature` | No | Scope hint forwarded to the skill. |

---

## Retired modes

The legacy 4-mode system is retired:

- **Document Feature / Register Changelog / Full** → pick `technical` or `functional` instead.
- **Changelog** → produced automatically by `/commit`; do NOT use this command for changelogs.
- **Free Command** → just talk to Claude directly.
