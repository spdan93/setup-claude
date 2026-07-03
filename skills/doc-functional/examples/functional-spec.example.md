# Serviço de Encurtamento de URLs

## Propósito

Equipes de marketing e operadores internos precisam de uma forma de converter URLs longas e difíceis de lidar em links curtos e compartilháveis que possam ser incorporados em campanhas, e-mails e publicações em redes sociais sem quebrar a formatação. O serviço também precisa rastrear quantas vezes cada link foi acessado, para que os responsáveis pelas campanhas possam medir o engajamento sem depender de ferramentas de analytics de terceiros. Ao centralizar a criação e o rastreamento de links em um único serviço interno, a organização ganha visibilidade sobre todos os links compartilhados, pode desativar links comprometidos ou expirados imediatamente e evita dependência de fornecedores externos de encurtamento de URLs.

## Atores

| Ator | Descrição | Tipo |
|---|---|---|
| Operador | Usuário interno autenticado (membro da equipe de marketing, gerente de campanha) que cria, atualiza e desativa links curtos | Humano |
| Visitante | Qualquer pessoa que acessa um link curto, tipicamente via browser; não autenticado | Humano |
| Agendador | Processo automatizado que desativa links cuja data de expiração passou | Sistema |

## Capacidades Funcionais

- O Operador pode criar um link curto fornecendo uma URL de destino e uma data de expiração opcional.
- O Operador pode especificar um alias personalizado para um link curto no lugar do código gerado pelo sistema, desde que o alias não esteja em uso.
- O Operador pode visualizar uma lista de todos os links curtos que criou, incluindo as contagens de cliques atuais.
- O Operador pode desativar um link curto a qualquer momento, impedindo imediatamente novos redirecionamentos.
- O Operador pode reativar um link curto desativado, restaurando o comportamento de redirecionamento.
- O Operador pode atualizar a URL de destino de um link curto existente sem alterar seu short code.
- O Visitante pode acessar um link curto e ser redirecionado para a URL de destino em uma única etapa.
- O Visitante recebe uma mensagem de erro clara e legível quando um link não existe, foi desativado ou expirou.
- O Agendador pode expirar links automaticamente quando sua data e hora de expiração configuradas passarem.

## Regras de Negócio

| ID da Regra | Descrição | Condição | Resultado |
|---|---|---|---|
| BR-001 | Expiração de link | Quando um link curto possui uma data-hora `expiresAt` e o horário UTC atual é ≥ `expiresAt` | O sistema recusa o redirecionamento e exibe ao Visitante um aviso de "Link expirado"; o link não é automaticamente excluído |
| BR-002 | Unicidade de alias personalizado | Quando um Operador submete um alias personalizado idêntico a um alias ativo ou desativado existente | O sistema rejeita a requisição de criação e informa ao Operador que o alias já está em uso |
| BR-003 | Rate limiting no redirecionamento | Quando um único endereço IP faz mais de 60 requisições de redirecionamento em qualquer janela de 60 segundos | O sistema bloqueia temporariamente novas requisições desse IP por 60 segundos e retorna uma resposta de "Muitas requisições" |
| BR-004 | URL de destino deve ter esquema permitido | Quando a URL de destino usa um esquema diferente de `http` ou `https` (ex.: `javascript:`, `ftp://`) | O sistema rejeita a requisição de criação e informa ao Operador que apenas URLs http e https são permitidas |
| BR-005 | Recusa de redirecionamento para link desativado | Quando um Visitante acessa um link curto que um Operador desativou explicitamente | O sistema recusa o redirecionamento e exibe ao Visitante um aviso de "Link indisponível" |
| BR-006 | Latência da contagem de cliques | Quando um Visitante acessa um link curto | A contagem de cliques para aquele link é incrementada em até 30 segundos; não precisa ser síncrona com o redirecionamento |

A fonte e a responsabilidade de cada regra são mantidas no registro de Regras de Negócio correspondente (`docs/functional/...`).

## Fluxos Funcionais

### Caminho Feliz: Visitante acessa um link curto ativo

1. Visitante digita ou clica em uma URL curta (ex.: `https://sho.rt/aB3x9`) no browser.
2. O sistema busca o short code `aB3x9`.
3. O sistema confirma que o link está ativo e não expirado (BR-001).
4. O sistema redireciona o Visitante para a URL de destino.
5. O browser do Visitante carrega a página de destino.
6. O sistema registra um evento de clique para o link (BR-006).

