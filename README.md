# Claude Orchestrator

Automação completa do pipeline de desenvolvimento: Ideia → PRD → Plan → Código.

## Arquitetura

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         VOCÊ (Terminal/IDE)                                  │
│                                                                             │
│   /workflow ────────────────────────────────────────────────────────────►   │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    CLAUDE CODE (Contexto Principal)                          │
│                                                                             │
│   Orquestra o pipeline, executa commands, gerencia checkpoints              │
│   NÃO faz trabalho pesado - delega para subagentes                          │
└─────────────────────────────────────────────────────────────────────────────┘
         │              │              │              │
         ▼              ▼              ▼              ▼
    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
    │   PRD   │    │   PRD   │    │  Plan   │    │Developer│
    │ Writer  │    │Reviewer │    │Architect│    │         │
    │(isolado)│    │(isolado)│    │(isolado)│    │(isolado)│
    └─────────┘    └─────────┘    └─────────┘    └─────────┘
                                                      │
                                                      ▼
                                                ┌───────────┐
                                                │   Code    │
                                                │ Reviewer  │
                                                │ (isolado) │
                                                └───────────┘
```

### Por que subagentes isolados?

| Aspecto                   | Benefício                                                   |
| ------------------------- | ----------------------------------------------------------- |
| **Contexto separado**     | Cada agente começa "limpo", sem viés da conversa anterior   |
| **Economia de tokens**    | Agente recebe só o necessário, não todo o histórico         |
| **Especialização**        | Cada agente tem instruções específicas para sua tarefa      |
| **Code review imparcial** | O code-reviewer roda em sessão isolada, sem viés do implementador |

### Fluxo de Dados

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  Ideia   │───▶│   PRD    │───▶│   Plan   │───▶│  Código  │
│ (texto)  │    │  (.md)   │    │  (.md)   │    │  (git)   │
└──────────┘    └──────────┘    └──────────┘    └──────────┘
                     │               │               │
                     ▼               ▼               ▼
                docs/prds/      docs/plans/      Repositório
```

> **Fase de Issue Tracker (opcional, não incluída)**: hoje o pipeline não cria
> issues. Quando você adotar um provider (GitHub Issues, Jira, Linear, etc.),
> pluga aqui o passo de criação de issues — um agente/comando específico do
> provider. O pipeline funciona ponta a ponta sem essa fase: o Plan + o
> `issues-manifest.json` local já guardam as tasks com IDs placeholder.

**Artefatos são o contrato entre fases** - cada agente lê o artefato da fase anterior e produz o próximo.

### Transferência de Contexto (Meta-Prompt)

Como cada agente tem **contexto isolado**, ele não sabe o que aconteceu antes. O `meta-prompt` resolve isso:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  Orchestrator (contexto principal)                                          │
│                                                                             │
│  1. PRD aprovado em docs/prds/feature.md                                    │
│  2. Preciso chamar plan-architect                                           │
│  3. Mas plan-architect NÃO sabe de nada!                                    │
│                                                                             │
│  Solução: /meta-prompt gera prompt estruturado                              │
│                                                                             │
│  Task(subagent_type="plan-architect", prompt="""                            │
│    ## Objective                                                             │
│    Create implementation plan from PRD                                      │
│                                                                             │
│    ## Input Artifacts                                                       │
│    - docs/prds/2025_01_01-feature.md                                        │
│                                                                             │
│    ## Expected Output                                                       │
│    Implementation Plan with phases, tasks, TC-* test cases                  │
│                                                                             │
│    ## Constraints                                                           │
│    - Follow the Implementation Plan template                                │
│    - Each task must have acceptance criteria                                │
│  """)                                                                       │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Regra**: Antes de chamar qualquer agent, use `/meta-prompt` para gerar o prompt estruturado.

## Como Usar

### 1. Pipeline Completo (Recomendado)

```bash
# Inicia do zero
/workflow

# Sem checkpoints (vai direto)
/workflow --yolo

# Retoma de uma fase específica
/workflow --from=plan
```

**O que acontece**:

1. **PRD Write** → você descreve a ideia, agent cria PRD → checkpoint (você aprova)
2. **PRD Review** → agent revisa e refina → checkpoint (você aprova)
3. **Plan Create** → agent decompõe em tasks técnicas → checkpoint (você aprova)
4. **Execution** → `/develop` executa as tasks do Plan na ordem de dependência (DAG)

