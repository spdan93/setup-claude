<!-- Exemplo: plano de testes completamente preenchido para o Serviço de Encurtamento de URLs. Use como referência de profundidade e tom ao preencher o template test-plan.md. -->

# Plano de Testes: Encurtador de URLs — Ciclo de Vida do Link

**Data:** 2026-06-23
**Autor:** QA Lead
**Status:** Aprovado

---

## Escopo

- **Funcionalidade / fluxo sob teste:** Ciclo de vida completo do link — criar, redirecionar, desativar, reativar e expirar; rastreamento de contagem de cliques; rate limiting em redirecionamentos; unicidade de alias customizado (BR-001 a BR-006).
- **Ambientes alvo:** Staging (`https://staging.sho.rt`) — backend PostgreSQL, Redis para controle de rate limit.
- **Plano de Implementação relacionado:** `docs/plans/url-shortener-core.md`

---

## Pré-condições / Dados de Teste

| # | Pré-condição | Observações |
|---|---|---|
| 1 | Ambiente de staging em execução e acessível em `https://staging.sho.rt` | Verificado por `GET /health` retornando `200 OK` |
| 2 | Pelo menos duas contas de Operador existem: `op-alice@example.com` (admin) e `op-bob@example.com` (padrão) | Criadas via script de seed `scripts/seed-test-users.sh` |
| 3 | Um Bearer token válido foi obtido para `op-alice` via `POST /auth/token` | Token armazenado na variável de ambiente `TEST_ALICE_TOKEN` |
| 4 | O short code `existing-alias` já existe no banco de dados, pertencente a `op-bob` | Inserido por `scripts/seed-test-links.sh` |
| 5 | Um link com `expiresAt` definido para 2026-01-01T00:00:00Z existe com o código `exp-link-01` | Inserido; sua expiração já passou no momento dos testes |
| 6 | Contadores de rate limit no Redis estão zerados para todos os IPs de teste antes do cenário de rate limit | Execute `redis-cli FLUSHDB` na instância Redis do staging |

---

## Cenários de Teste

| # | Cenário | Descrição |
|---|---|---|
| S-01 | Caminho feliz — criar e redirecionar | Operador cria um link curto; Visitante o acessa e chega ao destino. |
| S-02 | Alias customizado — disponível | Operador fornece um alias único; o sistema cria o link com esse alias. |
| S-03 | Alias customizado — já em uso | Operador fornece um alias que já existe; o sistema rejeita com erro BR-002. |
| S-04 | Expiração do link | Visitante acessa um link expirado; o sistema recusa o redirecionamento e exibe aviso de expiração (BR-001). |
| S-05 | Desativar e reativar | Operador desativa um link; Visitante é bloqueado; Operador reativa; Visitante é redirecionado novamente. |
| S-06 | Rate limiting no redirecionamento | Um único IP faz 61 requisições de redirecionamento em 60 s; a requisição 61 é bloqueada com 429 (BR-003). |
| S-07 | Scheme de URL de destino inválido | Operador tenta criar um link com destino `javascript:`; o sistema rejeita (BR-004). |
| S-08 | Rastreamento de contagem de cliques | A contagem de cliques incrementa em até 30 s após um redirecionamento bem-sucedido (BR-006). |
| S-09 | Short code inexistente | Visitante acessa um código não cadastrado no sistema; o sistema retorna "Link não encontrado". |

---

## Casos de Teste