### Caminho Alternativo: Operador cria um link com alias personalizado

1. Operador envia um novo link com URL de destino `https://example.com/very/long/path` e alias `summer-sale`.
2. O sistema verifica que `summer-sale` não está em uso (BR-002).
3. O alias está disponível, portanto o sistema cria o link com short code `summer-sale`.
4. O sistema confirma a criação e exibe a URL curta `https://sho.rt/summer-sale` ao Operador.

### Caminho Alternativo: Link expirado (BR-001)

1. Visitante acessa uma URL curta.
2. O sistema busca o short code e constata que a data de expiração do link passou.
3. O sistema não redireciona o Visitante. Em vez disso, exibe a mensagem "Este link expirou".
4. O Visitante não é enviado a nenhuma URL de destino.

### Caminho Alternativo: Alias personalizado já em uso (BR-002)

1. Operador envia um novo link com alias `summer-sale`.
2. O sistema verifica e constata que `summer-sale` já está em uso por outro link.
3. O sistema rejeita a requisição e informa ao Operador: "O alias 'summer-sale' já está em uso. Por favor, escolha um alias diferente."
4. O Operador escolhe um novo alias ou prossegue sem um (usando o código gerado pelo sistema).

### Exceção: Short code não existe

1. Visitante acessa uma URL curta com um código que não está no sistema.
2. O sistema não encontra um link correspondente.
3. O sistema exibe a mensagem "Link não encontrado". O Visitante não é redirecionado.

### Exceção: Visitante atingiu o rate limit (BR-003)

1. O endereço IP do Visitante faz mais de 60 requisições de redirecionamento em 60 segundos.
2. O sistema bloqueia novas requisições de redirecionamento desse IP por 60 segundos e retorna a mensagem "Muitas requisições".
3. Após 60 segundos, as requisições do Visitante são aceitas novamente.

## Casos de Borda

| Cenário | Resultado Esperado |
|---|---|
| Visitante acessa um link exatamente no momento em que ele expira | O sistema trata o link como expirado (a verificação de expiração compara timestamps UTC; um link com `expiresAt = T` está expirado em qualquer momento ≥ T) |
| Operador tenta criar um link com `expiresAt` no passado | O sistema rejeita a requisição de criação e informa ao Operador que a data de expiração deve ser no futuro |
| Operador atualiza a URL de destino enquanto um Visitante está em processo de redirecionamento | O redirecionamento já em andamento usa a URL de destino que estava em cache no momento em que a requisição chegou; a nova URL se aplica às requisições subsequentes |
| Operador desativa um link e depois o reativa | A contagem de cliques é preservada; o link volta a aceitar redirecionamentos com o mesmo short code |
| A URL de destino em si possui redirecionamentos (cadeia de redirecionamentos) | O sistema armazena e serve a URL de destino original conforme fornecida; não segue nem achata cadeias de redirecionamentos no momento da criação |
| Dois Operadores tentam simultaneamente reivindicar o mesmo alias personalizado | A restrição de unicidade do banco de dados garante que apenas um tenha sucesso; o outro recebe o erro de alias em uso (BR-002) |

## Critérios de Aceite (negócio)

- [ ] Um Operador pode criar um link curto fornecendo apenas uma URL de destino; o sistema retorna uma URL curta funcional em até 3 segundos.
- [ ] Um Visitante que acessa a URL curta é redirecionado para o destino correto sem etapas adicionais.
- [ ] Um Operador pode criar um link curto com um alias personalizado; a URL curta resultante contém exatamente esse alias.
- [ ] Se um Operador tentar criar um link com um alias que já existe, o sistema recusa e explica o motivo sem criar nenhum link.
- [ ] Após um Operador desativar um link, o próximo Visitante que o acessar vê uma mensagem clara de "Link indisponível" em vez de ser redirecionado.
- [ ] Após a data de expiração de um link passar, Visitantes veem uma mensagem clara de "Link expirado" em vez de serem redirecionados.
- [ ] A contagem de cliques de um link aumenta em pelo menos 1 dentro de 30 segundos após um Visitante acessá-lo com sucesso.
- [ ] Um Visitante que tenta acessar um short code inexistente vê a mensagem "Link não encontrado".
