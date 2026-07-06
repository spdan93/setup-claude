# Instalação

Kit `.claude` agnóstico — pipeline **PRD → Plan → Execução**, comandos, agentes, skills,
hook de segurança (delete-2FA) e statusline. Funciona em qualquer projeto e qualquer stack.
As regras específicas de stack ficam no `CLAUDE.md` de cada projeto (o kit **defere** a elas).

---

## No fundo, instalar é copiar 4 coisas

Toda a instalação — script, manual ou por agente — faz **exatamente isto**:

1. **Tudo, menos `statusline/`** → `<repo>/.claude/`
   (`agents/ commands/ skills/ hooks/ orchestrator/ templates/`, os docs e os dois `settings*.json`)
2. **`statusline/`** → `~/.claude/statusline/` (nível de usuário — a mesma em todo projeto)
3. **Dois blocos de JSON**: o `hooks` no `settings.json` do **projeto**, o `statusLine` no
   `settings.json` do **usuário** (`~/.claude`)
4. **`.claude/`** entra no `.gitignore` do repo (é tooling local, não vai pro git)

> **Docs duráveis** (PRDs, plans, changelog, documentação) ficam **fora** do `.claude`, em
> `<repo>/docs/` — versionados normalmente.

Os instaladores (`install.sh` / `install.ps1`) só automatizam esses 4 passos e ainda dão
robustez: idempotência, **merge não-destrutivo** do `settings.json`, prune por manifest no
update e carimbo de versão. Se preferir, dá pra fazer os 4 passos na mão (ver **Modo 2**).

---

## Modo 1 — Script (recomendado)

**macOS / Linux:**
```bash
bash /caminho/do/kit/install.sh .          # híbrido no repo atual
bash /caminho/do/kit/install.sh ~/projeto  # híbrido em outro repo
bash /caminho/do/kit/install.sh ~/         # "global": tudo em ~/.claude (sem split)
```

**Windows** (roda no **Windows PowerShell 5.1 nativo** — não precisa instalar o PowerShell 7):
```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 .        # híbrido no repo atual
powershell -ExecutionPolicy Bypass -File .\install.ps1 C:\repo  # outro repo
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Global  # tudo em ~/.claude
```

O instalador é **idempotente** e **não destrutivo**: copia os arquivos, dá `+x` nos scripts,
detecta o SO, faz **merge** do `settings.json` (hook no projeto, statusline no usuário) e
adiciona `.claude/` ao `.gitignore` — **sem apagar** o que você já tinha. Rodar 2× não duplica.

Se você **já tiver** uma `statusLine` no `~/.claude`, ele **pergunta** se quer substituir
(`[y/N]`). Em modo não-interativo (agente/CI) mantém a sua — use `FORCE_STATUSLINE=1` (bash)
pra substituir sem perguntar. `CLAUDE_CONFIG_DIR=<dir>` muda o destino de usuário.

> Tem `pwsh` (PowerShell 7)? Pode usar no lugar de `powershell` — o instalador detecta qual
> você tem e liga a statusline com o interpretador certo. **Ressalva:** o hook delete-2FA é
> bash — no Windows ele só dispara se houver um bash (Git Bash) disponível; o resto funciona sem.

---

## Modo 2 — Por agente de IA / manual (copy-paste, sem script)

A instalação é simples o bastante pra um agente (ou você) fazer na mão, **sem `jq` e sem
PowerShell** — o LLM lê o `settings.json` que existir e faz o merge sozinho. Cole a instrução
abaixo pro seu agente, trocando `<REPO>` pelo caminho do projeto:

> **Instale o kit `.claude` no repositório `<REPO>`:**
>
> 1. Copie, do kit, tudo **menos** `statusline/`, `install.sh`, `install.ps1` e `.kit-manifest`
>    para `<REPO>/.claude/` — ou seja: `agents/ commands/ skills/ hooks/ orchestrator/
>    templates/`, os `.md` de doc e `settings.json` + `settings.local.json`. Não sobrescreva
>    um `settings.json` que já exista: faça **merge** (passo 3).
> 2. Copie `statusline/` para `~/.claude/statusline/`. Em macOS/Linux dê
>    `chmod +x ~/.claude/statusline/*.sh`.
> 3. **Merge de dois blocos** (leia o arquivo, junte as chaves, não substitua o arquivo):
>    - Em **`<REPO>/.claude/settings.json`**, garanta o bloco `hooks` abaixo.
>    - Em **`~/.claude/settings.json`**, garanta o bloco `statusLine` do seu SO abaixo.
> 4. Adicione a linha `.claude/` ao `<REPO>/.gitignore` (se ainda não estiver lá).
> 5. Confirme: `<REPO>/.claude/settings.json` tem o hook `delete-2fa.sh`; `~/.claude/settings.json`
>    tem a `statusLine`; `.gitignore` tem `.claude/`.

