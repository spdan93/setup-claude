# Instalação

Kit `.claude` agnóstico — pipeline **PRD → Plan → Execução**, comandos, agentes, skills,
hook de segurança (delete-2FA) e statusline. Funciona em qualquer projeto, com qualquer
stack. As regras específicas de stack ficam no `CLAUDE.md` de cada projeto (este kit
**defere** a elas).

A instalação é **híbrida**:

- **Statusline → nível de usuário** (`~/.claude`) — a mesma em todos os projetos.
- **Comandos/agentes/skills/hook → nível de projeto** (`<repo>/.claude`) — locais ao repo.
- **`<repo>/.claude` entra no `.gitignore`** — é tooling local, não vai pro git.
- **Docs duráveis** (PRDs, plans, changelog) ficam **fora** do `.claude`, na **raiz do
  repo** em `docs/` — versionados normalmente.

---

## Instalação rápida (recomendada)

```bash
bash /caminho/do/kit/install.sh .          # híbrido no repo atual
bash /caminho/do/kit/install.sh ~/projeto  # híbrido em outro repo
bash /caminho/do/kit/install.sh ~/         # "global": tudo em ~/.claude (sem split)
```

O `install.sh` é **idempotente** e **não destrutivo**: copia os arquivos, dá `+x` nos
scripts, detecta o SO, faz **merge** do `settings.json` (hook no projeto, statusline no
usuário) e adiciona `.claude/` ao `.gitignore` do repo — **sem apagar** nada que você já
tinha. Rodar 2× não duplica nada.

Se você **já tiver** uma `statusLine` configurada no `~/.claude`, ele **pergunta** se quer
substituir (`[y/N]`). Em execução não-interativa (agente/CI) ele mantém a sua por
segurança — use `FORCE_STATUSLINE=1` pra substituir sem perguntar.

> **Variáveis**: `CLAUDE_CONFIG_DIR=<dir>` muda o destino de usuário (default `~/.claude`).
> **Windows**: use o instalador PowerShell (requer PowerShell 7+):
>
> ```powershell
> pwsh -File C:\caminho\do\kit\install.ps1 .        # híbrido no repo atual
> pwsh -File C:\caminho\do\kit\install.ps1 -Global  # tudo em ~/.claude (sem split)
> ```
>
> O `install.ps1` espelha o `install.sh` (híbrido, idempotente, merge não-destrutivo do
> `settings.json`, ask-before-replace da statusline, prune por manifest, version stamp).
> Ressalva: o hook **delete-2FA é bash** — no Windows ele só dispara se houver um bash
> (Git Bash) disponível pro Claude Code; o resto funciona sem bash.

---

## Instalar do GitHub / Atualizar

O kit é distribuído como um repositório git (fonte da verdade). Clone uma vez num lugar
estável e instale nos projetos a partir dele.

**Instalar**
```bash
git clone https://github.com/<voce>/setup-claude ~/.claude-kit
~/.claude-kit/install.sh /caminho/do/projeto
```

**Atualizar** (no futuro)
```bash
git -C ~/.claude-kit pull                       # baixa a versão nova do kit
~/.claude-kit/install.sh /caminho/do/projeto    # re-aplica (projeto + statusline user-level)
```

No update, o `install.sh`:
- copia os arquivos novos;
- faz **prune** (via `.kit-manifest`) dos arquivos que saíram do kit — **sem tocar** nos
  que você criou dentro do `.claude`;
- preserva seu `settings.json` / `settings.local.json` e sua statusline;
- carimba a versão instalada em `.claude/.kit-version`.

**Qual versão está instalada?**
```bash
cat /caminho/do/projeto/.claude/.kit-version
```

> Versionamento: vem do arquivo `VERSION` do kit (+ short SHA do git, se disponível).
> Marque releases com tags no repo: `git tag v1.1.0`.

---

## Onde cada coisa fica

| Peça | Nível | Caminho |
|------|-------|---------|
| Statusline | **usuário** | `~/.claude/statusline/` + `statusLine` em `~/.claude/settings.json` |
| Comandos, agentes, skills | **projeto** | `<repo>/.claude/{commands,agents,skills}/` (inclui `skills/doc-*`) |
| Hook delete-2FA | **projeto** | `<repo>/.claude/hooks/` + `hooks` em `<repo>/.claude/settings.json` |
| Estado do pipeline | **projeto** | `<repo>/.claude/orchestrator/pipelines/` (efêmero, gitignored) |
| PRDs / Plans / changelog / docs | **repo (versionado)** | `<repo>/docs/...` — **fora** do `.claude` |

