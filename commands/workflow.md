---
name: workflow
description: Orchestrates complete pipeline from idea to implementation
allowed-tools: Read, Write, Skill, Task
model: sonnet
---

# Workflow - Pipeline Orchestrator

## Purpose
Execute the complete pipeline: PRD → Review → Plan → Execution (→ optional E2E) with checkpoints.

## Usage
```bash
/workflow                     # Start new pipeline from idea
/workflow --from=plan         # Resume from a specific phase
/workflow --yolo              # Skip checkpoints (auto-advance)
/workflow --verbose           # Show detailed output (debug mode)
```

## Arguments

| Arg | Required | Description |
|-----|----------|-------------|
| `idea` | No | Feature idea (asked interactively if not provided) |
| `--from` | No | Start from phase: prd \| review \| plan \| execution |
| `--yolo` | No | Skip checkpoints, auto-advance through pipeline |
| `--verbose` | No | Show detailed output instead of minimal status |

## Delegates To

Uses the **workflow-orchestrator** skill for phase logic and delegates to:

**Agents**:
- `prd-writer` (Phase 1)
- `prd-reviewer` (Phase 2)
- `plan-architect` (Phase 3)
- `developer` (Phase 4 - per task)

**Commands**:
- `/e2e` (Phase 5 - browser E2E validation for UI-visible features)

**Skills**:
- `workflow-orchestrator` - Phase transitions
- `checkpoint-validator` - Approval gates
- `meta-prompt` - **REQUIRED** before calling any agent (see Meta-Prompt Rule)

## Issue Tracker (optional, not included)

This pipeline does not create issues in any tracker. Tasks live in the Plan (and,
optionally, in a local `issues-manifest.json` with placeholder IDs), and the
`developer` agent executes them directly from the Plan.

If you later adopt a provider (GitHub Issues, Jira, Linear, etc.), plug an issue
creation step between Phase 3 (Plan) and Phase 4 (Execution): add a provider-specific
agent/command that turns Plan tasks into tracked issues, then have `developer` read
from the tracker. The architecture leaves this seam open intentionally.

## Meta-Prompt Rule

**CRITICAL**: Before invoking ANY agent, use the `meta-prompt` skill to generate the structured prompt.

```
For each agent call:
1. Gather context (artifacts, constraints, expected output)
2. Invoke Skill("meta-prompt") with task_type and artifacts
3. Use the generated prompt as input to Task(subagent_type=..., prompt=generated_prompt)
```

This ensures consistent, complete context transfer between pipeline phases.

## Process

### Phase 1: PRD Creation
1. Ask user for feature idea (if not provided)
2. **Use meta-prompt** to generate prompt:
   - task_type: "documentation"
   - artifacts: [user idea, project CLAUDE.md context]
   - expected_output: "PRD document following the PRD template"
3. Invoke `Task(subagent_type="prd-writer", prompt=generated_prompt)`
4. Agent returns PRD path
5. Run `Skill("checkpoint-validator", phase="PRD", artifact=prd_path)`
6. If approved → Advance to Phase 2

### Phase 2: PRD Review
1. **Use meta-prompt** to generate prompt:
   - task_type: "review"
   - artifacts: [prd_path, PRD template reference]
   - expected_output: "Refined PRD with actionable feedback"
2. Invoke `Task(subagent_type="prd-reviewer", prompt=generated_prompt)`
3. Agent returns refined PRD
4. Run `Skill("checkpoint-validator", phase="Review", artifact=prd_path)`
5. If approved → Advance to Phase 3

### Phase 3: Implementation Plan
1. **Use meta-prompt** to generate prompt:
   - task_type: "plan"
   - artifacts: [prd_path, Implementation Plan template reference]
   - expected_output: "Implementation Plan with phases, tasks, and TC-* test cases"
2. Invoke `Task(subagent_type="plan-architect", prompt=generated_prompt)`
3. Agent returns Plan path
4. Run `Skill("checkpoint-validator", phase="Plan", artifact=plan_path)`
5. If approved → Advance to Phase 4

