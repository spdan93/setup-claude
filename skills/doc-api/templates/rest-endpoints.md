<!-- Human-readable Markdown reference for one or more REST API endpoints, grouped by resource. -->

# API Reference: {Resource or Module Name}

> **Base URL:** `https://api.example.com/v1`
> **Auth:** Bearer token required on all endpoints unless noted.

---

### GET /resources

Brief description of what this endpoint returns and who would call it.

**Authentication:** Bearer `<token>` — requires scope `resources:read`

**Path parameters:** none

**Query parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `page` | integer | no | 1 | Page number (1-based). |
| `limit` | integer | no | 20 | Items per page. |
| `filter` | string | no | — | Filter expression. |

**Request body:** none

**Response — 200 OK**

```json
{
  "data": [
    {
      "id": "123",
      "name": "Example resource",
      "createdAt": "2026-01-15T12:00:00Z"
    }
  ],
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 42
  }
}
```

**Errors:**

| Status | Code | When |
|---|---|---|
| 401 | `UNAUTHORIZED` | Missing or invalid Bearer token. |
| 403 | `FORBIDDEN` | Token lacks `resources:read` scope. |
| 500 | `INTERNAL_ERROR` | Unexpected server error. |

---

### POST /resources

Brief description of what this endpoint creates.

**Authentication:** Bearer `<token>` — requires scope `resources:write`

**Path parameters:** none

**Query parameters:** none

**Request body** (`application/json`)**:**

| Field | Type | Required | Description |
|---|---|---|---|
| `name` | string | yes | Human-readable name for the resource. |
| `description` | string | no | Optional longer description. |

```json
{
  "name": "My new resource",
  "description": "Optional description."
}
```

**Response — 201 Created**

```json
{
  "id": "124",
  "name": "My new resource",
  "description": "Optional description.",
  "createdAt": "2026-01-15T12:05:00Z"
}
```

**Errors:**

| Status | Code | When |
|---|---|---|
| 400 | `VALIDATION_ERROR` | Missing required field or invalid value. |
| 401 | `UNAUTHORIZED` | Missing or invalid Bearer token. |
| 403 | `FORBIDDEN` | Token lacks `resources:write` scope. |
| 422 | `UNPROCESSABLE` | Request is well-formed but semantically invalid. |
| 500 | `INTERNAL_ERROR` | Unexpected server error. |

---

### GET /resources/{id}

Brief description of what this endpoint retrieves.

**Authentication:** Bearer `<token>` — requires scope `resources:read`

**Path parameters:**

| Name | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Unique identifier of the resource. |

**Query parameters:** none

**Request body:** none

**Response — 200 OK**

```json
{
  "id": "123",
  "name": "Example resource",
  "description": "Optional description.",
  "createdAt": "2026-01-15T12:00:00Z",
  "updatedAt": "2026-01-16T09:30:00Z"
}
```

**Errors:**

| Status | Code | When |
|---|---|---|
| 401 | `UNAUTHORIZED` | Missing or invalid Bearer token. |
| 403 | `FORBIDDEN` | Token lacks `resources:read` scope. |
| 404 | `NOT_FOUND` | No resource with the given `id` exists. |
| 500 | `INTERNAL_ERROR` | Unexpected server error. |

---

### PUT /resources/{id}

Brief description of what this endpoint replaces or updates.

**Authentication:** Bearer `<token>` — requires scope `resources:write`

**Path parameters:**

| Name | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Unique identifier of the resource to update. |

**Query parameters:** none

**Request body** (`application/json`)**:**

| Field | Type | Required | Description |
|---|---|---|---|
| `name` | string | yes | New name for the resource. |
| `description` | string | no | New description (omit to clear). |

```json
{
  "name": "Updated resource name",
  "description": "Updated description."
}
```

**Response — 200 OK**

```json
{
  "id": "123",
  "name": "Updated resource name",
  "description": "Updated description.",
  "updatedAt": "2026-01-17T08:00:00Z"
}
```

**Errors:**

| Status | Code | When |
|---|---|---|
| 400 | `VALIDATION_ERROR` | Missing required field or invalid value. |
| 401 | `UNAUTHORIZED` | Missing or invalid Bearer token. |
| 403 | `FORBIDDEN` | Token lacks `resources:write` scope. |
| 404 | `NOT_FOUND` | No resource with the given `id` exists. |
| 500 | `INTERNAL_ERROR` | Unexpected server error. |

---

### DELETE /resources/{id}

Brief description of what this endpoint removes.

**Authentication:** Bearer `<token>` — requires scope `resources:delete`

**Path parameters:**

| Name | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Unique identifier of the resource to delete. |

**Query parameters:** none

**Request body:** none

**Response — 204 No Content**

Empty body.

**Errors:**

| Status | Code | When |
|---|---|---|
| 401 | `UNAUTHORIZED` | Missing or invalid Bearer token. |
| 403 | `FORBIDDEN` | Token lacks `resources:delete` scope. |
| 404 | `NOT_FOUND` | No resource with the given `id` exists. |
| 500 | `INTERNAL_ERROR` | Unexpected server error. |
