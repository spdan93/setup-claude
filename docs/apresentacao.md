# Workshop Claude — Guia do Apresentador

> Documento de apoio para conduzir o treinamento de **2 dias** com o time.
> Formato: guia do apresentador (tópicos + falas + momentos de mão na massa).
> _Rascunho — vamos preencher o Dia 1 juntos; o Dia 2 (instalação do kit) já está montado._

**Público:** time de desenvolvimento
**Duração:** 2 dias
**Objetivo geral:** apresentar o Claude, os conceitos e, ao final, ter cada pessoa com o kit `.claude` instalado e rodando no próprio projeto.

---

## Dia 1 — Conceitos gerais e apresentação do Claude

> Objetivo do dia: todo mundo sai entendendo **o que é** o Claude e os **blocos de
> construção** que vão usar no Dia 2 — sem entrar em detalhes profundos, mas com definições
> firmes.

### Abertura

- **Boas-vindas e objetivo dos 2 dias.** "Hoje é conceito; amanhã é mão na massa — cada um sai
  com o kit rodando no próprio projeto."
- **Agenda:** Dia 1 = o que é o Claude e seus blocos de construção; Dia 2 = instalar e usar o
  kit `.claude`.
- **Tom:** prático, sem jargão, perguntas à vontade a qualquer momento.
- **Calibrar a sala:** perguntar quem já usou Claude / alguma IA de código (mão pra cima), pra
  ajustar o ritmo.
- **Lembrete do pré-requisito do Dia 2:** ter o **Claude Code instalado** e, de preferência,
  **um projeto real em mãos** pra instalar o kit amanhã.

### Fundamentos

**LLM (Large Language Model)**
Um modelo treinado em enormes quantidades de texto para uma tarefa simples: **prever a próxima
palavra**. Dessa tarefa emergem habilidades de escrever, raciocinar, resumir e programar. Ele
não "consulta respostas" num banco de dados — **gera** linguagem a partir dos padrões que
aprendeu. Analogia: um autocomplete levado ao extremo, que aprendeu a conversar.

**Claude**
A família de LLMs da **Anthropic** — e o assistente construído sobre eles. O **Claude Code** é
o Claude rodando no terminal como um **agente**: ele lê arquivos, roda comandos e edita código.
Quando dizemos "o modelo" no workshop, é o Claude.

**Token**
A unidade em que o modelo lê e escreve texto: **pedaços de palavra** — nem letras soltas, nem
palavras inteiras. "Trabalhando" pode virar `Trabalh` + `ando`; palavras comuns costumam ser 1
token. Regra de bolso: **~1 token ≈ 4 caracteres ≈ ¾ de uma palavra** (em português cai um
pouco mais de tokens por palavra que em inglês). É exatamente o que o LLM prevê: **o próximo
token**. Importa porque **tudo é medido em tokens** — a janela de contexto, a velocidade e o
preço. Analogia: são as **"sílabas"** que o modelo usa pra ler e gerar texto.

**Contexto (janela de contexto)**
Tudo que o modelo **enxerga** ao gerar uma resposta: a conversa até ali, os arquivos que leu,
os resultados de comandos e as instruções. O modelo **não tem memória** entre mensagens — a
cada resposta ele relê todo o contexto do zero. A **janela de contexto** é o limite finito
disso, medido em **tokens** (pedaços de palavra). Por que importa:

- O que é relevante precisa **estar** no contexto — o que não está, o modelo não sabe.
- Contexto **demais atrapalha**: informação irrelevante dilui a atenção e piora a resposta.
- Quando a janela enche, o Claude **resume/compacta** o histórico pra continuar.

Analogia: é a **mesa de trabalho** do modelo — cabe só um tanto; o que está na mesa ele usa, o
que saiu da mesa ele esquece. _(É por isso que subagentes ajudam — trabalham numa "mesa limpa"
— e que a statusline mostra uma barra de uso de contexto.)_

### Como o Claude Code trabalha (o loop agêntico)

O Claude Code não só conversa — ele **age**. Cada tarefa segue um ciclo:

