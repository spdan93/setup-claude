# Distribuição do kit via npm/npx — Documento de Arquitetura

> **Status:** ideia parada (2026-07-10). Documento para retomada futura.
> Não é um plano de implementação — é o desenho da melhor arquitetura possível
> para, quando quisermos, empacotar este kit e distribuí-lo via `npx`/`npm`
> com `install` e `update`.

---

## 1. Objetivo

Permitir instalar e atualizar o kit do Claude Code com um único comando, sem
clonar o repositório, funcionando igual em macOS, Linux e Windows:

```bash
npx <kit>            # instala no repo atual
npx <kit> update     # atualiza para a versão mais nova (idempotente)
```

## 2. Por que o npm encaixa neste kit (melhor do que o normal)

O contra-argumento clássico de "empacotar no npm" é *"exige Node instalado"*.
**Aqui esse argumento cai por terra:** o Claude Code **já é distribuído via npm**
(`npm install -g @anthropic-ai/claude-code`). Todo mundo que instala este kit
**já tem Node e npm**. A dependência que "adicionaríamos" já está garantida.

Ganho principal — um instalador em Node **elimina a saga de portabilidade** que
já enfrentamos:

| Dor atual (bash/powershell) | Com instalador em Node |
|---|---|
| `install.sh` + `install.ps1` mantidos em paralelo | **um script só** |
| Fallback `jq → python3 → awk` pra mesclar JSON | `JSON.parse`/`stringify` nativo |
| Inferno de ASCII no PowerShell 5.1 (CP1252) | Node não tem esse problema |
| `stat -f` (BSD) vs `stat -c` (GNU) | `fs.statSync` cross-platform |

Troca-se **dois instaladores frágeis por um robusto**. É menos manutenção, não mais.

> **Nota importante:** os *statuslines* (`statusline-command-*.sh` / `.ps1`)
> **continuam** sendo scripts de shell/PowerShell — eles são executados pelo
> Claude Code em runtime, não pelo instalador. O instalador Node apenas os
> **copia**. Portanto a portabilidade do instalador melhora sem perder nada.

## 3. O que o instalador atual (`install.sh`) já faz — a PRESERVAR

Inventário fiel do comportamento atual (a versão Node precisa replicar tudo isto):

1. **Dois modos de layout:**
   - **Híbrido (default):** `commands/`, `agents/`, `skills/`, `hooks/`, docs →
     `<repo>/.claude/`. Statusline → `~/.claude/` (nível usuário, igual em todo projeto).
   - **Global:** se o destino é o próprio `~/.claude`, tudo vai junto (sem split).
2. **Cópia idempotente** dos arquivos do kit, excluindo `.git`, `.gitignore`,
   `.DS_Store`, `settings.json`, `settings.local.json`, `.kit-version`, `.kit-manifest`.
3. **`.kit-manifest`** — lista dos arquivos que o kit envia. No update, arquivos
   que sumiram do kit são **podados** do destino (`comm -23` old vs new manifest).
4. **`.kit-version`** — carimba a versão instalada; loga `fresh install` / `unchanged` / `old → new`.
5. **Merge de `settings.json`** (nunca clobbera; mescla):
   - **Hook `delete-2fa.sh`** em `hooks.PreToolUse` (só adiciona se ainda não existe — detecta por substring do comando).
   - **`statusLine`** no `settings.json` de nível **usuário** (`~/.claude`).
6. **Detecção de SO** para escolher o comando da statusline (macOS `stat -f` / Linux `stat -c`; Windows fica manual hoje).
7. **`settings.local.json`** — copiado só se ainda não existir (nunca sobrescreve).
8. **`chmod +x`** nos `hooks/*.sh` e `statusline/*.sh`.
9. **`.gitignore`** do repo — adiciona `.claude/` (tooling não é commitado).
10. **Proteção da statusLine existente:** se o `settings.json` do usuário já tem
    uma `statusLine`, pergunta antes de substituir (`FORCE_STATUSLINE=1` pula a pergunta;
    modo não-interativo mantém a existente).