### Phase 4: Execution
1. Show message: "Tasks ready. Developer agents can pick up tasks directly from the Plan."
2. User can manually trigger a developer per task OR use automation
3. After implementation finishes, advance to Phase 5 if the feature has a
   browser-visible surface (any UI). For pure backend/library work, skip to commit.

### Phase 5: E2E Validation (optional, only for browser-visible features)
1. Ask user: "Does this feature have UI/visual flow that warrants E2E validation? (yes/no)"
2. If **yes**:
   - Show prerequisites checklist:
     - Is the target dev server running?
     - For authenticated surfaces: is the login session set up manually?
   - Confirm with user before continuing.
   - Invoke `/e2e <target> <feature-slug> --final`
   - `/e2e` interactively collects scenarios, drives the browser across
     desktop + mobile viewports, and generates an evidence report in
     `docs/test-evidence/{feature}-{timestamp}.md`.
   - Run `Skill("checkpoint-validator", phase="E2E", artifact=evidence_path)`
   - If approved → advance to commit
   - If failed → user decides: fix and re-run, or accept partial coverage with
     justification documented in the evidence file
3. If **no**: skip directly to commit/ship.
4. Commit the evidence file together with the feature code via `/commit` or `/ship`.

## Rules

**MUST**:
- Use the `workflow-orchestrator` skill to manage state
- Run `checkpoint-validator` after each phase (unless --yolo)
- Save pipeline state after each transition
- Respect user decisions (yes/no/edit) at each gate
- Create pipeline directory: `.claude/orchestrator/pipelines/{pipeline_id}/`

**NEVER**:
- Skip checkpoints without --yolo flag
- Auto-advance after rejection (no)
- Modify artifacts directly (agents do that)
- Continue if an agent fails critically

## YOLO Mode

When `--yolo` flag is set:
- Skip checkpoint-validator calls
- Auto-advance through all phases
- Still respect agent failures (pipeline stops on error)
- Log all actions for audit

## State Management

Pipeline state saved at: `.claude/orchestrator/pipelines/{pipeline_id}/pipeline-state.json`

Updates after each phase with:
- Current phase number
- Completed phases array
- Artifact paths
- Timestamps

## Output Mode

**Default: Quiet mode** - Minimal output to save tokens.

### Quiet Mode (default)
Output only:
- Phase transitions: `[Phase 2/4] PRD Review`
- Status updates: `✓ PRD created: docs/prds/2026_02_01-feature.md`
- Checkpoints: `Approve PRD? [yes/no/edit]`
- Errors: `✗ Error: agent failed`

**Example quiet output**:
```
[Phase 1/4] PRD Creation
✓ PRD created: docs/prds/2026_02_01-notifications.md

Approve PRD? [yes/no/edit]: yes

[Phase 2/4] PRD Review
✓ PRD refined

Approve? [yes/no/edit]: yes

[Phase 3/4] Implementation Plan
✓ Plan created: docs/plans/2026_02_01-notifications-plan.md
✓ 8 tasks defined

Approve? [yes/no/edit]: yes

[Phase 4/4] Execution
✓ Tasks ready — developer agents can pick them up from the Plan.

Pipeline complete.
```

### Verbose Mode (`--verbose`)
Output includes:
- All quiet mode output
- Agent invocation details
- Meta-prompt content
- File paths being read/written
- Timing information

**When to use**:
- First time running pipeline
- Debugging failures
- Understanding what agents are doing

### Implementation Rules

When executing the workflow:

**Quiet mode** (no `--verbose`):
```
- Use concise status messages
- Don't echo file contents
- Don't show agent prompts
- Don't show intermediate steps
- Only show: phase, status, checkpoint, errors
```

**Verbose mode** (`--verbose`):
```
- Show everything
- Echo meta-prompt content
- Show agent responses
- Show file paths and operations
- Include timing: "[Phase 2 completed in 45s]"
```
