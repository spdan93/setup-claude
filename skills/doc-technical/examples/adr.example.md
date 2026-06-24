# ADR: Use Base62 Counter Encoding for Short Codes

## Status

Accepted

## Context

The URL Shortener Service needs to assign a unique short code to every link stored in the system. Short codes appear in public URLs, so they must be:

- Short enough to be practical (target ≤7 characters for the foreseeable future).
- Globally unique without requiring a distributed coordination step.
- URL-safe without percent-encoding.

The initial implementation target is 10 million new links per day with a single-region PostgreSQL primary. The database already auto-increments a `BIGINT` primary key for every inserted row.

Three properties were in tension:
1. **Brevity** — fewer characters are better for user-facing URLs.
2. **Uniqueness guarantee** — no two rows may map to the same short code.
3. **Predictability of enumeration** — codes that reveal insertion order expose the full link inventory to scraping.

The team accepted that property 3 could be partially mitigated at the application layer (see Consequences) rather than requiring a more complex generation scheme.

## Decision

We will encode the auto-incremented PostgreSQL row ID in base62 (`[0-9A-Za-z]`, 62 symbols) to produce short codes. The `Encoder` module (`src/lib/encoder.ts`) converts the integer to a base62 string using big-endian digit ordering; decoding is the exact inverse. Codes are stored in the `links.short_code` column after the row is inserted and the ID is known.

## Consequences

**Positive:**
- Uniqueness is guaranteed by the database primary key — no separate uniqueness check or retry loop is needed.
- Code length grows slowly and predictably: 4 characters handles ~14.7 M links, 5 characters ~916 M links. The constant controlling minimum code length can be bumped without a schema change.
- Encoding and decoding are O(log n) pure functions with no I/O; they are trivial to unit test.
- Decoding a short code to its row ID is useful for audit and support workflows without an additional index.

**Negative:**
- Codes are enumerable: an observer can iterate consecutive codes to discover all active links. High-value or sensitive links should use the custom alias feature (which accepts any `[a-zA-Z0-9_-]` string up to 30 characters) to avoid revealing the counter position.
- The scheme couples code generation to the primary key of a single database table. If the service ever shards across multiple databases, a coordination layer will be needed to avoid ID collision. This is noted as a future risk but is not in scope for the current architecture.

**Neutral:**
- The encoding alphabet (`0-9A-Za-z`) is intentionally case-sensitive. URLs on this service are case-sensitive; the redirect handler treats `aB3x` and `ab3x` as different codes.

## Alternatives Considered

| Alternative | Reason rejected |
|---|---|
| **Random UUID (128-bit), stored in full** | 32-character hexadecimal codes are too long for user-facing URLs; truncating to 8 characters produces ~1-in-4300 collision probability after 1 M links, requiring a collision-check retry loop. |
| **NanoID (random, URL-safe, 8 characters)** | Collision-free at our scale but still requires a database uniqueness check on every insert and a retry on the rare collision; adds latency on the write path and complexity in the repository layer. |
| **Hashids over the row ID** | Produces non-enumerable codes from integers, addressing the enumeration concern. Rejected because the Hashids library introduces a dependency for a pure encoding concern, the alphabet and salt must be kept stable forever (breaking change if leaked or rotated), and the team judged the enumeration risk as acceptable given the application-layer mitigations. |
| **Snowflake-style distributed ID** | Overkill for a single-region deployment. Adds an external coordination service or requires careful node-ID assignment. Revisit if the service shards. |
