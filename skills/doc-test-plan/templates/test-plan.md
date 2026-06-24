<!-- Test plan template: structured test scenarios and cases with TC-* traceability. -->

# Test Plan: {Feature Name}

**Date:** YYYY-MM-DD
**Author:**
**Status:** Draft | Review | Approved

---

## Scope

<!-- What is being tested. One sentence per item. Link to spec, PRD, or Implementation Plan if available. -->

- Feature / flow under test:
- Target environments:
- Related Implementation Plan: `docs/plans/` _(link if applicable)_

---

## Preconditions / Test Data

<!-- System state that must exist before any test case can run. -->

| # | Precondition | Notes |
|---|---|---|
| 1 | | |

---

## Test Scenarios

<!-- Logical groups of related behaviour. Each scenario maps to one or more test cases below. -->

| # | Scenario | Description |
|---|---|---|
| S-01 | Happy path | Nominal flow with valid inputs |
| S-02 | Invalid input | Input validation and error states |
| S-03 | Edge cases | Boundary values and unusual but valid inputs |

---

## Test Cases

<!-- One row per atomic check. Case ID format: TC-{scenario}-{nn} (e.g., TC-S01-01).
     Linked TC: the [TC-N.M-NN] tag from the Implementation Plan, if any. Leave blank for exploratory cases.
     Priority: P1 = blocker, P2 = important, P3 = nice-to-have. -->

| Case ID | Linked TC | Steps | Expected Result | Priority |
|---|---|---|---|---|
| TC-S01-01 | | 1. … <br> 2. … <br> 3. … | | P1 |
| TC-S02-01 | | 1. … <br> 2. … | | P2 |
| TC-S03-01 | | 1. … | | P3 |

---

## Out of Scope

<!-- Explicit exclusions. Never leave this blank. -->

- Third-party integrations not owned by this team (e.g., external OAuth provider UI)
- Performance and load testing (separate plan required)
<!-- add further exclusions here -->

---

## Sign-off

| Role | Name | Date | Status |
|---|---|---|---|
| Author | | | Draft |
| Reviewer | | | Pending |
| Approver | | | Pending |
