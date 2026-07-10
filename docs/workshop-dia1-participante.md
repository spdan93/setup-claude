# Workshop Claude — Dia 1 · Material do participante

Bem-vindo(a)! Este é o material de apoio do **Dia 1**. Hoje o foco é **entender** o Claude e os
conceitos que você vai usar amanhã, no Dia 2, quando cada um vai instalar e rodar o kit `.claude`
no próprio projeto.

Guarde este documento como referência — não precisa decorar nada; a ideia é que você saiba
**o que é cada coisa** e **por que importa**.

> **O que você vai aprender hoje:** o que é um LLM e o Claude, o que são tokens e contexto, como
> o Claude Code trabalha, os "blocos de construção" (command, skill, agent, hook, MCP), os
> comandos do dia a dia, como escolher o modelo, boas práticas e cuidados, e o papel dos
> artefatos Markdown — em especial o `CLAUDE.md`.

---

## 1. Fundamentos

**LLM (Large Language Model)**
Um modelo treinado em enormes quantidades de texto para uma tarefa simples: **prever a próxima
palavra**. Dessa tarefa emergem habilidades de escrever, raciocinar, resumir e programar. Ele
não "consulta respostas" num banco de dados — **gera** linguagem a partir dos padrões que
aprendeu. Analogia: um autocomplete levado ao extremo, que aprendeu a conversar.

**Claude**
A família de LLMs da **Anthropic** — e o assistente construído sobre eles. O **Claude Code** é
o Claude rodando no terminal como um **agente**: ele lê arquivos, roda comandos e edita código.
Quando dissermos "o modelo" no workshop, é o Claude.

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
disso, medido em **tokens**. Por que importa:

- O que é relevante precisa **estar** no contexto — o que não está, o modelo não sabe.
- Contexto **demais atrapalha**: informação irrelevante dilui a atenção e piora a resposta.
- Quando a janela enche, o Claude **resume/compacta** o histórico pra continuar.

Analogia: é a **mesa de trabalho** do modelo — cabe só um tanto; o que está na mesa ele usa, o
que saiu da mesa ele esquece.

---

## 2. Como o Claude Code trabalha (o loop agêntico)

O Claude Code não só conversa — ele **age**. Cada tarefa segue um ciclo:

1. **Entende** o pedido e o contexto (arquivos, `CLAUDE.md`, conversa).
2. **Propõe** um caminho e **usa ferramentas** — ler/editar arquivos, rodar comandos no
   terminal, buscar na web.
3. **Observa** o resultado (saída do comando, erro, teste) e **corrige o rumo**.
4. Repete até concluir.

- **Ferramentas (tools):** são as "mãos" do modelo — ler/escrever arquivo, rodar comando,
  buscar. Um agente é definido justamente por **quais ferramentas** pode usar.
- **Permissões:** antes de ações que mudam algo (editar, rodar comando), o Claude **pede sua
  aprovação** — você aprova uma vez, sempre, ou nega.
- **Plan Mode:** um modo **só-leitura** em que o Claude estuda e apresenta um **plano** antes de
  tocar em qualquer coisa — ótimo pra tarefas grandes (atalho: `Shift+Tab` alterna os modos).

Analogia: é um **par programador** que mostra o que vai fazer, pede o "ok" e vai ajustando
conforme os testes rodam.

---

## 3. Os blocos de construção

Do mais simples ao mais avançado. A diferença entre eles é sempre **quem dispara** e **o que
ganham**.

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

---

## 4. Comandos essenciais do dia a dia

Estes são comandos **embutidos** do Claude Code (diferentes dos comandos do kit, como
`/commit`, que você vê amanhã). Digite `/` no terminal pra ver todos.

**Começando**

| Comando | O que faz |
|---------|-----------|
| `/help` | Lista os comandos disponíveis e mostra ajuda geral — o ponto de partida. |
| `/init` | Analisa o projeto e **gera um `CLAUDE.md` inicial** com as convenções do repositório. |

**Contexto e sessão** _(a "mesa de trabalho" na prática)_

| Comando | O que faz |
|---------|-----------|
| `/context` | Mostra um mapa visual de **o que está ocupando** a janela de contexto. |
| `/compact` | **Resume** a conversa pra liberar contexto sem perder o fio. |
| `/clear` | **Zera** o contexto e começa do limpo — use ao trocar de tarefa. |
| `/rewind` | **Volta** a conversa e/ou o código a um checkpoint anterior. |
| `/resume` | **Retoma** uma conversa anterior, escolhendo de uma lista de sessões. |

**Modelo, skills, agentes, plugins e MCP**

