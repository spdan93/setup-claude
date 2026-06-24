# Serviço de Encurtamento de URLs — Design Técnico

## Visão Geral

O Serviço de Encurtamento de URLs converte URLs arbitrariamente longas em códigos curtos compactos (ex.: `https://sho.rt/aB3x9`) e redireciona os visitantes para o destino original. O serviço foi projetado para equipes internas de marketing e analytics que precisam de links compartilháveis e rastreáveis em uma escala de aproximadamente 10 milhões de redirecionamentos por dia. Ele oferece uma API pública de redirecionamento e uma API privada de gerenciamento para criar, atualizar e expirar links.

## Arquitetura

O sistema é composto por três camadas de execução: um API gateway, um serviço de aplicação sem estado e uma camada de persistência com cache em processo.

```
Browser do Cliente / Consumidor da API
        │
        ▼
  ┌─────────────┐
  │ API Gateway │   — encerramento TLS, rate limiting, encaminhamento de auth
  └──────┬──────┘
         │
         ▼
  ┌──────────────────┐
  │  App Service     │   — geração de short code, resolução de redirecionamento, CRUD
  │  (Node.js / TS)  │
  └──────┬───────────┘
         │
    ┌────┴──────────────────────┐
    ▼                           ▼
┌──────────┐            ┌──────────────┐
│  Redis   │            │  PostgreSQL  │
│  (cache) │            │  (armazena-  │
│          │◄──populate─│   mento      │
└──────────┘            │   primário)  │
                        └──────────────┘
```

O gateway cuida do rate limiting para que o serviço de aplicação permaneça sem estado e escale horizontalmente. O Redis mantém um cache read-through dos 1 milhão de short codes mais acessados, mantendo a latência de redirecionamento abaixo de 10 ms para os caminhos mais quentes.

## Componentes e Responsabilidades

| Componente | Responsabilidade | Arquivo(s) principal(is) |
|---|---|---|
| **API Gateway** | Encerramento TLS, rate limiting por IP (BR-003), validação de JWT para endpoints de gerenciamento, roteamento de requisições | Config de infraestrutura (`nginx/nginx.conf`) |
| **LinkController** | Valida requisições HTTP recebidas, aplica restrições de entrada, delega ao LinkService, formata respostas | `src/controllers/link.controller.ts` |
| **LinkService** | Orquestra a criação de short codes (chama Encoder), escritas no cache, escritas no banco de dados, resolução de redirecionamentos, aplicação de expiração | `src/services/link.service.ts` |
| **Encoder** | Converte IDs auto-incrementados do banco de dados em short codes base62; decodificação inversa para uso em auditoria | `src/lib/encoder.ts` |
| **LinkRepository** | Repositório TypeORM; responsável por todas as leituras/escritas no banco para a tabela `links`; nunca chamado fora do LinkService | `src/repositories/link.repository.ts` |
| **CacheClient** | Wrapper leve em torno do `ioredis`; expõe `get`, `set` e `invalidate` tipados para o formato `CachedLink` | `src/lib/cache-client.ts` |
| **ClickTracker** | Publica um evento de clique leve em uma fila em processo; um worker em segundo plano descarrega contagens no PostgreSQL em lotes de 500 | `src/workers/click-tracker.ts` |

**Fora do escopo deste serviço:** autenticação de usuários (delegada ao gateway), renderização de preview de URL (um microserviço de preview separado) e dashboards de analytics (leem diretamente da tabela `click_events` por um serviço de BI).

## Fluxo de Dados

### Criação de short code (API de gerenciamento)

1. Cliente autenticado faz POST `{ url, alias?, expiresAt? }` para `POST /api/v1/links`.
2. `LinkController` valida o formato da URL e verifica que `alias` (se fornecido) contém apenas `[a-zA-Z0-9_-]` e tem ≤30 caracteres.
3. `LinkService` chama `LinkRepository.insert(url, alias, expiresAt)`. O banco de dados auto-incrementa o ID da linha.
4. Se nenhum `alias` foi fornecido, `Encoder.encode(rowId)` produz um short code base62 (4–7 caracteres). O código é gravado de volta na linha.
5. `CacheClient.set(shortCode, { url, expiresAt })` com TTL igual ao tempo de vida restante do link (padrão: sem TTL se não houver expiração).
6. O controller retorna `201 Created` com `{ shortCode, shortUrl, expiresAt }`.

### Redirecionamento (API pública)

1. Browser faz GET `/:shortCode`.
2. `LinkService.resolve(shortCode)` verifica `CacheClient.get(shortCode)` primeiro.
3. **Cache hit:** verifica `expiresAt`. Se expirado, retorna 410 Gone; caso contrário, retorna a URL e incrementa assincronamente a fila de contadores.
4. **Cache miss:** consulta `LinkRepository.findByCode(shortCode)`. Se não encontrado → 404. Se encontrado → popula o cache e prossegue como cache hit.
5. O controller emite `301 Moved Permanently` para links permanentes; `302 Found` para links com data de expiração (evita cache do browser para links prestes a expirar).
6. `ClickTracker.record(shortCode, timestamp, referrer, userAgent)` é chamado após o envio da resposta — o redirecionamento nunca é bloqueado pelo rastreamento.

