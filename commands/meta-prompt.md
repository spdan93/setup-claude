---
name: meta-prompt
description: Generate structured prompts for cross-agent context transfer
---

# Meta-Prompt Command

Generate a structured English prompt for passing context to another LLM or agent.

## Usage

```bash
# Interactive mode (recommended)
/meta-prompt

# With arguments
/meta-prompt --task="implementation" --artifacts="path/to/file.md" --output="code with tests"
```

## Arguments

| Argument | Description | Example |
|----------|-------------|---------|
| `--task` | Type of task | `review`, `plan`, `implementation`, `issue`, `documentation`, `test` |
| `--artifacts` | Comma-separated paths or references | `docs/plan.md,src/file.ts` |
| `--constraints` | Rules or limitations | `"follow the project's CLAUDE.md / codebase patterns"` |
| `--output` | Expected output format | `"code review with approval status"` |
| `--criteria` | Acceptance criteria | `"tests pass, no security issues"` |

## Behavior

1. **If arguments provided**: Generate prompt directly using the `meta-prompt` skill
2. **If no arguments**: Prompt interactively for required inputs

## Instructions for Claude

When this command is invoked:

1. Load the `meta-prompt` skill from `.claude/skills/meta-prompt/SKILL.md`
2. Collect inputs (from arguments or interactively):
   - `task_type` (required)
   - `artifacts` (required)
   - `constraints` (optional)
   - `expected_output` (required)
   - `acceptance_criteria` (optional)
3. Generate the structured prompt following the skill's output format
4. Display the generated prompt to the user
5. Optionally copy to clipboard or save to file

## Example Output

```markdown
## Objective

Implement the user authentication feature with JWT token support.

## Context Summary

This task creates the authentication layer for the API, enabling secure user sessions.

## Input Artifacts

- `docs/plans/2026-01-28-auth-plan.md#task-1-1` - Task specification
- `src/auth/` - Existing auth module for reference

## Constraints

- Use the existing JWT library already in the project
- Follow the project's CLAUDE.md / codebase patterns
- Must include unit tests

## Required Output Format

1. Implementation in `src/auth/`
2. Tests colocated with the implementation (per the project's test convention)
3. Updated module exports

## Step-by-step Instructions

1. Read task specification from plan
2. Review existing auth patterns
3. Implement JWT strategy
4. Create guards for protected routes
5. Write unit tests
6. Verify all tests pass

## Acceptance Criteria

- [ ] JWT tokens generated correctly
- [ ] Guards protect specified routes
- [ ] Unit tests pass
- [ ] No security vulnerabilities

## Non-goals

- Do NOT implement OAuth (separate task)
- Do NOT modify existing user model

## Questions (if info missing)

None - sufficient context provided.
```

## When to Use

- **Manual prompt generation**: When you need to craft a specific prompt for an external tool
- **Debugging**: To see what prompt would be generated before passing to an agent
- **Documentation**: To document the exact context being passed between components

## Related

- Skill: `.claude/skills/meta-prompt/SKILL.md`
- Used by: `/workflow`, `developer` agent