1. **Entende** o pedido e o contexto (arquivos, `CLAUDE.md`, conversa).
2. **Propõe** um caminho e **usa ferramentas** — ler/editar arquivos, rodar comandos no
   terminal, buscar na web.
3. **Observa** o resultado (saída do comando, erro, teste) e **corrige o rumo**.
4. Repete até concluir.

- **Ferramentas (tools):** são as "mãos" do modelo — ler/escrever arquivo, rodar bash, buscar.
  Um agente é definido justamente por **quais ferramentas** pode usar.
- **Permissões:** antes de ações que mudam algo (editar, rodar comando), o Claude **pede
  aprovação** — você aprova uma vez, sempre, ou nega. Dá pra afrouxar/apertar por modo.
- **Plan Mode:** um modo **só-leitura** em que o Claude estuda e apresenta um **plano** antes de
  tocar em qualquer coisa — ótimo pra tarefas grandes (atalho: `Shift+Tab` alterna os modos).

Analogia: é um **par programador** que mostra o que vai fazer, pede o "ok" e vai ajustando
conforme os testes rodam.

### Os blocos de construção

> Ordem do mais simples ao mais avançado. A diferença entre eles é sempre **quem dispara** e
> **o que ganham**.

**Command (`/comando`)**
Uma instrução pronta e reutilizável que **você** dispara digitando `/nome`. Em vez de reescrever
um prompt longo, você salva uma vez e invoca. Ex.: `/commit`, `/documentation`.
Analogia: um **atalho de teclado para um prompt**.

**Skill**
Um pacote de conhecimento/instruções que o **modelo carrega sozinho** quando é relevante para a
tarefa — ele reconhece "isso se aplica aqui" e aplica, sem você chamar. Analogia: uma
**especialidade que o Claude pega da prateleira** quando o assunto aparece.

**Agent (agente / subagente)**
Uma instância do modelo com **contexto, instruções e ferramentas próprios**, focada numa tarefa
que você (ou o Claude) **delega**. Um subagente trabalha isolado e devolve só o resultado, sem
poluir a conversa principal. Analogia: um **especialista a quem você entrega um trabalho bem
definido**.

**Hook**
Um script que roda **automaticamente** em certo evento (ex.: antes de executar um comando), sem
depender da "boa vontade" do modelo — é **determinístico**, sempre roda. Serve para proteções e
automações. Ex.: o hook _delete-2FA_, que bloqueia exclusões perigosas.
Analogia: uma **regra automática** (um "escutador" de eventos).

**MCP (Model Context Protocol)**
Um **padrão aberto** que conecta o Claude a ferramentas e fontes de dados externas (bancos,
APIs, Google Drive, etc.) de forma uniforme. Em vez de uma integração sob medida para cada uma,
o MCP é um "encaixe" comum. Analogia: um **USB-C para IA** — uma porta padrão pra plugar
qualquer coisa.

### Resumo que trava as diferenças

| Bloco | Quem dispara | Serve para |
|-------|--------------|------------|
| **Command** | **Você**, explícito (`/nome`) | Reusar um prompt pronto |
| **Skill** | **O modelo**, quando é relevante | Aplicar conhecimento/método na hora certa |
| **Agent** | Delegado (por você ou pelo Claude) | Entregar uma tarefa isolada a um especialista |
| **Hook** | **Um evento**, automático | Proteção e automação determinística |
| **MCP** | Conexão contínua | Ligar o Claude ao mundo externo (dados/ferramentas) |

### Usando o Claude no dia a dia — comandos essenciais

> Estes são comandos **embutidos** do Claude Code (diferentes dos comandos do kit, como
> `/commit`). Digite `/` no terminal pra ver todos. Vale demonstrar ao vivo os de contexto —
> eles são a aplicação prática da "mesa de trabalho".

**Começando**

| Comando | O que faz |
|---------|-----------|
| `/help` | Lista os comandos disponíveis e mostra ajuda geral — o ponto de partida. |
| `/init` | Analisa o projeto e **gera um `CLAUDE.md` inicial** com as convenções do repositório. |

