<!-- Example: fully-filled test plan for the URL Shortener Service. Use this as a depth/tone reference when filling the test-plan.md template. -->

# Test Plan: URL Shortener — Core Link Lifecycle

**Date:** 2026-06-23
**Author:** QA Lead
**Status:** Approved

---

## Scope

- **Feature / flow under test:** End-to-end link lifecycle — create, redirect, deactivate, reactivate, and expiry; click-count tracking; rate limiting on redirects; custom alias uniqueness (BR-001 through BR-006).
- **Target environments:** Staging (`https://staging.sho.rt`) — PostgreSQL backend, Redis rate-limit store.
- **Related Implementation Plan:** `docs/plans/url-shortener-core.md`

---

## Preconditions / Test Data

| # | Precondition | Notes |
|---|---|---|
| 1 | Staging environment is running and reachable at `https://staging.sho.rt` | Verified by `GET /health` returning `200 OK` |
| 2 | At least two Operator accounts exist: `op-alice@example.com` (admin) and `op-bob@example.com` (standard) | Created via seed script `scripts/seed-test-users.sh` |
| 3 | A valid Bearer token is obtained for `op-alice` via `POST /auth/token` | Token stored in env var `TEST_ALICE_TOKEN` |
| 4 | The short code `existing-alias` already exists in the database, owned by `op-bob` | Seeded by `scripts/seed-test-links.sh` |
| 5 | A link with `expiresAt` set to 2026-01-01T00:00:00Z exists with code `exp-link-01` | Seeded; its expiry is well in the past at test time |
| 6 | Redis rate-limit counters for all test IPs are flushed before the rate-limit scenario | Run `redis-cli FLUSHDB` against the staging Redis instance |

---

## Test Scenarios

| # | Scenario | Description |
|---|---|---|
| S-01 | Happy path — create and redirect | Operator creates a short link; Visitor follows it and reaches the destination. |
| S-02 | Custom alias — available | Operator provides a unique custom alias; system creates the link with that alias. |
| S-03 | Custom alias — already taken | Operator provides an alias that already exists; system rejects with BR-002 error. |
| S-04 | Link expiry | Visitor follows an expired link; system refuses redirect and shows expiry notice (BR-001). |
| S-05 | Deactivate and reactivate | Operator deactivates a link; Visitor is blocked; Operator reactivates; Visitor is redirected again. |
| S-06 | Rate limiting on redirect | Single IP makes 61 redirect requests in 60 s; request 61 is blocked with 429 (BR-003). |
| S-07 | Invalid destination URL scheme | Operator attempts to create a link with a `javascript:` destination; system rejects (BR-004). |
| S-08 | Click-count tracking | Click count increments within 30 s of a successful redirect (BR-006). |
| S-09 | Non-existent short code | Visitor follows a code not in the system; system returns "Link not found". |

---

## Test Cases

