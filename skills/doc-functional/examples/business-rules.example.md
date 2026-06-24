# Business Rules: URL Shortener Service

> **Scope**: All rules that govern link creation, redirect behaviour, expiry, alias management, and traffic handling for the URL Shortener Service.
> **Owner**: Platform team (primary); Marketing team (business authority for expiry and alias policies).
> **Last reviewed**: 2026-06-23

## Rules

| Rule ID | Description | Condition | Outcome | Source |
|---|---|---|---|---|
| BR-001 | Link expiry | When a short link has a configured `expiresAt` timestamp and the current UTC time is greater than or equal to that timestamp | The system refuses the redirect and presents the Visitor with a human-readable "This link has expired" message; the link record is retained for audit purposes and is not automatically deleted | Product policy — initial requirements review, 2026-01 |
| BR-002 | Custom alias uniqueness | When an Operator submits a request to create a short link with a custom alias and that alias string already exists in the system (active or deactivated) | The system rejects the creation request with an explicit error message identifying the conflicting alias; no link is created | Platform design constraint — uniqueness enforced by database index |
| BR-003 | Redirect rate limiting per IP | When a single client IP address makes more than 60 redirect requests within any rolling 60-second window | The system returns a "Too Many Requests" response to that IP for the remainder of the 60-second window; legitimate redirect traffic is unaffected; the Operator who owns the targeted link is not notified unless the pattern persists for more than 5 minutes | Security policy — abuse prevention, 2026-01 |
| BR-004 | Permitted URL schemes | When an Operator submits a destination URL that uses a scheme other than `http` or `https` (examples: `javascript:`, `ftp://`, `data:`, `file://`) | The system rejects the creation request and informs the Operator that only `http` and `https` destination URLs are permitted | Security policy — prevents cross-site scripting and protocol-handler abuse, 2026-01 |
| BR-005 | Deactivated link redirect refusal | When a Visitor follows a short link that an Operator has explicitly marked as deactivated (regardless of whether the link has an expiry date) | The system refuses the redirect and presents the Visitor with a "Link unavailable" message; the click event is not recorded | Product policy — operators must be able to stop redirects immediately |
| BR-006 | Click count eventual consistency | When a Visitor successfully follows an active, non-expired short link | The system increments the click count for that link within 30 seconds of the redirect response being sent; the count increment may be asynchronous and is not guaranteed to be reflected in the Operator's view instantaneously | Engineering trade-off — async counting accepted to keep redirect latency below 10 ms; documented in technical design |
| BR-007 | Expiry date must be in the future | When an Operator submits a link creation or update request with an `expiresAt` value that is less than or equal to the current UTC time | The system rejects the request and informs the Operator that the expiry date must be a future timestamp | Product policy — prevents accidental creation of immediately-expired links, 2026-03 |
| BR-008 | Alias character restrictions | When an Operator submits a custom alias | The system accepts only characters matching `[a-zA-Z0-9_-]` and rejects any alias exceeding 30 characters; aliases failing either constraint cause the creation request to be rejected with a descriptive error | Platform design constraint — ensures URL-safety without percent-encoding |

> **Column guide**
> - **Rule ID**: stable identifier; never reuse a retired ID — mark retired rules ~~struck through~~ instead.
> - **Description**: a short name usable as a label in flows and acceptance criteria.
> - **Condition**: the exact trigger ("when the cart total exceeds $500", "when the user's account status is Suspended").
> - **Outcome**: what the system must do — expressed in observable, user-facing terms.
> - **Source**: the requirement, policy document, or authority that established this rule.

## Notes

- **BR-001 vs BR-005 interaction**: A link that is both deactivated and expired presents as "Link unavailable" (BR-005 takes precedence) because "unavailable" is the broader, operator-controlled state. If an Operator reactivates the link after the expiry date has also passed, the link immediately presents as "expired" (BR-001).
- **BR-003 threshold review pending**: The 60-requests-per-60-seconds threshold was set conservatively at launch. The platform team will review actual traffic patterns at the 3-month mark and may relax the limit for authenticated API consumers.
- **BR-006 tolerance window**: The 30-second window is a service-level commitment, not a hard technical limit. Monitoring alerts fire if the p99 flush latency exceeds 20 seconds.
- **Cross-reference**: BR-001, BR-002, BR-005 are all referenced in the Functional Specification flows (`skills/doc-functional/examples/functional-spec.example.md`).