**Contexto e sessão** _(a "mesa de trabalho" na prática)_

| Comando | O que faz |
|---------|-----------|
| `/context` | Mostra um mapa visual de **o que está ocupando** a janela de contexto (system prompt, ferramentas, mensagens, arquivos, MCP). |
| `/compact` | **Resume** a conversa pra liberar contexto sem perder o fio. Aceita instrução opcional do que preservar. |
| `/clear` | **Zera** o contexto e começa do limpo — mesma sessão, mesa vazia. Use ao trocar de tarefa. |
| `/rewind` | **Volta** a conversa e/ou o código a um checkpoint anterior (desfaz um caminho). |
| `/resume` | **Retoma** uma conversa anterior, escolhendo de uma lista de sessões. |

**Modelo, skills, agentes, plugins e MCP**

| Comando | O que faz |
|---------|-----------|
| `/model` | Troca o **modelo** ativo (ex.: Opus, Sonnet, Haiku) conforme a tarefa e o custo. |
| `/skills` | Lista e gerencia as **skills** disponíveis. |
| `/agents` | Lista, cria e gerencia **subagentes** (inclusive os customizados). |
| `/plugin` | Gerencia **plugins** e marketplaces (instalar/ativar). |
| `/mcp` | Lista e gerencia **servidores MCP** (conectar, autenticar, ver status). |

**Monitoramento e conta**

| Comando | O que faz |
|---------|-----------|
| `/status` | Panorama da sessão: versão, conta, **modelo**, conectividade e diretório de trabalho. |
| `/usage` | Mostra seu **uso e limites** do plano (consumo das janelas de 5h e semanal). |

**Sair**

| Comando | O que faz |
|---------|-----------|
| `/exit` | Encerra o Claude Code. |

### Modelos e custo

O Claude vem em modelos com equilíbrios diferentes entre **capacidade, velocidade e preço**:

| Modelo | Perfil | Bom para |
|--------|--------|----------|
| **Opus** | mais capaz | raciocínio difícil, arquitetura, tarefas longas |
| **Sonnet** | equilibrado | o dia a dia — código, edições, a maioria das tarefas |
| **Haiku** | mais rápido/barato | tarefas simples e mecânicas, alto volume |

- Troca com `/model`; acompanha o consumo com `/usage`.
- Tudo é medido em **tokens** (lembra?) — modelos mais capazes custam mais por token.
- Regra prática: use o **modelo mais simples que dá conta** da tarefa.
- **Mito comum:** trocar de modelo no meio da conversa **não perde o contexto** — o novo
  modelo relê todo o histórico e continua (por isso ele pode **pedir uma confirmação**, já que
  reprocessa tudo sem cache). Quem zera o contexto é o `/clear`.

### Boas práticas de prompting

Como o resultado depende do que entra no contexto, **pedir bem** faz toda a diferença:

- **Seja específico** sobre o objetivo e o critério de "pronto".
- **Dê contexto e aponte arquivos** ("veja `src/auth.ts`") em vez de descrever de memória.
- **Uma tarefa por vez** — peças grandes viram plano (use o Plan Mode).
- **Itere:** revise o resultado e corrija o rumo; não espere acertar de primeira.
- **Deixe o modelo perguntar** — se algo está ambíguo, peça que ele confirme antes de agir.

Analogia: trate como **onboarding de um dev novo** — quanto mais claro o pedido e o contexto,
melhor a entrega.

### Cuidados e limitações

- **Pode errar com confiança** (alucinar) — afirma coisas plausíveis, mas falsas. **Sempre
  revise** o output.
- **Revise os diffs** antes de aceitar — você é responsável pelo código, não o modelo.
- **Ele só sabe o que está no contexto** — não conhece o que é privado/recente se você não der.
- **Verifique fatos e comandos** sensíveis antes de rodar.
- Gancho pro Dia 2: é por isso a **regra de ouro** — o kit **nunca** commita sozinho; quem
  decide é você.

