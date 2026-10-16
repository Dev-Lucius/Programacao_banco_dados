# Programação em Banco de Dados

## Atividade Avaliada – 1º Bimestre

| | |
| --- | --- |
| **Disciplina** | Programação em Banco de Dados |
| **Atividade** | Avaliada 1º Bim. |
| **Valor** | 5,0 pontos |
| **Professor** | Igor Avila Pereira |

---

## Contexto

Como é de conhecimento de todos da turma, o **ifbet** representa um sistema de apostas esportivas hipotético, conforme o script disponibilizado em aula.

Para esta atividade, considere que um jogo está **encerrado** quando o resultado está preenchido, ou seja, tanto os gols do visitante como os do time da casa já foram setados. Os gols armazenados em `aposta` correspondem ao **palpite do usuário**.

Resolva as questões usando recursos de **PL/pgSQL** e **SQL** apresentados durante as aulas.

---

## Distribuição de pontos

| Questão | Tema | Pontos |
| :-: | --- | :-: |
| 1 | Relatório de acertos por usuário em um jogo | 1,5 |
| 2 | Cancelamento em lote das apostas de um usuário para um jogo | 1,5 |
| 3 | Auditoria de apostas pendentes | 2,0 |
| | **Total** | **5,0** |

---

## Questão 1 (1,5 ponto) – Relatório de acertos por usuário em um jogo

Implemente a **função** abaixo.

```sql
relatorio_acertos_jogo(var_jogo_id INTEGER)
RETURNS TABLE (
    usuario_id        INTEGER,
    nome_usuario      TEXT,
    acertos_exatos    BIGINT,
    acertos_resultado BIGINT,
    total_apostas     BIGINT
)
```

A função deve produzir **uma linha para cada usuário que tenha apostado no jogo informado**. Considere as seguintes classificações para cada aposta de um jogo encerrado:

- **Acerto exato:** o placar previsto é igual ao placar real.
- **Acerto do resultado:** o usuário não acertou o placar exato, mas previu corretamente o vencedor ou o empate.
- **Sem acerto:** nenhuma das condições anteriores foi satisfeita.

### Requisitos

- Se o jogo não estiver encerrado ou não existir, a função **não deve retornar linhas**.
- A coluna `acertos_exatos` deve contar os acertos exatos.
- A coluna `acertos_resultado` deve contar os acertos do resultado, **sem contar novamente os acertos exatos**.
- A coluna `total_apostas` deve contar **todas** as apostas do usuário naquele jogo.

---

## Questão 2 (1,5 ponto) – Cancelamento em lote das apostas de um usuário para um jogo

Implemente a **procedure**.

```sql
cancelar_apostas_usuario_jogo(
    var_usuario_id INTEGER,
    var_jogo_id    INTEGER
)
```

A procedure deve cancelar todas as apostas de um usuário para um jogo específico, devolvendo ao saldo do usuário o valor de cada aposta cancelada e removendo os respectivos registros da tabela `aposta`.

### Requisitos

- Antes de cancelar, verifique se o usuário e o jogo existem.
- Não permita o cancelamento se o jogo já estiver encerrado.
- Para cada aposta encontrada, devolva o valor ao saldo do usuário e remova a aposta.
- Se não houver apostas correspondentes, informe a situação usando `RAISE NOTICE`.
- Informe ao final quantas apostas foram canceladas.

---

## Questão 3 (2,0 pontos) – Auditoria de apostas pendentes

Implemente uma **função**:

```sql
auditoria_apostas_pendentes()
RETURNS TABLE (
    jogo_id             INTEGER,
    quantidade_apostas  BIGINT,
    total_apostado      MONEY,
    quantidade_usuarios BIGINT
)
```

A função deve gerar um relatório de todos os jogos **ainda não encerrados** que possuam **pelo menos uma aposta**. Para cada jogo, retorne a quantidade de apostas registradas, a soma dos valores apostados e a quantidade de usuários distintos que apostaram.

### Requisitos

- Considere como **pendente** todo jogo cujo resultado real ainda não esteja completamente preenchido.
- Ordene o resultado pela quantidade de apostas em **ordem decrescente** e, em caso de empate, pelo identificador do jogo em **ordem crescente**.