**Bloco 1 — hook (em `<REPO>/.claude/settings.json`):**
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/delete-2fa.sh", "timeout": 10 }
        ]
      }
    ]
  }
}
```

**Bloco 2 — statusline (em `~/.claude/settings.json`), escolha a linha do seu SO:**
```jsonc
{
  "statusLine": {
    "type": "command",
    // macOS:
    "command": "bash \"$HOME/.claude/statusline/statusline-command-macos.sh\""
    // Linux:   "command": "bash \"$HOME/.claude/statusline/statusline-command-linux.sh\""
    // Windows: "command": "powershell -NoProfile -File \"%USERPROFILE%\\.claude\\statusline\\statusline-command-windows.ps1\""
  }
}
```

> O `settings.local.json` (allowlist de permissões) é copiado junto e é opcional — ajuste à
> vontade. O merge manual não faz prune no update; se quiser esse controle, use o **Modo 1**.

---

## Onde cada coisa fica

| Peça | Nível | Caminho |
|------|-------|---------|
| Statusline | **usuário** | `~/.claude/statusline/` + `statusLine` em `~/.claude/settings.json` |
| Comandos, agentes, skills, templates | **projeto** | `<repo>/.claude/{commands,agents,skills,templates}/` (inclui `skills/doc-*`) |
| Hook delete-2FA | **projeto** | `<repo>/.claude/hooks/` + `hooks` em `<repo>/.claude/settings.json` |
| Estado do pipeline | **projeto** | `<repo>/.claude/orchestrator/pipelines/` (efêmero, gitignored) |
| PRDs / Plans / changelog / docs | **repo (versionado)** | `<repo>/docs/...` — **fora** do `.claude` |

---

## Instalar do GitHub / Atualizar

O kit é distribuído como repositório git. Clone uma vez num lugar estável e instale nos
projetos a partir dele.

**Instalar**
```bash
git clone https://github.com/<voce>/setup-claude ~/.claude-kit
~/.claude-kit/install.sh /caminho/do/projeto
```

**Atualizar**
```bash
git -C ~/.claude-kit pull                       # baixa a versão nova
~/.claude-kit/install.sh /caminho/do/projeto    # re-aplica (projeto + statusline)
```

No update, o `install.sh` copia os arquivos novos, faz **prune** (via `.kit-manifest`) dos que
saíram do kit — **sem tocar** no que você criou dentro do `.claude` —, preserva seu
`settings.json`/`settings.local.json` e sua statusline, e carimba a versão em
`.claude/.kit-version` (`cat` pra ver qual está instalada).

> Versionamento vem do arquivo `VERSION` (+ short SHA do git). Marque releases com `git tag v1.2.0`.

---

## Dependências

| Peça | Precisa de |
|------|-----------|
| `install.sh` (merge do settings, mac/linux) | `jq` |
| `install.ps1` (Windows) | **nada além do PowerShell 5.1** (JSON nativo — sem `jq`) |
| Modo 2 (manual / por agente) | nada (o LLM/você faz o merge do JSON) |
| Statusline (mac/linux) | `git`, `bc` (e `jq` pro render) |
| Statusline (windows) | **PowerShell 5.1+**, `git` (sem `jq`) |
| Comandos de build/test | o que o projeto usa (npm/pnpm/etc.) |

---

## CLAUDE.md por projeto (importante)

Os agentes (`developer`, `plan-architect`...) **não assumem stack** — leem as regras do
`CLAUDE.md` do projeto (design system, i18n, isolamento de dados, padrões de teste, branch
padrão, etc.). Crie/edite o seu com:

```bash
/claude-md create        # ou: /claude-md edit ./CLAUDE.md
```

---

## Peças opt-in / opcionais

- **Issue tracker** — não incluído. O pipeline roda end-to-end sem ele (tasks vêm do Plan).
  Ao adotar GitHub Issues/Jira/Linear, pluga um passo de criação de issues entre Plan e
  Execução (ver `README.md` › "Issue Tracker").
- **E2E de browser** (`/e2e`) — precisa de um agente de automação (skill `playwright-e2e-testing`
  ou MCP Playwright).
- **Comandos opinativos** (`/commit`, `/ship`, `/documentation`) — assumem corpo de commit em
  5 seções + changelog. Ajuste se não servir o projeto.

> **Commit nunca é automático (regra de ouro):** nenhum comando ou agente do kit faz `git commit`
> por conta própria. Commit só acontece quando **você** pede — via `/commit` ou instrução direta.
> O `/develop` implementa e faz `git add` (stage), mas **nunca** commita.

> **`.gitignore`:** como `.claude/` fica gitignored, os comandos/agentes desse projeto **não**
> são versionados (é tooling local por escolha). Os artefatos do trabalho (PRDs, plans, docs)
> **são** versionados, pois ficam em `docs/`.

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
    ├── README.md INSTALL.md USAGE.md CONVENTIONS.md
    ├── settings.json            # hook delete-2FA
    ├── settings.local.json      # allowlist de permissões
    ├── agents/  commands/  skills/  templates/
    ├── hooks/delete-2fa.sh
    └── orchestrator/            # config + estado do pipeline (efêmero)
```

---

## Próximos passos

- **[USAGE.md](USAGE.md)** — como usar cada comando e o workflow completo.
- **[CONVENTIONS.md](CONVENTIONS.md)** — nomes/formatos canônicos compartilhados.
- **[README.md](README.md)** — arquitetura e racional do pipeline.