### Artefatos Markdown (e o `CLAUDE.md`)

**Por que Markdown.** É texto puro, **legível por humanos e por LLM** ao mesmo tempo,
versionável no git e estruturado por títulos. Virou a "língua franca" entre pessoa e modelo.

**Um artefato, dois papéis:**

- **Output pra humanos** — PRDs, planos, documentação, changelog: coisas que as pessoas leem,
  revisam e aprovam.
- **Contexto pra LLM** — o próprio modelo **lê** esses `.md` pra carregar informação na "mesa
  de trabalho". Ex.: ler o PRD antes de gerar o plano; ler o plano antes de implementar.

O mesmo arquivo serve aos dois lados — é a **ponte** entre o que a pessoa entende e o que o
modelo precisa ter em contexto.

**`CLAUDE.md` — o principal de todos.**
É o artefato que o Claude Code **carrega automaticamente no contexto** no início de cada sessão
daquele projeto. Nele ficam as **regras e convenções do repositório**: stack, padrões de
código, design system, i18n, branch padrão, como rodar testes, o que evitar. Ou seja: o modelo
**já chega sabendo** as regras do projeto, sem você repetir a cada conversa.

- Pode existir em **nível de usuário** (`~/.claude/CLAUDE.md`, vale pra tudo) e de **projeto**
  (`./CLAUDE.md`, vale só pro repo).
- Gera-se com `/init` (embutido) ou `/claude-md create` (do kit).
- Como ele ocupa contexto **toda** sessão, mantenha-o **enxuto** — só o que é regra de verdade
  (lembra da lição de tokens/contexto).

Analogia: é o **manual de onboarding do projeto** que o modelo lê antes de começar a trabalhar.

### Encerramento do Dia 1

- **Recap em uma frase:** um LLM prevê tokens; ele só sabe o que está no **contexto**; e os
  **blocos** (command, skill, agent, hook, MCP) são formas de controlar o que entra nesse
  contexto e o que o Claude faz com ele.
- **A grande sacada:** quase tudo gira em torno de **gerenciar contexto** — por isso importam
  os artefatos Markdown e, acima de todos, o **`CLAUDE.md`**.
- **Gancho pro Dia 2:** "Amanhã a gente instala um kit que junta comandos, agentes, skills e
  hooks num pipeline pronto — cada um no seu projeto — e coloca tudo isso pra rodar."
- **Lembretes:** trazer o **Claude Code instalado** e **um projeto real** pra mão na massa.
- **Espaço pra dúvidas** antes de encerrar.

---

## Dia 2 — Instalação e uso do kit `.claude` (mão na massa)

**Objetivo do dia:** cada pessoa sai com o kit **instalado, validado e rodando** um fluxo real
no próprio projeto.

### 1. O que é o kit (2 min)

Um pacote `.claude` **agnóstico** que adiciona ao Claude Code um pipeline
**PRD → Plan → Execução**, além de comandos, agentes, skills, um hook de segurança
(delete-2FA) e uma statusline. Funciona em **qualquer projeto e qualquer stack** — as regras
específicas de cada projeto ficam no `CLAUDE.md` dele.

### 2. Panorama do kit — o que vem dentro (5 min)

> Tudo aqui são os **blocos do Dia 1** já aplicados. O kit é um conjunto pronto deles.

**Comandos** (você dispara com `/`):

| Comando | Pra quê |
|---------|---------|
| `/prd-write`, `/prd-review` | criar e refinar o PRD (o "o quê" e o "porquê") |
| `/plan-create` | virar o PRD num plano de implementação em tarefas |
| `/develop` | executar as tarefas do plano em ordem (faz `git add`, **nunca** commita) |
| `/test-write`, `/e2e` | gerar testes dos casos e rodar E2E de browser |
| `/documentation` | gerar doc (técnica, funcional, caderno de testes, API) |
| `/commit`, `/ship` | commit estruturado + changelog / documentar+versionar+commit |
| `/claude-md` | criar/editar o `CLAUDE.md` do projeto |
| `/workflow` | orquestra o pipeline inteiro, da ideia à implementação |
| `/meta-prompt` | transporta contexto entre etapas/agentes |
| `/confirm-delete` | libera uma exclusão barrada pelo hook delete-2FA (o "2FA") |