> **Fase de Issue Tracker (opcional, não incluída)**: entre o Plan e a Execution
> você pode plugar um passo de criação de issues no provider que adotar (GitHub
> Issues, Jira, Linear, etc.). Sem ela, o pipeline segue normalmente — as tasks
> ficam no Plan e no `issues-manifest.json` local, com IDs placeholder.

### 2. Comandos Standalone (Pular para Fase Específica)

```bash
# Criar apenas PRD
/prd-write "Adicionar login via Google"

# Revisar PRD existente
/prd-review docs/prds/2025_01_01-feature.md

# Criar Implementation Plan
/plan-create --prd=docs/prds/2025_01_01-feature.md
```

### 3. Executar as Tasks do Plan

Forma recomendada — `/develop` executa as tasks na ordem de dependência (DAG):

```bash
/develop                       # próxima task não-bloqueada do Plan
/develop --task=task-2-1-abc   # uma task específica (UUID ou ref 2.1)
/develop --all                 # percorre o DAG inteiro
/develop --all --yolo          # autônomo, commita por task
/develop --status              # quadro de progresso
```

Por baixo, `/develop` invoca o agente `developer` por task. Para uma task avulsa de baixo
nível, dá pra chamar o agente direto:

```bash
Task(subagent_type="developer", prompt="Implementar task-2-1-abc do Plan docs/plans/...")
```

**O que o developer faz (por task)**:

1. Lê a task (do Plan; ou do tracker, se configurado) — critérios de aceite + **TC-\* casos de teste**
2. **Move issue para "In Progress"** no tracker (se configurado)
3. Lê excerpt do Plan (contexto técnico)
4. Chama `/test-write` para gerar testes 1:1 dos TC-\* cases
5. Implementa código até testes passarem
6. Usa `meta-prompt` para gerar prompt estruturado
7. Invoca o **code-reviewer** (sessão isolada) para code review (com TC-\* para validar cobertura)
8. **Resilience Loop**: Se FAIL → corrige e tenta de novo (até 3x)
9. Se PASS → **Move issue para "In Review"** no tracker (se configurado)
10. Changes staged para seu commit manual
11. **"In Review" → "Done"** é MANUAL (Tech Lead aprova PR)

**Fluxo de status no tracker (opcional)**:

```
┌─────────┐      ┌─────────────┐      ┌───────────┐      ┌──────────┐
│  Todo   │─────▶│ In Progress │─────▶│ In Review │─────▶│   Done   │
└─────────┘      └─────────────┘      └───────────┘      └──────────┘
     │                  │                   │                  │
 DEVELOPER          DEVELOPER           DEVELOPER          HUMANO
 inicia (2)         finaliza (9)        aguarda           Tech Lead
```

### 4. Gerar Testes de TC-\* Cases

```bash
# Gera testes automatizados 1:1 a partir dos TC-* da issue
/test-write ABC-123

# Resultado: arquivo .spec.ts com 1 teste por TC-*
# Cada teste tem comentário // [TC-X.X-XX] antes do it()
```

### 5. Gerar Prompt Estruturado (Manual)

```bash
# Quando precisar passar contexto para outra LLM/agent
/meta-prompt --task="review" --artifacts="src/file.ts" --output="code review"

# Resultado: prompt em inglês com seções padronizadas
```

## Estrutura