| Comando | O que faz |
|---------|-----------|
| `/model` | Troca o **modelo** ativo (ex.: Opus, Sonnet, Haiku). |
| `/skills` | Lista e gerencia as **skills** disponíveis. |
| `/agents` | Lista, cria e gerencia **subagentes**. |
| `/plugin` | Gerencia **plugins** e marketplaces. |
| `/mcp` | Lista e gerencia **servidores MCP** (conectar, autenticar, ver status). |

**Monitoramento e conta**

| Comando | O que faz |
|---------|-----------|
| `/status` | Panorama da sessão: versão, conta, modelo, conectividade e diretório. |
| `/usage` | Mostra seu **uso e limites** do plano (janelas de 5h e semanal). |

**Sair**

| Comando | O que faz |
|---------|-----------|
| `/exit` | Encerra o Claude Code. |

---

## 5. Escolhendo o modelo (e custo)

O Claude vem em modelos com equilíbrios diferentes entre **capacidade, velocidade e preço**:

| Modelo | Perfil | Bom para |
|--------|--------|----------|
| **Opus** | mais capaz | raciocínio difícil, arquitetura, tarefas longas |
| **Sonnet** | equilibrado | o dia a dia — código, edições, a maioria das tarefas |
| **Haiku** | mais rápido/barato | tarefas simples e mecânicas, alto volume |

- Troca com `/model`; acompanha o consumo com `/usage`.
- Tudo é medido em **tokens** — modelos mais capazes custam mais por token.
- Regra prática: use o **modelo mais simples que dá conta** da tarefa.
- **Mito comum:** trocar de modelo no meio da conversa **não perde o contexto** — o novo modelo
  relê todo o histórico e continua (por isso ele pode **pedir uma confirmação**, já que
  reprocessa tudo sem cache). Quem zera o contexto é o `/clear`.

---

## 6. Boas práticas de prompting

Como o resultado depende do que entra no contexto, **pedir bem** faz toda a diferença:

- **Seja específico** sobre o objetivo e o critério de "pronto".
- **Dê contexto e aponte arquivos** ("veja `src/auth.ts`") em vez de descrever de memória.
- **Uma tarefa por vez** — peças grandes viram plano (use o Plan Mode).
- **Itere:** revise o resultado e corrija o rumo; não espere acertar de primeira.
- **Deixe o modelo perguntar** — se algo está ambíguo, peça que ele confirme antes de agir.

Analogia: trate como **onboarding de um dev novo** — quanto mais claro o pedido e o contexto,
melhor a entrega.

---

## 7. Cuidados e limitações

- **Pode errar com confiança** (alucinar) — afirma coisas plausíveis, mas falsas. **Sempre
  revise** o output.
- **Revise os diffs** antes de aceitar — você é responsável pelo código, não o modelo.
- **Ele só sabe o que está no contexto** — não conhece o que é privado/recente se você não der.
- **Verifique fatos e comandos** sensíveis antes de rodar.

---

## 8. Artefatos Markdown (e o `CLAUDE.md`)

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
- Gera-se com `/init` (embutido) ou `/claude-md create` (do kit — você vê amanhã).
- Como ele ocupa contexto **toda** sessão, mantenha-o **enxuto** — só o que é regra de verdade.

Analogia: é o **manual de onboarding do projeto** que o modelo lê antes de começar a trabalhar.

---

## Cola rápida (pra guardar)

| Termo | Em uma linha |
|-------|--------------|
| **LLM** | Modelo que prevê o próximo token; **gera** linguagem, não consulta banco. |
| **Token** | Pedaço de palavra; tudo (contexto, preço, velocidade) é medido nele. |
| **Contexto** | A "mesa de trabalho" do modelo; só sabe o que está nela. |
| **Command** | Prompt pronto que **você** dispara com `/nome`. |
| **Skill** | Conhecimento que **o modelo** aplica quando é relevante. |
| **Agent** | Especialista isolado a quem se **delega** uma tarefa. |
| **Hook** | Script **automático** num evento (ex.: proteção delete-2FA). |
| **MCP** | "USB-C" que liga o Claude a ferramentas/dados externos. |
| **CLAUDE.md** | Manual do projeto, carregado automático no contexto toda sessão. |

---

## Amanhã (Dia 2)

Você vai **instalar o kit `.claude`** no seu projeto e rodar um fluxo real de ponta a ponta
(PRD → Plano → Execução), usando na prática todos esses conceitos.

**Traga pronto:** o **Claude Code instalado** e, de preferência, **um projeto real** pra
trabalhar.
