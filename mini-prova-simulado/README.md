# Simulado – Programação em Banco de Dados

## Atividade Avaliada (simulado) – PL/pgSQL e SQL no IFBET

| | |
| --- | --- |
| **Disciplina** | Programação em Banco de Dados |
| **Valor** | 5,0 pontos |
| **Tempo sugerido** | 90 minutos |
| **Recursos** | PostgreSQL 11 ou superior, `psql` ou outro cliente SQL |
| **Inspirado em** | Atividade Avaliada do 1º Bimestre |

---

## Orientações

- Resolva as questões usando recursos de **PL/pgSQL** e **SQL** vistos em aula.
- Respeite **exatamente** os nomes, os parâmetros e as colunas de retorno pedidos em cada assinatura.
- Qualifique as colunas com *alias* (`a.valor`, `u.nome`). As colunas de `RETURNS TABLE` também são variáveis dentro da função e podem gerar ambiguidade.
- Em `RETURN QUERY`, os tipos do `SELECT` precisam coincidir com os declarados em `RETURNS TABLE` (use casts como `::TEXT` e `::BIGINT` quando necessário).
- Teste cada solução com dados reais antes de considerá-la pronta.

---

## Contexto

O **ifbet** representa um sistema de apostas esportivas hipotético. O usuário possui um saldo, escolhe um jogo e registra uma aposta informando o **placar que acredita que vai acontecer**.

Para esta atividade, considere que:

- Um jogo está **encerrado** quando o resultado está preenchido, ou seja, tanto `gols_casa` quanto `gols_visitante` da tabela `jogo` são diferentes de `NULL`.
- Os gols armazenados em `aposta` correspondem ao **palpite do usuário**.
- Uma aposta tem **acerto exato** quando o placar previsto é igual ao placar real.

---

## Esquema do banco

```sql
CREATE TABLE usuario (
    id     SERIAL PRIMARY KEY,
    nome   VARCHAR(100) NOT NULL,
    email  VARCHAR(150),
    saldo  NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (saldo >= 0),
    ativo  BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE equipe (
    id     SERIAL PRIMARY KEY,
    nome   VARCHAR(100) NOT NULL,
    local  VARCHAR(100)
);

CREATE TABLE jogo (
    id              SERIAL PRIMARY KEY,
    id_casa         INT NOT NULL REFERENCES equipe(id),
    id_visitante    INT NOT NULL REFERENCES equipe(id),
    data_jogo       TIMESTAMP NOT NULL DEFAULT now(),
    gols_casa       INT,          -- NULL enquanto o jogo não terminou
    gols_visitante  INT,          -- NULL enquanto o jogo não terminou
    CHECK (id_casa <> id_visitante)
);

CREATE TABLE aposta (
    id              SERIAL PRIMARY KEY,
    id_usuario      INT NOT NULL REFERENCES usuario(id),
    id_jogo         INT NOT NULL REFERENCES jogo(id),
    valor           NUMERIC(12,2) NOT NULL CHECK (valor > 0),
    odd             NUMERIC(6,2)  NOT NULL CHECK (odd > 0),
    gols_casa       INT,          -- palpite do usuário
    gols_visitante  INT,          -- palpite do usuário
    data_aposta     TIMESTAMP NOT NULL DEFAULT now()
);
```

> Se o seu banco do IFBET já possui outras colunas (por exemplo `palpite`, `processada` ou a tabela `transacao`), elas **não são usadas** neste simulado. A regra de jogo encerrado é sempre a do enunciado: placar completo.

### Relacionamentos

```text
usuario 1 ───< aposta >─── 1 jogo >─── 2 equipe (id_casa, id_visitante)
```

---

## Distribuição de pontos

| Questão | Tema | Pontos |
| :-: | --- | :-: |
| 1 | Desempenho de uma equipe como mandante | 1,0 |
| 2 | Registro de palpite com validações | 1,5 |
| 3 | Premiação dos acertos exatos | 1,5 |
| 4 | Média de gols de uma equipe com tratamento de exceção | 1,0 |
| | **Total** | **5,0** |

---

## Questão 1 (1,0 ponto) – Desempenho de uma equipe como mandante

Implemente a **função** abaixo.

```sql
desempenho_mandante(var_equipe_id INTEGER)
RETURNS TABLE (
    jogo_id           INTEGER,
    equipe_visitante  TEXT,
    placar            TEXT,
    resultado         TEXT
)
```

A função deve listar os jogos **encerrados** em que a equipe informada atuou como **mandante** (time da casa).

- `placar` deve seguir o formato `gols_casa x gols_visitante`, por exemplo `2 x 1`.
- `resultado` deve ser `VITORIA`, `EMPATE` ou `DERROTA`, sempre sob a ótica da equipe informada.

### Requisitos

- Considere apenas jogos encerrados.
- Se a equipe não existir ou não tiver jogos encerrados como mandante, a função **não deve retornar linhas**.
- Utilize `CASE` para classificar o resultado.
- Ordene pelo identificador do jogo em ordem crescente.

---

## Questão 2 (1,5 ponto) – Registro de palpite com validações

Implemente a **procedure**.

