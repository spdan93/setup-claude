---
name: checkpoint-validator
description: Validates artifacts and presents approval gates between phases
---

# Checkpoint Validator

## Purpose
Validate phase outputs and present structured approval gates to user before advancing pipeline.

## Triggers
- Called after each agent completes its phase
- Before advancing to next phase

## Inputs
- Phase name (e.g., "PRD", "Plan", "Issues")
- Artifact path (file to validate)
- Next phase name

## Logic
1. **Validate artifact exists**:
   - Check file exists at expected path
   - If missing → Return fail status

2. **Parse artifact** (basic validation):
   - For PRD/Plan: Check YAML frontmatter is valid
   - For manifest: Check JSON is parseable
   - Extract key metadata (version, status, etc.)

3. **Build checklist**:
   ```
   ✓ Artifact created at {path}
   ✓ Format is valid (YAML/JSON parsed)
   ⚠ Review required: [human validation items]
   ```

4. **Format checkpoint gate**:
   ```
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   🚦 CHECKPOINT: {Phase Name}
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   Artifact generated: {path}

   Validation Checklist:
     ✓ [automated checks]
     ⚠ [manual review items]

   Next phase: {next_phase}

   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Approve and advance? (yes/no/edit)
     - yes: Advance to next phase
     - no: Cancel pipeline
     - edit: Allow editing the artifact before advancing
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ```

5. **Parse user response**:
   - Approval keywords: yes, y, sim, s, approve, aprovar, continue, continuar
   - Rejection keywords: no, n, não, nao, cancel, cancelar, abort, abortar
   - Edit keywords: edit, editar, revise, revisar

## Outputs
- Formatted checkpoint message (displayed to user)
- Validation status (pass/fail/warn)
- User decision (approve/reject/edit)

## Rules
- **MUST**: Check artifact exists before presenting checkpoint
- **MUST**: Parse YAML/JSON to validate format
- **MUST**: Use the exact gate format shown above for gate presentation
- **MUST**: Accept all approval keywords listed above (multilingual)
- **NEVER**: Auto-approve (always wait for user input)
- **NEVER**: Modify artifacts (validation only)
- **NEVER**: Skip validation checks

## Validation by Phase
**PRD**:
- [ ] File exists in the PRDs directory
- [ ] YAML frontmatter valid (title, status, version, dates, author)
- [ ] Has section 1 (Context)
- [ ] Has section 6 (Next Steps)

**Plan**:
- [ ] File exists in the plans directory
- [ ] YAML frontmatter valid (prd_source, versions, phases, estimated_issues)
- [ ] Has Executive Summary (check word count ≤180)
- [ ] Has at least one phase with tasks
- [ ] All tasks have UUID format `task-X-Y-zzzzz`

**Issues/Manifest** (only validated if an issue tracker is configured):
- [ ] Manifest file exists
- [ ] JSON is valid
- [ ] Has pipeline_id, sources, phases
- [ ] All tasks have `tracker_id` populated
- [ ] All UUIDs match Plan UUIDs
