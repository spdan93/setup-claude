---
allowed-tools: Read, Edit, Write, Glob, Grep, Bash
model: sonnet
argument-hint: create [path] | edit <path-to-claude-md>
description: Create or edit CLAUDE.md files - conceptual context documentation (README for AI agents)
---

# Purpose

Create or edit CLAUDE.md files as **isolated context blocks** for directories.

## What is CLAUDE.md?

CLAUDE.md is the ONLY context file an autonomous agent needs to read when working in a directory. It answers:
- **WHAT** is this directory (domain, responsibilities)
- **WHY** it exists (purpose, business reason)
- **HOW** to work here (patterns, rules, workflows)

**This is NOT code documentation** - it's conceptual definition of existence.

## Critical Constraints

- **200 lines MAXIMUM** - be maximally clear with minimum tokens
- **Zero code** - only concepts, definitions, and reasoning
- **Isolated context** - agent shouldn't need to read other files to understand basics
- **Self-contained** - references are for deep dives, not dependencies

## Mode: $ARGUMENTS

---

## Best Practices Reference

### Core Principles

1. **Isolated context block** - Agent reads ONLY this file to understand the directory
2. **200 lines MAXIMUM** - Maximum clarity with minimum tokens
3. **Zero code** - Concepts, definitions, reasoning only
4. **Self-contained** - Don't require reading other files for basic understanding
5. **Universal guidance only** - Skip task-specific or temporary details
6. **References for deep dives** - Not dependencies for basic context

### The WHY-WHAT-HOW Framework

#### WHY (Purpose & Context)
- What the project/directory does
- Why it exists - business/architectural reason
- Business logic that affects code decisions
- What would be missing without this module

#### WHAT (Responsibilities & Structure)
- Project type and main technologies
- Key directories and their conceptual purposes
- Domain/concern boundaries
- Important file locations and their roles

#### HOW (Development Workflow)
- Build/run commands
- Testing procedures
- Patterns and conventions
- Verification methods
- Critical rules (security, performance, etc.)

### Anti-Patterns to AVOID

- **Code snippets** - Zero code allowed, only concepts
- **Code style guidelines** - Use linters/formatters instead
- **Implementation details** - Focus on WHY/WHAT/HOW, not how code works
- **Task-specific hotfixes** - Only universal, permanent guidance
- **Database schemas** - Too detailed, distracts from concepts
- **Dependencies on other files** - Must be self-contained for basic understanding
- **Verbose explanations** - Be maximally clear with minimum tokens

### Progressive Disclosure

Instead of stuffing everything into CLAUDE.md:

1. Keep CLAUDE.md minimal and universal
2. Use a separate docs folder in `/docs/` to store detailed documentation
3. Reference the documentation with file folders or file paths when needed

---

## Instructions: CREATE Mode

Use when creating a new CLAUDE.md file from scratch.

### 1. Analyze the target directory

**Directory Contents**:
```bash
ls -la [target-path]
```

**Subdirectory Structure**:
```bash
find [target-path] -type d \( -name node_modules -o -name .git -o -name dist -o -name build -o -name __pycache__ -o -name .next -o -name .nuxt -o -name coverage -o -name .turbo -o -name .cache -o -name .venv -o -name venv -o -name env -o -name .env -o -name target -o -name vendor -o -name .idea -o -name .vscode \) -prune -o -type d -print 2>/dev/null | head -100 | sed 's|^\./||' | sort
```

**Project Context**:
- Read package.json, pyproject.toml, or equivalent for dependencies
- Check existing README.md for context
- Look for existing linter/formatter configs
- Identify entry points and key source files
- Check parent CLAUDE.md for broader context

### 2. Map conceptual structure

For EACH directory/file found:
- Determine its **conceptual purpose** (not what code it has, but WHY it exists)
- Group related concepts logically
- Identify domain boundaries
- Understand patterns (features/, components/, services/, etc.)

### 3. Generate CLAUDE.md as Conceptual Documentation

**Semantic Structure**:

