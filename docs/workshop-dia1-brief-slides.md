# Brief para geração de slides — Workshop Claude · Dia 1

## Instrução para o modelo

Você é um designer de apresentações. A partir deste documento, **gere os slides do Dia 1** de
um workshop interno sobre o Claude. Siga a estrutura slide a slide da seção "Roteiro dos slides"
abaixo: use os **bullets** como conteúdo do slide (frases curtas) e as **Notas** como texto do
apresentador (não colocar no slide, e sim nas speaker notes). Respeite as diretrizes de design.

- **Idioma:** português (pt-BR).
- **Não invente conteúdo** além do que está aqui; pode reescrever para caber melhor no slide,
  mantendo o sentido.
- **Uma ideia por slide.** Slides são visuais de apoio, não a fala inteira.

---

## Contexto do workshop

- **Tema:** apresentar o Claude para o time de desenvolvimento (2 dias).
- **Dia 1 (este):** conceitos — o que é o Claude e seus blocos de construção. Sem detalhes
  profundos, mas com definições firmes.
- **Dia 2:** mão na massa — instalar e usar um kit `.claude` no próprio projeto.
- **Público:** desenvolvedores, muitos com pouco ou nenhum contato prévio com IA de código.
- **Objetivo do Dia 1:** ao final, todo mundo entende LLM, tokens, contexto, os blocos
  (command, skill, agent, hook, MCP), como o Claude trabalha, e o papel do `CLAUDE.md`.

---

## Diretrizes de design

- **Tom:** prático, direto, sem jargão desnecessário. Amigável, não acadêmico.
- **Densidade:** no máximo ~5 bullets por slide, frases curtas (idealmente < 10 palavras).
- **Destaque:** termos-chave em **negrito** (LLM, token, contexto, os nomes dos blocos).
- **Analogias como âncora visual:** cada conceito tem uma analogia — use como imagem/ícone
  mental (ex.: contexto = "mesa de trabalho", MCP = "USB-C", CLAUDE.md = "manual de onboarding").
- **Consistência:** paleta e tipografia uniformes; um ícone recorrente por tipo de bloco.
- **Divisores de seção:** use slides de separação entre as grandes partes (Fundamentos, Como o
  Claude trabalha, Blocos de construção, Uso no dia a dia, Artefatos).
- **Total sugerido:** ~22–26 slides.

---

## Roteiro dos slides

### Slide 1 — Capa
- **Workshop Claude — Dia 1**
- Subtítulo: Conceitos e fundamentos
- _Nota:_ boas-vindas; hoje é conceito, amanhã é mão na massa (instalar o kit no próprio projeto).

### Slide 2 — O que você vai aprender hoje
- O que é um **LLM** e o **Claude**
- **Tokens** e **contexto**
- Como o Claude Code **trabalha**
- Os **blocos**: command, skill, agent, hook, MCP
- Boas práticas, cuidados e o **`CLAUDE.md`**
- _Nota:_ não precisa decorar; a ideia é saber o que é cada coisa e por que importa.

### Slide 3 — Divisor: Fundamentos

### Slide 4 — LLM (Large Language Model)
- Treinado pra **prever a próxima palavra**
- Daí emergem: escrever, raciocinar, programar
- **Gera** linguagem — não consulta um banco
- _Analogia:_ autocomplete no extremo, que aprendeu a conversar
- _Nota:_ ele produz a partir de padrões aprendidos; não "busca" a resposta pronta.

### Slide 5 — Claude
- A família de **LLMs da Anthropic**
- **Claude Code** = Claude no terminal, como **agente**
- Lê arquivos, roda comandos, edita código
- _Nota:_ quando dissermos "o modelo", é o Claude.

### Slide 6 — Token
- A unidade que o modelo lê/escreve: **pedaço de palavra**
- Regra de bolso: **~1 token ≈ 4 caracteres ≈ ¾ de palavra**
- **Tudo é medido em tokens:** contexto, velocidade, preço
- _Analogia:_ as "sílabas" do modelo
- _Nota:_ "Trabalhando" → `Trabalh` + `ando`. É o que o LLM prevê: o próximo token.

### Slide 7 — Contexto (janela de contexto)
- Tudo que o modelo **enxerga** ao responder
- **Não tem memória** — relê tudo a cada resposta
- Janela é **finita** (medida em tokens)
- Relevante precisa **estar** lá; excesso **atrapalha**
- _Analogia:_ a **mesa de trabalho** — usa o que está nela, esquece o resto
- _Nota:_ quando enche, o Claude resume/compacta pra continuar.

### Slide 8 — Divisor: Como o Claude Code trabalha

### Slide 9 — O loop agêntico
- **Entende** → **Propõe/age** → **Observa** → **corrige** → repete
- Usa **ferramentas**: ler/editar arquivos, rodar comando, buscar
- _Analogia:_ um **par programador** que mostra o que vai fazer
- _Nota:_ ele não só conversa — age e ajusta conforme os testes rodam.

