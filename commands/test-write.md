---
name: test-write
description: Generate automated tests from immutable TC-* test cases
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, AskUserQuestion
model: sonnet
---

# Test Write Command

## Purpose
Generate automated tests with the project's test runner that prove each TC-* test case from the "Test Cases (immutable)" section. Can be called by a developer agent or manually by the user.

## Usage
```bash
/test-write --issue=<ISSUE-ID>                            # From your issue tracker
/test-write --plan=docs/plans/xxx.md --task=task-1-2-abc  # From Plan task
/test-write --cases="[TC-1.1-01] Given X..."              # Direct input
```

## Inputs

| Arg | Required | Description |
|-----|----------|-------------|
| `--issue` | No* | Issue ID in your tracker (e.g. Linear/Jira/GitHub Issues) to extract test cases from |
| `--plan` | No* | Plan path + --task UUID to extract test cases |
| `--task` | No* | Task UUID (requires --plan) |
| `--cases` | No* | Direct TC-* cases as text |
| `--target` | No | Target directory for tests (auto-detected if not provided) |

*At least one source required (issue, plan+task, or cases)

## Process

### Step 1: Extract Test Cases
1. If `--issue` provided:
   - Fetch the issue from the configured tracker (optional integration — e.g. an MCP tool, CLI, or `gh issue view`; skip if no tracker is configured and ask the user to paste the cases instead)
   - Extract the "Test Cases (immutable)" section
   - Parse TC-* cases into a structured list
2. If `--plan` + `--task` provided:
   - Read Plan file
   - Find task by UUID
   - Extract the "Test Cases" section
3. If `--cases` provided:
   - Parse direct input into TC-* list

**Validation**: Fail if no TC-* cases found

### Step 2: Parse Test Cases
Parse each TC-* case into structured format:
```typescript
interface TestCase {
  id: string           // e.g., "TC-1.2-01"
  given: string        // Context/precondition
  when: string         // Action
  then: string         // Expected result
  raw: string          // Original text
}
```

### Step 3: Detect Test Environment
1. Identify target directory from:
   - `--target` argument
   - Issue/task labels (e.g. frontend/backend) if available
   - The location of the code under test
2. **Detect the project's test runner** — do not assume one. Inspect:
   - `package.json` scripts/devDependencies (e.g. Vitest, Jest, Mocha, Playwright, ...)
   - Other test config (`vitest.config.*`, `jest.config.*`, `pytest.ini`, `pyproject.toml`, `go.mod`, `Cargo.toml`, ...)
   - Choose the runner the target package already uses
3. Find existing test patterns:
   - Search for existing test files (e.g. `*.spec.*`, `*.test.*`, `test_*.py`, `*_test.go`) in or near the target
   - Read 1-2 examples to match naming, imports, and assertion style

### Step 4: Discover Implementation Context
1. If code already implemented:
   - Read staged/modified files from `git diff --staged --name-only`
   - Understand functions/components to test
2. If code not implemented yet:
   - Read task description for expected interfaces
   - Create test stubs that will fail until implementation exists

### Step 5: Generate Tests
For each TC-* case, generate a test that:
1. **Maps directly to the test case** (include the TC-* ID in the describe/test name)
2. **Follows project patterns** from discovered examples (runner, assertion style, file layout)
3. **Tests exactly what the case specifies** (no more, no less)

**Test Structure** (adapt syntax to the detected runner):
```typescript
// TC-1.2-01: Given X, when Y, then Z
describe('[TC-1.2-01] Feature description', () => {
  it('should Z when Y given X', async () => {
    // Given: X
    const context = setupContext()

    // When: Y
    const result = await performAction(context)

    // Then: Z
    expect(result).toBe(expectedValue)
  })
})
```

### Step 6: Write Test File
1. Determine the test file path following the project's convention:
   - Same directory as the implementation file, or the project's dedicated test directory
   - Name it per the existing pattern (e.g. `{implementation}.spec.ts`, `{implementation}.test.ts`, `test_{module}.py`)
2. If file exists:
   - Append new tests to existing file
   - Avoid duplicating existing TC-* tests
3. If file doesn't exist:
   - Create with proper imports and structure

### Step 7: Validate & Run
1. Run linting on the generated test file (if the project has a linter)
2. Run the tests using the project's own test command (from `package.json` scripts or the runner's CLI), scoped to the new file when possible
3. If tests fail:
   - If implementation exists → Report failure (code may be wrong)
   - If implementation doesn't exist → Expected (TDD mode)

### Step 8: Report
Return summary:
```markdown
## Test Generation Report

**Source**: {issue/plan/direct}
**Test Cases**: {count} TC-* cases processed
**Test File**: {path}
**Runner**: {detected runner}

### Generated Tests
| TC ID | Test Name | Status |
|-------|-----------|--------|
| TC-1.2-01 | should Z when Y given X | ✓ Generated |
| TC-1.2-02 | should error when invalid | ✓ Generated |

### Run Results
- Tests run: {count}
- Passed: {count}
- Failed: {count} (expected if TDD mode)
```

## Rules

**MUST**:
- Extract TC-* cases from specified source (issue, plan, or direct)
- Generate exactly one test per TC-* case (1:1 mapping)
- Include TC-* ID in test/describe name for traceability
- Use the project's detected test runner and existing patterns
- Use Given/When/Then structure matching the test case
- Run tests after generation to verify syntax

**NEVER**:
- Modify the "Test Cases (immutable)" section (read-only)
- Generate tests for scenarios not in the TC-* list
- Skip any TC-* case (must be 1:1)
- Generate duplicate tests for the same TC-*
- Add extra assertions beyond what the TC-* specifies

**Test-First (TDD) Mode**:
- If called before implementation exists, tests SHOULD fail
- This is expected and correct behavior
- Developer implements code to make tests pass

## Examples

### From Issue
```bash
/test-write --issue=<ISSUE-ID>
```
Extracts the "Test Cases (immutable)" section from the issue in your tracker.

### From Plan
```bash
/test-write --plan=docs/plans/2026_01_28-feature-plan.md --task=task-1-2-abc
```
Extracts test cases from a specific task in the Plan.

### Direct Input
```bash
/test-write --cases="[TC-1.1-01] Given an empty cart, when the user adds an item, then the cart total updates
[TC-1.1-02] Given an item in the cart, when the user removes it, then the cart becomes empty"
```

### TDD Mode (before implementation)
```bash
/test-write --issue=<ISSUE-ID>
# Generates tests that fail (no implementation yet)
# Developer then implements code to make tests pass
```

## Output Artifacts
- Test file at `{target}/{feature}.{spec|test}.{ext}` following project convention
- Generation report (returned as text)

## Integration with Developer Agent
When called from a developer agent:
1. Developer extracts TC-* cases from the issue/plan
2. Developer calls `/test-write --cases="..."` or `/test-write --issue=<ISSUE-ID>`
3. This command generates tests
4. Developer verifies tests run (pass or expected TDD failures)
5. Flow continues to code review (e.g. the `code-reviewer` subagent / `/code-review` skill)
