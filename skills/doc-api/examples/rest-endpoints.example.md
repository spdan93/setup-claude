<!-- Example: fully-filled REST endpoint reference for the URL Shortener Service. Use this as a depth/tone reference when filling the rest-endpoints.md template. -->

# API Reference: URL Shortener — Links

> **Base URL:** `https://api.sho.rt/v1`
> **Auth:** Bearer token required on all management endpoints. The redirect endpoint (`GET /{code}`) is public.

---

### POST /links

Creates a new short link. Returns the generated (or custom) short code and the fully-qualified short URL. The destination URL must use the `http` or `https` scheme (BR-004). If a custom `alias` is provided it must not already be in use (BR-002).

**Authentication:** Bearer `<token>` — requires scope `links:write`

**Path parameters:** none

**Query parameters:** none

**Request body** (`application/json`)**:**

| Field | Type | Required | Description |
|---|---|---|---|
| `destinationUrl` | string (URL) | yes | The long URL to redirect to. Must use `http` or `https`. |
| `alias` | string | no | Custom short code (e.g. `summer-sale`). 3–50 characters, `[a-zA-Z0-9_-]`. Must be globally unique. |
| `expiresAt` | string (date-time) | no | ISO 8601 UTC date-time after which the link stops redirecting. Must be in the future. |

```json
{
  "destinationUrl": "https://marketing.example.com/campaigns/summer-2026?utm_source=email",
  "alias": "summer-sale",
  "expiresAt": "2026-09-01T00:00:00Z"
}
```

**Response — 201 Created**

```json
{
  "id": "lnk_01j8kxzp3n",
  "shortCode": "summer-sale",
  "shortUrl": "https://sho.rt/summer-sale",
  "destinationUrl": "https://marketing.example.com/campaigns/summer-2026?utm_source=email",
  "active": true,
  "expiresAt": "2026-09-01T00:00:00Z",
  "createdAt": "2026-06-23T10:15:00Z"
}
```

**Errors:**

| Status | Code | When |
|---|---|---|
| 400 | `VALIDATION_ERROR` | `destinationUrl` is missing, malformed, or uses a forbidden scheme (`ftp`, `javascript`, etc.); `expiresAt` is in the past; `alias` contains invalid characters. |
| 401 | `UNAUTHORIZED` | Missing or expired Bearer token. |
| 403 | `FORBIDDEN` | Token lacks `links:write` scope. |
| 422 | `ALIAS_TAKEN` | The provided `alias` is already in use by another link (active or deactivated). |
| 500 | `INTERNAL_ERROR` | Unexpected server error. |

---

### GET /{code}

Redirects the caller to the destination URL associated with the short code. This endpoint is public (no authentication required). Returns `302 Found` on success. If the link is expired (BR-001), deactivated (BR-005), or unknown, returns an appropriate non-redirect response.

**Authentication:** none

**Path parameters:**

| Name | Type | Required | Description |
|---|---|---|---|
| `code` | string | yes | The short code or custom alias (e.g. `summer-sale`, `aB3x9`). |

**Query parameters:** none

**Request body:** none

**Response — 302 Found**

Empty body. The `Location` header contains the destination URL.

```
HTTP/1.1 302 Found
Location: https://marketing.example.com/campaigns/summer-2026?utm_source=email
```

**Errors:**

| Status | Code | When |
|---|---|---|
| 404 | `LINK_NOT_FOUND` | No link with the given `code` exists in the system. |
| 410 | `LINK_EXPIRED` | The link exists but its `expiresAt` date has passed (BR-001). |
| 410 | `LINK_UNAVAILABLE` | The link exists but has been deactivated by the Operator (BR-005). |
| 429 | `RATE_LIMITED` | The caller's IP has exceeded 60 redirect requests in 60 seconds (BR-003). Includes `Retry-After: 60` header. |
| 500 | `INTERNAL_ERROR` | Unexpected server error. |

---

### GET /links

Returns a paginated list of short links owned by the authenticated Operator.

**Authentication:** Bearer `<token>` — requires scope `links:read`

**Path parameters:** none

**Query parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `page` | integer | no | 1 | Page number (1-based). |
| `limit` | integer | no | 20 | Items per page. Maximum 100. |
| `active` | boolean | no | — | Filter by active status. Omit to return all. |

**Request body:** none

**Response — 200 OK**

```json
{
  "data": [
    {
      "id": "lnk_01j8kxzp3n",
      "shortCode": "summer-sale",
      "shortUrl": "https://sho.rt/summer-sale",
      "destinationUrl": "https://marketing.example.com/campaigns/summer-2026?utm_source=email",
      "active": true,
      "clicks": 142,
      "expiresAt": "2026-09-01T00:00:00Z",
      "createdAt": "2026-06-23T10:15:00Z"
    }
  ],
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 1
  }
}
```

