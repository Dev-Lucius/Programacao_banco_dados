# Super Resumo – Functions e Stored Procedures em PostgreSQL (PL/pgSQL)

**Base de estudo:** IFBET (usuários, equipes, jogos, apostas, transações)
**Cobre:** Exercícios 19 a 57 e Desafios 1 a 9

---

## Sumário

1. [Function × Procedure](#1-function--procedure)
2. [Estrutura básica de um subprograma](#2-estrutura-básica-de-um-subprograma)
3. [Tipos de retorno](#3-tipos-de-retorno)
4. [Variáveis, `SELECT INTO` e `FOUND`](#4-variáveis-select-into-e-found)
5. [Condicionais: `IF` e `CASE`](#5-condicionais-if-e-case)
6. [Agregações e `GROUP BY`](#6-agregações-e-group-by)
7. [`JOIN`s usados no IFBET](#7-joins-usados-no-ifbet)
8. [Window function: `ROW_NUMBER()`](#8-window-function-row_number)
9. [Estruturas de repetição](#9-estruturas-de-repetição)
10. [Mensagens: `RAISE NOTICE` e `RAISE EXCEPTION`](#10-mensagens-raise-notice-e-raise-exception)
11. [Tratamento de erros com `EXCEPTION`](#11-tratamento-de-erros-com-exception)
12. [Transações, `COMMIT` e travas](#12-transações-commit-e-travas)
13. [Funções utilitárias do PostgreSQL](#13-funções-utilitárias-do-postgresql)
14. [Padrões de projeto aplicados ao IFBET](#14-padrões-de-projeto-aplicados-ao-ifbet)
15. [Armadilhas comuns](#15-armadilhas-comuns)
16. [Mapa: exercício → conceito](#16-mapa-exercício--conceito)
17. [Colinha de sintaxe](#17-colinha-de-sintaxe)

---

## 1. Function × Procedure

| Característica | `FUNCTION` | `PROCEDURE` |
| --- | --- | --- |
| Como é chamada | `SELECT f(...)` ou `SELECT * FROM f(...)` | `CALL p(...)` |
| Retorno | Obrigatório (`RETURNS ...`) | Não retorna valor |
| Usável dentro de `SELECT`, `WHERE`, `JOIN` | Sim | Não |
| Pode usar `COMMIT` / `ROLLBACK` | **Não** | **Sim** (PostgreSQL 11+) |
| Uso típico | Consultas, cálculos, validações, relatórios | Operações que alteram dados: depositar, sacar, encerrar jogo, processar lotes |

**Regra prática:** se o objetivo é *consultar ou calcular*, use function. Se é *executar uma ação com efeitos* (e talvez controlar transação), use procedure.

---

## 2. Estrutura básica de um subprograma

```sql
CREATE OR REPLACE FUNCTION nome(p_param TIPO, ...)
RETURNS TIPO
LANGUAGE plpgsql
AS $$
DECLARE
    v_variavel TIPO := valor_inicial;
BEGIN
    -- comandos
    RETURN valor;
END;
$$;
```

```sql
CREATE OR REPLACE PROCEDURE nome(p_param TIPO, ...)
LANGUAGE plpgsql
AS $$
BEGIN
    -- comandos (sem RETURN de valor)
END;
$$;
```

Pontos importantes:

- **`$$ ... $$` (dollar quoting):** delimita o corpo sem precisar escapar aspas simples.
- **`CREATE OR REPLACE`:** recria o subprograma. Não permite mudar o tipo de retorno de uma function já existente; nesse caso use `DROP FUNCTION` antes.
- **Blocos:** `DECLARE` (opcional) → `BEGIN` → `END;`.
- **Parâmetros com valor padrão:** `p_palpite TEXT DEFAULT 'C'` (os parâmetros com padrão ficam por último).
- **Convenção adotada:** `p_` para parâmetros, `v_` para variáveis locais, `r_`/`registro` para `RECORD`. Evita conflito com nomes de colunas.
- **Chamada:**

```sql
SELECT saldo_suficiente(1, 100);        -- function escalar
SELECT * FROM ranking_apostadores();    -- function que retorna tabela
CALL depositar(1, 500);                 -- procedure
```

---

## 3. Tipos de retorno

| Tipo | Quando usar | Exemplo no IFBET |
| --- | --- | --- |
| Escalar (`INT`, `NUMERIC`, `TEXT`, `BOOLEAN`) | Um único valor | `obter_saldo`, `usuario_existe`, `total_apostado_loop` |
| `VOID` | Só executa algo (ex.: `RAISE NOTICE`) | `percorrer_usuarios()` |
| `SETOF tipo` | Várias linhas de **uma** coluna | `simular_valores`, `gerar_1_a_10` |
| `RETURNS TABLE (...)` | Várias linhas e colunas | `ranking_apostadores`, `historico_apostas`, `classificacao_campeonato` |

### Devolvendo várias linhas

- **`RETURN QUERY <select>`**: acrescenta ao resultado todas as linhas do `SELECT`. É a forma mais direta.
- **`RETURN NEXT valor`**: acrescenta **uma** linha por vez (útil dentro de loops). Termina-se com `RETURN;`.

```sql
CREATE OR REPLACE FUNCTION apostas_acima(p_valor NUMERIC)
RETURNS TABLE (id_aposta INT, usuario TEXT, id_jogo INT, valor NUMERIC, odd NUMERIC)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT a.id, u.nome::TEXT, a.id_jogo, a.valor, a.odd
      FROM aposta a
      JOIN usuario u ON u.id = a.id_usuario
     WHERE a.valor > p_valor;
END;
$$;
```

**Atenção aos tipos:** em `RETURN QUERY`, os tipos das colunas do `SELECT` precisam bater com os declarados em `RETURNS TABLE`. Por isso aparecem casts como `u.nome::TEXT` (de `VARCHAR`), `COUNT(*)::BIGINT` ou `SUM(...)::BIGINT`. O tamanho (`NUMERIC(12,2)` × `NUMERIC`) é ignorado.

**As colunas de `RETURNS TABLE` viram variáveis** dentro da function. Para evitar ambiguidade com colunas reais, qualifique tudo com alias (`a.valor`, `u.nome`).

---

## 4. Variáveis, `SELECT INTO` e `FOUND`

### Atribuição

```sql
v_total := v_total + registro.valor;
```

### `SELECT ... INTO`

Guarda o resultado de uma consulta em variáveis.

```sql
SELECT u.nome INTO v_nome FROM usuario u WHERE u.id = p_usuario_id;

SELECT a.id_usuario, a.valor
  INTO v_usuario_id, v_valor
  FROM aposta a
 WHERE a.id = p_aposta_id;
```

| Situação | `SELECT INTO` normal | `SELECT INTO STRICT` |
| --- | --- | --- |
| Nenhuma linha | Variável fica `NULL`; `FOUND = FALSE` | Dispara `NO_DATA_FOUND` |
| Mais de uma linha | Usa a primeira | Dispara `TOO_MANY_ROWS` |

### `FOUND`

Variável booleana especial, atualizada após `SELECT INTO`, `UPDATE`, `INSERT`, `DELETE`, `FETCH` e loops `FOR`.

```sql
UPDATE aposta SET odd = p_nova_odd WHERE id = p_aposta_id;
IF NOT FOUND THEN
    RAISE EXCEPTION 'Aposta % não existe', p_aposta_id;
END IF;
```

### Outros recursos

- **`RECORD`:** variável genérica que recebe uma linha (`registro.nome`, `registro.saldo`).
- **`INSERT ... RETURNING id INTO v_id`:** captura o ID recém-gerado (usado em `criar_aposta`).

---

## 5. Condicionais: `IF` e `CASE`

### `IF / ELSIF / ELSE`

```sql
IF v_saldo = 0 THEN
    RETURN 'SEM SALDO';
ELSIF v_saldo < 100 THEN
    RETURN 'SALDO BAIXO';
ELSE
    RETURN 'SALDO ALTO';
END IF;
```

### `CASE`

Duas formas; as duas funcionam tanto dentro de consultas quanto como comando PL/pgSQL.

```sql
-- CASE "pesquisado" dentro de um SELECT
SELECT CASE
           WHEN j.encerrado THEN j.gols_casa::TEXT || ' x ' || j.gols_visitante::TEXT
           ELSE 'A REALIZAR'
       END
  FROM jogo j;

-- Usado em resultado_partida
SELECT CASE
           WHEN p_gols_casa > p_gols_visitante THEN 'C'
           WHEN p_gols_casa < p_gols_visitante THEN 'V'
           ELSE 'E'
       END;
```

**Como escolher:** `IF` para controlar o fluxo do programa; `CASE` para escolher *valores* dentro de uma expressão.

---

## 6. Agregações e `GROUP BY`

| Função | O que faz |
| --- | --- |
| `COUNT(*)` / `COUNT(col)` | Conta linhas / conta valores não nulos |
| `SUM(col)` | Soma |
| `AVG(col)` | Média |
| `MAX(col)` / `MIN(col)` | Maior / menor |

Pontos importantes:

- **`COALESCE(x, 0)`** troca `NULL` por um valor padrão. `SUM`, `MAX`, `MIN` e `AVG` retornam `NULL` quando não há linhas.
- **`GROUP BY`** é necessário quando se mistura coluna comum com agregação.
- **`COUNT(*) FILTER (WHERE condição)`** conta só as linhas que atendem à condição. Foi a base das estatísticas de vitórias, empates e derrotas:

```sql
SELECT COUNT(*)                                             AS jogos,
       COUNT(*) FILTER (WHERE pe.gols_pro >  pe.gols_contra) AS vitorias,
       COUNT(*) FILTER (WHERE pe.gols_pro =  pe.gols_contra) AS empates,
       COUNT(*) FILTER (WHERE pe.gols_pro <  pe.gols_contra) AS derrotas,
       COALESCE(SUM(pe.gols_pro), 0)                        AS gols_marcados
  FROM vw_partidas_equipe pe
 WHERE pe.id_equipe = 1;
```

- **`ORDER BY 2 DESC, 1`:** ordena pela posição da coluna no `SELECT`. Usado em funções `RETURNS TABLE` para fugir de ambiguidade de nomes.

### Pontuação de campeonato (classificação)

```text
P  = 3 × vitórias + 1 × empates
J  = jogos       V = vitórias     E = empates     D = derrotas
GP = gols pró    GC = gols contra SG = GP − GC
Critérios de desempate usados: P, V, SG, GP, nome
```

---

## 7. `JOIN`s usados no IFBET

| Tipo | Uso | Exemplo |
| --- | --- | --- |
| `JOIN` (inner) | Só linhas com correspondência | `ranking_apostadores`, `usuarios_com_apostas` |
| `LEFT JOIN` | Mantém o lado esquerdo mesmo sem correspondência | `ranking_equipes`, `classificacao_campeonato`, `ranking_financeiro` |
| `LEFT JOIN ... WHERE x.id IS NULL` | **Anti-join**: "quem não tem" | `usuarios_sem_apostas` |
| Duas junções na mesma tabela | Obter mandante e visitante | `JOIN equipe ec ON ec.id = j.id_casa JOIN equipe ev ON ev.id = j.id_visitante` |

Condição de junção composta, usada para contar jogos de uma equipe como mandante **ou** visitante:

```sql
LEFT JOIN jogo j ON eq.id IN (j.id_casa, j.id_visitante)
```

### View de apoio: cada partida sob a ótica de cada equipe

Uma partida encerrada gera **duas linhas**, uma para cada equipe, com gols pró e contra. Isso simplifica estatísticas, classificação e artilharia:

```sql
CREATE VIEW vw_partidas_equipe AS
SELECT j.id AS id_jogo, j.id_casa AS id_equipe, j.id_visitante AS id_adversario,
       j.gols_casa AS gols_pro, j.gols_visitante AS gols_contra
  FROM jogo j WHERE j.encerrado
UNION ALL
SELECT j.id, j.id_visitante, j.id_casa, j.gols_visitante, j.gols_casa
  FROM jogo j WHERE j.encerrado;
```

---

## 8. Window function: `ROW_NUMBER()`

Numera linhas sem colapsá-las (diferente do `GROUP BY`).

```sql
SELECT ROW_NUMBER() OVER (ORDER BY u.saldo DESC, u.nome) AS posicao,
       u.nome, u.saldo
  FROM usuario u;
```

- `OVER (ORDER BY ...)` define a ordem da numeração.
- Pode combinar com agregações: `ROW_NUMBER() OVER (ORDER BY ..., COALESCE(SUM(a.valor),0) DESC)` junto de `GROUP BY` (usado em `ranking_financeiro`).
- Retorna `BIGINT`.

---

## 9. Estruturas de repetição

### 9.1 `FOR ... IN <consulta> LOOP`

Percorre o resultado de um `SELECT`; a variável do laço é um `RECORD`.

```sql
FOR registro IN
    SELECT u.nome, u.saldo FROM usuario u ORDER BY u.id
LOOP
    RAISE NOTICE 'Usuário: % | Saldo: %', registro.nome, registro.saldo;
END LOOP;
```

Usado em: percorrer usuários, apostas e equipes; histórico em texto; bônus em lote; liquidação de apostas; geração de campeonato.

### 9.2 `WHILE condição LOOP`

Repete enquanto a condição for verdadeira.

```sql
WHILE v_i < p_quantidade LOOP
    RETURN NEXT ROUND((10 + random() * 490)::NUMERIC, 2);
    v_i := v_i + 1;
END LOOP;
```

### 9.3 `LOOP ... EXIT WHEN ... END LOOP`

Laço "infinito" que o programador interrompe.

```sql
LOOP
    RETURN NEXT v_i;
    v_i := v_i + 1;
    EXIT WHEN v_i > 10;
END LOOP;
```

### 9.4 `EXIT` e `CONTINUE`

| Comando | Efeito |
| --- | --- |
| `EXIT` / `EXIT WHEN cond` | Sai do laço |
| `CONTINUE` / `CONTINUE WHEN cond` | Pula para a próxima iteração |

`CONTINUE` foi usado em `simular_apostas` para descartar sorteios em que o usuário não tinha saldo.

### 9.5 Cursor explícito + `WHILE FOUND`

Quando o exercício pede `WHILE` ou `LOOP` "puro" sobre linhas de uma consulta, usa-se um cursor:

```sql
DECLARE
    c_apostas CURSOR FOR SELECT a.id FROM aposta a WHERE a.id_usuario = p_usuario_id;
    v_id INT;
BEGIN
    OPEN c_apostas;
    FETCH c_apostas INTO v_id;
    WHILE FOUND LOOP
        v_qtd := v_qtd + 1;
        FETCH c_apostas INTO v_id;
    END LOOP;
    CLOSE c_apostas;
```

`FETCH` atualiza `FOUND`: `TRUE` se trouxe uma linha, `FALSE` quando acabaram.

### 9.6 Proteção contra laço infinito

Em `simular_apostas`, um contador de tentativas (`v_tentativas < v_max`) garante que o `WHILE` termina mesmo que ninguém tenha saldo.

---

## 10. Mensagens: `RAISE NOTICE` e `RAISE EXCEPTION`

| Comando | Efeito |
| --- | --- |
| `RAISE NOTICE 'texto %', valor;` | Mostra uma mensagem informativa e **continua** a execução |
| `RAISE EXCEPTION 'texto %', valor;` | Gera um erro, **interrompe** o subprograma e desfaz as alterações da transação (ou do bloco com tratamento) |

Regras:

- Cada `%` é substituído, em ordem, por um argumento. **A quantidade de `%` deve ser igual à de argumentos.**
- Para imprimir o caractere `%`, escreva `%%`.
- Para quebra de linha em textos, use a string `E'\n'`.

---

## 11. Tratamento de erros com `EXCEPTION`

```sql
BEGIN
    -- comandos que podem falhar
EXCEPTION
    WHEN condição THEN
        -- tratamento
    WHEN OTHERS THEN
        -- qualquer outro erro
END;
```

### Condições vistas

| Condição | Quando ocorre |
| --- | --- |
| `NO_DATA_FOUND` | `SELECT INTO STRICT` sem linhas |
| `division_by_zero` | Divisão por zero |
| `check_violation` | Quebra de `CHECK` (ex.: saldo negativo) |
| `OTHERS` | Captura qualquer erro não tratado antes |

### Variáveis disponíveis no handler

- **`SQLSTATE`:** código do erro (ex.: `23514`, `22012`).
- **`SQLERRM`:** mensagem do erro.

```sql
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Erro (SQLSTATE %): %', SQLSTATE, SQLERRM;
        RETURN FALSE;
```

### Propriedade fundamental

Um bloco `BEGIN ... EXCEPTION ... END` funciona como um **savepoint** (subtransação). Se algo falha dentro dele, **tudo o que o bloco já alterou é desfeito** antes de o handler rodar. Isso garante que não existe "débito sem crédito" em `transferir_seguro`.

### Duas estratégias

| Estratégia | Exemplo | Resultado |
| --- | --- | --- |
| Engolir o erro e avisar | `depositar_seguro` (`RAISE NOTICE 'Depósito não realizado.'`) | O chamador não recebe erro |
| Relançar com mensagem amigável | `transferir_seguro` (`RAISE EXCEPTION 'Transferência não realizada: %', SQLERRM`) | O chamador percebe a falha |

---

## 12. Transações, `COMMIT` e travas

### Atomicidade padrão

Um `CALL` (ou um comando isolado) executa dentro de **uma transação**. Se ocorrer um `RAISE EXCEPTION` sem tratamento, **tudo** é desfeito.

### `COMMIT` em procedures (processamento em lote)

Confirmar a cada N registros evita transações gigantes e preserva o progresso já feito:

```sql
FOR registro IN SELECT u.id FROM usuario u ORDER BY u.id LOOP
    UPDATE usuario SET saldo = saldo + 10 WHERE id = registro.id;
    v_cont := v_cont + 1;

    IF v_cont % 100 = 0 THEN
        COMMIT;                 -- confirma cada lote de 100
    END IF;
END LOOP;
COMMIT;                         -- confirma o último lote parcial
```

Regras e limitações:

- Só **procedures** podem usar `COMMIT`/`ROLLBACK`; functions não.
- A procedure deve ser chamada com `CALL` **fora** de um bloco `BEGIN ... COMMIT` explícito.
- **Não é permitido `COMMIT` dentro de um bloco que tenha `EXCEPTION`.**
- `i % 100 = 0` (resto da divisão) é o truque para "a cada 100".

### Travas de linha: `FOR UPDATE`

```sql
SELECT u.saldo INTO v_saldo
  FROM usuario u
 WHERE u.id = p_usuario_id
   FOR UPDATE;
```

Bloqueia a linha até o fim da transação, impedindo que dois saques simultâneos leiam o mesmo saldo e gastem duas vezes. Com `JOIN`, use `FOR UPDATE OF alias` para travar apenas uma das tabelas.

### Defesa em profundidade

A validação no código (`IF v_saldo < p_valor THEN RAISE EXCEPTION`) é a primeira barreira; o `CHECK (saldo >= 0)` na tabela é a última.

---

## 13. Funções utilitárias do PostgreSQL

| Função / recurso | Uso nos exercícios |
| --- | --- |
| `random()` | Número `double` entre 0 e 1 (valores, odds e placares aleatórios) |
| `floor(x)` | Arredonda para baixo: `floor(random() * 5)::INT` gera 0 a 4 |
| `ROUND(x, 2)` | Arredonda em 2 casas (prêmio, odd, valor simulado) |
| `ORDER BY random() LIMIT 1` | Sorteia uma linha de uma tabela |
| `ARRAY['C','E','V'][i]` | Escolhe um elemento de um array pelo índice (começa em 1) |
| `COALESCE(a, b)` | Primeiro valor não nulo |
| `NULLIF(a, b)` | Retorna `NULL` se `a = b` |
| `to_char(x, 'FM990.00')` | Formata número (a odd `2.5` vira `2.50`) |
| `translate(txt, de, para)` | Troca caracteres; usado para converter `1,500.00` em `1.500,00` |
| `\|\|` | Concatenação de texto (qualquer `NULL` zera o resultado) |
| `RTRIM(txt, E'\n')` | Remove quebras de linha do final |
| `EXISTS (SELECT 1 ...)` | Testa existência de linhas (base de `usuario_existe` etc.) |
| `now()` | Data e hora atuais |
| `::TIPO` | Conversão de tipo (`::TEXT`, `::BIGINT`, `::INT`, `::NUMERIC`) |

---

## 14. Padrões de projeto aplicados ao IFBET

### 14.1 Validar → Agir → Registrar

Quase toda procedure segue esta ordem:

```text
1. Validar entradas (valor > 0, odd > 0, palpite válido)
2. Validar existência (usuário, jogo, aposta)
3. Validar regras de negócio (saldo suficiente, jogo não encerrado)
4. Executar a alteração (UPDATE / INSERT / DELETE)
5. Registrar a operação (INSERT em transacao)
6. Informar o resultado (RAISE NOTICE)
```

### 14.2 Livro-razão (`transacao`)

Toda movimentação financeira vira uma linha com **valor com sinal**:

| Tipo | Sinal | Origem |
| --- | :-: | --- |
| `DEPOSITO` | + | `depositar` |
| `SAQUE` | − | `sacar` |
| `TRANSF_ENVIADA` | − | `transferir`, `transferir_seguro` |
| `TRANSF_RECEBIDA` | + | `transferir`, `transferir_seguro` |
| `APOSTA` | − | `criar_aposta`, `simular_apostas` |
| `ESTORNO` | + | `cancelar_aposta` |
| `PREMIO` | + | `encerrar_jogo`, `processar_apostas` |
| `BONUS` | + | `processar_bonus` |
| `AJUSTE` | ± | `alterar_saldo` |
| `LIMPEZA` | − | `limpar_usuarios_inativos` |

O extrato (`extrato_usuario`) é simplesmente um `SELECT` ordenado dessa tabela.

### 14.3 Ciclo de vida de uma aposta

```text
criar_aposta        → debita o saldo, cria a aposta (processada = FALSE)
cancelar_aposta     → permitido só com jogo aberto: devolve o valor e apaga a aposta
encerrar_jogo       → grava o placar, paga as vencedoras, marca TODAS como processadas
processar_apostas   → liquida o que ficou pendente em jogos já encerrados
```

### 14.4 Regras de apostas e prêmios

- **Palpite:** `C` (vitória da casa), `E` (empate), `V` (vitória do visitante).
- **Resultado da partida:** função `resultado_partida(gols_casa, gols_visitante)` devolve `C`, `E` ou `V`.
- **Vencedora:** `palpite = resultado_partida(...)`.
- **Prêmio:** `valor × odd` (como o valor já foi debitado ao apostar, o prêmio devolve a aposta e o lucro).
- **Idempotência:** o campo `processada` impede pagar duas vezes.

### 14.5 Geração de campeonato

```text
Para cada equipe A (mandante):
    Para cada equipe B <> A (visitante):
        Se ainda não existe jogo A x B:
            cria o jogo
            sorteia o placar
            CALL encerrar_jogo(...)
No fim: exibe classificacao_campeonato()
```

Impedir `A x A` é feito no `WHERE eq.id <> r_casa.id` (e há um `CHECK (id_casa <> id_visitante)` na tabela).

### 14.6 Reaproveitamento de código

- **Funções de apoio** (`usuario_existe`, `saldo_suficiente`, `jogo_existe`, `nome_jogo`, `fmt_moeda`) mantêm as procedures curtas e legíveis.
- **View** (`vw_partidas_equipe`) evita repetir a lógica "mandante ou visitante".

---

## 15. Armadilhas comuns

| Problema | Causa | Solução |
| --- | --- | --- |
| `column reference "x" is ambiguous` | Nome de parâmetro/coluna de saída igual a nome de coluna | Prefixos `p_`/`v_`, aliases e `ORDER BY` por posição; ou `#variable_conflict use_column` |
| `structure of query does not match function result type` | Tipos do `SELECT` diferentes dos de `RETURNS TABLE` | Casts (`::TEXT`, `::BIGINT`) |
| `NO_DATA_FOUND` nunca dispara | `SELECT INTO` sem `STRICT` | Use `SELECT INTO STRICT` ou teste `IF NOT FOUND` |
| `cannot commit while a subtransaction is active` | `COMMIT` dentro de bloco com `EXCEPTION` | Retire o `COMMIT` do bloco com tratamento |
| `invalid transaction termination` | Procedure com `COMMIT` chamada dentro de transação explícita ou de uma function | Chame com `CALL` direto, em modo autocommit |
| Resultado `NULL` inesperado | `NULL` em concatenação ou em `SUM`/`MAX` sem linhas | `COALESCE` |
| Mensagem `RAISE` falha | Número de `%` diferente do número de argumentos | Conferir a contagem |
| Laço infinito em simulações | Condição de saída nunca satisfeita | Limite de tentativas |
| `CREATE OR REPLACE` falha | Mudança de tipo de retorno | `DROP FUNCTION` antes |
| Pagamento duplicado | Processar a mesma aposta duas vezes | Flag `processada` |
| Saldo lido por duas sessões ao mesmo tempo | Falta de trava | `SELECT ... FOR UPDATE` |
| Divisão inteira inesperada | `INT / INT` | Usar `NUMERIC` nos parâmetros |

---

## 16. Mapa: exercício → conceito

| Exercícios | Subprogramas | Conceito principal |
| --- | --- | --- |
| 19–24 | `listar_apostas_usuario`, `jogos_equipe`, `jogos_futuros`, `jogos_encerrados`, `apostas_acima`, `usuarios_com_saldo_minimo` | `RETURNS TABLE`, `RETURN QUERY`, `JOIN`, `CASE` |
| 25–28 | `ranking_apostadores`, `ranking_equipes`, `usuarios_sem_apostas`, `usuarios_com_apostas` | Agregação + `GROUP BY`, `LEFT JOIN`, anti-join |
| 29–31 | `percorrer_usuarios`, `percorrer_apostas`, `percorrer_equipes` | `FOR ... IN SELECT`, `RECORD`, `RAISE NOTICE` |
| 32–33 | `total_apostado_loop`, `contar_apostas_loop` | Acumuladores em loop (sem `SUM`/`COUNT`) |
| 34–37 | `contar_apostas`, `simular_valores`, `gerar_1_a_10`, `encontrar_aposta_alta` | `WHILE`, `LOOP`/`EXIT WHEN`, cursor + `FOUND`, `RETURN NEXT`, `random()` |
| 38–42 | `depositar`, `sacar`, `transferir`, `alterar_odd`, `alterar_saldo` | Procedures, validação com `IF`, `RAISE EXCEPTION`, `FOR UPDATE` |
| 43–46 | `nome_usuario_seguro`, `calcular_odds`, `atualizar_saldo_seguro`, `depositar_seguro` | `EXCEPTION`, `STRICT`, `division_by_zero`, `WHEN OTHERS`, `SQLSTATE`/`SQLERRM` |
| 47–50 | `historico_apostas`, `historico_apostas_texto`, `estatisticas_equipe`, `classificacao_campeonato` | Múltiplos `JOIN`s, montagem de texto, `FILTER`, view, pontuação |
| 51 | `transferir_seguro` | Bloco com `EXCEPTION` como savepoint |
| 52–54 | `processar_bonus`, `processar_bonus_lotes`, `limpar_usuarios_inativos` | Processamento em lote e `COMMIT` periódico |
| 55–57 | `criar_aposta`, `cancelar_aposta`, `encerrar_jogo` | Integração de várias tabelas, `INSERT ... RETURNING`, liquidação de apostas |
| Desafios 1–4 | `relatorio_usuario`, `extrato_usuario`, `ranking_financeiro`, `artilharia` | Relatórios, livro-razão, `ROW_NUMBER()` |
| Desafios 5–7 | `gerar_campeonato`, `simular_apostas`, `processar_apostas` | Laços aninhados, simulação, processamento em massa |
| Desafios 8–9 | Sistema completo + script `psql` | Integração e testes ponta a ponta |

---

## 17. Colinha de sintaxe

```sql
-- FUNCTION escalar
CREATE OR REPLACE FUNCTION f(p_id INT) RETURNS NUMERIC
LANGUAGE plpgsql AS $$
DECLARE v_x NUMERIC;
BEGIN
    SELECT t.col INTO v_x FROM tabela t WHERE t.id = p_id;
    RETURN v_x;
END; $$;

-- FUNCTION que retorna tabela
CREATE OR REPLACE FUNCTION g(p_id INT)
RETURNS TABLE (a INT, b TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY SELECT t.a, t.b::TEXT FROM tabela t WHERE t.id = p_id;
END; $$;

-- FUNCTION que retorna várias linhas de uma coluna
CREATE OR REPLACE FUNCTION h() RETURNS SETOF INT
LANGUAGE plpgsql AS $$
BEGIN
    FOR i IN 1..3 LOOP RETURN NEXT i; END LOOP;
    RETURN;
END; $$;

-- PROCEDURE com validação, alteração e registro
CREATE OR REPLACE PROCEDURE p(p_id INT, p_valor NUMERIC)
LANGUAGE plpgsql AS $$
BEGIN
    IF p_valor <= 0 THEN
        RAISE EXCEPTION 'Valor inválido: %', p_valor;
    END IF;

    UPDATE usuario SET saldo = saldo + p_valor WHERE id = p_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Usuário % não existe', p_id;
    END IF;

    INSERT INTO transacao (id_usuario, tipo, valor) VALUES (p_id, 'DEPOSITO', p_valor);
END; $$;

-- Tratamento de erro
BEGIN
    ...
EXCEPTION
    WHEN division_by_zero THEN ...
    WHEN OTHERS THEN RAISE NOTICE '% - %', SQLSTATE, SQLERRM;
END;

-- Laços
FOR r IN SELECT ... LOOP ... END LOOP;
WHILE condicao LOOP ... END LOOP;
LOOP ... EXIT WHEN condicao; END LOOP;

-- Cursor
OPEN c; FETCH c INTO v; WHILE FOUND LOOP ... FETCH c INTO v; END LOOP; CLOSE c;

-- Lote com COMMIT
IF v_cont % 100 = 0 THEN COMMIT; END IF;

-- Chamadas
SELECT f(1);
SELECT * FROM g(1);
CALL p(1, 100);
```

---

## Checklist final de revisão

- [ ] Sei quando usar `FUNCTION` e quando usar `PROCEDURE`.
- [ ] Sei devolver várias linhas com `RETURNS TABLE` + `RETURN QUERY` e com `RETURN NEXT`.
- [ ] Sei a diferença entre `SELECT INTO` e `SELECT INTO STRICT`, e para que serve `FOUND`.
- [ ] Domino `FOR`, `WHILE`, `LOOP`/`EXIT`, `CONTINUE` e cursores.
- [ ] Sei diferenciar `RAISE NOTICE` de `RAISE EXCEPTION`.
- [ ] Entendo que `BEGIN ... EXCEPTION` desfaz o que o bloco fez.
- [ ] Sei usar `COMMIT` em lotes e conheço suas restrições.
- [ ] Sei evitar ambiguidades de nomes e erros de tipo em `RETURN QUERY`.
- [ ] Consigo montar relatórios com `JOIN`, `GROUP BY`, `FILTER` e `ROW_NUMBER()`.
- [ ] Sigo o padrão validar → agir → registrar nas procedures.
