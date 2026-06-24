# USAGE — como usar o kit

Guia prático de "como eu faço X" com este kit `.claude`. Para arquitetura e racional,
veja **[README.md](README.md)**; para instalar, **[INSTALL.md](INSTALL.md)**; para os
formatos canônicos (paths, TC-*, UUIDs), **[CONVENTIONS.md](CONVENTIONS.md)**.

---

## 1. Visão geral em 30 segundos

O kit gira em torno de um pipeline da **ideia → código**, com gates de aprovação humana
entre cada fase:

```
ideia ──► PRD ──► Review ──► Plan ──► Execução ──► (E2E opcional) ──► commit/ship
          (prd-writer)(prd-reviewer)(plan-architect)(developer)        (/commit · /ship)
            └── checkpoint ──┘└── checkpoint ──┘└── checkpoint ──┘
```

`/workflow` orquestra tudo isso de ponta a ponta. Mas **cada fase também roda sozinha**:
você pode chamar só `/prd-write`, só `/plan-create`, só `/commit`, etc. — útil quando já
tem parte do trabalho pronto ou só quer um pedaço.

---

## 2. Pipeline completo (`/workflow`)

Happy path, de ponta a ponta:

```bash
/workflow
```

1. **Pergunta a ideia** (ou passe inline). Ex.: "notificações push para usuários".
2. **Fase 1/4 — PRD**: delega ao agente `prd-writer`, que lê o `CLAUDE.md` do projeto,
   procura PRDs/código relacionados e grava `docs/prds/2026_06_22-push-notifications.md`.
   → **Checkpoint**: `Approve PRD? [yes/no/edit]`.
3. **Fase 2/4 — Review**: `prd-reviewer` valida estrutura/consistência e refina o PRD no
   lugar (status → `in_review`/`approved`). → **Checkpoint**.
4. **Fase 3/4 — Plan**: `plan-architect` transforma o PRD aprovado em
   `docs/plans/2026_06_22-push-notifications-plan.md` com fases, tasks (UUID
   `task-N-M-xxxxx`), critérios de aceite e **Test Cases (immutable)** `[TC-N.M-NN]`.
   → **Checkpoint** (mostra contagem de tasks).
5. **Fase 4/4 — Execução**: rode `/develop --all` para executar as tasks do Plan na ordem
   de dependência. Ele dirige o agente `developer` por task (código + testes via
   `/test-write` + review via `code-reviewer`), grava progresso em `dev-status.json`
   (resumível) e mantém o diff de cada task revisável. `/develop` sozinho faz a próxima
   task; `--yolo` roda autônomo e commita por task.
6. **Fase 5 — E2E (opcional)**: só se a feature tiver UI. Pergunta se quer rodar; se sim,
   chama `/e2e <feature> --final` (precisa do dev server no ar). Gera evidência em
   `docs/test-evidence/`.
7. **Fechar**: `/commit` ou `/ship` para versionar/documentar/commitar.

**Checkpoints** aceitam `yes` (avança), `no` (para — não auto-avança), `edit` (ajusta o
artefato antes de seguir). Nada é commitado automaticamente.

**Flags**:

| Flag | Efeito |
|------|--------|
| `--from=prd\|review\|plan\|execution` | Retoma de uma fase específica |
| `--yolo` | Pula os checkpoints e auto-avança (ainda para em erro de agente) |
| `--verbose` | Saída detalhada (prompts, paths, timing) em vez do modo quieto |

> O pipeline **não cria issues** em nenhum tracker — as tasks vivem no Plan. Adotar
> GitHub Issues/Jira/Linear é opt-in (ver README › Issue Tracker).

---

## 3. Comandos (referência prática)

### Pipeline

| Comando | O que faz | Uso |
|---------|-----------|-----|
| `/workflow` | Roda o pipeline inteiro com checkpoints | `/workflow` · `/workflow --from=plan --yolo` |
| `/prd-write` | Cria um PRD novo a partir de uma ideia | `/prd-write "Add Google OAuth login"` |
| `/prd-review` | Revisa/refina um PRD existente (edita no lugar) | `/prd-review docs/prds/2026_06_22-feature.md` |
| `/plan-create` | Gera o Implementation Plan de um PRD aprovado | `/plan-create --prd=docs/prds/2026_06_22-feature.md` |
| `/develop` | Executa as tasks do Plan na ordem de dependência (DAG) via `developer` | `/develop --all` · `/develop --task=task-2-1-abc` |

- **`/develop`** — a fase de Execução. Lê o Plan, executa as tasks respeitando o DAG de
  dependências, invoca o `developer` por task e grava progresso em `dev-status.json`
  (dá **resume**). Sem flag, faz a próxima task não-bloqueada; `--all` percorre tudo;
  `--task=<uuid|ref>` faz uma; `--yolo` roda sem checkpoints e commita por task;
  `--status` só mostra o quadro de progresso.
