---
name: commit
description: Execute a structured commit with a detailed technical message and push to the configured remote(s)
---

# Commit Command

Execute commit with detailed technical message and automatic push.

> **Note**: The labels in the commit body below are presented in **English** as a portable default. Use the project's dominant language for the body if it differs (detect from existing commit history / repo docs; default to English if unclear).

## Instructions

You must analyze all changes in the repository and create a professional commit with a complete technical message.

### 1. Analyze Changes

Execute the following commands to understand context:

```bash
# Check modified files
git status

# Check full diff of changes
git diff

# Check staged files diff (if any)
git diff --cached

# Check recent commits for style consistency
git log --oneline -5
```

### 2. Commit Message Structure

Message must follow Conventional Commits format with technical detail:

```
<type>(<scope>): <concise descriptive title>

<detailed body explaining:>
- Cause: Why this change was necessary
- Changes: What was technically changed (files, functions, components)
- Consequence: Expected impact/result
- Functionality: How the feature/fix works
- Gain: Technical or business benefit obtained

<footer with metadata>
Developed-by: {execute `git config user.name` to get the real user name configured in git}
```

**CRITICAL**: ALL 5 sections (Cause, Changes, Consequence, Functionality, Gain) are MANDATORY in every commit, regardless of size. Even small fixes must have all 5 sections. The `Developed-by` footer is also MANDATORY. If the project's language is not English, translate these section labels accordingly but keep all 5.

### 3. Commit Types

| Type | Use |
|------|-----|
| `feat` | New functionality |
| `fix` | Bug fix |
| `refactor` | Refactoring without behavior change |
| `perf` | Performance improvement |
| `style` | Formatting, spaces, etc. |
| `docs` | Documentation |
| `test` | Tests |
| `chore` | Maintenance tasks |
| `ci` | CI/CD |

### 4. Scope

Based on affected area. Use a short scope that reflects the part of the codebase touched. Examples:
- `api` - API endpoints
- `db` - Database/migrations
- `auth` - Authentication
- `ui` - Interface/components
- `core` - Core/shared logic
- Specific module or package name (e.g., `users`, `billing`, `parser`)

Follow the project's existing scope conventions if it has them (check `git log`).

### 5. Complete Message Example

```
feat(auth): add refresh-token rotation

Cause: Access tokens were long-lived with no rotation, widening the
window of misuse if a token leaked.

Changes:
- Added RefreshTokenService with rotate() and revoke() methods
- Updated login handler to issue a paired refresh token
- Added refresh_tokens table migration with expiry + revoked columns
- Wired /auth/refresh endpoint to validate and rotate

Consequence: Stolen tokens are invalidated on the next refresh,
shrinking the exposure window to a single short-lived access token.

Functionality: On each refresh the old token is revoked and a new
pair is issued; reuse of a revoked token triggers full session
revocation.

Gain: Stronger session security with no change to the client flow
beyond calling the refresh endpoint.

Developed-by: {git config user.name}
```

### 6. Issue tracker linking (Optional)

**BEFORE creating the commit**, ask the user using the `AskUserQuestion` tool whether to link the commit to an issue in their tracker (e.g. Linear, Jira, GitHub Issues):

- **Question**: "Link this commit to an issue?"
- **Options**:
  - "Yes" (then ask for the issue identifier)
  - "No"

If user answers **Yes**, ask for the issue identifier (e.g., `<ISSUE-ID>` such as `ABC-123`).

Include the identifier in the **commit title** in brackets:
```
feat(auth): add refresh-token rotation [<ISSUE-ID>]
```

To **auto-close the issue** (if the tracker supports it), add to the footer:
```
Fixes <ISSUE-ID>
```

### 7. Generate the Changelog Entry

Before running `git commit`, create a changelog entry so it ships inside the commit it describes.

> **Changelog language**: the changelog entry is written in **pt-BR by default**. There is no per-commit language prompt — the changelog file follows pt-BR regardless of the commit message language.

**7a. Resolve metadata**

```bash
AUTHOR=$(git config user.name)
DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M)
STAMP=$(date +%Y_%m_%d-%H%M)
BRANCH=$(git branch --show-current)
# List staged files (use git status --porcelain if nothing is staged yet)
git diff --cached --name-only
```