11. **Oferta de dependência da statusline:** a statusline lê JSON a cada render e
    precisa de `jq` **ou** `python3`. Se faltarem os dois, detecta o gerenciador de
    pacotes (apt/dnf/pacman/zypper/apk/brew) e **oferece instalar `jq`** (interativo)
    ou imprime o comando (não-interativo).
12. **Idempotência total:** rodar de novo não duplica nada; preserva customizações.

> Qualquer reescrita em Node é **incompleta** se não cobrir os 12 itens acima.
> Este é o contrato de comportamento.

## 4. Arquitetura recomendada

### 4.1 Estrutura do pacote (o próprio repo vira o pacote)

```
setup-claude/
├── package.json            # name, bin, files[], version (fonte única da versão)
├── bin/
│   └── cli.js              # entrypoint: parse de subcomando → install/update/...
├── src/
│   ├── install.js         # orquestra o fluxo (modo híbrido vs global)
│   ├── copy.js            # cópia idempotente + honra o files[] do pacote
│   ├── manifest.js        # .kit-manifest: gerar, comparar, podar removidos
│   ├── settings.js        # merge de settings.json (hook + statusLine) em JS puro
│   ├── statusline.js      # escolha de SO, cópia, checagem de dep (jq/python)
│   ├── gitignore.js       # adiciona .claude/ ao .gitignore do repo
│   └── version.js         # ler/gravar .kit-version, mensagens fresh/unchanged/updated
├── assets/                # o CONTEÚDO do kit que viaja no tarball:
│   ├── commands/  agents/  skills/  hooks/  statusline/  templates/
│   ├── settings.json  settings.local.json
│   └── USAGE.md  CONVENTIONS.md  README.md
└── VERSION                # opcional: manter sincronizado com package.json.version
```

- **`files[]` no `package.json`** controla o que entra no tarball (`assets/` + `bin/` + `src/`).
  Assim `apresentacao.md`, `.git`, etc. **não** são publicados.
- **Versão única:** `package.json.version` passa a ser a fonte da verdade;
  `.kit-version` no destino recebe esse valor. (`VERSION` na raiz pode virar
  derivado ou ser aposentado.)

### 4.2 CLI

```bash
npx <kit>                     # = install, no repo atual (cwd)
npx <kit> install [dir]       # instala em dir (default: cwd); dir=~ força modo global
npx <kit> update [dir]        # re-copia + re-mescla + poda removidos; preserva custom
npx <kit> uninstall [dir]     # (opcional) remove só o que o manifest registra
npx <kit> --version           # versão do kit
```

Flags a preservar do install.sh: `--force-statusline`, modo não-interativo
(detectar TTY), `CLAUDE_CONFIG_DIR` como override do dir de usuário.

### 4.3 Runtime: Node puro, **zero dependências**

- Só `node:fs`, `node:path`, `node:os`, `node:child_process`. Sem libs externas
  → `npx` não baixa árvore de deps, instala num piscar.
- Merge de JSON = `JSON.parse` + manipulação de objeto + `JSON.stringify(obj, null, 2)`.
  Some toda a lógica `jq/python3/awk`.
- Cópia recursiva = `fs.cpSync(src, dest, { recursive: true })` com filtro de exclusão.

### 4.4 `install` vs `update` — a semântica é quase a mesma

O `install.sh` **já é idempotente**, então `update` é praticamente `install` rodado
de novo. Diferença conceitual a explicitar:

- **`install`:** primeira vez. Copia tudo, mescla settings, cria `.kit-version`/manifest, mexe no `.gitignore`.
- **`update`:** re-copia arquivos do kit (sobrescreve os do kit), **poda** o que sumiu
  do kit (via manifest), re-mescla settings de forma aditiva (não duplica hook/statusLine),
  atualiza `.kit-version`. **Nunca** toca em arquivos que o usuário criou e que não
  fazem parte do manifest (ex.: `settings.local.json`, docs em `docs/`).

**Regra de ouro do update:** só sobrescreve/poda o que está no `.kit-manifest`.
Tudo fora do manifest é do usuário e é intocável.

