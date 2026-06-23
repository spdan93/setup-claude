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

# Linka a epic existente
/workflow ABC-123
```

**O que acontece**:

1. **PRD Write** → você descreve a ideia, agent cria PRD → checkpoint (você aprova)
2. **PRD Review** → agent revisa e refina → checkpoint (você aprova)
3. **Plan Create** → agent decompõe em tasks técnicas → checkpoint (você aprova)
4. **Execution** → você ou agents implementam as tasks

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

### 3. Implementar Task Específica

```bash
# Developer pega a task e implementa
Task(subagent_type="developer", prompt="Implementar ABC-123")
```

**O que o developer faz**:

1. Lê issue do tracker (critérios de aceite + **TC-\* casos de teste**)
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
├── agents/                 # Agents que rodam em sessões isoladas
│   ├── prd-writer.md      # Cria PRD de ideia
│   ├── prd-reviewer.md    # Revisa PRD draft
│   ├── plan-architect.md  # Decompõe PRD em tasks
│   ├── developer.md       # Implementa código
│   └── code-reviewer.md   # Review em sessão isolada
│
├── skills/                 # Skills usadas internamente
│   ├── workflow-orchestrator.md    # Transições do pipeline
│   ├── checkpoint-validator.md     # Gates de aprovação
│   └── meta-prompt.md              # Gera prompts para transferência entre agents
│
├── commands/               # Comandos que você chama
│   ├── workflow.md        # Pipeline completo
│   ├── prd-write.md       # Criar PRD
│   ├── prd-review.md      # Revisar PRD
│   ├── plan-create.md     # Criar Plan
│   ├── test-write.md      # Gerar testes 1:1 de TC-* cases
│   └── meta-prompt.md     # Gerar prompt estruturado manualmente
│
└── orchestrator/
    ├── config.json         # Thresholds, defaults
    ├── README.md           # User guide detalhado
    └── pipelines/          # Estado de cada pipeline
        └── {pipeline_id}/
            ├── pipeline-state.json
            └── issues-manifest.json
```

## Artefatos Gerados

```
docs/
├── prds/
│   └── YYYY_MM_DD-{pipeline_id}.md          # PRD oficial
└── plans/
    └── YYYY_MM_DD-{pipeline_id}-plan.md     # Implementation Plan

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

### Configuração de Modelos

O modelo de cada agent é definido no **frontmatter YAML** do arquivo `.claude/agents/*.md`:

```yaml
# .claude/agents/developer.md
---
name: developer
description: Implements tasks from tracker issues...
model: sonnet # ← MODELO DEFINIDO AQUI
template_version: '1.0'
allowed_tools: [Read, Write, Edit, ...]
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
# FASE 5: Implementação (Você Invoca)
# ═══════════════════════════════════════════════════════════════════

# Implementar primeira task
Task(subagent_type="developer", prompt="Implementar ABC-201")

# O Developer agent:
# 1. Lê a task ABC-201 (do Plan ou do tracker, se configurado)
# 2. Move status para "In Progress" (se houver tracker)
# 3. Lê excerpt do Plan
# 4. Gera testes com /test-write
# 5. Implementa código
# 6. Submete para o code-reviewer (sessão isolada)
# 7. Se review rejeitar → corrige (até 3x)
# 8. Após aprovação → move para "In Review" (se configurado)
# 9. Faz git add (staged)

# Você revisa e commita:
git diff --staged
git commit -m "feat(notifications): implement email notification service [ABC-201]"

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

## Frontend/UI Issue Guidelines

For the workflow to be more autonomous on UI/UX tasks, issues must include specific information:

### Required Checklist for Frontend Issues

#### 1. Visual Reference

- [ ] Screenshot or link to an existing reference component in the system
- [ ] If a new component, mockup/wireframe or detailed description
- [ ] Reference an existing component by name and where it is already used

#### 2. Behavior/UX

- [ ] Expected interactions (click, hover, focus, etc.)
- [ ] Component states (loading, disabled, error, empty)
- [ ] Example: "Dropdown should open on input click (onFocus), not just on icon"

#### 3. Visual Patterns

- [ ] Specific colors if different from default
- [ ] Borders, shadows, border-radius
- [ ] Spacing if critical
- [ ] Example: "Table with zebra stripes, subtle border and border-radius"

#### 4. Data and Options

- [ ] What data populates dropdowns/selects
- [ ] Filtering rules (which values are valid in which context)
- [ ] Required validations

#### 5. Specific Acceptance Criteria

```markdown
## Acceptance Criteria

- [ ] "Key" field shows: the expected set of keys for the current context
- [ ] "Value" field shows: the values valid for the selected key
- [ ] Inputs reuse the existing shared component (not a one-off)
- [ ] Dropdown opens on input click (not just on icon)
- [ ] Table with alternating row colors
- [ ] Container with border and subtle background (fieldset pattern)
```

### Well-Written Issue Example

```markdown
## Title

[Frontend] Refactor dialog fields to reuse the shared dropdown component

## Description

Replace the current selects in the dialog with the existing shared dropdown
component, following the pattern already used elsewhere in the app.

## Visual Reference

- Component: the existing shared dropdown component
- Reference usage: an existing screen that already uses it
- Screenshot: [attach image]

## Behavior

- Click on input opens dropdown automatically
- Single selection allowed (max-selections=1)
- "Value" field allows manual input in some contexts, but not others

## Data

- Key: the set of keys valid for the current context
- Value: the values valid for the selected key
- Destination: the available targets

## Visual Pattern

- Container: subtle background, thin border, rounded corners
- Table: zebra stripes, subtle box-shadow
- Header: light background, uppercase text

## Acceptance Criteria

- [ ] All fields reuse the shared dropdown component
- [ ] Dropdown opens on input focus
- [ ] Context-specific values appear only where valid
- [ ] Layout follows the established reference pattern
```

### Why This Matters

Without this information, the agent needs to:

1. Guess which component to use → wrong approach
2. Infer behaviors → correction iterations
3. Choose colors/styles → manual adjustments

With complete specification:

1. Correct implementation on first attempt
2. Fewer review iterations
3. More autonomous workflow

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
# → Developer pega as tasks do Plan e implementa
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
/workflow ABC-123              # Linka a epic existente
```

### Comandos Individuais

```bash
/prd-write "ideia"                # Cria PRD
/prd-review path/to/prd.md        # Revisa PRD existente
/plan-create --prd=path.md        # Cria Plan de PRD
/test-write ABC-123               # Gera testes da task
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