```
.claude/
├── agents/                 # Subagentes (sessões isoladas, via Task)
│   ├── prd-writer.md       # Cria PRD de ideia
│   ├── prd-reviewer.md     # Revisa PRD draft
│   ├── plan-architect.md   # Decompõe PRD em tasks + TC-*
│   ├── developer.md        # Implementa código (TDD + review)
│   └── code-reviewer.md    # Review em sessão isolada
│
├── commands/               # Slash commands que você chama
│   ├── workflow.md         # Pipeline completo
│   ├── prd-write · prd-review · plan-create.md    # Fases do pipeline
│   ├── develop.md          # Executa as tasks do Plan (DAG)
│   ├── test-write.md       # Testes 1:1 dos TC-*
│   ├── e2e.md              # E2E de browser + evidência
│   ├── commit · ship · documentation.md          # Commit (grava changelog por commit) / release / docs
│   ├── meta-prompt.md      # Prompt estruturado (manual)
│   ├── claude-md.md        # Cria/edita CLAUDE.md
│   └── confirm-delete.md   # 2FA do hook de delete
│
├── skills/                 # Skills (cada uma é <nome>/SKILL.md)
│   ├── meta-prompt/                # interna: prompts entre agentes
│   ├── workflow-orchestrator/      # interna: transições de fase
│   ├── checkpoint-validator/       # interna: gates de aprovação
│   ├── bug-tracker/                # standalone: audita bugs em commits
│   ├── microservices-analyzer/     # standalone: análise de arquitetura (C4)
│   ├── playwright-e2e-testing/     # standalone: guia/padrões de E2E
│   ├── doc-technical/              # documentação técnica (via /documentation)
│   ├── doc-functional/             # documentação funcional (via /documentation)
│   ├── doc-test-plan/              # cadernos de testes (via /documentation)
│   ├── doc-api/                    # documentação de API (via /documentation)
│   └── doc-changelog/              # template-only: usado internamente pelo /commit
│
├── hooks/delete-2fa.sh     # Guarda de comandos destrutivos (2FA)
├── statusline/             # Statusline mac/linux/windows (nível de usuário)
├── orchestrator/           # Dados internos do pipeline
│   ├── config.json
│   └── pipelines/{pipeline_id}/    # pipeline-state.json · dev-status.json
├── install.sh · VERSION
└── README · INSTALL · USAGE · CONVENTIONS (.md)
```

> Árvore completa (níveis usuário vs projeto) em **[INSTALL.md](INSTALL.md)**.

## Artefatos Gerados

```
docs/
├── prds/
│   └── YYYY_MM_DD-{pipeline_id}.md          # PRD oficial
├── plans/
│   └── YYYY_MM_DD-{pipeline_id}-plan.md     # Implementation Plan
├── changelog/                               # docs/changelog/ — entrada por commit (gerada pelo /commit)
│   └── YYYY_MM_DD-HHMM-{slug}.md
├── technical/                               # Documentação técnica (/documentation technical)
├── functional/                              # Documentação funcional (/documentation functional)
├── test-plans/                              # Cadernos de testes (/documentation test-plan)
└── api/                                     # Documentação de API (/documentation api)

.claude/orchestrator/pipelines/{pipeline_id}/
├── pipeline-state.json                      # Estado do pipeline
└── issues-manifest.json                     # Mapping tasks ↔ tracker
```

## Agents

| Agent              | Modelo           | O Que Faz                           |
| ------------------ | ---------------- | ----------------------------------- |
| **prd-writer**     | opus             | Transforma ideia em PRD estruturado |
| **prd-reviewer**   | sonnet           | Revisa PRD para completude/clareza  |
| **plan-architect** | opus             | Decompõe PRD em tasks técnicas      |
| **developer**      | sonnet (default) | Implementa código + testes (staged) |
| **code-reviewer**  | sonnet           | Revisa changes em sessão isolada    |

Os agentes rodam em **sessões isoladas** via `Task(subagent_type=...)`. O `/workflow` e o
`/develop` os invocam automaticamente, mas você também pode chamá-los direto (ver _Override
de Modelo_ abaixo).

### Configuração de Modelos

O modelo de cada agent é definido no **frontmatter YAML** do arquivo `.claude/agents/*.md`:

```yaml
# .claude/agents/developer.md
---
name: developer
description: Implements tasks with code, tests, and documentation
model: sonnet # ← MODELO DEFINIDO AQUI
tools: Read, Write, Edit, Grep, Glob, Bash, Skill, Task, AskUserQuestion
---
```

**Modelos disponíveis**:

- `opus` - Máxima qualidade, mais lento, mais caro
- `sonnet` - Equilíbrio qualidade/velocidade
- `haiku` - Mais rápido, mais barato, tarefas simples

**Justificativa por agent**:

| Agent          | Modelo | Por quê?                                          |
| -------------- | ------ | ------------------------------------------------- |
| prd-writer     | opus   | Criação de PRD requer raciocínio profundo         |
| prd-reviewer   | sonnet | Revisão é menos complexa que criação              |
| plan-architect | opus   | Decomposição técnica precisa de análise detalhada |
| developer      | sonnet | Melhor equilíbrio qualidade/velocidade/custo      |
| code-reviewer  | sonnet | Revisão objetiva em sessão isolada                |

### Override de Modelo

Você pode sobrescrever o modelo na chamada do Task:

