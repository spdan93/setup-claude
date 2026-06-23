---
name: plan-create
description: Create Implementation Plan from approved PRD
---

# Plan Create

## Purpose
Standalone command to create Implementation Plan from an approved PRD.

## Usage
```bash
/plan-create                                   # Interactive - lists PRDs
/plan-create --prd=docs/prds/2026_01_27-feature.md
```

## Delegates To
- Agent: `plan-architect`

## Arguments

| Arg | Required | Description |
|-----|----------|-------------|
| `--prd` | No | Path to PRD file (prompted if not provided) |

## Process
1. If --prd not provided:
   - List PRDs in docs/prds/ (sorted by date, newest first)
   - Ask user to select one
2. Verify PRD file exists
3. Check PRD status (warn if not "approved")
4. Extract pipeline_id from PRD filename
5. Check if Plan already exists at target path
6. If exists → Ask user: `overwrite` / `version bump` / `cancel`
7. Invoke `Task(subagent_type="plan-architect", prompt="Create plan from PRD at {prd_path}")`
8. Agent returns Plan path
9. Return success message with path and task count

## Conflict Handling

If Plan file already exists:
- Show current Plan info (version, task count, date)
- Ask: `overwrite` / `version bump` / `cancel`
- If overwrite → Agent overwrites
- If version bump → Increment plan_version, mark old as outdated
- If cancel → Exit

## Output
- Plan file path
- Success message: "Implementation Plan created at {path}"
- Task count: "{N} tasks across {M} phases"
