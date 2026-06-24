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
| Estado do pipeline | `.claude/orchestrator/pipelines/{pipeline_id}/pipeline-state.json` |
| Manifest (opcional) | `.claude/orchestrator/pipelines/{pipeline_id}/issues-manifest.json` |
| Progresso de execução | `.claude/orchestrator/pipelines/{pipeline_id}/dev-status.json` (efêmero; status por task, p/ `/develop` resumir) |
| Evidência E2E | `docs/test-evidence/{feature}-{timestamp}.md` |

> **Localização**: artefatos duráveis (PRDs, plans, changelog, docs, evidências) ficam em
> `docs/` na **raiz do repo** — fora do `.claude/` e **versionados** no git. O `.claude/`
> é tooling local (gitignored); só o **estado efêmero** do pipeline mora nele
> (`.claude/orchestrator/pipelines/`). Nunca grave documentação dentro do `.claude/`.

### `pipeline_id`
Slug do título: `lowercase`, `kebab-case`, apenas `[a-z0-9-]`, ≤ 50 chars.
Ex.: "Push Notifications for Users" → `push-notifications-for-users`.

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

- **Prosa / docs / commits**: seguir a convenção dominante do projeto (detectar pelos
  docs/commits; default inglês se incerto).
- **Headings de template** (PRD/Plan/meta-prompt): inglês canônico (lista acima).

---

## Modelos

| Tier | Quando |
|------|--------|
| `opus` | raciocínio profundo / decomposição (prd-writer, plan-architect) |
| `sonnet` | execução equilibrada (developer, prd-reviewer, code-reviewer) |
| `haiku` | tarefas mecânicas |

Prioridade: `model` na chamada `Task(...)` > `model` no frontmatter > default do sistema.
