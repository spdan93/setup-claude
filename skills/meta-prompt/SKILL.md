---
name: meta-prompt
description: Generates structured prompts in English for cross-agent context transfer. Use whenever passing context between agents or commands requiring structured prompts.
---

# Meta-Prompt Generator

## Purpose

Transform any context (issues, docs, plans, artifacts) into a **standardized English prompt** for passing to another LLM/agent. This ensures consistent, complete context transfer across the orchestration pipeline.

## When to Use

**MANDATORY** in these scenarios:
- Before calling any agent from `/workflow`
- Before `developer` invokes `code-reviewer`
- Any time structured context needs to pass between agents

## Inputs

The meta-prompt accepts the following parameters:

| Parameter | Required | Description |
|-----------|----------|-------------|
| `task_type` | Yes | Type of task: `review`, `plan`, `implementation`, `issue`, `documentation`, `test` |
| `artifacts` | Yes | Paths or content snippets to include as context |
| `constraints` | No | Rules, limitations, or boundaries for the task |
| `expected_output` | Yes | What the receiving agent should produce |
| `acceptance_criteria` | No | Specific criteria to validate success |
| `additional_context` | No | Any extra information relevant to the task |

## Output Format

The generated prompt **MUST** follow this exact structure:

```markdown
## Objective

[Clear, single-sentence statement of what needs to be accomplished]

## Context Summary

[2-3 sentences summarizing the broader context and why this task matters]

## Input Artifacts

[List of artifacts with paths and brief descriptions]
- `path/to/file.md` - Description of what this file contains
- `path/to/another.ts` - Description of relevance

## Constraints

[Bulleted list of rules and limitations]
- Constraint 1
- Constraint 2

## Required Output Format

[Exact specification of what the output should look like]

## Step-by-step Instructions

1. First, do X
2. Then, do Y
3. Finally, do Z

## Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Non-goals

[Explicit list of what is OUT OF SCOPE]
- Do NOT do X
- Do NOT modify Y

## Questions (if info missing)

[Only include if critical information is missing]
- Question about unclear requirement?
```

## Rules

1. **Output ALWAYS in English** - Regardless of input language
2. **No invention** - Only use information explicitly provided in inputs
3. **Be specific** - Avoid vague instructions; include file paths, function names, exact criteria
4. **Include non-goals** - Explicitly state what should NOT be done to prevent scope creep
5. **Preserve technical details** - Include code snippets, IDs, and technical specs verbatim

## Usage Examples

### Example 1: Generating prompt for code-reviewer

**Input:**
```yaml
task_type: review
artifacts:
  - src/store/sessionStore.ts
  - src/store/sessionStore.test.ts
constraints:
  - Follow project patterns in CLAUDE.md
  - Only review changed files
expected_output: Code review with actionable feedback
acceptance_criteria:
  - No security vulnerabilities
  - Tests cover happy path and edge cases
```

**Generated Prompt:**
```markdown
## Objective

Review the sessionStore implementation and its tests for correctness, security, and adherence to project standards.

## Context Summary

The sessionStore manages state for the user session module. Recent changes need review before merge to ensure quality and consistency with existing patterns.

## Input Artifacts

- `src/store/sessionStore.ts` - Main store implementation
- `src/store/sessionStore.test.ts` - Unit tests for the store

## Constraints

- Follow patterns defined in CLAUDE.md
- Only review the files listed above
- Do not suggest changes to unrelated files

## Required Output Format

Structured review with:
1. Summary (1-2 sentences)
2. Issues found (with severity: critical/major/minor)
3. Suggestions for improvement
4. Approval status: APPROVED / CHANGES_REQUESTED

## Step-by-step Instructions

1. Read the implementation file completely
2. Verify business logic correctness
3. Check for security vulnerabilities (XSS, injection, etc.)
4. Review test coverage and assertions
5. Compare against CLAUDE.md patterns
6. Provide actionable feedback

## Acceptance Criteria

- [ ] No security vulnerabilities identified
- [ ] Tests cover happy path scenarios
- [ ] Tests cover edge cases and error states
- [ ] Code follows project conventions

## Non-goals

- Do NOT refactor code beyond the review scope
- Do NOT add new features
- Do NOT modify files outside the artifact list

## Questions (if info missing)

None - sufficient context provided.
```

### Example 2: Generating prompt for developer agent

**Input:**
```yaml
task_type: implementation
artifacts:
  - docs/plans/2026-01-28-feature-plan.md#task-1-1
  - Issue tracker ticket <ISSUE-ID>
constraints:
  - Use existing patterns from the reference controller/module
  - Must include unit tests
expected_output: Working implementation with tests
acceptance_criteria:
  - All tests pass
  - Type-checker/build passes without errors
  - Follows CLAUDE.md rules
```

**Generated Prompt:**
```markdown
## Objective

Implement Task 1.1 from the feature plan, creating the specified functionality with full test coverage.

## Context Summary

This task is part of a larger feature implementation. It establishes the foundation for subsequent tasks and must follow existing architectural patterns.

## Input Artifacts

- `docs/plans/2026-01-28-feature-plan.md#task-1-1` - Task specification with requirements
- Issue tracker ticket `<ISSUE-ID>` - Tracking issue with additional context (if a tracker is configured)

## Constraints

- Follow patterns from the reference controller/module as reference
- Must include unit tests for all new code
- Follow the project's language/strictness conventions (see CLAUDE.md)
- Follow CLAUDE.md project rules

## Required Output Format

1. Implementation files
2. Test files
3. Summary of changes made

## Step-by-step Instructions

1. Read the task specification from the plan
2. Analyze the reference controller/module for patterns
3. Implement the required functionality
4. Write unit tests covering:
   - Happy path
   - Edge cases
   - Error scenarios
5. Run tests to verify
6. Update the issue status in the tracker (if configured)

## Acceptance Criteria

- [ ] All unit tests pass
- [ ] Type-checker/build passes without errors
- [ ] Implementation follows the reference patterns
- [ ] Code adheres to CLAUDE.md rules
- [ ] Test coverage includes edge cases

## Non-goals

- Do NOT implement tasks beyond 1.1
- Do NOT refactor existing code unless necessary
- Do NOT add features not in the specification

## Questions (if info missing)

None - sufficient context provided.
```

## Integration Points

This skill is invoked by:
- `/workflow` command (before each agent call)
- `/meta-prompt` command (manual usage)
- `developer` agent (before calling code-reviewer)
- Any component needing structured context transfer

## Anti-patterns

**DO NOT:**
- Generate prompts without `task_type` and `artifacts`
- Include information not provided in inputs
- Output in any language other than English
- Skip the "Non-goals" section
- Use vague language like "improve" or "optimize" without specifics
