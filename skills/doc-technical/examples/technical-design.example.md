# URL Shortener Service — Technical Design

## Overview

The URL Shortener Service converts arbitrarily long URLs into compact short codes (e.g., `https://sho.rt/aB3x9`) and redirects visitors to the original destination. It is designed for internal marketing and analytics teams who need shareable, trackable links at a scale of roughly 10 million redirects per day. The service provides a public redirect API and a private management API for creating, updating, and expiring links.

## Architecture

The system is composed of three runtime layers: an API gateway, a stateless application service, and a persistence tier with an in-process cache.

```
Client Browser / API Consumer
        │
        ▼
  ┌─────────────┐
  │ API Gateway │   — TLS termination, rate limiting, auth forwarding
  └──────┬──────┘
         │
         ▼
  ┌──────────────────┐
  │  App Service     │   — short-code generation, redirect resolution, CRUD
  │  (Node.js / TS)  │
  └──────┬───────────┘
         │
    ┌────┴──────────────────────┐
    ▼                           ▼
┌──────────┐            ┌──────────────┐
│  Redis   │            │  PostgreSQL  │
│  (cache) │            │  (primary    │
│          │◄──populate─│   data store)│
└──────────┘            └──────────────┘
```

The gateway handles rate limiting so the app service can remain stateless and horizontally scalable. Redis holds a read-through cache of the 1 million most-accessed short codes, keeping redirect latency below 10 ms for hot paths.

## Components & Responsibilities

| Component | Responsibility | Key file(s) |
|---|---|---|
| **API Gateway** | TLS termination, per-IP rate limiting (BR-03), JWT validation for management endpoints, request routing | Infrastructure config (`nginx/nginx.conf`) |
| **LinkController** | Validates incoming HTTP requests, enforces input constraints, delegates to LinkService, formats responses | `src/controllers/link.controller.ts` |
| **LinkService** | Orchestrates short-code creation (calls Encoder), cache writes, database writes, redirect lookups, expiry enforcement | `src/services/link.service.ts` |
| **Encoder** | Converts auto-incremented database IDs to base62 short codes; inverse decode for audit use | `src/lib/encoder.ts` |
| **LinkRepository** | TypeORM repository; owns all database reads/writes for the `links` table; never called from outside LinkService | `src/repositories/link.repository.ts` |
| **CacheClient** | Thin wrapper around `ioredis`; exposes `get`, `set`, and `invalidate` typed to the `CachedLink` shape | `src/lib/cache-client.ts` |
| **ClickTracker** | Publishes a lightweight click event to an in-process queue; a background worker flushes counts to PostgreSQL in batches of 500 | `src/workers/click-tracker.ts` |

**Not owned by this service:** user authentication (delegated to the gateway), URL preview rendering (a separate preview microservice), and analytics dashboards (read directly from the `click_events` table by a BI service).

## Data Flow

### Short code creation (management API)

1. Authenticated client POSTs `{ url, alias?, expiresAt? }` to `POST /api/v1/links`.
2. `LinkController` validates the URL format and checks that `alias` (if supplied) contains only `[a-zA-Z0-9_-]` and is ≤30 characters.
3. `LinkService` calls `LinkRepository.insert(url, alias, expiresAt)`. The database auto-increments the row ID.
4. If no `alias` was supplied, `Encoder.encode(rowId)` produces a base62 short code (4–7 characters). The code is written back to the row.
5. `CacheClient.set(shortCode, { url, expiresAt })` with TTL equal to the link's remaining lifetime (default: no TTL if no expiry).
6. The controller returns `201 Created` with `{ shortCode, shortUrl, expiresAt }`.

### Redirect (public API)