```sql
registrar_palpite(
    var_usuario_id      INTEGER,
    var_jogo_id         INTEGER,
    var_valor           NUMERIC,
    var_odd             NUMERIC,
    var_gols_casa       INTEGER,
    var_gols_visitante  INTEGER
)
```

A procedure deve registrar uma nova aposta do usuário no jogo informado, debitando o valor apostado do saldo do usuário.

### Requisitos

- Verifique se o valor é maior que zero, se a odd é maior que 1 e se os gols previstos são informados e não negativos. Em caso de violação, interrompa com `RAISE EXCEPTION` e uma mensagem clara.
- Verifique se o usuário e o jogo existem.
- Não permita apostar em jogo **já encerrado**.
- Não permita a operação se o usuário **não tiver saldo suficiente**.
- Cada usuário pode ter **no máximo 3 apostas por jogo**. Se o limite já foi atingido, a aposta não deve ser registrada.
- Quando todas as validações passarem, debite o valor do saldo e insira a aposta com o placar previsto.
- Ao final, informe com `RAISE NOTICE` o identificador da aposta criada e o novo saldo do usuário.
- Se qualquer validação falhar, **nenhuma alteração** deve permanecer no banco.

---

## Questão 3 (1,5 ponto) – Premiação dos acertos exatos

Implemente uma **função**:

```sql
premiacao_acertos_exatos()
RETURNS TABLE (
    usuario_id          INTEGER,
    nome_usuario        TEXT,
    apostas_encerradas  BIGINT,
    acertos_exatos      BIGINT,
    total_apostado      MONEY,
    premio_total        MONEY
)
```

A função deve gerar um relatório dos usuários que possuem apostas em **jogos encerrados**. Para cada usuário, retorne:

- `apostas_encerradas`: quantidade de apostas do usuário em jogos encerrados;
- `acertos_exatos`: quantidade dessas apostas em que o placar previsto é igual ao placar real;
- `total_apostado`: soma dos valores de todas essas apostas;
- `premio_total`: soma do prêmio de cada acerto exato, onde **prêmio = valor apostado × odd**.

### Requisitos

- Considere somente apostas de jogos encerrados. Apostas em jogos pendentes devem ser ignoradas.
- Um usuário sem nenhum acerto exato deve aparecer com `premio_total` igual a zero (e **não** `NULL`).
- Usuários sem apostas em jogos encerrados não devem aparecer.
- Ordene pelo `premio_total` em ordem **decrescente** e, em caso de empate, pelo identificador do usuário em ordem **crescente**.

---

## Questão 4 (1,0 ponto) – Média de gols de uma equipe

Implemente a **função**:

```sql
media_gols_equipe(var_equipe_id INTEGER)
RETURNS NUMERIC
```

A função deve retornar a **média de gols marcados** pela equipe informada nos jogos **encerrados**, considerando tanto os jogos em que ela foi mandante quanto aqueles em que foi visitante. O resultado deve ser arredondado para 2 casas decimais.

### Requisitos

- **Não utilize `AVG()`**: calcule a média dividindo a soma de gols pela quantidade de jogos.
- Obtenha a soma e a quantidade com `SELECT ... INTO`.
- Se a equipe não existir, interrompa com `RAISE EXCEPTION`.
- Se a equipe não tiver jogos encerrados, a divisão por zero deve ser tratada com `EXCEPTION`: exiba uma mensagem com `RAISE NOTICE` e retorne `NULL`.

> **Atenção:** `SUM()` sobre nenhuma linha devolve `NULL`, e `NULL / 0` não gera erro de divisão por zero. Pense em como garantir que a divisão realmente ocorra com o denominador igual a zero.

---

## Critérios de avaliação sugeridos

| Questão | O que é avaliado |
| :-: | --- |
| 1 | Assinatura correta; filtro de jogos encerrados e de mandante; `CASE` do resultado; formato do placar; ordenação; nenhuma linha para equipe inexistente |
| 2 | Todas as validações com mensagens; limite de 3 apostas por jogo; débito do saldo; inserção correta; `RAISE NOTICE` final; ausência de alterações parciais em caso de erro |
| 3 | Filtro de jogos encerrados; contagem do acerto exato com `FILTER`; prêmio = valor × odd; `COALESCE` para zero; agrupamento por usuário; ordenação com desempate |
| 4 | `SELECT INTO`; soma de gols nas duas posições (casa e visitante); sem `AVG()`; tratamento de `division_by_zero`; `RAISE EXCEPTION` para equipe inexistente; arredondamento |

---

## Sugestão de roteiro de teste

Para conferir suas respostas, monte um pequeno conjunto de dados e verifique manualmente os resultados esperados:

1. Cadastre **4 equipes**, **3 usuários** e **5 jogos**, deixando alguns com placar (encerrados) e outros sem (pendentes).
2. Insira apostas variadas: acertos exatos, acertos só de resultado e erros.
3. Faça uma equipe **sem nenhum jogo encerrado** para testar o tratamento de exceção da Questão 4.
4. Faça um usuário com **saldo insuficiente** e outro com **3 apostas no mesmo jogo** para testar a Questão 2.
5. Execute os testes dentro de `BEGIN; ... ROLLBACK;` para não sujar o banco, usando blocos `DO` com `EXCEPTION` para as chamadas que devem falhar.
