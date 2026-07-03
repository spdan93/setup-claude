<!-- Exemplo: referência de endpoints REST completamente preenchida para o Serviço de Encurtamento de URLs. Use como referência de profundidade e tom ao preencher o template rest-endpoints.md. -->

# Referência de API: Encurtador de URLs — Links

> **URL Base:** `https://api.sho.rt/v1`
> **Auth:** Bearer token obrigatório em todos os endpoints de gerenciamento. O endpoint de redirecionamento (`GET /{code}`) é público.

---

### POST /links

Cria um novo link curto. Retorna o short code gerado (ou customizado) e a URL curta completa. A URL de destino deve usar o scheme `http` ou `https` (BR-004). Se um `alias` customizado for fornecido, ele não pode já estar em uso (BR-002).

**Autenticação:** Bearer `<token>` — requer scope `links:write`

**Parâmetros de path:** nenhum

**Parâmetros de query:** nenhum

**Corpo da requisição** (`application/json`)**:**

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `destinationUrl` | string (URL) | sim | A URL longa para redirecionar. Deve usar `http` ou `https`. |
| `alias` | string | não | Short code customizado (ex.: `summer-sale`). 3–50 caracteres, `[a-zA-Z0-9_-]`. Deve ser globalmente único. |
| `expiresAt` | string (date-time) | não | Data e hora UTC no formato ISO 8601 após a qual o link para de redirecionar. Deve ser no futuro. |

```json
{
  "destinationUrl": "https://marketing.example.com/campaigns/summer-2026?utm_source=email",
  "alias": "summer-sale",
  "expiresAt": "2026-09-01T00:00:00Z"
}
```

**Resposta — 201 Created**

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

**Erros:**

| Status | Código | Quando |
|---|---|---|
| 400 | `VALIDATION_ERROR` | `destinationUrl` está ausente, malformado ou usa um scheme proibido (`ftp`, `javascript`, etc.); `expiresAt` está no passado; `alias` contém caracteres inválidos. |
| 401 | `UNAUTHORIZED` | Bearer token ausente ou expirado. |
| 403 | `FORBIDDEN` | Token não possui o scope `links:write`. |
| 422 | `ALIAS_TAKEN` | O `alias` fornecido já está em uso por outro link (ativo ou desativado). |
| 500 | `INTERNAL_ERROR` | Erro inesperado no servidor. |

---

### GET /{code}

Redireciona o chamador para a URL de destino associada ao short code. Este endpoint é público (sem autenticação necessária). Retorna `302 Found` em caso de sucesso. Se o link estiver expirado (BR-001), desativado (BR-005) ou inexistente, retorna uma resposta de não-redirecionamento adequada.

**Autenticação:** nenhuma

**Parâmetros de path:**

| Nome | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `code` | string | sim | O short code ou alias customizado (ex.: `summer-sale`, `aB3x9`). |

**Parâmetros de query:** nenhum

**Corpo da requisição:** nenhum

**Resposta — 302 Found**

Corpo vazio. O header `Location` contém a URL de destino.

```
HTTP/1.1 302 Found
Location: https://marketing.example.com/campaigns/summer-2026?utm_source=email
```

**Erros:**

| Status | Código | Quando |
|---|---|---|
| 404 | `LINK_NOT_FOUND` | Nenhum link com o `code` fornecido existe no sistema. |
| 410 | `LINK_EXPIRED` | O link existe, mas sua data `expiresAt` já passou (BR-001). |
| 410 | `LINK_UNAVAILABLE` | O link existe, mas foi desativado pelo Operador (BR-005). |
| 429 | `RATE_LIMITED` | O IP do chamador excedeu 60 requisições de redirecionamento em 60 segundos (BR-003). Inclui o header `Retry-After: 60`. |
| 500 | `INTERNAL_ERROR` | Erro inesperado no servidor. |

---

### GET /links

Retorna uma lista paginada de links curtos pertencentes ao Operador autenticado.

**Autenticação:** Bearer `<token>` — requer scope `links:read`

**Parâmetros de path:** nenhum

**Parâmetros de query:**

| Nome | Tipo | Obrigatório | Padrão | Descrição |
|---|---|---|---|---|
| `page` | integer | não | 1 | Número da página (base 1). |
| `limit` | integer | não | 20 | Itens por página. Máximo 100. |
| `active` | boolean | não | — | Filtrar por status ativo. Omita para retornar todos. |

