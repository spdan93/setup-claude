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

(The `SKILL.md` test above naturally returns only real skills — the changelog is not a skill; it lives at `templates/changelog/` and is produced automatically by `/commit`.)

For each directory returned by the glob above, read the `description:` field from its `SKILL.md` YAML frontmatter. The directories discovered by the glob are exactly the options presented — each option's label is the type name (e.g. `technical`) and its description is the value read from that skill's `SKILL.md` at run time.

Present those options to the user via `AskUserQuestion`. Do NOT use hard-coded descriptions; always read the live `description:` from each `SKILL.md`.

### 2. Invoke the skill

Forward any `--template=<name>` flag and the path/feature hint to the skill unchanged. Example:

```
Skill("doc-technical", "--template=adr src/backend")
```

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
