<!-- Structured register of business rules with conditions, outcomes, and authoritative sources. -->

# Business Rules: [Domain / Feature Name]

> **Scope**: [One sentence describing what system or feature these rules govern.]
> **Owner**: [Team or role responsible for maintaining this register.]
> **Last reviewed**: YYYY-MM-DD

## Rules

| Rule ID | Description | Condition | Outcome | Source |
|---|---|---|---|---|
| BR-001 | [Short, searchable name] | When [precise trigger condition] | Then [observable outcome] | [Ticket / policy / stakeholder] |
| BR-002 | | | | |
| BR-003 | | | | |

> **Column guide**
> - **Rule ID**: stable identifier; never reuse a retired ID — mark retired rules ~~struck through~~ instead.
> - **Description**: a short name usable as a label in flows and acceptance criteria.
> - **Condition**: the exact trigger ("when the cart total exceeds $500", "when the user's account status is Suspended").
> - **Outcome**: what the system must do — expressed in observable, user-facing terms.
> - **Source**: the requirement, policy document, or authority that established this rule.

## Notes

> Use this section for:
> - Rules under discussion or pending confirmation (tag with `<!-- TODO: confirm with [owner] -->`).
> - Deprecated rules (keep for audit trail; mark the row ~~struck through~~ and note the date retired).
> - Cross-references to related rule sets in other documents.