**Corpo da requisição:** nenhum

**Resposta — 200 OK**

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

**Erros:**

| Status | Código | Quando |
|---|---|---|
| 401 | `UNAUTHORIZED` | Bearer token ausente ou expirado. |
| 403 | `FORBIDDEN` | Token não possui o scope `links:read`. |
| 500 | `INTERNAL_ERROR` | Erro inesperado no servidor. |

---

### GET /links/{id}

Retorna os detalhes completos de um único link curto pelo seu ID interno.

**Autenticação:** Bearer `<token>` — requer scope `links:read`

**Parâmetros de path:**

| Nome | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id` | string | sim | ID interno do link (ex.: `lnk_01j8kxzp3n`). |

**Parâmetros de query:** nenhum

**Corpo da requisição:** nenhum

**Resposta — 200 OK**

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

**Erros:**

| Status | Código | Quando |
|---|---|---|
| 401 | `UNAUTHORIZED` | Bearer token ausente ou expirado. |
| 403 | `FORBIDDEN` | Token não possui o scope `links:read`, ou o link pertence a outro Operador. |
| 404 | `LINK_NOT_FOUND` | Nenhum link com o `id` fornecido existe. |
| 500 | `INTERNAL_ERROR` | Erro inesperado no servidor. |

---

### PATCH /links/{id}

Atualiza parcialmente um link curto. Suporta alteração da URL de destino, data de expiração ou status ativo. O `shortCode` e o `alias` são imutáveis após a criação.

**Autenticação:** Bearer `<token>` — requer scope `links:write`

**Parâmetros de path:**

| Nome | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id` | string | sim | ID interno do link. |

**Parâmetros de query:** nenhum

**Corpo da requisição** (`application/json`)**:**

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `destinationUrl` | string (URL) | não | Nova URL de destino. Deve usar `http` ou `https`. |
| `expiresAt` | string (date-time) | não | Nova data e hora de expiração em UTC. Passe `null` para remover a expiração. |
| `active` | boolean | não | `true` para reativar, `false` para desativar. |

```json
{
  "destinationUrl": "https://marketing.example.com/campaigns/summer-2026-v2?utm_source=email",
  "active": true
}
```

**Resposta — 200 OK**

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

**Erros:**

| Status | Código | Quando |
|---|---|---|
| 400 | `VALIDATION_ERROR` | `destinationUrl` usa um scheme proibido; `expiresAt` está no passado. |
| 401 | `UNAUTHORIZED` | Bearer token ausente ou expirado. |
| 403 | `FORBIDDEN` | Token não possui o scope `links:write`, ou o link pertence a outro Operador. |
| 404 | `LINK_NOT_FOUND` | Nenhum link com o `id` fornecido existe. |
| 500 | `INTERNAL_ERROR` | Erro inesperado no servidor. |

---

### GET /links/{id}/stats

Retorna estatísticas de cliques de um único link curto.

**Autenticação:** Bearer `<token>` — requer scope `links:read`

**Parâmetros de path:**

| Nome | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id` | string | sim | ID interno do link. |

**Parâmetros de query:**

| Nome | Tipo | Obrigatório | Padrão | Descrição |
|---|---|---|---|---|
| `from` | string (date) | não | 30 dias atrás | Data de início (inclusiva) para agregação de cliques. Formato: `YYYY-MM-DD`. |
| `to` | string (date) | não | hoje | Data de fim (inclusiva). Formato: `YYYY-MM-DD`. |

**Corpo da requisição:** nenhum

**Resposta — 200 OK**

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

**Erros:**

| Status | Código | Quando |
|---|---|---|
| 400 | `VALIDATION_ERROR` | `from` ou `to` não é uma data válida; `from` é posterior a `to`. |
| 401 | `UNAUTHORIZED` | Bearer token ausente ou expirado. |
| 403 | `FORBIDDEN` | Token não possui o scope `links:read`, ou o link pertence a outro Operador. |
| 404 | `LINK_NOT_FOUND` | Nenhum link com o `id` fornecido existe. |
| 500 | `INTERNAL_ERROR` | Erro inesperado no servidor. |