**Agentes** (especialistas a quem o kit delega): `prd-writer`, `prd-reviewer`,
`plan-architect`, `developer`, `code-reviewer`.

**Skills** (o modelo carrega quando é relevante): `doc-technical` / `doc-functional` /
`doc-test-plan` / `doc-api` (documentação), `checkpoint-validator`, `bug-tracker`,
`playwright-e2e-testing`, `microservices-analyzer`, `workflow-orchestrator`, `meta-prompt`.

**Hook:** `delete-2FA` — barra exclusões perigosas; `/confirm-delete` é o desbloqueio.

Analogia: o Dia 1 te deu as **peças de Lego**; o kit é um **modelo já montado** com elas.

### 3. A ideia central: instalar é copiar 4 coisas (3 min)

Deixar claro antes de qualquer comando — desmistifica o processo:

1. **Tudo, menos `statusline/`** → `<repo>/.claude/`
2. **`statusline/`** → `~/.claude/` (nível de usuário — a mesma em todo projeto)
3. **Dois blocos de JSON**: `hooks` no `settings.json` do **projeto**; `statusLine` no
   `settings.json` do **usuário**
4. **`.claude/`** entra no `.gitignore` do repo

> Os artefatos de trabalho (PRDs, plans, changelog, docs) ficam em `<repo>/docs/` — **fora**
> do `.claude` e **versionados**.

### 4. Duas formas de instalar (demonstrar as duas)

**Forma A — Script (recomendada).** Um comando por SO:

```bash
# macOS / Linux
bash /caminho/do/kit/install.sh .
```
```powershell
# Windows (roda no PowerShell 5.1 nativo — não precisa instalar o PowerShell 7)
powershell -ExecutionPolicy Bypass -File .\install.ps1 .
```

**Forma B — Por agente de IA (o "wow" do dia).** Abrir um agente e pedir em uma frase:

> "Instale o kit `setup-claude` (está em `<caminho-do-kit>`) no projeto `C:\meu-projeto`,
> seguindo o Modo 2 do `INSTALL.md`. Não sobrescreva minha statusline se já existir e não
> commite nada."

O agente lê o `INSTALL.md`, copia as pastas, faz o merge dos 2 blocos de `settings.json`
sozinho (sem `jq`) e ajusta o `.gitignore`.

### 5. Mão na massa — cada um instala no seu projeto (15–20 min)

1. Clonar o kit uma vez num lugar estável:
   ```bash
   git clone <url-do-kit> ~/.claude-kit
   ```
2. Instalar no projeto (script **ou** agente).
3. **Validar** juntos:
   - `<repo>/.claude/settings.json` tem o hook `delete-2fa.sh`
   - `~/.claude/settings.json` tem a `statusLine`
   - `.gitignore` do repo tem a linha `.claude/`
   - abrir o Claude Code no projeto e ver a **statusline de 3 linhas** aparecer

### 6. Se algo quebrar — troubleshooting (5 min)

Install ao vivo sempre trava pra alguém. Os mais comuns:

| Sintoma | Causa provável | Saída |
|---------|----------------|-------|
| `jq: command not found` | `jq` ausente (só o `install.sh` precisa) | instalar `jq` (brew/apt) **ou** usar o Modo 2 (manual/agente, sem jq) |
| `pwsh não reconhecido` (Windows) | não tem PowerShell 7 | usar `powershell` (5.1 nativo) — o instalador suporta |
| Statusline não aparece | `statusLine` não entrou no `~/.claude/settings.json`, ou falta `git`/`bc` | conferir o bloco no settings do **usuário**; instalar `git`/`bc` |
| Statusline sem ícones (Windows) | terminal sem alguns glyphs unicode | esperado — a versão Windows usa ASCII; funciona igual |
| Hook delete-2FA não dispara | bloco `hooks` fora do settings do **projeto**, ou (Windows) sem bash | conferir `settings.json` do projeto; no Windows precisa de Git Bash |
| Mudei o kit e não atualizou | falta re-rodar o instalador | `git -C ~/.claude-kit pull` + `install.sh <projeto>` |