1. Browser GETs `/:shortCode`.
2. `LinkService.resolve(shortCode)` checks `CacheClient.get(shortCode)` first.
3. **Cache hit:** check `expiresAt`. If expired, return 410 Gone; otherwise return the URL and asynchronously increment the counter queue.
4. **Cache miss:** query `LinkRepository.findByCode(shortCode)`. If not found → 404. If found → populate cache, then proceed as hit.
5. Controller issues `301 Moved Permanently` for permanent links; `302 Found` for links with an expiry date (prevents browser caching of soon-to-expire links).
6. `ClickTracker.record(shortCode, timestamp, referrer, userAgent)` is called after the response is flushed — the redirect is never blocked by tracking.

## Dependencies

| Dependency | Type | Purpose |
|---|---|---|
| **PostgreSQL 15** | External data store | Durable storage of links, aliases, expiry dates, and click counts |
| **Redis 7** | External cache | Sub-10 ms read path for redirect resolution; TTL-based expiry of cached entries |
| **ioredis** | Library | Typed Redis client with automatic reconnection and cluster support |
| **TypeORM** | Library | ORM for the `links` and `click_events` tables; used only by `LinkRepository` |
| **class-validator** | Library | Decorator-based DTO validation in `LinkController` |
| **API Gateway (nginx)** | Internal upstream | Rate limiting (see BR-03); JWT header forwarding for management routes |
| **Auth Service** | Internal dependency | Issues JWTs validated by the gateway; this service does not call it directly |
| **Preview Service** | Internal downstream | Reads `links.url` to generate Open Graph previews; this service does not call it |

## Key Decisions & Trade-offs

**Base62 counter encoding over random UUIDs.** Short codes are derived from the auto-incremented database row ID encoded in base62. This guarantees global uniqueness without a separate uniqueness check and produces short, predictable-length codes (a 4-character code handles up to 14.7 million links). The trade-off is that codes are enumerable: a bad actor can iterate codes to discover all active links. Mitigation: the redirect endpoint does not expose the target URL in any header before the redirect fires, and high-value links can use custom aliases that do not reveal the counter position.

**Read-through cache in Redis, not a CDN.** A CDN would give lower redirect latency globally but would serve stale 301 responses for minutes after a link is disabled or expired. Redis allows instant invalidation (`CacheClient.invalidate(shortCode)`) when an operator disables a link through the management API. The accepted cost is that cache serving is single-region; a global CDN layer may be added in a future phase for read-only, non-expiring links.

**Asynchronous click counting.** Counting clicks on the critical redirect path would add a synchronous database write to every request. Instead, events are queued in-process and flushed in batches. This means click counts may be up to 10 seconds stale. Analytics consumers are explicitly informed of this lag; it is acceptable given that dashboards refresh at 60-second intervals.

**302 for links with expiry, 301 for permanent links.** Browsers cache 301 responses indefinitely. Using 302 for expiring links ensures that after a link expires, the browser fetches the redirect target fresh and receives the 410 Gone response rather than serving a stale destination from its cache.

## Risks

- **Counter exhaustion:** At 100 million links, 5-character base62 codes are still available (62^5 ≈ 916 million). No action needed in the short term; `Encoder` can be updated to use 6-character codes by bumping a constant when the table approaches 800 million rows.
- **Redis unavailability:** If Redis is unreachable, `LinkService.resolve` falls back to PostgreSQL directly. Redirect latency degrades to ~50 ms (from ~5 ms) but correctness is maintained. Management operations are unaffected.
- **Batch click flush loss:** If the process crashes while the in-memory click queue is non-empty, up to 500 click events can be lost. This is a known, accepted trade-off given the analytics-only nature of the data. A future improvement is to persist the queue to Redis before process shutdown.
- **Alias squatting:** Any authenticated user can reserve a custom alias. There is no namespace isolation between teams. A centralised alias registry (outside this service's scope) is planned for a later phase.

## References

- ADR: Use base62 counter encoding for short codes — `skills/doc-technical/examples/adr.example.md`
- Business Rules register — `skills/doc-functional/examples/business-rules.example.md`
- Functional Specification — `skills/doc-functional/examples/functional-spec.example.md`
- RFC 7231 §6.4.2 (301 Moved Permanently) and §6.4.3 (302 Found)