```bash
# Usa o modelo padrão (sonnet) definido no agent
Task(subagent_type="developer", prompt="Implementar ABC-123")

# Override para opus (task muito complexa)
Task(subagent_type="developer", model="opus", prompt="Refatorar arquitetura do módulo")

# Override para haiku (muito simples, só renomear variável)
Task(subagent_type="developer", model="haiku", prompt="Renomear função X para Y")
```

**Prioridade**: `model` na chamada > `model` no frontmatter > default do sistema

### Code Review (Sessão Isolada) ⭐

O **code-reviewer** roda em uma **sessão isolada**, com contexto limpo, e revisa as
changes sem o viés de quem as implementou:

1. Recebe o contexto da revisão (diff + critérios + TC-* + CLAUDE.md)
2. Avalia correção, cobertura dos TC-*, e aderência às convenções do projeto
3. Retorna findings estruturados:
   - **PASS** → changes ficam staged para seu commit manual
   - **FAIL** → developer corrige (Resilience Loop)
   - **WARN** → sugestões opcionais (decisão do developer)

**Vantagem**: A revisão acontece em contexto isolado, então não herda as suposições
da sessão que escreveu o código.

### Resilience Loop ⭐

Quando o code-reviewer rejeita a implementação, o Developer **não desiste**:

```
┌────────────────────────────────────────────────────────────────┐
│                    RESILIENCE LOOP                              │
│                                                                │
│   attempt = 1                                                  │
│                                                                │
│   WHILE attempt <= 3:                                          │
│       1. Submeter para o code-reviewer                         │
│       2. Se PASS → sair do loop ✓                              │
│       3. Se FAIL:                                               │
│          - Ler feedback                                        │
│          - Corrigir código                                     │
│          - Re-rodar testes                                     │
│          - attempt += 1                                        │
│                                                                │
│   Se attempt > 3:                                              │
│       → ESCALAR para usuário                                   │
│       → Opções: aprovar manual / dar guidance / cancelar       │
└────────────────────────────────────────────────────────────────┘
```

**Por que 3 tentativas?** Erros comuns (lint, formatting, variáveis não usadas) são corrigidos automaticamente. Problemas arquiteturais precisam de intervenção humana.

### Status Management (Opcional) ⭐

Se você usar um issue tracker (Linear, Jira, GitHub Issues, etc.) e ele estiver
configurado, o Developer gerencia automaticamente o status da issue:

| Momento                  | Ação Automática                         | Quem Faz               |
| ------------------------ | --------------------------------------- | ---------------------- |
| Ao iniciar implementação | `Todo → In Progress` + assign + comment | Developer              |
| Após review aprovar      | `In Progress → In Review` + summary     | Developer              |
| Após PR aprovado e merge | `In Review → Done`                      | **HUMANO (Tech Lead)** |

O fluxo de status acima é genérico e opcional — adapte aos estados do seu tracker
ou desabilite se não usar um.

**Por que "Done" é manual?** O Tech Lead precisa revisar o PR e aprovar o merge. Automação futura pode criar PR automaticamente, mas a aprovação final será sempre humana.

## Skills

O kit traz 10 skills. Três são **internas do pipeline** (acionadas pelos comandos/agentes —
você raramente chama à mão), três são **standalone** (uso direto, independentes do pipeline)
e quatro são skills de **documentação sob demanda** (invocadas via `/documentation`):

| Skill | Tipo | O que faz |
| ----- | ---- | --------- |
| `meta-prompt` | interna | Gera prompt estruturado para transferência de contexto entre agentes |
| `workflow-orchestrator` | interna | Lógica de transição entre as fases do `/workflow` |
| `checkpoint-validator` | interna | Valida artefatos e apresenta os gates `yes/no/edit` |
| `bug-tracker` | standalone | Audita commits recentes em busca de bugs e gera plano de correção priorizado |
| `microservices-analyzer` | standalone | Análise de arquitetura a partir do repo: diagramas C4, catálogo de serviços, matriz de dependências |
| `playwright-e2e-testing` | standalone | Guia e padrões de testes E2E com Playwright (usado pelo `/e2e`) |
| `doc-technical` | documentação, sob demanda | Gera documentação técnica em `docs/technical/` |
| `doc-functional` | documentação, sob demanda | Gera documentação funcional em `docs/functional/` |
| `doc-test-plan` | documentação, sob demanda | Gera cadernos de testes em `docs/test-plans/` |
| `doc-api` | documentação, sob demanda | Gera documentação de API em `docs/api/` |

