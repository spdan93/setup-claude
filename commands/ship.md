---
name: ship
description: Document, version bump, and commit changes with push in one workflow
---

# Ship Command

Complete workflow to document, version bump, and commit changes with a push to the configured remote(s).

> **Note**: Write generated output (documentation, changelogs, commit messages) in the project's dominant language (detect from repo docs/commits; default English if unclear).

## Overview

This command combines two workflows into one:

1. **Documentation** - Version bumping, changelog updates, and feature documentation
2. **Commit** - Structured commit message with optional issue-tracker linking and push

## Instructions

Execute this command when you've completed a feature or fix and want to ship it with proper documentation and versioning.

---

## PHASE 1: Documentation & Versioning

### 1.1 Check Changes Across All Packages (MANDATORY)

Before any documentation, verify changes in every changed package/app and bump versions accordingly.

#### Discover changed packages

If this is a monorepo, discover the package roots (each directory containing a `package.json` or equivalent manifest). If it's a single-package repo, treat the repo root as the one package. Do not assume a fixed layout — detect it.

```bash
# Find package manifests (Node example; adapt to the project's ecosystem)
git diff --name-only HEAD~10 | sed 's#/[^/]*$##' | sort -u
# Or locate manifests:
#   Node:    find . -name package.json -not -path '*/node_modules/*'
#   Python:  pyproject.toml / setup.cfg
#   Rust:    Cargo.toml
#   Go:      go.mod
```

For each package root, check whether it has changes:

```bash
git diff --name-only HEAD~10 -- <package-dir>/
```

#### Version Bump Rules (Semantic Versioning)

For EACH package with changes, bump following **MAJOR.MINOR.PATCH**:

| Change Type | Bump  | Example       | When to Use                                                               |
| ----------- | ----- | ------------- | ------------------------------------------------------------------------- |
| **PATCH**   | x.x.X | 1.2.3 → 1.2.4 | Bug fixes, minor adjustments, refactoring without behavior change         |
| **MINOR**   | x.X.0 | 1.2.3 → 1.3.0 | New features, significant improvements, backward-compatible functionality |
| **MAJOR**   | X.0.0 | 1.2.3 → 2.0.0 | Breaking changes, API changes, feature removal (rare, ask user)           |

**If user specifies bump** (e.g., `fix 1.6.4`, `minor`, `patch`), use exactly what was requested.

#### Bump Commands

Use the bump mechanism the project's ecosystem provides. For Node packages:

```bash
# Bump patch (fixes)
cd <package-dir> && npm version patch --no-git-tag-version

# Bump minor (features)
cd <package-dir> && npm version minor --no-git-tag-version

# Bump major (breaking changes)
cd <package-dir> && npm version major --no-git-tag-version

# Specific version
cd <package-dir> && npm version X.Y.Z --no-git-tag-version
```

For other ecosystems, edit the version field in the manifest directly (`pyproject.toml`, `Cargo.toml`, etc.).

### 1.2 Update Changelogs (MANDATORY)

Update the project's changelog(s). Common locations (use whichever the project has):

#### a) Root or per-package `CHANGELOG.md`

1. Add a new entry at the top (after any `## [Unreleased]` section) with the date and version.
2. Use the existing format. If none exists, follow Keep a Changelog style:

   ```markdown
   ## [X.Y.Z] - YYYY-MM-DD

   ### Added / Changed / Fixed / Removed

   - **Feature Name**: Brief description
     - Detail 1
     - Detail 2
   ```

#### b) Documentation-site changelog page (if the project has a docs site)

If the project publishes a docs site with a changelog page (e.g. `docs/changelog`), add the same entry there in that site's format, and update any "Last updated" line if present.

**Update every changelog the project maintains.** If the project only has one, update that one.

### 1.3 Feature Analysis

Before documenting, analyze:

- What was implemented (functionality, endpoints, components)
- Where it was implemented (which package/module)
- How it works (flow, dependencies, integrations)
- Why it was implemented (use case, problem solved)

### 1.4 Document Location

**If user specified a path after the command**, use that exact path.

**If not specified**, determine the best location based on feature type and the project's existing docs structure:

| Feature Type                       | Typical Location                          |
| ---------------------------------- | ----------------------------------------- |
| Endpoints/API                      | API reference docs                        |
| Architecture/Patterns              | Architecture docs                         |
| Backend (services, entities)       | Backend docs                              |
| Frontend (components, UI)          | Frontend docs                             |
| External integrations              | Integrations docs                         |
| Usage guides (how to use feature)  | Guides section (create subfolder if needed) |
| Setup/Configuration                | Setup docs                                |
| Contribution/Code standards        | Contributing docs                         |

Map these categories onto the project's actual docs directory layout.

### 1.5 Documentation Pattern

Follow the project's existing documentation format (Markdown, MDX, reStructuredText, etc.). A generic structure:

````markdown
## Feature Name

Concise description of what it is and what it's for.

### Characteristics

| Aspect | Description |
| ------ | ----------- |
| ...    | ...         |

### How to Use

Clear instructions with code examples.

### Endpoints (if applicable)

#### Endpoint Name

```http
METHOD /path
Header: value
```

**Request:**

```json
{ "field": "value" }
```

**Response:**

```json
{ "result": "value" }
```

### Examples

```typescript
// Example code
```

### Considerations

- Bullet points with important information
- Limitations or warnings
- Best practices
````

### 1.6 Writing Rules

1. **Incremental**: Add content without removing existing documentation, unless the feature invalidates old docs
2. **Consistent**: Use same style, formatting, and tone as existing documents
3. **Technical but accessible**: Be technically precise, but write clearly
4. **Real examples**: Use examples that work in the project's actual context
5. **Document language**: Keep each document's existing language
6. **Internal links**: Reference other documentation sections when relevant

---

## PHASE 2: Commit & Push

**MANDATORY**: Invoke the `commit` command (use the Skill tool to invoke `commit`).

The `commit` skill handles the complete commit workflow:
- Analyzing all staged/unstaged changes
- Asking about optional issue-tracker linking
- Creating the commit with the mandatory 5-section structure (Cause/Changes/Consequence/Functionality/Gain)
- Adding the `Developed-by` footer
- Pushing to the configured remote(s)

**DO NOT** duplicate the commit logic here. `commit` is the single source of truth for commit message format and process.

---

## Final Checklist

Before finishing, verify:

**Phase 1 - Documentation:**

- [ ] Checked changes in ALL changed packages/apps
- [ ] Bumped version in the manifest for each changed package
- [ ] Updated `CHANGELOG.md` for each changed package (if it exists)
- [ ] Updated the docs-site changelog page (if the project has one)
- [ ] Updated any "Last updated" marker in the changelog (if present)
- [ ] Document is in the correct location in the docs directory
- [ ] Valid formatting for the docs format used
- [ ] Code examples are correct
- [ ] Didn't break existing content
- [ ] Internal links work
- [ ] Tables are properly formatted

**Phase 2 - Commit (handled by `commit`):**

- [ ] `commit` was invoked via Skill tool
- [ ] All 5 sections present (Cause/Changes/Consequence/Functionality/Gain)
- [ ] `Developed-by` footer present
- [ ] Issue linked (if applicable)
- [ ] Push successful to the configured remote(s)

---

**Optional argument**: `$ARGUMENTS`

If provided, use as specific document path or bump indication. Examples:

- `/ship docs/guides/transaction-id.md`
- `/ship fix 1.6.4` (indicates patch bump to version 1.6.4)
- `/ship minor` (indicates minor bump)
