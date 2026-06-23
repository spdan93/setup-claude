---
name: prd-write
description: Create new PRD from user idea
---

# PRD Write

## Purpose
Standalone command to create a new PRD without running full pipeline.

## Usage
```bash
/prd-write                           # Interactive - asks for idea
/prd-write "Add Google OAuth login"  # Direct with idea
```

## Delegates To
- Agent: `prd-writer`

## Arguments

| Arg | Required | Description |
|-----|----------|-------------|
| `idea` | No | Feature idea or requirement (asked if not provided) |

## Process
1. If idea not provided → Ask user for feature idea
2. Invoke `Task(subagent_type="prd-writer", prompt=idea)`
3. Agent returns PRD path
4. Check if file exists at expected path
5. Return success message with path

## Conflict Handling

If PRD file already exists at target path:
- Show message with current PRD path
- Ask user: `overwrite` / `version bump` / `cancel`
- If overwrite → Proceed with agent (will overwrite)
- If version bump → Increment version in frontmatter
- If cancel → Exit without changes

## Output
- PRD file path
- Success message: "PRD created at {path}"