## Dependências

| Dependência | Tipo | Propósito |
|---|---|---|
| **PostgreSQL 15** | Armazenamento externo | Armazenamento durável de links, aliases, datas de expiração e contagens de cliques |
| **Redis 7** | Cache externo | Caminho de leitura sub-10 ms para resolução de redirecionamentos; expiração por TTL de entradas em cache |
| **ioredis** | Biblioteca | Cliente Redis tipado com reconexão automática e suporte a cluster |
| **TypeORM** | Biblioteca | ORM para as tabelas `links` e `click_events`; usado apenas pelo `LinkRepository` |
| **class-validator** | Biblioteca | Validação de DTO baseada em decoradores no `LinkController` |
| **API Gateway (nginx)** | Upstream interno | Rate limiting (ver BR-003); encaminhamento de cabeçalho JWT para rotas de gerenciamento |
| **Auth Service** | Dependência interna | Emite JWTs validados pelo gateway; este serviço não o chama diretamente |
| **Preview Service** | Downstream interno | Lê `links.url` para gerar previews Open Graph; este serviço não o chama |

## Decisões e Compromissos

**Codificação de contador em base62 em vez de UUIDs aleatórios.** Os short codes são derivados do ID auto-incrementado da linha do banco de dados codificado em base62. Isso garante unicidade global sem uma verificação de unicidade separada e produz códigos curtos de comprimento previsível (um código de 4 caracteres suporta até 14,7 milhões de links). O compromisso é que os códigos são enumeráveis: um agente malicioso pode iterar os códigos para descobrir todos os links ativos. Mitigação: o endpoint de redirecionamento não expõe a URL de destino em nenhum cabeçalho antes do disparo do redirecionamento, e links de alto valor podem usar aliases personalizados que não revelam a posição do contador.

**Cache read-through no Redis, não em CDN.** Uma CDN proporcionaria menor latência de redirecionamento globalmente, mas serviria respostas 301 obsoletas por minutos após um link ser desativado ou expirado. O Redis permite invalidação instantânea (`CacheClient.invalidate(shortCode)`) quando um operador desativa um link pela API de gerenciamento. O custo aceito é que o serviço de cache é de região única; uma camada de CDN global pode ser adicionada em uma fase futura para links somente leitura e sem expiração.

**Contagem de cliques assíncrona.** Contar cliques no caminho crítico de redirecionamento adicionaria uma escrita síncrona no banco de dados a cada requisição. Em vez disso, os eventos são enfileirados em processo e descarregados em lotes. Isso significa que as contagens de cliques podem estar defasadas em até 10 segundos. Os consumidores de analytics são informados explicitamente sobre esse atraso; é aceitável dado que os dashboards atualizam em intervalos de 60 segundos.

**302 para links com expiração, 301 para links permanentes.** Os browsers armazenam respostas 301 indefinidamente. Usar 302 para links com expiração garante que, após o link expirar, o browser busque o destino do redirecionamento atualizado e receba a resposta 410 Gone em vez de servir um destino obsoleto do seu cache.

## Riscos

- **Esgotamento do contador:** Com 100 milhões de links, os short codes de 5 caracteres em base62 ainda estão disponíveis (62^5 ≈ 916 milhões). Nenhuma ação necessária no curto prazo; o `Encoder` pode ser atualizado para usar códigos de 6 caracteres incrementando uma constante quando a tabela se aproximar de 800 milhões de linhas.
- **Indisponibilidade do Redis:** Se o Redis estiver inacessível, `LinkService.resolve` cai diretamente no PostgreSQL. A latência de redirecionamento degrada para ~50 ms (de ~5 ms), mas a correção é mantida. As operações de gerenciamento não são afetadas.
- **Perda no flush de cliques em lote:** Se o processo cair enquanto a fila de cliques em memória não estiver vazia, até 500 eventos de clique podem ser perdidos. Este é um compromisso conhecido e aceito dado o caráter exclusivamente analítico dos dados. Uma melhoria futura é persistir a fila no Redis antes do encerramento do processo.
- **Squatting de alias:** Qualquer usuário autenticado pode reservar um alias personalizado. Não há isolamento de namespace entre equipes. Um registro centralizado de aliases (fora do escopo deste serviço) está planejado para uma fase posterior.

## Referências

- ADR: Uso de codificação de contador em base62 para short codes — `skills/doc-technical/examples/adr.example.md`
- Registro de Regras de Negócio — `skills/doc-functional/examples/business-rules.example.md`
- Especificação Funcional — `skills/doc-functional/examples/functional-spec.example.md`
- RFC 7231 §6.4.2 (301 Moved Permanently) e §6.4.3 (302 Found)