```markdown
# [Directory/Module Name]

One-line conceptual description of this directory's purpose and role in the system.

## Purpose (WHY)

Why does this directory exist? What problem does it solve? What's its role in the larger system?

- Business/architectural reason for existence
- What would be missing without this module
- Relationship to other major components

## Responsibilities (WHAT)

What conceptual responsibilities does this directory own?

- Primary domain/concern (e.g., "User authentication flow", "Analytics event processing")
- Key concepts and entities it manages
- Boundaries of what belongs here vs elsewhere

## Structure

Brief overview of how this directory is organized conceptually:

```
directory/
├── subdirectory/     # Conceptual purpose
├── another/          # Conceptual purpose
└── important-file.ts # Key role/responsibility
```

## Working Here (HOW)

How should agents approach work in this directory?

### Patterns
- Architectural patterns followed (e.g., "Feature-first organization", "Layered architecture")
- Conventions specific to this area
- Integration points with other parts of system

### Commands (if applicable)
- `npm run relevant-command` - Purpose
- Key workflows specific to this directory

### Critical Rules
- Security/tenancy constraints
- Other security constraints
- Performance considerations
- Any MUST/MUST NOT rules specific to this area

## Key Concepts

Domain-specific concepts important to understand when working here:
- Technical decisions and their rationale
- Why certain approaches were chosen
- Trade-offs and constraints

## Related Documentation

- Link to `/docs/` files for deep dives
- References to architectural decision records
- Related CLAUDE.md files in other directories
```

**Remember**: Focus on concepts, understanding, and reasoning - not implementation details.

### 4. Verify the result

- [ ] **200 lines MAXIMUM** - absolute hard limit
- [ ] **Isolated context** - agent can understand directory without reading other files
- [ ] **Zero code** - only concepts, definitions, reasoning
- [ ] Explains WHY directory exists (purpose/reasoning)
- [ ] Describes WHAT it's responsible for (conceptually)
- [ ] Guides HOW to work here (patterns/rules)
- [ ] No style guidelines (that's for linters)
- [ ] Maximally clear with minimum tokens
- [ ] Self-contained - references are optional deep dives only

---

## Instructions: EDIT Mode

Use when editing an existing CLAUDE.md file to add or update information.

### 1. Read the existing CLAUDE.md

- Read the target CLAUDE.md file completely
- Understand current structure and content
- Identify which WHY-WHAT-HOW sections exist
- Note the file's current line count

### 2. Understand the requested changes

Based on user input, determine:
- What new **conceptual information** needs to be added
- Which section(s) should be updated (WHY/WHAT/HOW)
- Whether new sections are needed
- What context is missing for AI agents

### 3. Gather context for the update

**If adding purpose/reasoning (WHY)**:
- Understand business/architectural decisions
- Identify relationships with other components
- Clarify the role in the larger system

**If adding responsibilities (WHAT)**:
- Define domain boundaries
- Identify key concepts managed here
- Clarify what belongs vs what doesn't

**If adding workflow/patterns (HOW)**:
- Check scripts in package.json
- Review architectural patterns in code
- Identify conventions being followed
- Look for critical rules (security, isolation, etc.)

**Always check codebase for context**:
- Search for relevant files/patterns
- Read key implementation files to understand concepts
- Review existing documentation in `/docs/`

### 4. Make surgical edits

**CRITICAL RULES**:
- This is **conceptual documentation**, not code documentation
- Focus on WHY (purpose), WHAT (responsibility), HOW (patterns)
- Preserve existing structure and formatting
- Maintain WHY-WHAT-HOW organization
- Add information to appropriate sections
- Keep additions concise and information-dense
- Follow existing writing style
- Avoid duplicating information

**Edit Strategy**:
- Use Edit tool for targeted changes
- Preserve line limits (target: under 300 lines)
- Maintain Progressive Disclosure principle
- Each addition should add conceptual understanding, not implementation details

### 5. Verify the edit

After editing, check:
- [ ] **Still under 200 lines** - absolute hard limit
- [ ] **Zero code added** - concepts only
- [ ] Added **conceptual context**, not implementation details
- [ ] New information is in correct section (WHY/WHAT/HOW)
- [ ] Information explains reasoning and purpose
- [ ] Formatting consistent with existing content
- [ ] No duplication with existing sections
- [ ] File remains maximally clear with minimum tokens
- [ ] Still self-contained and isolated

---

## Output Format

After completing the action, provide:

1. **Summary of changes** (create: what was created, edit: what was modified)
2. **Line count** (before → after if applicable)
3. **Checklist status** against best practices
4. **Recommendations** for further improvements (if any)

Remember: A good CLAUDE.md is like a good README for AI - concise, structural, and focused on enabling effective collaboration through conceptual understanding.
