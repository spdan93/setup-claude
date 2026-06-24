# URL Shortener Service

## Purpose

Marketing teams and internal operators need a way to convert long, unwieldy URLs into short, shareable links that can be embedded in campaigns, emails, and social posts without breaking formatting. The service also needs to track how many times each link has been followed, so campaign owners can measure engagement without relying on third-party analytics tools. By centralising link creation and tracking in a single internal service, the organisation gains visibility into all shared links, can deactivate compromised or expired links immediately, and avoids dependence on external URL-shortening vendors.

## Actors

| Actor | Description | Type |
|---|---|---|
| Operator | Authenticated internal user (marketing team member, campaign manager) who creates, updates, and deactivates short links | Human |
| Visitor | Any person who follows a short link, typically via a browser; not authenticated | Human |
| Scheduler | An automated process that deactivates links whose expiry date has passed | System |

## Functional Capabilities

- Operator can create a short link by providing a destination URL and an optional expiry date.
- Operator can specify a custom alias for a short link in place of the system-generated code, provided the alias is not already taken.
- Operator can view a list of all short links they have created, including current click counts.
- Operator can deactivate a short link at any time, immediately preventing further redirects.
- Operator can reactivate a deactivated short link, restoring redirect behaviour.
- Operator can update the destination URL of an existing short link without changing its short code.
- Visitor can follow a short link and be redirected to the destination URL in a single step.
- Visitor receives a clear, human-readable error when a link does not exist, has been deactivated, or has expired.
- Scheduler can expire links automatically when their configured expiry date and time passes.

## Business Rules

| Rule ID | Description | Condition | Outcome |
|---|---|---|---|
| BR-001 | Link expiry | When a short link has an `expiresAt` date-time and that date-time has passed | The system refuses the redirect and presents the Visitor with a "Link expired" notice; the link is not automatically deleted |
| BR-002 | Custom alias uniqueness | When an Operator submits a custom alias that is identical to an existing active or deactivated alias | The system rejects the creation request and informs the Operator that the alias is already taken |
| BR-003 | Rate limiting on redirect | When a single IP address makes more than 60 redirect requests within any 60-second window | The system temporarily blocks further requests from that IP for 60 seconds and returns a "Too many requests" response |
| BR-004 | Destination URL must be reachable scheme | When the destination URL uses a scheme other than `http` or `https` (e.g., `javascript:`, `ftp://`) | The system rejects the creation request and informs the Operator that only http and https URLs are permitted |
| BR-005 | Deactivated link redirect refusal | When a Visitor follows a short link that an Operator has explicitly deactivated | The system refuses the redirect and presents the Visitor with a "Link unavailable" notice |
| BR-006 | Click count latency | When a Visitor follows a short link | The click count for that link is incremented within 30 seconds; it need not be synchronous with the redirect |

## Functional Flows

### Happy Path: Visitor follows an active short link

1. Visitor enters or clicks a short URL (e.g., `https://sho.rt/aB3x9`) in their browser.
2. The system looks up the short code `aB3x9`.
3. The system confirms the link is active and not expired (BR-001).
4. The system redirects the Visitor to the destination URL.
5. The Visitor's browser loads the destination page.
6. The system records a click event for the link (BR-006).

### Alternate Path: Operator creates a link with a custom alias

1. Operator submits a new link with destination URL `https://example.com/very/long/path` and alias `summer-sale`.
2. The system checks that `summer-sale` is not already in use (BR-002).
3. The alias is available, so the system creates the link with short code `summer-sale`.
4. The system confirms creation and displays the short URL `https://sho.rt/summer-sale` to the Operator.

### Alternate Path: Link has expired (BR-001)

1. Visitor follows a short URL.
2. The system looks up the short code and finds the link's expiry date has passed.
3. The system does not redirect the Visitor. Instead, it displays a "This link has expired" message.
4. The Visitor is not sent to any destination URL.

### Alternate Path: Custom alias already taken (BR-002)

1. Operator submits a new link with alias `summer-sale`.
2. The system checks and finds `summer-sale` is already in use by another link.
3. The system rejects the request and informs the Operator: "The alias 'summer-sale' is already taken. Please choose a different alias."
4. The Operator either chooses a new alias or proceeds without one (using the system-generated code).

### Exception: Short code does not exist

1. Visitor follows a short URL with a code that is not in the system.
2. The system cannot find a matching link.
3. The system displays a "Link not found" message. The Visitor is not redirected.

### Exception: Visitor is rate-limited (BR-003)

1. Visitor's IP address makes more than 60 redirect requests within 60 seconds.
2. The system blocks further redirect requests from that IP for 60 seconds and returns a "Too many requests" message.
3. After 60 seconds, the Visitor's requests are accepted again.

## Edge Cases

| Scenario | Expected Outcome |
|---|---|
| Visitor follows a link exactly at the moment it expires | The system treats the link as expired (the expiry check compares UTC timestamps; a link with `expiresAt = T` is expired at any time ≥ T) |
| Operator attempts to create a link with an `expiresAt` in the past | The system rejects the creation request and informs the Operator that the expiry date must be in the future |
| Operator updates the destination URL while a Visitor is mid-redirect | The redirect already in flight uses the destination URL that was cached at the time the request arrived; the new URL applies to subsequent requests |
| Operator deactivates a link then reactivates it | Click count is preserved; the link resumes accepting redirects with the same short code |
| Destination URL itself redirects (chain redirect) | The system stores and serves the original destination URL as supplied; it does not follow or flatten redirect chains at creation time |
| Two Operators simultaneously attempt to claim the same custom alias | The database unique constraint ensures only one succeeds; the other receives the alias-taken error (BR-002) |

## Acceptance (business)

- [ ] An Operator can create a short link by providing only a destination URL; the system returns a working short URL within 3 seconds.
- [ ] A Visitor who follows the short URL is redirected to the correct destination with no additional steps.
- [ ] An Operator can create a short link with a custom alias; the resulting short URL contains that alias verbatim.
- [ ] If an Operator tries to create a link with an alias that already exists, the system refuses and explains why without creating any link.
- [ ] After an Operator deactivates a link, the next Visitor who follows it sees a clear "Link unavailable" message instead of being redirected.
- [ ] After a link's expiry date passes, Visitors see a clear "Link expired" message instead of being redirected.
- [ ] The click count for a link increases by at least 1 within 30 seconds of a Visitor successfully following that link.
- [ ] A Visitor who attempts to follow a short code that does not exist sees a "Link not found" message.