| Case ID | Linked TC | Steps | Expected Result | Priority |
|---|---|---|---|---|
| TC-S01-01 | TC-1.1-01 | 1. `POST /links` with `{"destinationUrl":"https://example.com"}` and valid Bearer token. <br> 2. Note the `shortCode` in the `201` response. <br> 3. `GET /{shortCode}` without a Bearer token (browser-style). | Step 1 returns `201 Created` with `shortCode` and `shortUrl`. Step 3 returns `302 Found` with `Location: https://example.com`. | P1 |
| TC-S01-02 | TC-1.1-02 | 1. `POST /links` with `{"destinationUrl":"https://example.com"}`. <br> 2. Note the `id` from the `201` response. <br> 3. `GET /links/{id}/stats` with valid Bearer token. | Stats response contains `{"clicks": 0, ...}` immediately after creation. | P2 |
| TC-S02-01 | TC-1.2-01 | 1. `POST /links` with `{"destinationUrl":"https://example.com","alias":"summer-sale"}`. <br> 2. `GET /summer-sale` without a token. | Step 1 returns `201 Created` with `shortCode: "summer-sale"`. Step 2 returns `302 Found` with `Location: https://example.com`. | P1 |
| TC-S03-01 | TC-1.2-02 | 1. `POST /links` with `{"destinationUrl":"https://other.example.com","alias":"existing-alias"}`. | Returns `422 Unprocessable Entity` with `{"code":"ALIAS_TAKEN","message":"The alias 'existing-alias' is already taken."}`. No new link is created. | P1 |
| TC-S04-01 | TC-1.3-01 | 1. `GET /exp-link-01` without a token. | Returns `410 Gone` with body `{"code":"LINK_EXPIRED","message":"This link has expired."}`. No `Location` header is present. | P1 |
| TC-S04-02 | TC-1.3-02 | 1. `POST /links` with `{"destinationUrl":"https://example.com","expiresAt":"2020-01-01T00:00:00Z"}`. | Returns `400 Bad Request` with `{"code":"VALIDATION_ERROR","message":"expiresAt must be a future date-time."}`. | P2 |
| TC-S05-01 | TC-1.4-01 | 1. `POST /links` → note `id` and `shortCode` from the `201` response. <br> 2. `PATCH /links/{id}` with `{"active": false}` (deactivate). <br> 3. `GET /{shortCode}` without a token. | Step 2 returns `200 OK` with `{"active":false}`. Step 3 returns `410 Gone` with `{"code":"LINK_UNAVAILABLE","message":"This link is unavailable."}`. | P1 |
| TC-S05-02 | TC-1.4-02 | 1. Following TC-S05-01. <br> 2. `PATCH /links/{id}` with `{"active": true}` (reactivate). <br> 3. `GET /{shortCode}` without a token. | Step 2 returns `200 OK` with `{"active":true}`. Step 3 returns `302 Found` with correct `Location`. Click count from before deactivation is preserved. | P1 |
| TC-S06-01 | TC-1.5-01 | 1. Send 60 `GET /{validCode}` requests from the same IP within 60 s. <br> 2. Send request 61 within the same window. | Requests 1–60 return `302 Found`. Request 61 returns `429 Too Many Requests` with `Retry-After: 60` header. | P1 |
| TC-S07-01 | TC-1.6-01 | 1. `POST /links` with `{"destinationUrl":"javascript:alert(1)"}`. | Returns `400 Bad Request` with `{"code":"VALIDATION_ERROR","message":"destinationUrl must use http or https scheme."}`. | P1 |
| TC-S07-02 | TC-1.6-02 | 1. `POST /links` with `{"destinationUrl":"ftp://files.example.com/report.pdf"}`. | Returns `400 Bad Request` with `{"code":"VALIDATION_ERROR","message":"destinationUrl must use http or https scheme."}`. | P2 |
| TC-S08-01 | TC-1.7-01 | 1. `GET /links/{code}/stats` → note `clicks` value. <br> 2. `GET /{code}` (follow the link). <br> 3. Wait 30 s. <br> 4. `GET /links/{code}/stats` again. | Click count in step 4 is exactly `clicks + 1`. | P1 |
| TC-S09-01 | TC-1.8-01 | 1. `GET /does-not-exist-xyz` without a token. | Returns `404 Not Found` with `{"code":"LINK_NOT_FOUND","message":"Link not found."}`. | P1 |
| TC-S09-02 | TC-1.8-02 | 1. `GET /` (root path with no code). | Returns `404 Not Found` or `400 Bad Request`; no unhandled exception or 500. | P3 |

---

## Out of Scope

- Performance and load testing (separate load-test plan required; Locust suite is pending).
- Auth0 / identity-provider UI flows — only the Bearer token obtained after login is exercised here.
- Visitor-facing front-end UI rendering beyond HTTP status codes and response bodies.
- Email-notification integrations for link-expiry alerts (not yet implemented).
- Browser compatibility and visual regression testing.

---

## Sign-off

| Role | Name | Date | Status |
|---|---|---|---|
| Author | QA Lead | 2026-06-23 | Approved |
| Reviewer | Engineering Lead | 2026-06-23 | Approved |
| Approver | Product Owner | 2026-06-23 | Approved |
