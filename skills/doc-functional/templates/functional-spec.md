<!-- Comprehensive functional specification covering actors, capabilities, business rules, flows, and business-view acceptance criteria. -->

# [Feature / System Name]

## Purpose

> One paragraph. What business problem does this solve? Who benefits, and how? No technology or implementation detail.

## Actors

| Actor | Description | Type |
|---|---|---|
| [Actor name] | [Role and relevant context] | Human / System |

## Functional Capabilities

> State what each actor can do. Format: "[Actor] can [action] [object] [condition if any]."

- [Actor] can …
- [Actor] can …

## Business Rules

> Each rule gets a stable ID for cross-referencing. Add or remove rows as needed.

| Rule ID | Description | Condition | Outcome |
|---|---|---|---|
| BR-001 | [Short name] | When [condition] | Then [observable outcome] |
| BR-002 | | | |

## Functional Flows

### Happy Path: [Flow name]

1. [Actor] [action].
2. [System] [observable response].
3. …

### Alternate Path: [Condition triggering alternate]

> Reference the relevant rule (e.g., BR-001) when a rule governs the branch.

1. [Actor] [action].
2. [System] [observable response — cites BR-XXX if applicable].
3. …

### Exception: [Error or unavailability scenario]

1. …

## Edge Cases

| Scenario | Expected Outcome |
|---|---|
| [Boundary condition] | [What the user sees or what the system does] |

## Acceptance (business)

> Criteria a product owner can verify without reading code. Each item is a checkable statement.

- [ ] [Observable outcome that confirms the capability works]
- [ ] [Observable outcome for the main alternate path]
- [ ] [Observable outcome when a business rule is enforced]
