---
name: develop
description: Execute Implementation Plan tasks in dependency order via the developer agent, with local progress tracking and resume
allowed-tools: Read, Write, Bash, Skill, Task, AskUserQuestion
model: sonnet
---

# Develop — Plan Execution Runner

## Purpose
Drive the **Execution** phase of the pipeline: read an Implementation Plan, run its tasks
through the `developer` agent in **dependency (DAG) order**, track progress locally so the
run can be **resumed**, and keep each task's diff clean for review. This is the command
that turns a Plan into staged/committed code.

It does NOT implement code itself — it orchestrates the `developer` agent (which implements,
tests, and runs the `code-reviewer` loop) one task at a time.

## Usage
```bash
/develop                              # implement the next unblocked task of the active Plan
/develop --task=task-2-1-abc          # implement a specific task (by UUID or ref like 2.1)
/develop --all                        # run the whole DAG until done or blocked
/develop --all --yolo                 # run the whole DAG unattended (no checkpoints); still never commits
/develop --plan=docs/plans/2026_02_01-x-plan.md   # choose the Plan explicitly
/develop --status                     # show progress only (done / pending / blocked / failed)
```

## Arguments

| Arg | Description |
|-----|-------------|
| `--plan` | Path to the Plan. Default: most recent in `docs/plans/`, or the active pipeline. |
| `--task` | A single task to run, by UUID (`task-2-1-abc`) or ref (`2.1`). |
| `--all` | Run every task, in dependency order, until done or blocked. |
| `--yolo` | Run the DAG unattended (no per-task checkpoint). **Still never commits** — changes are staged; you commit with `/commit`. |
| `--status` | Print the progress table and exit (no execution). |
| (none) | Run the **single next unblocked task** (status `pending`, all deps `done`). |

## Delegates To
- Agent: `developer` (per task) — implements, tests, runs the `code-reviewer` loop, stages.
- Skill: `meta-prompt` — **REQUIRED** to build the developer prompt for each task.
- Command: `/commit` — **you** run it to commit finished work. `/develop` never invokes it automatically.

## How it works