- **`/prd-write`** — sem argumento, pergunta a ideia. Se o PRD já existir, oferece
  `overwrite` / `version bump` / `cancel`. Use quando só quer o documento, sem o pipeline.
- **`/prd-review`** — sem path, lista os PRDs em `docs/prds/` (mais novos primeiro) para
  você escolher. Use antes de gerar o Plan, para garantir qualidade.
- **`/plan-create`** — sem `--prd`, lista os PRDs. Avisa se o PRD não estiver `approved`.
  Se o Plan já existir, oferece `overwrite` / `version bump` / `cancel`.

### Qualidade & testes

| Comando | O que faz | Uso |
|---------|-----------|-----|
| `/test-write` | Gera testes 1:1 a partir dos `[TC-*]` (immutable) | `/test-write --plan=docs/plans/x.md --task=task-1-2-abc` |
| `/e2e` | Roda E2E de browser e gera relatório de evidência | `/e2e login-flow --url=http://localhost:3000 --final` |

- **`/test-write`** — fontes de TC: `--issue=<ISSUE-ID>`, `--plan=...` + `--task=<uuid>`,
  ou `--cases="[TC-1.1-01] Given..."`. Detecta o runner do projeto (Vitest/Jest/pytest/...),
  gera **um teste por TC** (com o ID no nome) e roda. Em modo TDD (sem implementação), os
  testes falham de propósito. `--target` força o diretório de saída.
- **`/e2e`** — requer o dev server **já rodando** (o comando não sobe servidor nem faz
  login). Coleta cenários interativamente, dirige o browser em desktop + mobile e grava
  o relatório. Sem `--final`, salva em `.test-evidence-local/` (gitignored); com `--final`,
  em `docs/test-evidence/` (versionado). Sempre passe `--url` ou ele pergunta — nunca
  chuta porta.

### Commit & docs

| Comando | O que faz | Uso |
|---------|-----------|-----|
| `/commit` | Commit estruturado (5 seções) + grava entrada em `docs/changelog/` + push | `/commit` · `/commit "valida formulário de signup"` |
| `/ship` | Version bump + `/commit` (que já grava o changelog) | `/ship` · `/ship minor` · `/ship fix 1.6.4` |
| `/documentation <tipo>` | Gera documentação do tipo escolhido via skill `doc-<tipo>` | `/documentation technical` · `/documentation api` |

- **`/commit`** — analisa o diff, pergunta se quer linkar a uma issue (`<ISSUE-ID>` no
  título; `Fixes <ISSUE-ID>` no rodapé), exige as **5 seções obrigatórias** no corpo
  (Cause, Changes, Consequence, Functionality, Gain) + `Developed-by`, e **grava uma
  entrada de changelog** em `docs/changelog/YYYY_MM_DD-HHMM-{slug}.md` como parte do
  commit. Nunca troca de branch; faz push no(s) remote(s) configurado(s).
- **`/ship`** — fecha uma feature: descobre os pacotes alterados, faz version bump
  semântico e então invoca `/commit` (que grava o changelog). Aceite o bump inline
  (`minor`, `patch`, `fix 1.6.4`) ou um path de doc.
- **`/documentation`** — roteador que descobre automaticamente todos os `skills/doc-*/`
  (exceto `doc-changelog`) e delega ao tipo escolhido. Tipos disponíveis:

  | Tipo | Comando | Saída |
  |------|---------|-------|
  | Documentação técnica | `/documentation technical` | `docs/technical/` |
  | Documentação funcional | `/documentation functional` | `docs/functional/` |
  | Caderno de testes | `/documentation test-plan` | `docs/test-plans/` |
  | Documentação de API | `/documentation api` | `docs/api/` |

### Utilitários

| Comando | O que faz | Uso |
|---------|-----------|-----|
| `/meta-prompt` | Gera prompt estruturado p/ passar contexto entre agentes | `/meta-prompt --task=implementation --artifacts=docs/plan.md` |
| `/claude-md` | Cria/edita um `CLAUDE.md` (contexto conceitual, ≤200 linhas) | `/claude-md create` · `/claude-md edit ./CLAUDE.md` |
| `/confirm-delete` | 2º fator que libera um delete bloqueado pelo hook | `/confirm-delete` |

- **`/meta-prompt`** — interativo, ou com `--task` / `--artifacts` / `--constraints` /
  `--output` / `--criteria`. O `/workflow` usa isto internamente antes de cada agente; você
  raramente precisa chamar à mão (útil para debug ou para um tool externo).