## 5. Decisões em aberto (com recomendação)

Estas eram as perguntas do brainstorming; ficam registradas com a recomendação
para decisão futura.

### 5.1 Registro / distribuição
- **Opções:** (a) público no npmjs.com; (b) privado (GitHub Packages / registro
  privado, exige token); (c) direto do GitHub sem publicar (`npx github:user/repo`).
- **Recomendação:** começar por **(c) `npx github:user/repo`** para validar sem
  burocracia de conta/registro, e migrar para **(a) npm público** quando estabilizar
  (semver de verdade, `@latest`, descoberta). Só ir pra (b) privado se o kit passar
  a conter algo interno que não pode ser público.

### 5.2 Coexistência com `install.sh` / `install.ps1`
- **Opções:** substituir de vez, ou manter os scripts shell como fallback.
- **Recomendação:** **manter os dois modos durante a transição.** O `npx` vira o
  caminho recomendado no INSTALL.md; `install.sh`/`.ps1` continuam para quem não
  quer/pode usar npx. Depois de N versões estáveis, considerar aposentar os shell.

### 5.3 Modelo de consumo pelo time
- **Opções:** (a) ad-hoc `npx <kit>` em qualquer repo; (b) `devDependency` pinada
  no `package.json` de cada projeto do time.
- **Recomendação:** **suportar os dois.** Ad-hoc para uso rápido/qualquer repo;
  devDependency pinada quando o time quer **todos na mesma versão** — aí o `update`
  vira um bump de versão num PR só. São o mesmo binário, usos diferentes.

### 5.4 Statusline no Windows
- Hoje o `install.sh` deixa o Windows manual. O instalador Node **pode** cablear a
  `statusLine` do Windows automaticamente (mesma lógica, escolhendo o `.ps1`).
- **Recomendação:** aproveitar a reescrita para **automatizar o Windows** também —
  era uma limitação só do bash, não do problema.

## 6. Riscos / cuidados

- **Cache do `npx`:** invocações podem pegar versão em cache. O `update` deve
  sempre resolver `@latest` (ou instruir `npx <kit>@latest update`).
- **Preservar customização:** o update jamais pode clobberar o que o usuário editou.
  A lógica de manifest do `install.sh` já resolve isso — **portar, não reinventar.**
- **Publicação:** exige conta/escopo npm (ou token do GitHub Packages) — só relevante
  se sair da opção (c).
- **Paridade de comportamento:** a reescrita só está "pronta" quando cobre os 12
  itens da seção 3. Vale um teste de fumaça nos 3 SOs (os mesmos cenários que já
  quebraram: Ubuntu sem jq, Windows PS 5.1, macOS).

## 7. Roteiro de implementação (alto nível, para o plano futuro)

1. **Scaffold do pacote:** `package.json` (name, bin, files[]), mover conteúdo do
   kit para `assets/`, `bin/cli.js` com parse de subcomando.
2. **Núcleo de cópia + manifest + versão** (`copy.js`, `manifest.js`, `version.js`)
   — replicar itens 2, 3, 4 da seção 3.
3. **Merge de settings em JS** (`settings.js`) — hook delete-2FA + statusLine,
   aditivo e idempotente (itens 5, 10).
4. **Statusline + SO + checagem de dep** (`statusline.js`) — itens 6, 8, 11 +
   automação do Windows (5.4).
5. **gitignore + modos híbrido/global** (`gitignore.js`, `install.js`) — itens 1, 9.
6. **Subcomando `update`** — reuso do install idempotente + poda por manifest (seção 4.4).
7. **Teste de fumaça nos 3 SOs** e atualização do `INSTALL.md` com o caminho `npx`.
8. **(Opcional) Publicar** conforme decisão 5.1.

---

**Resumo de uma linha:** é o próximo passo natural do kit — um instalador em Node
unifica os dois instaladores frágeis, resolve de raiz os bugs de portabilidade que
viemos apagando, e habilita `install`/`update` triviais; o Node já está garantido
porque o Claude Code é distribuído por npm.
