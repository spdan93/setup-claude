# ADR: Uso de Codificação de Contador em Base62 para Short Codes

## Situação

Aceito

## Contexto

O Serviço de Encurtamento de URLs precisa atribuir um short code único a cada link armazenado no sistema. Os short codes aparecem em URLs públicas, portanto devem ser:

- Curtos o suficiente para serem práticos (alvo ≤7 caracteres para o futuro previsível).
- Globalmente únicos sem exigir uma etapa de coordenação distribuída.
- Seguros para URL sem codificação percentual.

O alvo inicial de implementação é 10 milhões de novos links por dia com um PostgreSQL primário de região única. O banco de dados já auto-incrementa uma chave primária `BIGINT` para cada linha inserida.

Três propriedades estavam em tensão:
1. **Brevidade** — menos caracteres são melhores para URLs voltadas ao usuário.
2. **Garantia de unicidade** — nenhuma linha pode mapear para o mesmo short code.
3. **Previsibilidade de enumeração** — códigos que revelam a ordem de inserção expõem todo o inventário de links para scraping.

A equipe aceitou que a propriedade 3 poderia ser parcialmente mitigada na camada de aplicação (ver Consequências) em vez de exigir um esquema de geração mais complexo.

## Decisão

Codificaremos o ID de linha auto-incrementado do PostgreSQL em base62 (`[0-9A-Za-z]`, 62 símbolos) para produzir short codes. O módulo `Encoder` (`src/lib/encoder.ts`) converte o inteiro para uma string base62 usando ordenação big-endian de dígitos; a decodificação é a inversa exata. Os códigos são armazenados na coluna `links.short_code` após a inserção da linha e o ID ser conhecido.

## Consequências

**Positivas:**
- A unicidade é garantida pela chave primária do banco de dados — nenhuma verificação de unicidade separada ou loop de nova tentativa é necessário.
- O comprimento do código cresce de forma lenta e previsível: 4 caracteres suportam ~14,7 M de links, 5 caracteres ~916 M de links. A constante que controla o comprimento mínimo do código pode ser incrementada sem alteração de esquema.
- Codificação e decodificação são funções puras O(log n) sem I/O; são trivialmente testáveis em testes unitários.
- Decodificar um short code para seu ID de linha é útil para fluxos de auditoria e suporte sem um índice adicional.

**Negativas:**
- Os códigos são enumeráveis: um observador pode iterar códigos consecutivos para descobrir todos os links ativos. Links de alto valor ou sensíveis devem usar o recurso de alias personalizado (que aceita qualquer string `[a-zA-Z0-9_-]` de até 30 caracteres) para evitar revelar a posição do contador.
- O esquema acopla a geração de códigos à chave primária de uma única tabela do banco de dados. Se o serviço vier a fazer sharding em múltiplos bancos de dados, será necessária uma camada de coordenação para evitar colisão de IDs. Isso está registrado como risco futuro, mas não está no escopo da arquitetura atual.

**Neutra:**
- O alfabeto de codificação (`0-9A-Za-z`) é intencionalmente case-sensitive. As URLs neste serviço diferenciam maiúsculas de minúsculas; o handler de redirecionamento trata `aB3x` e `ab3x` como códigos diferentes.

## Alternativas Consideradas

| Alternativa | Motivo da rejeição |
|---|---|
| **UUID aleatório (128 bits), armazenado completo** | Códigos hexadecimais de 32 caracteres são longos demais para URLs voltadas ao usuário; truncar para 8 caracteres produz probabilidade de colisão de ~1 em 4300 após 1 M de links, exigindo um loop de nova tentativa para verificar colisões. |
| **NanoID (aleatório, URL-safe, 8 caracteres)** | Sem colisão na nossa escala, mas ainda exige uma verificação de unicidade no banco a cada inserção e uma nova tentativa em caso de colisão rara; adiciona latência no caminho de escrita e complexidade na camada de repositório. |
| **Hashids sobre o ID de linha** | Produz códigos não enumeráveis a partir de inteiros, abordando a preocupação de enumeração. Rejeitado porque a biblioteca Hashids introduz uma dependência para uma preocupação puramente de codificação, o alfabeto e o salt devem ser mantidos estáveis para sempre (mudança quebra se vazar ou for rotacionado), e a equipe considerou o risco de enumeração aceitável dadas as mitigações na camada de aplicação. |
| **ID distribuído estilo Snowflake** | Excessivo para um deploy de região única. Adiciona um serviço externo de coordenação ou exige atribuição cuidadosa de node-ID. Revisar se o serviço fizer sharding. |
