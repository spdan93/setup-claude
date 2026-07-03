# Conventions — contrato entre arquivos

Agents, commands e skills deste kit se referenciam por **nomes e formatos canônicos**.
Se um deles muda num arquivo, precisa mudar em todos que dependem dele — senão o pipeline
quebra em silêncio (ex.: o `developer` procura a seção "Test Cases (immutable)" que o
`plan-architect` gera). Este arquivo é a fonte única desses contratos.

> Paths abaixo são **defaults sensatos**, não obrigatórios. Ajuste por projeto se quiser —
> mas mantenha consistente entre todos os arquivos do kit.

---

## Artefatos e caminhos

| Artefato | Caminho |
|----------|---------|
| PRD | `docs/prds/YYYY_MM_DD-{pipeline_id}.md` |
| Implementation Plan | `docs/plans/YYYY_MM_DD-{pipeline_id}-plan.md` |
| Changelog por commit | `docs/changelog/YYYY_MM_DD-HHMM-{slug}.md` |
| Documentação técnica | `docs/technical/` |
| Documentação funcional | `docs/functional/` |
| Cadernos de testes | `docs/test-plans/` |
| Documentação de API | `docs/api/` (+ `docs/api/openapi.yaml` se aplicável) |
| Evidência E2E | `docs/test-evidence/{feature}-{timestamp}.md` |
| Estado do pipeline | `.claude/orchestrator/pipelines/{pipeline_id}/pipeline-state.json` |
| Manifest (opcional) | `.claude/orchestrator/pipelines/{pipeline_id}/issues-manifest.json` |
| Progresso de execução | `.claude/orchestrator/pipelines/{pipeline_id}/dev-status.json` (efêmero; status por task, p/ `/develop` resumir) |

> **Localização**: artefatos duráveis (PRDs, plans, changelog, docs, evidências) ficam em
> `docs/` na **raiz do repo** — fora do `.claude/` e **versionados** no git. O `.claude/`
> é tooling local (gitignored); só o **estado efêmero** do pipeline mora nele
> (`.claude/orchestrator/pipelines/`). Nunca grave documentação dentro do `.claude/`.

### `pipeline_id`
Slug do título: `lowercase`, `kebab-case`, apenas `[a-z0-9-]`, ≤ 50 chars.
Ex.: "Push Notifications for Users" → `push-notifications-for-users`.

### Convenção de datas

- **Nomes de arquivo**: `YYYY_MM_DD` com underscores (ex.: `2026_06_23-feature.md`).
- **Campo `Date:` dentro do documento**: ISO `YYYY-MM-DD` com hífens (ex.: `2026-06-23`).

---

## Tipos de documentação

O kit inclui quatro tipos de documentação sob demanda, cada um como uma skill
`skills/doc-<tipo>/` com `SKILL.md` + `templates/` + `examples/`:

| Tipo | Skill | Diretório de saída |
|------|-------|-------------------|
| Técnico | `doc-technical` | `docs/technical/` |
| Funcional | `doc-functional` | `docs/functional/` |
| Caderno de testes | `doc-test-plan` | `docs/test-plans/` |
| API | `doc-api` | `docs/api/` |

> O changelog **não** é uma skill: seu template fica em `templates/changelog/commit-entry.md`
> (fora de `skills/`) e é usado internamente pelo `/commit`. Não aparece no `/documentation`.

**Seleção de template**: cada skill lista seus templates disponíveis e seleciona o mais
adequado com base na descrição/contexto fornecido pelo usuário.

**Adicionar um novo tipo**: crie `skills/doc-<novo>/` com `SKILL.md` (frontmatter `name`/`description`)
+ `templates/` + `examples/` (um exemplo preenchido por template). O `/documentation`
descobre automaticamente qualquer `skills/doc-*/SKILL.md` e dispara pela descrição da tarefa.

---

## Nomes canônicos de seção (templates PRD/Plan)

Em **inglês**, idênticos em todos os arquivos (o conteúdo segue o idioma do projeto):

- `Executive Summary`
- `Context`
- `Acceptance Criteria`
- `Test Cases (immutable)`
- `Notes for Agents`
- `Next Steps`

---

## Task UUID

Formato: `task-{phase}-{num}-{hash5}` onde `hash5` = primeiros 5 chars do hash do título
em lowercase. Ex.: `task-2-1-a3b2c`. Determinístico (mesmo título → mesmo UUID).

---

## Test Cases (imutáveis)

- Tag: `[TC-N.M-NN]` (N=fase, M=task, NN=sequencial). Ex.: `[TC-1.2-01]`.
- Formato Gherkin: **"Given X, when Y, then Z"**.
- Relação **1:1**: cada TC vira exatamente um teste automatizado; nem a mais, nem a menos.
- São **imutáveis** depois de definidos no Plan: se estiverem errados, corrija no Plan e
  regenere — o `developer` e o `code-reviewer` não os alteram.

---

## Frontmatter (por tipo)

| Tipo | Local | Campos |
|------|-------|--------|
| **Agent** | `agents/*.md` | `name`, `description`, `model`, `tools` (lista separada por vírgula) |
| **Command** | `commands/*.md` | `description`; opcionais: `allowed-tools` (vírgula), `argument-hint`, `model` |
| **Skill** | `skills/<nome>/SKILL.md` | `name`, `description` |

> Atenção: agent usa `tools:`; command usa `allowed-tools:` (com hífen). Skill **precisa**
> ser uma pasta `<nome>/SKILL.md` — `.md` solto não é descoberto como skill.

---

## Issue tracker

Opcional e não incluído. Sempre que um ID de issue aparecer, use o placeholder
`<ISSUE-ID>` (ou `ABC-123` em exemplos). Campo de epic no frontmatter: `epic` (opcional).

---

## Idioma

- **Artefatos de documentação** (saída das skills `doc-*`): idioma escolhido pelo usuário
  no momento da geração — **pt-BR** (default), en-US ou es. A skill pergunta via
  `AskUserQuestion` antes de escrever; o usuário pode omitir para aceitar pt-BR.
  Os headings das seções do artefato são traduzidos para o idioma escolhido.
- **`SKILL.md` (prose de instrução)**: sempre em inglês — é instrução para o LLM, não
  conteúdo para o usuário final.
- **Changelog por commit** (`docs/changelog/`): escrito em pt-BR por padrão; não há
  prompt de idioma por commit.
- **PRD e Plan** (`prd-writer` / `plan-architect`): **conteúdo/prosa em pt-BR por padrão**
  (en-US ou es só se o usuário pedir). Mas os **headings estruturais ficam em inglês
  canônico** — são contrato lido por `developer`, `code-reviewer`, `/test-write` e
  `checkpoint-validator` (ex.: `Test Cases (immutable)`, `Executive Summary`).
- **Mensagem de commit**: corpo escrito em **pt-BR por padrão** (labels: Causa / Mudanças /
  Consequência / Funcionalidade / Ganho); en-US só se o usuário pedir explicitamente. As
  palavras-chave do tipo convencional (`feat`, `fix`, `refactor`, etc.) e o footer
  `Developed-by` permanecem em inglês.
- **Headings de template** (PRD/Plan/meta-prompt): inglês canônico (lista acima).

---

## Modelos

| Tier | Quando |
|------|--------|
| `opus` | raciocínio profundo / decomposição (prd-writer, plan-architect) |
| `sonnet` | execução equilibrada (developer, prd-reviewer, code-reviewer) |
| `haiku` | tarefas mecânicas |

Prioridade: `model` na chamada `Task(...)` > `model` no frontmatter > default do sistema.
