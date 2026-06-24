# Regras de Negócio: Serviço de Encurtamento de URLs

> **Escopo**: Todas as regras que governam a criação de links, comportamento de redirecionamento, expiração, gerenciamento de aliases e controle de tráfego do Serviço de Encurtamento de URLs.
> **Responsável**: Equipe de plataforma (principal); equipe de marketing (autoridade de negócio para políticas de expiração e alias).
> **Última revisão**: 2026-06-23

## Regras

| ID da Regra | Descrição | Condição | Resultado | Fonte |
|---|---|---|---|---|
| BR-001 | Expiração de link | Quando um link curto possui um timestamp `expiresAt` configurado e o horário UTC atual é maior ou igual a esse timestamp | O sistema recusa o redirecionamento e exibe ao Visitante uma mensagem legível "Este link expirou"; o registro do link é mantido para fins de auditoria e não é automaticamente excluído | Política de produto — revisão de requisitos iniciais, 2026-01 |
| BR-002 | Unicidade de alias personalizado | Quando um Operador envia uma requisição para criar um link curto com um alias personalizado e essa string de alias já existe no sistema (ativa ou desativada) | O sistema rejeita a requisição de criação com uma mensagem de erro explícita identificando o alias em conflito; nenhum link é criado | Restrição de design da plataforma — unicidade aplicada por índice do banco de dados |
| BR-003 | Rate limiting de redirecionamento por IP | Quando um único IP cliente faz mais de 60 requisições de redirecionamento em qualquer janela deslizante de 60 segundos | O sistema retorna uma resposta "Muitas Requisições" para esse IP pelo restante da janela de 60 segundos; o tráfego legítimo de redirecionamento não é afetado; o Operador dono do link alvo não é notificado a menos que o padrão persista por mais de 5 minutos | Política de segurança — prevenção de abuso, 2026-01 |
| BR-004 | Esquemas de URL permitidos | Quando um Operador envia uma URL de destino que usa um esquema diferente de `http` ou `https` (exemplos: `javascript:`, `ftp://`, `data:`, `file://`) | O sistema rejeita a requisição de criação e informa ao Operador que apenas URLs de destino `http` e `https` são permitidas | Política de segurança — previne cross-site scripting e abuso de protocol handler, 2026-01 |
| BR-005 | Recusa de redirecionamento para link desativado | Quando um Visitante acessa um link curto que um Operador marcou explicitamente como desativado (independentemente de o link ter data de expiração) | O sistema recusa o redirecionamento e exibe ao Visitante a mensagem "Link indisponível"; o evento de clique não é registrado | Política de produto — operadores devem poder interromper redirecionamentos imediatamente |
| BR-006 | Consistência eventual da contagem de cliques | Quando um Visitante acessa com sucesso um link curto ativo e não expirado | O sistema incrementa a contagem de cliques para aquele link em até 30 segundos após o envio da resposta de redirecionamento; o incremento pode ser assíncrono e não é garantido que seja refletido imediatamente na visão do Operador | Compromisso de engenharia — contagem assíncrona aceita para manter latência de redirecionamento abaixo de 10 ms; documentado no design técnico |
| BR-007 | Data de expiração deve ser futura | Quando um Operador envia uma requisição de criação ou atualização de link com um valor `expiresAt` menor ou igual ao horário UTC atual | O sistema rejeita a requisição e informa ao Operador que a data de expiração deve ser um timestamp futuro | Política de produto — previne a criação acidental de links já expirados, 2026-03 |
| BR-008 | Restrições de caracteres do alias | Quando um Operador envia um alias personalizado | O sistema aceita apenas caracteres que correspondam a `[a-zA-Z0-9_-]` e rejeita qualquer alias com mais de 30 caracteres; aliases que falhem em qualquer uma das restrições causam a rejeição da requisição de criação com uma mensagem de erro descritiva | Restrição de design da plataforma — garante segurança de URL sem codificação percentual |

> **Guia de colunas**
> - **ID da Regra**: identificador estável; nunca reutilizar um ID descontinuado — marcar regras descontinuadas com ~~tachado~~ em vez de removê-las.
> - **Descrição**: um nome curto utilizável como rótulo em fluxos e critérios de aceite.
> - **Condição**: o gatilho exato ("quando o total do carrinho excede R$500", "quando o status da conta do usuário é Suspenso").
> - **Resultado**: o que o sistema deve fazer — expresso em termos observáveis e voltados ao usuário.
> - **Fonte**: o requisito, documento de política ou autoridade que estabeleceu esta regra.

## Notas

- **Interação BR-001 vs BR-005**: Um link que está tanto desativado quanto expirado é apresentado como "Link indisponível" (BR-005 tem precedência) porque "indisponível" é o estado mais abrangente, controlado pelo operador. Se um Operador reativar o link após a data de expiração já ter passado, o link imediatamente é apresentado como "expirado" (BR-001).
- **Revisão pendente do limiar BR-003**: O limiar de 60 requisições por 60 segundos foi definido de forma conservadora no lançamento. A equipe de plataforma revisará os padrões de tráfego reais na marca dos 3 meses e poderá relaxar o limite para consumidores autenticados da API.
- **Janela de tolerância BR-006**: A janela de 30 segundos é um compromisso de nível de serviço, não um limite técnico rígido. Alertas de monitoramento disparam se a latência de flush p99 exceder 20 segundos.
- **Referência cruzada**: BR-001, BR-002, BR-005 são todos referenciados nos fluxos da Especificação Funcional (a Especificação Funcional correspondente em `docs/functional/2026_06_23-url-shortener.md`).