Cada skill é uma pasta `skills/<nome>/SKILL.md`. As de documentação disparam via
`/documentation <tipo>` ou pela descrição da tarefa; as standalone disparam pela descrição
(ou podem ser invocadas explicitamente); as internas são acionadas pelo próprio pipeline.

> As standalone (`bug-tracker`, `microservices-analyzer`, `playwright-e2e-testing`) não têm
> relação com o pipeline PRD→Plan — são ferramentas avulsas que vêm no kit e funcionam em
> qualquer projeto.

## Configuração

### config.json

```json
{
  "defaults": {
    "retry_attempts": 3,
    "retry_backoff_ms": 500,
    "rate_limit_delay_ms": 500
  },
  "hooks": {
    "enabled": false
  }
}
```

### Issue Tracker (opcional)

A integração com um issue tracker é **opcional e configurável**. Se você usar um
(Linear, Jira, GitHub Issues, etc.), configure as credenciais e os identificadores
do projeto conforme o provedor escolhido, por exemplo:

```json
{
  "provider": "linear",
  "teamId": "<seu-team-id>",
  "projectId": "<seu-project-id>"
}
```

Sem tracker configurado, o pipeline funciona normalmente — as "issues" ficam apenas
nos artefatos locais (Plan + issues-manifest.json) com IDs placeholder.

## Exemplos Práticos

### Exemplo 1: Feature do Zero (Passo a Passo Completo)

```bash
# ═══════════════════════════════════════════════════════════════════
# FASE 1: Iniciar Pipeline
# ═══════════════════════════════════════════════════════════════════

/workflow

# Claude: "Qual é a ideia da feature?"
# Você: "Sistema de notificações por e-mail para avisar usuários sobre novidades"

# ═══════════════════════════════════════════════════════════════════
# FASE 2: PRD (Automático)
# ═══════════════════════════════════════════════════════════════════

# → Agent prd-writer cria PRD em docs/prds/2025_01_01-notificacoes-email.md
# → Checkpoint: "PRD criado. Aprovar? [sim/não/editar]"
# Você: "sim"

# ═══════════════════════════════════════════════════════════════════
# FASE 3: Review do PRD (Automático)
# ═══════════════════════════════════════════════════════════════════

# → Agent prd-reviewer refina o PRD
# → Checkpoint: "PRD revisado. Aprovar? [sim/não/editar]"
# Você: "sim"

# ═══════════════════════════════════════════════════════════════════
# FASE 4: Implementation Plan (Automático)
# ═══════════════════════════════════════════════════════════════════

# → Agent plan-architect decompõe em tasks técnicas
# → Cada task tem TC-* (casos de teste imutáveis)
# → Checkpoint: "Plan criado com 8 tasks. Aprovar? [sim/não/editar]"
# Você: "sim"

# ═══════════════════════════════════════════════════════════════════
# FASE DE ISSUE TRACKER (opcional, não incluída)
# ═══════════════════════════════════════════════════════════════════

# O pipeline NÃO cria issues. As 8 tasks já estão no Plan e no
# issues-manifest.json local, com IDs placeholder (ex: ABC-201 a ABC-208).
# Se você adotar um provider (GitHub Issues, Jira, Linear, etc.), pluga aqui
# o passo de criação de issues — um agente/comando específico do provider.

# ═══════════════════════════════════════════════════════════════════
# FASE 5: Execução (Você Invoca)
# ═══════════════════════════════════════════════════════════════════

# Executa as tasks do Plan na ordem de dependência:
/develop --all          # ou /develop pra uma task por vez

# Por baixo, para cada task o developer:
# 1. Lê a task do Plan (excerpt) + TC-*
# 2. Gera testes com /test-write (TDD: falham primeiro)
# 3. Implementa até os testes passarem
# 4. Submete ao code-reviewer (sessão isolada); se FAIL, corrige (até 3x)
# 5. Deixa staged — /develop commita por task (em --all) ou você commita

# /develop grava progresso em dev-status.json → retome com /develop --status
git diff --staged

# ═══════════════════════════════════════════════════════════════════
# FASE 6: Tech Lead Review (Manual)
# ═══════════════════════════════════════════════════════════════════

# Criar PR (manual ou futuro automático)
git push origin feat/notifications
gh pr create --title "feat: email notifications [ABC-201]"

# Tech Lead revisa PR
# Após merge → Tech Lead move issue para "Done" no tracker
```

### Exemplo 2: Apenas PRD

