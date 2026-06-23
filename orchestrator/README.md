# Claude Orchestrator - Workflow Automation

Sistema de automação de pipeline para desenvolvimento: Ideia → PRD → Plan → Código.

## Uso Rápido

### Pipeline Completo
```bash
/workflow                      # Inicia pipeline do zero
/workflow <ISSUE-ID>           # Linka a uma epic existente no tracker (se configurado)
/workflow --yolo               # Modo autônomo (sem checkpoints)
```

### Comandos Standalone

```bash
# Criar PRD
/prd-write "Adicionar login via Google"

# Revisar PRD
/prd-review docs/prds/2026_01_27-feature.md

# Criar Implementation Plan
/plan-create --prd=docs/prds/2026_01_27-feature.md
```

## Pipeline de Fases

```
┌─────────────┐
│  PRD Write  │ → prd-writer agent (opus)
└─────────────┘
      ↓
┌─────────────┐
│ PRD Review  │ → prd-reviewer agent (sonnet)
└─────────────┘
      ↓
┌─────────────┐
│    Plan     │ → plan-architect agent (opus)
└─────────────┘
      ↓
┌ ─ ─ ─ ─ ─ ─ ┐
   Issues        (opcional / não incluída) → plugue um provider aqui
└ ─ ─ ─ ─ ─ ─ ┘
      ↓
┌─────────────┐
│  Execution  │ → developer agent (opus) per task
└─────────────┘
      ↓
┌─────────────┐
│Code Review  │ → code-reviewer agent (sessão isolada, sem viés)
└─────────────┘
```

> **Fase de Issue Tracker (opcional, não incluída)**: hoje o pipeline não cria
> issues. Quando você adotar um provider (GitHub Issues, Jira, Linear, etc.),
> pluga aqui o passo de criação de issues — um agente/comando específico do
> provider. O pipeline funciona ponta a ponta sem essa fase: o Plan + o
> `issues-manifest.json` local já guardam as tasks com IDs placeholder.

## Agents

| Agent | Modelo | Propósito | Invocado por |
|-------|--------|-----------|--------------|
| `prd-writer` | opus | Criar PRD de ideia | `/prd-write` |
| `prd-reviewer` | sonnet | Revisar PRD draft | `/prd-review` |
| `plan-architect` | opus | Criar Implementation Plan | `/plan-create` |
| `developer` | opus (default) | Implementar task | Manual ou automação |
| `code-reviewer` | sonnet | Review nativo em sessão isolada (sem viés de implementação) | `developer` (Task tool) |

## Skills

| Skill | Propósito | Invocado por |
|-------|-----------|--------------|
| `workflow-orchestrator` | Lógica de transição entre fases | `/workflow` |
| `checkpoint-validator` | Validar gates antes de avançar | `/workflow` |
| `meta-prompt` | Gera prompts estruturados para transferência entre agents | `/workflow`, `developer` |

## Meta-Prompt

**Regra obrigatória**: Sempre que contexto precisar ser transferido entre agents, usar `meta-prompt` skill.

**Pontos de integração**:
- `/workflow` → antes de chamar qualquer agent
- `developer` → antes de invocar `code-reviewer`

**Uso manual**:
```bash
/meta-prompt --task="review" --artifacts="src/file.ts" --output="code review"
```

**Output**: Prompt estruturado em inglês com seções padronizadas (Objective, Context, Artifacts, Constraints, Instructions, Acceptance Criteria, Non-goals).

## Artefatos Gerados

```
docs/
├── prds/
│   └── YYYY_MM_DD-{pipeline_id}.md          # PRD oficial
└── plans/
    └── YYYY_MM_DD-{pipeline_id}-plan.md     # Implementation Plan

.claude/orchestrator/pipelines/{pipeline_id}/
├── pipeline-state.json                       # Estado do pipeline
└── issues-manifest.json                      # Mapping tasks ↔ tracker (se configurado)
```

## Configuração

`.claude/orchestrator/config.json`:
```json
{
  "defaults": {
    "retry_attempts": 3,
    "retry_backoff_ms": 500,
    "rate_limit_delay_ms": 500
  }
}
```

## Issue Tracker (opcional, não incluída)

A fase de Issue Tracker é **opcional e não vem incluída**. Hoje o pipeline não cria
issues: ele funciona ponta a ponta direto do Plan, com as tasks guardadas no Plan e no
`issues-manifest.json` local (IDs placeholder). Quando você adotar um provider
(GitHub Issues, Jira, Linear, etc.), pluga aqui o passo de criação de issues — um
agente/comando específico do provider. Com tracker configurado, os IDs de issue
aparecem como `<ISSUE-ID>` nos artefatos.

## Princípios

1. **Standalone First**: Todos os comandos funcionam isoladamente
2. **Checkpoints obrigatórios**: Aprovação humana entre fases (exceto --yolo)
3. **Isolamento de contexto**: Code review em sessão separada (sem viés de implementação)
4. **Economia de tokens**: Developer lê apenas excerpt do Plan (~500-800 tokens)
5. **Meta-Prompt obrigatório**: Transferência de contexto entre agents via `meta-prompt` skill

## Próximos Passos

1. Testar pipeline completo com feature piloto
2. Criar CLAUDE.md específicos por área do projeto (se aplicável)
3. **Hooks** (pós-MVP): Sistema foi projetado mas scripts não implementados ainda
   - `.claude/orchestrator/hooks/` existe mas está vazio
   - `config.json` tem `hooks.enabled: false` por padrão
   - Implementar quando pipeline estabilizar: preview-issues.sh, validate-manifest.sh
4. Automatizar execução de developer agents

## Referências

- **Sistema de Casos de Teste Imutáveis (TC-*)**: testes derivados de casos de teste fixos no Plan
- **Meta-Prompt Layer**: transferência de contexto padronizada entre agents
- **Code Review nativo**: realizado pelo `code-reviewer` agent em sessão isolada