### Slide 10 — Ferramentas, permissões e Plan Mode
- **Ferramentas (tools):** as "mãos" do modelo
- **Permissões:** ele **pede aprovação** antes de mudar algo
- **Plan Mode:** modo só-leitura que apresenta um **plano** antes de agir (`Shift+Tab`)
- _Nota:_ um agente é definido por quais ferramentas pode usar.

### Slide 11 — Divisor: Os blocos de construção

### Slide 12 — Command (`/comando`)
- Prompt pronto que **você** dispara com `/nome`
- Ex.: `/commit`, `/documentation`
- _Analogia:_ **atalho de teclado para um prompt**

### Slide 13 — Skill
- Conhecimento que **o modelo carrega sozinho** quando é relevante
- Você não chama — ele reconhece e aplica
- _Analogia:_ especialidade **pega da prateleira**

### Slide 14 — Agent (agente / subagente)
- Instância com **contexto, instruções e ferramentas próprios**
- Trabalha **isolado** e devolve só o resultado
- _Analogia:_ **especialista** a quem se delega uma tarefa

### Slide 15 — Hook
- Script que roda **automaticamente** num evento
- **Determinístico** — sempre roda (proteção/automação)
- Ex.: **delete-2FA** bloqueia exclusões perigosas
- _Analogia:_ **regra automática** (um "escutador")

### Slide 16 — MCP (Model Context Protocol)
- **Padrão aberto** que liga o Claude a ferramentas/dados externos
- Bancos, APIs, Drive... num "encaixe" comum
- _Analogia:_ **USB-C para IA**

### Slide 17 — Resumo: quem dispara cada bloco
- **Command** → você, explícito
- **Skill** → o modelo, quando é relevante
- **Agent** → delegado a um especialista
- **Hook** → um evento, automático
- **MCP** → conexão com o mundo externo
- _Nota:_ apresentar como tabela; é o slide que "trava" as diferenças.

### Slide 18 — Divisor: Usando o Claude no dia a dia

### Slide 19 — Comandos essenciais (parte 1)
- `/help` — ajuda / ponto de partida
- `/init` — gera o `CLAUDE.md` inicial
- `/context` — o que ocupa o contexto
- `/compact` — resume pra liberar espaço
- `/clear` — zera o contexto (nova tarefa)
- _Nota:_ são comandos **embutidos** (diferentes dos comandos do kit).

### Slide 20 — Comandos essenciais (parte 2)
- `/rewind` · `/resume` — voltar / retomar sessões
- `/model` · `/usage` — trocar modelo / ver uso
- `/agents` · `/skills` · `/plugin` · `/mcp` — gerenciar extensões
- `/status` — panorama da sessão · `/exit` — sair

### Slide 21 — Modelos e custo
- **Opus** (mais capaz) · **Sonnet** (equilibrado) · **Haiku** (rápido/barato)
- Troca com `/model`; uso com `/usage`
- Regra: **o modelo mais simples que dá conta**
- **Mito:** trocar de modelo **não perde o contexto** (só `/clear` zera)
- _Nota:_ tudo é medido em tokens; mais capaz custa mais por token.

### Slide 22 — Boas práticas de prompting
- **Seja específico** (objetivo + "pronto")
- **Aponte arquivos**, não descreva de memória
- **Uma tarefa por vez** (grande → plano)
- **Itere**; deixe o modelo **perguntar**
- _Analogia:_ onboarding de um dev novo

### Slide 23 — Cuidados e limitações
- Pode **errar com confiança** (alucinar) → **sempre revise**
- **Revise os diffs** — a responsabilidade é sua
- Só sabe o que está **no contexto**
- Verifique fatos e comandos sensíveis
- _Nota:_ isso conecta com a "regra de ouro" do Dia 2 (nada de commit automático).

### Slide 24 — Divisor: Artefatos Markdown

### Slide 25 — Artefatos Markdown (dois papéis)
- **Legível por humano E por LLM**, versionável
- **Output pra humanos:** PRDs, planos, docs
- **Contexto pra LLM:** o modelo lê os `.md` pra se abastecer
- _Analogia:_ a **ponte** entre pessoa e modelo

### Slide 26 — `CLAUDE.md` — o principal de todos
- Carregado **automaticamente** no contexto de cada sessão
- Guarda as **regras do projeto** (stack, padrões, testes...)
- Gera com `/init` ou `/claude-md create`
- Mantenha **enxuto** (ocupa contexto sempre)
- _Analogia:_ **manual de onboarding** do projeto

### Slide 27 — Recap + amanhã
- LLM prevê tokens → só sabe o que está no **contexto**
- Os **blocos** controlam esse contexto e o que o Claude faz
- **Amanhã:** instalar o kit `.claude` e rodar PRD → Plano → Execução
- **Traga:** Claude Code instalado + um projeto real
- _Nota:_ encerrar com espaço pra dúvidas.