| ID do Caso | TC vinculado | Passos | Resultado Esperado | Prioridade |
|---|---|---|---|---|
| TC-S01-01 | TC-1.1-01 | 1. `POST /links` com `{"destinationUrl":"https://example.com"}` e Bearer token válido. <br> 2. Anote o `shortCode` na resposta `201`. <br> 3. `GET /{shortCode}` sem Bearer token (estilo browser). | Passo 1 retorna `201 Created` com `shortCode` e `shortUrl`. Passo 3 retorna `302 Found` com `Location: https://example.com`. | P1 |
| TC-S01-02 | TC-1.1-02 | 1. `POST /links` com `{"destinationUrl":"https://example.com"}`. <br> 2. Anote o `id` da resposta `201`. <br> 3. `GET /links/{id}/stats` com Bearer token válido. | Resposta de stats contém `{"clicks": 0, ...}` imediatamente após a criação. | P2 |
| TC-S02-01 | TC-1.2-01 | 1. `POST /links` com `{"destinationUrl":"https://example.com","alias":"summer-sale"}`. <br> 2. `GET /summer-sale` sem token. | Passo 1 retorna `201 Created` com `shortCode: "summer-sale"`. Passo 2 retorna `302 Found` com `Location: https://example.com`. | P1 |
| TC-S03-01 | TC-1.2-02 | 1. `POST /links` com `{"destinationUrl":"https://other.example.com","alias":"existing-alias"}`. | Retorna `422 Unprocessable Entity` com `{"code":"ALIAS_TAKEN","message":"The alias 'existing-alias' is already taken."}`. Nenhum novo link é criado. | P1 |
| TC-S04-01 | TC-1.3-01 | 1. `GET /exp-link-01` sem token. | Retorna `410 Gone` com corpo `{"code":"LINK_EXPIRED","message":"This link has expired."}`. Nenhum header `Location` está presente. | P1 |
| TC-S04-02 | TC-1.3-02 | 1. `POST /links` com `{"destinationUrl":"https://example.com","expiresAt":"2020-01-01T00:00:00Z"}`. | Retorna `400 Bad Request` com `{"code":"VALIDATION_ERROR","message":"expiresAt must be a future date-time."}`. | P2 |
| TC-S05-01 | TC-1.4-01 | 1. `POST /links` → anote `id` e `shortCode` da resposta `201`. <br> 2. `PATCH /links/{id}` com `{"active": false}` (desativar). <br> 3. `GET /{shortCode}` sem token. | Passo 2 retorna `200 OK` com `{"active":false}`. Passo 3 retorna `410 Gone` com `{"code":"LINK_UNAVAILABLE","message":"This link is unavailable."}`. | P1 |
| TC-S05-02 | TC-1.4-02 | 1. Continuando de TC-S05-01. <br> 2. `PATCH /links/{id}` com `{"active": true}` (reativar). <br> 3. `GET /{shortCode}` sem token. | Passo 2 retorna `200 OK` com `{"active":true}`. Passo 3 retorna `302 Found` com `Location` correto. A contagem de cliques anterior à desativação é preservada. | P1 |
| TC-S06-01 | TC-1.5-01 | 1. Envie 60 requisições `GET /{validCode}` do mesmo IP em 60 s. <br> 2. Envie a requisição 61 dentro da mesma janela. | Requisições 1–60 retornam `302 Found`. Requisição 61 retorna `429 Too Many Requests` com header `Retry-After: 60`. | P1 |
| TC-S07-01 | TC-1.6-01 | 1. `POST /links` com `{"destinationUrl":"javascript:alert(1)"}`. | Retorna `400 Bad Request` com `{"code":"VALIDATION_ERROR","message":"destinationUrl must use http or https scheme."}`. | P1 |
| TC-S07-02 | TC-1.6-02 | 1. `POST /links` com `{"destinationUrl":"ftp://files.example.com/report.pdf"}`. | Retorna `400 Bad Request` com `{"code":"VALIDATION_ERROR","message":"destinationUrl must use http or https scheme."}`. | P2 |
| TC-S08-01 | TC-1.7-01 | 1. `GET /links/{code}/stats` → anote o valor de `clicks`. <br> 2. `GET /{code}` (seguir o link). <br> 3. Aguarde 30 s. <br> 4. `GET /links/{code}/stats` novamente. | A contagem de cliques no passo 4 é exatamente `clicks + 1`. | P1 |
| TC-S09-01 | TC-1.8-01 | 1. `GET /does-not-exist-xyz` sem token. | Retorna `404 Not Found` com `{"code":"LINK_NOT_FOUND","message":"Link not found."}`. | P1 |
| TC-S09-02 | TC-1.8-02 | 1. `GET /` (caminho raiz sem código). | Retorna `404 Not Found` ou `400 Bad Request`; sem exceção não tratada ou erro 500. | P3 |

---

## Fora do Escopo

- Testes de performance e carga (plano de carga separado necessário; suite Locust pendente).
- Fluxos de UI do Auth0 / provedor de identidade — apenas o Bearer token obtido após o login é exercitado aqui.
- Renderização de UI front-end para Visitantes, além de status HTTP e corpos de resposta.
- Integrações de notificação por e-mail para alertas de expiração de links (ainda não implementado).
- Testes de compatibilidade de browser e regressão visual.

---

## Aprovação

| Papel | Nome | Data | Status |
|---|---|---|---|
| Autor | QA Lead | 2026-06-23 | Aprovado |
| Revisor | Engineering Lead | 2026-06-23 | Aprovado |
| Aprovador | Product Owner | 2026-06-23 | Aprovado |