- **`/claude-md`** — `create [path]` analisa o diretório e gera o arquivo; `edit <path>`
  faz edição cirúrgica. Foco em WHY/WHAT/HOW, zero código, máximo 200 linhas.
- **`/confirm-delete`** — fluxo 2FA: o hook bloqueia `rm`/`git rm`/`find -delete`, você
  confirma com "CONFIRMO DELETE", roda `/confirm-delete` (janela de 60s) e re-executa o
  comando original.

---

## 4. Agentes (quando invocar direto via `Task`)

Fora do pipeline, você pode chamar qualquer agente diretamente:

```
Task(subagent_type="developer", prompt="Implemente task-2-1-a3b2c do Plan docs/plans/...")
Task(subagent_type="developer", model="opus", prompt="...")   # override de modelo
```

> Para executar tasks do Plan, prefira **`/develop`** — ele já envolve o `developer` com
> ordem de dependência (DAG), `meta-prompt`, progresso resumível e commits por task.
> Chamar o `developer` direto via `Task` é o caminho de baixo nível (uma task avulsa).

| Agente | Modelo | O que faz |
|--------|--------|-----------|
| `prd-writer` | opus | Transforma uma ideia em PRD estruturado em `docs/prds/` |
| `prd-reviewer` | sonnet | Valida e refina um PRD no lugar; ajusta status/metadata |
| `plan-architect` | opus | Transforma PRD aprovado em Plan com tasks + TC-* |
| `developer` | sonnet | Implementa uma task (código + testes + review); deixa staged |
| `code-reviewer` | sonnet | Revisa o diff em sessão isolada; devolve PASS/FAIL/WARN (não corrige) |

Prioridade de modelo: `model` na chamada `Task(...)` > `model` no frontmatter do agente >
default do sistema. O `developer` ainda pode auto-escolher por complexidade (simple=haiku,
medium=sonnet, complex=opus) se habilitado.

---

## 5. Skills

São invocadas automaticamente (pela descrição) ou explicitamente. Três são **internas do
pipeline** e você normalmente não chama à mão:

| Skill | Uso | O que faz |
|-------|-----|-----------|
| `meta-prompt` | interna | Padroniza prompts entre agentes |
| `workflow-orchestrator` | interna | Lógica de transição de fases do `/workflow` |
| `checkpoint-validator` | interna | Gates de aprovação `yes/no/edit` entre fases |
| `bug-tracker` | direto | Audita commits recentes em busca de bugs e gera plano de correção |
| `microservices-analyzer` | direto | Análise de arquitetura: C4, catálogo de serviços, dependências |
| `playwright-e2e-testing` | direto | Guia/padrões de E2E Playwright (usado pelo `/e2e`) |
| `doc-technical` | `/documentation technical` | Gera documentação técnica em `docs/technical/` |
| `doc-functional` | `/documentation functional` | Gera documentação funcional em `docs/functional/` |
| `doc-test-plan` | `/documentation test-plan` | Gera caderno de testes em `docs/test-plans/` |
| `doc-api` | `/documentation api` | Gera documentação de API em `docs/api/` |

---

## 6. Receitas rápidas

- **Só criar um PRD** → `/prd-write "descrição da ideia"`
- **Já tenho PRD, quero o Plan** → `/plan-create --prd=docs/prds/2026_06_22-feature.md`
- **Pipeline inteiro sem parar em cada gate** → `/workflow --yolo`
- **Retomar da fase de Plan** → `/workflow --from=plan`
- **Executar o Plan inteiro (DAG) de forma autônoma** → `/develop --all --yolo`
- **Implementar a próxima task / uma task específica** → `/develop` · `/develop --task=2.1`
- **Ver o progresso da execução** → `/develop --status`
- **Gerar testes a partir dos TC de uma task** → `/test-write --plan=docs/plans/x.md --task=task-1-2-abc`
- **Validar feature de UI no browser** → suba o dev server, depois `/e2e checkout --url=http://localhost:3000 --final`
- **Documentar + versionar + commitar de uma vez** → `/ship`
- **Auditar bugs de commits recentes** → invoque a skill `bug-tracker`
- **Documentar um diretório p/ agentes** → `/claude-md create ./src/feature`
- **Gerar caderno de testes** → `/documentation test-plan`
- **Documentar a API** → `/documentation api`
- **Gerar documentação técnica de um módulo** → `/documentation technical`

---

## 7. Ver também

- **[INSTALL.md](INSTALL.md)** — instalação, dependências e estrutura do kit.
- **[CONVENTIONS.md](CONVENTIONS.md)** — paths, `pipeline_id`, UUID de task, formato `[TC-N.M-NN]`, frontmatter.
- **[README.md](README.md)** — arquitetura e racional do pipeline.
