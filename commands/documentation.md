---
name: documentation
description: Document features, register changelogs, or both
---

# Documentation Command

Document features, register changelogs, or both for the current project.

> **Note**: Write generated output (documentation, changelogs) in the project's dominant language (detect from repo docs/commits; default English if unclear).

## Operation Modes

**MANDATORY: Always ask the user which mode to use before proceeding.**

Use the AskUserQuestion tool with these options:

| Mode | Description | Version Bump |
|------|-------------|--------------|
| **1. Document Feature** | Document the feature developed in the current branch (all changes). Find the best location in the project's documentation or complement existing sections. | ❌ No |
| **2. Register Changelog** | Register only the changelog entry for the changes. | ✅ Yes (before documenting) |
| **3. Full Documentation** | Feature documentation + Changelog registration. | ✅ Yes (before documenting) |
| **4. Free Command** | User provides custom instructions. | ⚠️ Only if changelog-level changes exist |

---

## Mode 1: Document Feature (No Version Bump)

Document the feature without changing versions or changelogs.

### Steps

1. **Analyze current branch changes** (use the repo's default branch as the base)
   ```bash
   DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
   DEFAULT_BRANCH=${DEFAULT_BRANCH:-main}
   git diff --name-only "$DEFAULT_BRANCH"...HEAD
   git log "$DEFAULT_BRANCH"..HEAD --oneline
   ```

2. **Understand what was implemented**
   - Functionality, endpoints, components
   - Where (which package/module)
   - How it works (flow, dependencies)
   - Why (use case, problem solved)

3. **Find best documentation location** (see Document Location section)

4. **Write documentation** following the Documentation Pattern

5. **Final Checklist (Mode 1)**
   - [ ] Document is in correct location in the docs directory
   - [ ] Valid formatting for the docs format used
   - [ ] Code examples are correct
   - [ ] Didn't break existing content
   - [ ] Internal links work
   - [ ] Tables are properly formatted

---

## Mode 2: Register Changelog (Version Bump Required)

Register changelog entries only, with version bump.

### Steps

1. **Get current date** (MANDATORY - always execute):
   ```bash
   date +%Y-%m-%d
   ```

2. **Check changes in ALL changed packages** (relative to the default branch)
   ```bash
   DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
   DEFAULT_BRANCH=${DEFAULT_BRANCH:-main}
   git diff --name-only "$DEFAULT_BRANCH"...HEAD -- <package-dir>/
   ```
   Repeat per package root, or run without a path filter for a single-package repo.

3. **Bump version BEFORE documenting** (for traceability)
   - Follow Version Bump Rules section
   - Execute bump commands for each changed package

4. **Update changelogs**
   - Per-package or root `CHANGELOG.md` (if it exists)
   - The docs-site changelog page (if the project has one)

5. **Final Checklist (Mode 2)**
   - [ ] Got current date via bash command
   - [ ] Checked changes in ALL changed packages
   - [ ] Bumped version in the manifest for each changed package
   - [ ] Updated `CHANGELOG.md` (if it exists)
   - [ ] Updated the docs-site changelog page (if the project has one)
   - [ ] Updated any "Last updated" marker in the changelog (if present)

---

## Mode 3: Full Documentation (Feature + Changelog)

Full documentation with version bump.

### Steps

1. **Execute Mode 2 first** (Changelog with version bump)

2. **Then execute Mode 1** (Feature documentation)

3. **Final Checklist (Mode 3)**
   - All items from Mode 2 checklist
   - All items from Mode 1 checklist

---

## Mode 4: Free Command

User provides custom instructions.

### Steps

1. **Listen to user's specific request**

2. **Determine if changelog-level changes exist**
   - If YES: bump version before proceeding
   - If NO: proceed without version bump

3. **Execute user's request**

4. **Apply relevant checklist items based on what was done**

---

## Reference: Discover Packages

Detect the project layout — do not assume a fixed structure:

- **Monorepo**: each directory with a manifest (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, ...) is a package.
- **Single-package repo**: the repo root is the one package.

```bash
# Node example; adapt to the ecosystem
find . -name package.json -not -path '*/node_modules/*'
```

## Reference: Version Bump Rules (Semantic Versioning)

For EACH package with changes, bump following **MAJOR.MINOR.PATCH**:

| Change Type | Bump | Example | When to Use |
|-------------|------|---------|-------------|
| **PATCH** | x.x.X | 1.2.3 → 1.2.4 | Bug fixes, minor adjustments, refactoring without behavior change |
| **MINOR** | x.X.0 | 1.2.3 → 1.3.0 | New features, significant improvements, backward-compatible functionality |
| **MAJOR** | X.0.0 | 1.2.3 → 2.0.0 | Breaking changes, API changes, feature removal (rare, ask user) |

**If user specifies bump** (e.g., `fix 1.6.4`, `minor`, `patch`), use exactly what was requested.

### Bump Commands

Use the project's ecosystem mechanism. For Node packages:

```bash
cd <package-dir> && npm version patch --no-git-tag-version
cd <package-dir> && npm version minor --no-git-tag-version
cd <package-dir> && npm version major --no-git-tag-version
cd <package-dir> && npm version X.Y.Z --no-git-tag-version
```

For other ecosystems, edit the version field in the manifest directly.

## Reference: Changelog Formats

### `CHANGELOG.md` (Keep a Changelog style)

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added / Changed / Fixed / Removed
- Change description
```

### Docs-site changelog page (if present)

1. Add a new entry at the top (after any `## [Unreleased]` section) with the version.
2. Use the docs site's existing format:
   ```markdown
   ## [X.Y.Z] - YYYY-MM-DD

   ### Added / Changed / Fixed / Removed
   - **Feature Name**: Brief description
     - Detail 1
     - Detail 2
   ```
3. Update any "Last updated" line if the page has one.

## Reference: Document Location

**If user specified a path after the command**, use that exact path.

**If not specified**, determine the best location based on feature type and the project's existing docs layout:

| Feature Type | Typical Category |
|--------------|------------------|
| Endpoints/API | API reference |
| Architecture/Patterns | Architecture |
| Backend (services, entities) | Backend |
| Frontend (components, UI) | Frontend |
| External integrations | Integrations |
| Usage guides (how to use feature) | Guides (create subfolder if needed) |
| Setup/Configuration | Setup |
| Contribution/Code standards | Contributing |

Map these categories onto the project's actual docs directory.

## Reference: Documentation Pattern

Follow the project's existing documentation format (Markdown, MDX, etc.). A generic structure:

````markdown
## Feature Name

Concise description of what it is and what it's for.

### Characteristics

| Aspect | Description |
|--------|-------------|
| ... | ... |

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

## Reference: Writing Rules

1. **Incremental**: Add content without removing existing documentation, unless the feature invalidates old docs

2. **Consistent**: Use same style, formatting, and tone as existing documents

3. **Technical but accessible**: Be technically precise, but write clearly

4. **Real examples**: Use examples that work in the project's actual context

5. **Document language**: Keep each document's existing language

6. **Internal links**: Reference other documentation sections when relevant

## Reference: Docs Directory Structure

Inspect the project's docs directory to learn its layout before writing. A common shape:

```
docs/
├── index                       # Documentation home
├── api-reference               # API reference
├── changelog                   # Changelog
├── architecture                # System architecture
├── backend                     # Backend documentation
├── frontend                    # Frontend documentation
├── integrations                # Integrations
├── setup                       # Environment setup
├── contributing                # Contribution guide
└── guides/                     # Usage guides (getting started, advanced topics, ...)
```

Adapt to whatever structure and file extensions the project actually uses.

---

**Optional argument**: `$ARGUMENTS`

If provided, use as specific document path or bump indication. Examples:
- `/documentation docs/guides/transaction-id.md`
- `/documentation fix 1.6.4` (indicates patch bump to version 1.6.4)
- `/documentation minor` (indicates minor bump)

---