Extract `type` and `scope` from the commit title (e.g. `feat(auth)` → type=`feat`, scope=`auth`). Set `issue` to the linked identifier or `null`.

**7b. Build the slug**

Strip the `type(scope):` prefix from the commit title first, then convert the remaining title to kebab-case (≤50 chars), stripping special characters.
Example: `feat(auth): add refresh-token rotation` → `add-refresh-token-rotation`.

**7c. Fill the template**

Read `templates/changelog/commit-entry.md` and substitute every `{{placeholder}}` with the resolved value. If the template file is missing, use the inline format below as a fallback:

```markdown
---
date: <DATE>
time: <TIME>
author: <AUTHOR>
branch: <BRANCH>
type: <type>
scope: <scope>
commit_title: <full commit title>
files_changed: <N>
issue: <ISSUE-ID|null>
---

# <commit title>

## Cause
<why the change was necessary>

## Changes
<files / functions / components changed>

## Consequence
<impact / result>

## Functionality
<how it works>

## Gain
<technical or business benefit>

## Files
<- one bullet per changed file path>
```

**7d. Write the entry**

```bash
# Compute the target path — the LLM then writes the filled template to this file
# using its file-write tool (Write), not a shell heredoc.
# Path follows the convention: docs/changelog/YYYY_MM_DD-HHMM-{slug}.md
CHANGELOG_FILE="docs/changelog/${STAMP}-${slug}.md"
# (use the Write tool to write the filled template content to $CHANGELOG_FILE)
```

The `$VAR` names (STAMP, slug, etc.) are computed via the bash shown in 7a–7b; the final file content is written with the Write tool to `docs/changelog/${STAMP}-${slug}.md`. Do NOT run `git add` here — the commit step (section 8) stages everything, including this just-written changelog file, with its own `git add -A`.

**7e. (Optional) Update the index**

Append a one-line entry to `docs/changelog/INDEX.md`:

```
- <DATE> <TIME> — <commit title> — <AUTHOR>
```

Stage the index file if updated.

### 8. Commit Process

**IMPORTANT**: NEVER change the current branch. Commit and push must be done on the checked-out branch.

Execute in order:

```bash
# 1. Check current branch (for logging only, DO NOT change)
git branch --show-current

# 2. Stage all modified files, including the changelog file written in step 7d
git add -A

# 3. Create commit with structured message (include [<ISSUE-ID>] if provided)
git commit -m "$(cat <<'EOF'
<complete message here>
EOF
)"

# 4. Push to the configured remote
git push
```

> **Multiple remotes**: If the repo is configured with more than one remote (e.g. a mirror), push to each as needed — `git remote -v` lists them, then `git push <remote>` per remote. Otherwise a plain `git push` is sufficient.

### 9. Important Rules

1. **NEVER switch branches**: Always respect the checked-out branch
2. **Mandatory analysis**: ALWAYS analyze diff before creating message
3. **Technical precision**: Mention specific files, functions, and components changed
4. **Business context**: Explain change value when applicable
5. **Body language**: Write the body in the project's dominant language (default English); keep all 5 sections
6. **Push**: Push to the configured remote(s) after committing

### 10. Error Handling

If push fails:
- Check for remote commits not synced (`git pull --rebase`)
- Resolve conflicts if needed
- Retry push

If no changes to commit:
- Inform user there are no pending changes
- Don't execute unnecessary commands

### 11. Checklist

Before finishing, verify:

- [ ] Analyzed all changes (staged and unstaged)
- [ ] Asked about issue tracker linking
- [ ] Included issue identifier (if provided)
- [ ] Message follows Conventional Commits
- [ ] All 5 sections (Cause/Changes/Consequence/Functionality/Gain) are present and clear
- [ ] Specific technical files were mentioned
- [ ] Footer includes "Developed-by: {git config user.name}"
- [ ] Changelog entry written to `docs/changelog/` and staged
- [ ] Commit was created successfully
- [ ] Push was executed successfully to the configured remote(s)

---

**Optional argument**: `$ARGUMENTS`

If provided, use as additional context for the commit message.
Example: `/commit adds input validation to the signup form`