### 1. Resolve the Plan
- Use `--plan` if given; else pick the newest `docs/plans/*-plan.md` (or the active
  pipeline's plan from `.claude/orchestrator/pipelines/`). Extract `pipeline_id` from the
  filename (`YYYY_MM_DD-{pipeline_id}-plan.md`).

### 2. Parse the task DAG
- Read the Plan. For each task extract: **UUID** (from the task header `[task-N-M-xxxxx]`),
  **ref** (`N.M`), **title**, **`depends_on`** (array of UUIDs), and whether it has a
  "Test Cases (immutable)" section.
- Build the dependency graph. A task is **runnable** when its status is `pending` and every
  task in its `depends_on` has status `done`.

### 3. Load / init progress
- State file: `.claude/orchestrator/pipelines/{pipeline_id}/dev-status.json` (local,
  gitignored — ephemeral execution state, NOT a durable artifact).
- Schema:
  ```json
  {
    "plan": "docs/plans/2026_02_01-x-plan.md",
    "pipeline_id": "x",
    "updated": "ISO-8601",
    "tasks": {
      "task-1-1-abc": { "ref": "1.1", "status": "done",    "depends_on": [] },
      "task-1-2-def": { "ref": "1.2", "status": "pending", "depends_on": ["task-1-1-abc"] }
    }
  }
  ```
- Statuses: `pending` · `in_progress` · `done` · `failed` · `blocked`.
- On first run, seed every task as `pending`. On later runs, **reconcile**: add new tasks,
  keep existing statuses (this is what enables resume).

### 4. Select the work set
- `--status` → print the table, exit.
- `--task=X` → just X. If its deps aren't `done`, stop with "Blocked by {refs}".
- `--all` → repeatedly pick a runnable task until none remain.
- default → the single next runnable task. If none, report why (all done / blocked / failed).

### 5. Per-task flow (for each selected task)
1. Mark the task `in_progress`; save state.
2. **Build the prompt with `meta-prompt`**:
   - task_type: `implementation`
   - artifacts: [Plan excerpt = Executive Summary + this task + "Notes for Agents"; project CLAUDE.md]
   - constraints: [project CLAUDE.md rules; TC-* are immutable; validate 1:1 TC coverage]
   - acceptance_criteria: the task's criteria
3. **Invoke** `Task(subagent_type="developer", prompt=generated)`. The developer implements,
   generates tests from the TC-*, runs the `code-reviewer` resilience loop, and **stages**
   the changes (it does NOT commit).
4. Interpret the result:
   - **Success** (reviewer PASS/WARN, changes staged) → mark `done`.
   - **Escalation / failure** (reviewer FAIL after retries, or developer aborted) → mark
     `failed`; do **not** start any task that depends on it (mark dependents `blocked`).
5. **Checkpoint / commit** (see below).
6. Save state; continue (in `--all`) or finish.

### 6. Checkpoints (never auto-commit)
**Golden rule: `/develop` NEVER commits.** A commit happens only when *you* run `/commit`
(or `/ship`). The `developer` agent stages its work; `/develop` leaves it staged and stops
or continues — it never runs `git commit`, under any flag.

- **Single-task run** (default): implement one task, leave the changes **staged**, and stop.
  You review and run `/commit` when you want.
- **`--all` (checkpoints on)**: after each task, show the staged files and ask
  `continue / stop`. For a clean per-task history, run `/commit` yourself before continuing
  (recommended) — `/develop` will not do it for you.
- **`--all --yolo`**: run every task unattended (no checkpoints). Changes from all tasks
  accumulate **staged**; you commit at the end with `/commit` (or `/ship`). Trade-off: the
  per-task diffs are not individually committed unless you commit between runs.

### 7. Report
At the end, print:
```
Plan: docs/plans/2026_02_01-x-plan.md   (pipeline: x)
Done: 5/8   ·   Failed: 1   ·   Blocked: 1   ·   Pending: 1

✓ 1.1 Define data model         done
✓ 1.2 Implement service         done
✗ 2.1 Add API endpoint          failed  (reviewer FAIL after 3 attempts — escalated)
⊘ 2.2 Wire UI                    blocked (depends on 2.1)
…
Next: resolve 2.1, then re-run /develop --all
```

## Rules
**MUST**:
- Use the `meta-prompt` skill to build every developer prompt.
- Run tasks only when their `depends_on` are all `done` (respect the DAG).
- Persist progress to `dev-status.json` after every status change (enables resume).
- Treat "Test Cases (immutable)" as read-only; never alter a task's TC-*.
- Leave finished work **staged** for the user to commit; between tasks, pause so the user can run `/commit` for a clean history if they want.
- Stop a branch of the DAG whose dependency `failed` (mark dependents `blocked`).

**NEVER**:
- Implement code directly — always delegate to the `developer` agent.
- **Auto-commit — under ANY flag, including `--yolo`.** `/develop` never runs `git commit`; commits happen only when the user runs `/commit` or `/ship`.
- Start a task whose dependencies aren't `done`.
- Modify the Plan or its tasks (read-only source of truth).
- Continue running dependents after a dependency failed.

## Resume
Because progress lives in `dev-status.json`, re-running `/develop` (or `/develop --all`)
picks up exactly where it stopped: completed tasks are skipped, `failed`/`blocked` tasks are
reported, and the next runnable task proceeds. Use `--status` to inspect without running.

## Examples
```bash
# Start executing a freshly-approved plan, one task at a time with review of each
/develop --plan=docs/plans/2026_02_01-notifications-plan.md
git diff --staged        # review
/commit                  # commit task 1.1, then:
/develop                 # next unblocked task

# Autonomous run of the whole plan
/develop --all --yolo

# Check where things stand
/develop --status
```
