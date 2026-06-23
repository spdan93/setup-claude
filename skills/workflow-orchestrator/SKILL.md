---
name: workflow-orchestrator
description: Orchestrates phase transitions in the workflow pipeline
---

# Workflow Orchestrator

## Purpose
Lightweight orchestration logic for transitioning between pipeline phases and deciding next actions.

## Triggers
- Called by `/workflow` command at start and after each checkpoint
- Used to determine current phase and next action

## Inputs
- Current pipeline state (from `.claude/orchestrator/pipelines/{pipeline_id}/pipeline-state.json`)
- User approval decision (yes/no/edit from checkpoint)
- Optional: `--from` flag to start from specific phase

## Logic
1. **Read pipeline state** (if exists):
   - Extract current_phase, completed_phases, artifacts

2. **Determine next phase**:
   ```
   If no state exists → Start at phase 1 (PRD)
   If --from flag provided → Start at specified phase
   If user said "yes" → Advance to next phase
   If user said "no" → Abort pipeline
   If user said "edit" → Stay in current phase, allow edits
   ```

3. **Phase routing**:
   ```
   Phase 1: PRD → Invoke prd-writer agent
   Phase 2: Review → Invoke prd-reviewer agent
   Phase 3: Plan → Invoke plan-architect agent
   Phase 4: Execution → Developer agents pick up tasks from the Plan (manual or automated)
   (Optional) Issue Tracker → not included by default. If you adopt a provider
   (GitHub Issues, Jira, Linear, etc.), create issues from the Plan before execution.
   ```

4. **Update state**:
   - Save current phase
   - Record artifacts created (paths)
   - Update timestamp

5. **Return next action**:
   - Agent to invoke
   - Inputs required
   - Checkpoint message

## Outputs
- Next action instruction (which agent/command to call)
- Updated pipeline-state.json
- Checkpoint message for user approval

## Rules
- **MUST**: Save state after each phase transition
- **MUST**: Validate user approval before advancing
- **NEVER**: Skip checkpoints (unless --yolo flag)
- **NEVER**: Auto-advance without user confirmation
- **NEVER**: Modify artifacts directly (agents do that)

## State Format
```json
{
  "pipeline_id": "feature-name",
  "current_phase": 1-4,
  "status": "in_progress" | "completed" | "aborted",
  "completed_phases": [1, 2],
  "artifacts": {
    "prd": "docs/prds/2026_01_27-feature.md",
    "plan": "docs/plans/2026_01_28-feature-plan.md",
    "manifest": ".claude/orchestrator/pipelines/feature/issues-manifest.json"
  },
  "created": "ISO-8601",
  "updated": "ISO-8601"
}
```
