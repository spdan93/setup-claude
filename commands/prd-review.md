---
name: prd-review
description: Review and refine existing PRD
---

# PRD Review

## Purpose
Standalone command to review an existing PRD draft.

## Usage
```bash
/prd-review                                    # Interactive - lists PRDs
/prd-review docs/prds/2026_01_27-feature.md   # Direct with path
```

## Delegates To
- Agent: `prd-reviewer`

## Arguments

| Arg | Required | Description |
|-----|----------|-------------|
| `prd_path` | No | Path to PRD file (prompted if not provided) |

## Process
1. If prd_path not provided:
   - List PRDs in docs/prds/ (sorted by date, newest first)
   - Ask user to select one
2. Verify file exists
3. Invoke `Task(subagent_type="prd-reviewer", prompt="Review PRD at {prd_path}")`
4. Agent edits PRD in place
5. Return success message

## Output
- Updated PRD path
- Success message: "PRD reviewed at {path}"
- Summary of changes made