---

## Para agentes de IA

Este kit pode ser instalado por um agente (ex.: Claude Code) de forma determinística e segura:

1. Rode o instalador apontando pro repo-alvo:
   ```bash
   bash <kit>/install.sh <repo-dir>
   ```
2. **Seguro pra agente**: nunca deleta (usa `cp`/`mv`/`jq`, sem `rm` — não dispara o hook
   delete-2FA), **não sobrescreve** `settings.json`/`settings.local.json` existentes (merge
   via `jq`), não duplica linhas no `.gitignore`, e é idempotente. Em modo não-interativo
   mantém a statusline existente.
3. Pré-requisito: `jq` (o script falha cedo com mensagem clara se faltar).
4. Verificação pós-instalação:
   ```bash
   jq '.hooks'      <repo-dir>/.claude/settings.json   # deve listar delete-2fa.sh
   jq '.statusLine' "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"  # statusline (user-level)
   grep -n '.claude/' <repo-dir>/.gitignore
   ```

---

## Dependências

| Peça | Precisa de |
|------|-----------|
| Hook delete-2FA / merge do settings | `jq` |
| Statusline (mac/linux) | `jq`, `git`, `bc` |
| Statusline (windows) | PowerShell 7+, `git` |
| Comandos de build/test | o que o projeto usa (npm/pnpm/etc.) |

---

## CLAUDE.md por projeto (importante)

Os agentes (`developer`, `plan-architect`...) **não assumem stack** — eles leem as regras
do `CLAUDE.md` do projeto (design system, i18n, isolamento de dados, padrões de teste,
branch padrão, etc.). Crie/edite o seu com:

```bash
/claude-md create        # ou: /claude-md edit ./CLAUDE.md
```

---

## Peças opt-in / opcionais

- **Issue tracker** — não incluído. O pipeline roda end-to-end sem ele (tasks vêm do
  Plan). Quando adotar GitHub Issues/Jira/Linear, pluga um passo de criação de issues
  entre Plan e Execução (ver `README.md` › "Issue Tracker").
- **E2E de browser** (`/e2e`) — precisa de um agente de automação de browser
  (skill `playwright-e2e-testing` ou MCP Playwright).
- **Comandos opinativos** (`/commit`, `/ship`, `/documentation`) — assumem corpo de
  commit em 5 seções + changelog. Ajuste se não servir o projeto.

> **Nota sobre `.gitignore`**: como `.claude/` fica gitignored, os comandos/agentes desse
> projeto **não** são versionados nem compartilhados via git (é tooling local por escolha).
> Os artefatos do trabalho (PRDs, plans, docs) **são** versionados, pois ficam em `docs/`.

---

## Estrutura instalada

```
~/.claude/                       # NÍVEL DE USUÁRIO
└── statusline/                  # statusline mac/linux/windows + README
    └── (+ statusLine em ~/.claude/settings.json)

<repo>/                          # NÍVEL DE PROJETO (gitignored: .claude/)
├── .gitignore                   # ganha a linha ".claude/"
├── docs/                        # artefatos versionados (FORA do .claude)
│   ├── prds/        plans/      # PRDs e Implementation Plans
│   ├── changelog/               # entrada por commit (gerada pelo /commit)
│   ├── technical/  functional/  test-plans/  api/   # documentação sob demanda
│   └── test-evidence/
└── .claude/                     # tooling local (gitignored)
    ├── README.md INSTALL.md USAGE.md CONVENTIONS.md  install.sh · install.ps1
    ├── settings.json            # hook delete-2FA
    ├── settings.local.json      # allowlist de permissões
    ├── agents/  commands/  skills/
    ├── hooks/delete-2fa.sh
    └── orchestrator/            # config + estado do pipeline (efêmero)
```

---

## Próximos passos

- **[USAGE.md](USAGE.md)** — como usar cada comando e o workflow completo.
- **[CONVENTIONS.md](CONVENTIONS.md)** — nomes/formatos canônicos compartilhados.
- **[README.md](README.md)** — arquitetura e racional do pipeline.