```bash
/prd-write "Integração com um serviço externo de pagamentos"

# Resultado: docs/prds/2025_01_01-integracao-pagamentos.md
```

### Exemplo 3: Plan de PRD Existente

```bash
/plan-create --prd=docs/prds/2025_01_01-notificacoes.md

# Resultado: docs/plans/2025_01_02-notificacoes-plan.md
```

### Exemplo 4: Gerar Testes de uma Task

```bash
# A task ABC-123 tem TC-* cases definidos
/test-write ABC-123

# Resultado: arquivo .spec.ts gerado com testes 1:1
# Cada TC-* vira um it() com comentário de referência
```

## Requisitos

### Obrigatórios

- Nenhum requisito externo obrigatório. O code review é feito pelo agent
  **code-reviewer** em sessão isolada (nativo do Claude Code).

### Opcionais

- **Issue tracker** (GitHub Issues, Jira, Linear, etc.) — extensão opcional, não
  incluída: ao adotar um provider, você pluga o passo de criação de issues e a
  gestão de status automática
- Hooks de segurança (delete 2FA)

## Hooks de Segurança

### Delete 2FA (PreToolUse)

O workflow inclui um hook de segurança que **bloqueia comandos destrutivos** até confirmação dupla:

**Comandos bloqueados**: `rm`, `rmdir`, `git rm`, `find -delete`, `git clean`

**Fluxo**:

```
1. Você ou agent tenta: rm -rf pasta/
2. Hook bloqueia e gera token único
3. Claude mostra: "⚠️ DELETE BLOCKED - Token: abc123"
4. Você confirma: "CONFIRMO DELETE"
5. Claude re-executa com: rm -rf pasta/ --confirm-delete=abc123
```

**Configuração** (`.claude/settings.json`):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/delete-2fa.sh"
          }
        ]
      }
    ]
  }
}
```

**Arquivos**:

- `.claude/hooks/delete-2fa.sh` - Script que analisa comandos
- `.claude/settings.json` - Configuração do hook

## Diretrizes para Tasks de Frontend/UI

Para o workflow ser mais autônomo em tarefas de UI/UX, as tasks precisam trazer informação específica:

### Checklist obrigatório para tasks de frontend

#### 1. Referência visual

- [ ] Screenshot ou link para um componente de referência já existente no sistema
- [ ] Se for um componente novo, mockup/wireframe ou descrição detalhada
- [ ] Referencie um componente existente pelo nome e onde ele já é usado

#### 2. Comportamento/UX

- [ ] Interações esperadas (click, hover, focus, etc.)
- [ ] Estados do componente (loading, disabled, error, empty)
- [ ] Exemplo: "O dropdown deve abrir ao clicar no input (onFocus), não só no ícone"

#### 3. Padrões visuais

- [ ] Cores específicas se diferentes do padrão
- [ ] Bordas, sombras, border-radius
- [ ] Espaçamento se for crítico
- [ ] Exemplo: "Tabela com zebra stripes, borda sutil e border-radius"

#### 4. Dados e opções

- [ ] Quais dados populam os dropdowns/selects
- [ ] Regras de filtragem (quais valores são válidos em cada contexto)
- [ ] Validações obrigatórias

#### 5. Critérios de aceite específicos

```markdown
## Critérios de Aceite

- [ ] Campo "Key" mostra: o conjunto de keys esperado para o contexto atual
- [ ] Campo "Value" mostra: os valores válidos para a key selecionada
- [ ] Inputs reutilizam o componente compartilhado existente (não um one-off)
- [ ] Dropdown abre ao clicar no input (não só no ícone)
- [ ] Tabela com cores de linha alternadas
- [ ] Container com borda e fundo sutil (padrão fieldset)
```

### Exemplo de task bem escrita

```markdown
## Título

[Frontend] Refatorar campos do diálogo para reusar o componente de dropdown compartilhado

## Descrição

Substituir os selects atuais do diálogo pelo componente de dropdown compartilhado já
existente, seguindo o padrão já usado em outras partes do app.

## Referência visual

- Componente: o componente de dropdown compartilhado existente
- Uso de referência: uma tela existente que já o utiliza
- Screenshot: [anexar imagem]

## Comportamento

- Clicar no input abre o dropdown automaticamente
- Seleção única permitida (max-selections=1)
- Campo "Value" permite input manual em alguns contextos, mas não em outros

## Dados