### 7. Primeiro uso: dar contexto ao projeto (5 min)

- `/claude-md create` — gerar o `CLAUDE.md` do projeto (regras da stack). É o **primeiro
  passo** em todo projeto novo: sem ele, os agentes não conhecem os padrões.
- Referências instaladas: `INSTALL.md`, `USAGE.md`, `CONVENTIONS.md`.

### 8. O pipeline na prática: PRD → Plan → Execução (10 min)

O coração do kit. Cada etapa gera um **artefato Markdown** (Dia 1!) que alimenta a próxima:

1. **Ideia → PRD.** `/prd-write` (agente `prd-writer`) escreve; `/prd-review` (`prd-reviewer`)
   refina. Saída: `docs/prds/…`. O "o quê" e o "porquê", em pt-BR.
2. **PRD → Plano.** `/plan-create` (`plan-architect`) quebra o PRD em tarefas com dependências
   e casos de teste. Saída: `docs/plans/…`.
3. **Plano → Código.** `/develop` (`developer`) executa as tarefas em ordem, roda testes e faz
   `git add` — **nunca commita**. O `code-reviewer` revisa.
4. **(Opcional) Testes / E2E.** `/test-write`, `/e2e`.
5. **Documentar.** `/documentation` gera a doc do tipo escolhido (pt-BR por padrão).
6. **Fechar.** **Você** pede `/commit` (ou `/ship`) — commit estruturado + changelog. Nunca
   automático.

> `/workflow` amarra tudo num fluxo só — mas vale rodar **passo a passo** pra ver os artefatos
> surgindo em `docs/` (o "output pra humano + contexto pra LLM" do Dia 1).

Analogia: uma **linha de produção** — cada etapa recebe o artefato da anterior e entrega o próximo.

### 9. Exercício end-to-end (20–30 min)

Cada um, no próprio projeto (ou num de exemplo), roda uma **mini-feature** de ponta a ponta:

1. `/claude-md create` (se ainda não fez).
2. `/prd-write` de uma feature pequena e real (ex.: "adicionar campo X", "endpoint Y").
3. `/plan-create` a partir do PRD.
4. `/develop` pra implementar.
5. `/documentation` pra gerar uma doc.
6. Revisar o diff e **só então** `/commit`.
7. Abrir `docs/` e ver os artefatos gerados.

> Meta: **sentir o fluxo**, não entregar produção — escopo minúsculo de propósito. Circule
> pela sala ajudando; e deixe o modelo **perguntar** quando estiver ambíguo (boa prática do Dia 1).

### 10. A regra de ouro (não pode faltar)

**Commit nunca é automático.** Nenhum comando ou agente do kit faz `git commit` sozinho —
commit só acontece quando a pessoa pede (`/commit` ou instrução direta). O `/develop`
implementa e faz `git add`, mas **nunca** commita.

### 11. Atualização futura (2 min)

```bash
git -C ~/.claude-kit pull
~/.claude-kit/install.sh /caminho/do/projeto   # re-aplica; faz prune por manifest
```

---

## Checklist do apresentador

- [ ] Dia 1 montado e revisado
- [ ] Kit clonado e testado antes do workshop (mac/linux e Windows, se aplicável)
- [ ] URL do repositório do kit pronta pra compartilhar
- [ ] Projeto de exemplo pra demonstrar a instalação ao vivo
- [ ] Cada participante com Claude Code já instalado (pré-requisito do Dia 2)
- [ ] Feature pequena escolhida para o exercício end-to-end (escopo mínimo)
- [ ] Troubleshooting revisado (jq, PowerShell, statusline, hook)
- [ ] Pipeline testado ponta a ponta uma vez antes de apresentar