**Errors:**

| Status | Code | When |
|---|---|---|
| 401 | `UNAUTHORIZED` | Missing or expired Bearer token. |
| 403 | `FORBIDDEN` | Token lacks `links:read` scope. |
| 500 | `INTERNAL_ERROR` | Unexpected server error. |

---

### GET /links/{id}

Returns the full details of a single short link by its internal ID.

**Authentication:** Bearer `<token>` — requires scope `links:read`

**Path parameters:**

| Name | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Internal link ID (e.g. `lnk_01j8kxzp3n`). |

**Query parameters:** none

**Request body:** none

**Response — 200 OK**

```json
{
  "id": "lnk_01j8kxzp3n",
  "shortCode": "summer-sale",
  "shortUrl": "https://sho.rt/summer-sale",
  "destinationUrl": "https://marketing.example.com/campaigns/summer-2026?utm_source=email",
  "active": true,
  "clicks": 142,
  "expiresAt": "2026-09-01T00:00:00Z",
  "createdAt": "2026-06-23T10:15:00Z",
  "updatedAt": "2026-06-23T14:00:00Z"
}
```

**Errors:**

| Status | Code | When |
|---|---|---|
| 401 | `UNAUTHORIZED` | Missing or expired Bearer token. |
| 403 | `FORBIDDEN` | Token lacks `links:read` scope, or the link belongs to another Operator. |
| 404 | `LINK_NOT_FOUND` | No link with the given `id` exists. |
| 500 | `INTERNAL_ERROR` | Unexpected server error. |

---

### PATCH /links/{id}

Partially updates a short link. Supports changing the destination URL, expiry date, or active status. The `shortCode` and `alias` are immutable after creation.

**Authentication:** Bearer `<token>` — requires scope `links:write`

**Path parameters:**

| Name | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Internal link ID. |

**Query parameters:** none

**Request body** (`application/json`)**:**

| Field | Type | Required | Description |
|---|---|---|---|
| `destinationUrl` | string (URL) | no | New destination URL. Must use `http` or `https`. |
| `expiresAt` | string (date-time) | no | New expiry date-time in UTC. Pass `null` to remove expiry. |
| `active` | boolean | no | `true` to reactivate, `false` to deactivate. |

```json
{
  "destinationUrl": "https://marketing.example.com/campaigns/summer-2026-v2?utm_source=email",
  "active": true
}
```

**Response — 200 OK**

```json
{
  "id": "lnk_01j8kxzp3n",
  "shortCode": "summer-sale",
  "shortUrl": "https://sho.rt/summer-sale",
  "destinationUrl": "https://marketing.example.com/campaigns/summer-2026-v2?utm_source=email",
  "active": true,
  "clicks": 142,
  "expiresAt": "2026-09-01T00:00:00Z",
  "updatedAt": "2026-06-23T15:30:00Z"
}
```

**Errors:**

| Status | Code | When |
|---|---|---|
| 400 | `VALIDATION_ERROR` | `destinationUrl` uses a forbidden scheme; `expiresAt` is in the past. |
| 401 | `UNAUTHORIZED` | Missing or expired Bearer token. |
| 403 | `FORBIDDEN` | Token lacks `links:write` scope, or the link belongs to another Operator. |
| 404 | `LINK_NOT_FOUND` | No link with the given `id` exists. |
| 500 | `INTERNAL_ERROR` | Unexpected server error. |

---

### GET /links/{id}/stats

Returns click statistics for a single short link.

**Authentication:** Bearer `<token>` — requires scope `links:read`

**Path parameters:**

| Name | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Internal link ID. |

**Query parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `from` | string (date) | no | 30 days ago | Start date (inclusive) for click aggregation. Format: `YYYY-MM-DD`. |
| `to` | string (date) | no | today | End date (inclusive). Format: `YYYY-MM-DD`. |

**Request body:** none

**Response — 200 OK**

```json
{
  "id": "lnk_01j8kxzp3n",
  "shortCode": "summer-sale",
  "totalClicks": 142,
  "clicksByDay": [
    { "date": "2026-06-21", "clicks": 38 },
    { "date": "2026-06-22", "clicks": 61 },
    { "date": "2026-06-23", "clicks": 43 }
  ]
}
```

**Errors:**

| Status | Code | When |
|---|---|---|
| 400 | `VALIDATION_ERROR` | `from` or `to` is not a valid date; `from` is after `to`. |
| 401 | `UNAUTHORIZED` | Missing or expired Bearer token. |
| 403 | `FORBIDDEN` | Token lacks `links:read` scope, or the link belongs to another Operator. |
| 404 | `LINK_NOT_FOUND` | No link with the given `id` exists. |
| 500 | `INTERNAL_ERROR` | Unexpected server error. |