- Key: o conjunto de keys válido para o contexto atual
- Value: os valores válidos para a key selecionada
- Destino: os alvos disponíveis

## Padrão visual

- Container: fundo sutil, borda fina, cantos arredondados
- Tabela: zebra stripes, box-shadow sutil
- Header: fundo claro, texto em maiúsculas

## Critérios de Aceite

- [ ] Todos os campos reutilizam o componente de dropdown compartilhado
- [ ] Dropdown abre no focus do input
- [ ] Valores específicos de contexto aparecem só onde são válidos
- [ ] Layout segue o padrão de referência estabelecido
```

### Por que isso importa

Sem essa informação, o agente precisa:

1. Adivinhar qual componente usar → abordagem errada
2. Inferir comportamentos → iterações de correção
3. Escolher cores/estilos → ajustes manuais

Com especificação completa:

1. Implementação correta de primeira
2. Menos iterações de review
3. Workflow mais autônomo

## Troubleshooting

### Code Review

**"Review demorando muito"**:

- O code-reviewer faz uma análise profunda em sessão isolada
- É normal levar 1-3 minutos para reviews grandes
- Reviews muito grandes podem ser quebrados em partes menores

**"Review não rejeitou um problema óbvio"**:

- Garanta que o diff e os TC-* foram passados no prompt do code-reviewer
- Inclua o CLAUDE.md / convenções do projeto no contexto da revisão

### Issue Tracker

**"Erro ao acessar o tracker"**:

- Verifique a configuração e as credenciais do provedor escolhido
- Teste a conexão de forma independente (CLI/API do provedor)

**"Issue not found ABC-123"**:

- A issue existe no tracker?
- Está no projeto correto?
- O prefixo do ID está correto para o seu projeto?

**"Developer não move status"**:

- Verifique se o issue ID está no formato esperado (ex: `ABC-123`)
- O Developer só move status se houver um tracker configurado e detectar o padrão de ID

### Pipeline

**"Checkpoint travou"**:

- Responda explicitamente: "sim", "não", ou "editar"
- Se editar, faça as mudanças e re-execute o comando da fase

**"Agent falhou no meio"**:

- Verifique `.claude/orchestrator/pipelines/{id}/pipeline-state.json`
- Re-execute com `/workflow --from={fase}` para continuar de onde parou

**"TC-\* estão errados"**:

- TC-\* são **imutáveis** na Issue
- Volte ao Plan, corrija lá, e re-crie a Issue
- Developer não pode modificar TC-\*

### Hooks

**"Delete 2FA não bloqueia"**:

```bash
# Verificar se hook está configurado
cat .claude/settings.json | grep -A5 PreToolUse

# Verificar se script existe e é executável
ls -la .claude/hooks/delete-2fa.sh
```

**"Hook bloqueia tudo"**:

- Verifique regex no script delete-2fa.sh
- Comandos como `ls`, `cat` não devem ser bloqueados

## Economia de Tokens

| Fase                     | Consumo            |
| ------------------------ | ------------------ |
| PRD Write                | ~5-8k tokens       |
| PRD Review               | ~3-5k tokens       |
| Plan Create              | ~8-12k tokens      |
| Developer (per task)     | ~3-5k tokens       |
| **Code Review**          | ~3-6k tokens       |

⭐ Cada agent recebe só o contexto necessário, não todo o histórico

**Total**: ~40-50% economia vs passar docs completos repetidamente

## Princípios da Arquitetura

1. **Standalone First** - Todos os comandos funcionam isoladamente
2. **Checkpoints Obrigatórios** - Aprovação humana entre fases (exceto --yolo)
3. **Isolamento de Contexto** - Code review em sessão separada, sem viés do implementador
4. **Economia de Tokens** - Developer lê apenas excerpt do Plan (~500-800 tokens)
5. **TC-\* Imutáveis** - Casos de teste definidos no Plan, copiados verbatim para a task, geram testes 1:1
6. **Meta-Prompt Obrigatório** - Transferência de contexto entre agents via prompt estruturado
7. **Resilience Loop** - Developer itera até 3x com feedback do review antes de escalar
8. **Status Management (opcional)** - Developer atualiza status no tracker automaticamente (exceto Done)
9. **Output Mode** - Quiet por padrão, verbose com `--verbose`

## Cenários de Uso

### Autônomo (Pipeline Completo)

```bash
/workflow "Sistema de notificações por e-mail"
# → PRD criado e aprovado
# → PRD revisado e aprovado
# → Plan criado com TC-* cases e aprovado
# → /develop executa as tasks do Plan na ordem de dependência
```

### Semi-Autônomo (Fase Específica)

```bash
# Já tenho PRD, quero só o Plan
/plan-create --prd=docs/prds/meu-prd.md

# Já tenho uma task, quero só gerar testes
/test-write ABC-123
```

### Manual (Comando Isolado)

```bash
# Criar PRD standalone
/prd-write "Minha ideia"

# Revisar PRD standalone
/prd-review docs/prds/draft.md

# Gerar prompt para outra LLM
/meta-prompt --task="review" --artifacts="file.ts"
```

## Output Mode

**Default: Quiet mode** - Output mínimo para economizar tokens.

### Quiet Mode (default)

```
[Phase 1/4] PRD Creation
✓ PRD created: docs/prds/2025_01_01-notifications.md

Approve PRD? [yes/no/edit]: yes

[Phase 2/4] PRD Review
✓ PRD refined

Approve? [yes/no/edit]: yes

[Phase 3/4] Implementation Plan
✓ Plan created with 8 tasks

Approve? [yes/no/edit]: yes

[Phase 4/4] Execution
✓ Tasks ready in Plan + issues-manifest.json (placeholder IDs)

Pipeline complete.
```

### Verbose Mode (`--verbose`)

Use quando precisar de detalhes:
- Primeira execução do pipeline
- Debug de falhas
- Entender o que os agents estão fazendo

```bash
/workflow --verbose            # Output completo
/workflow --verbose --yolo     # Combinável com outras flags
```

Output inclui: prompts gerados, respostas dos agents, paths de arquivos, timing.

## Próximos Passos

1. ✅ MVP implementado
2. ✅ Code review em sessão isolada documentado
3. ✅ Sistema de Casos de Teste Imutáveis (TC-*)
4. ✅ Meta-Prompt Layer
5. ✅ Resilience Loop
6. ✅ Status Management (opcional)
7. ✅ Output Mode (quiet/verbose)
8. ⏳ Testar pipeline completo com feature piloto
9. ⏳ Validar fluxo de review em produção

## Referência Rápida de Comandos

### Pipeline Completo

```bash
/workflow                      # Interativo - pergunta a ideia
/workflow "minha feature"      # Direto com ideia
/workflow --yolo               # Sem checkpoints (auto-aprova tudo)
/workflow --verbose            # Output detalhado (debug)
/workflow --from=plan          # Começa da fase Plan
```

### Comandos Individuais

```bash
/prd-write "ideia"                # Cria PRD
/prd-review path/to/prd.md        # Revisa PRD existente
/plan-create --prd=path.md        # Cria Plan de PRD
/develop --all                    # Executa as tasks do Plan (DAG)
/develop --status                 # Progresso da execução
/test-write --plan=path.md --task=task-1-2-abc   # Gera testes 1:1 dos TC-*
/meta-prompt --task=review        # Gera prompt estruturado
```

### Invocar Agents Diretamente

```bash
# Via Task tool (dentro de uma sessão Claude)
Task(subagent_type="developer", prompt="Implementar ABC-123")
Task(subagent_type="prd-writer", prompt="Feature de notificações")
Task(subagent_type="code-reviewer", prompt="Revisar changes staged do ABC-123 (diff + critérios + TC-*)")
```

## FAQ

**Q: Posso usar só uma parte do workflow?**
A: Sim! Todos os comandos são standalone. Use `/prd-write` só para criar PRD, `/plan-create` só para criar Plan, etc.

**Q: O que acontece se eu rejeitar um checkpoint?**
A: O pipeline para. Você pode editar o artefato manualmente e re-executar a fase.

**Q: O Developer commita automaticamente?**
A: Não. Ele faz `git add` (stage) e aguarda você revisar e commitar.

**Q: Por que rodar o code review em sessão isolada?**
A: Para evitar viés. A sessão que implementou o código pode ter "ponto cego". O code-reviewer começa com contexto limpo e revisa com olhar fresco.

**Q: O que é TC-\* ?**
A: Test Cases definidos no Plan e copiados para a Issue. Cada TC-\* vira um teste automatizado 1:1. São **imutáveis** - se estiverem errados, volte ao Plan.

**Q: O Developer move issue para Done?**
A: Não. Ele move para "In Review" (se houver tracker configurado). O Tech Lead move para "Done" após aprovar o PR.
