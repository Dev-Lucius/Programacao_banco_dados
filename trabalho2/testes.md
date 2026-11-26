# Roteiro de Testes — Sistema de Gerenciamento de Eventos e Inscrições

Documento técnico com casos de teste para validar as funções, procedures e triggers implementadas no banco de dados PostgreSQL do Sistema de Gerenciamento de Eventos e Inscrições.

O objetivo é verificar o funcionamento das regras de negócio, a integridade dos dados, a automatização de operações e o comportamento do sistema diante de situações válidas e inválidas.

**Banco de dados:** `sistemas_eventos_inscricoes`  
**SGBD:** PostgreSQL  
**Linguagem:** SQL / PL/pgSQL

---

# 1. Orientações para execução dos testes

Antes de executar os testes, conecte-se ao banco de dados:

```sql
\c sistemas_eventos_inscricoes
```

## 1.1. Convenções utilizadas

Os testes estão organizados em três categorias:

| Categoria | Descrição |
|---|---|
| Teste positivo | Verifica se uma operação válida é executada corretamente |
| Teste negativo | Verifica se uma operação inválida é impedida |
| Teste de integridade | Verifica se os dados permanecem consistentes após uma operação |

Sempre que um teste realizar alterações nos dados, recomenda-se utilizar transações:

```sql
BEGIN;

-- Operações do teste

ROLLBACK;
```

O comando `ROLLBACK` desfaz as alterações realizadas durante a transação, permitindo executar testes sem comprometer os dados originais.

**Importante:** quando um teste negativo produzir uma exceção PostgreSQL, a transação ficará em estado de erro. Execute `ROLLBACK` antes de continuar.

Os identificadores utilizados nos exemplos consideram os dados de teste existentes no projeto. Caso os registros tenham sido modificados, adapte os identificadores conforme necessário.

---

# 2. Testes de funções

## 2.1. `fn_calcular_valor_inscricao()`

**Objetivo:** verificar se o cálculo do valor da inscrição respeita os descontos definidos para cada tipo de participante.

### CT-F01 — Cálculo para estudante

**Tipo:** Positivo.

**Descrição:** verificar se estudantes recebem 50% de desconto sobre o valor-base do evento.

**Pré-condições:**
- Participante 1 cadastrado como estudante.
- Evento 2 com valor-base de R$ 25,00 e status aberto.

**Execução:**

```sql
SELECT fn_calcular_valor_inscricao(1, 2);
```

**Resultado esperado:**

```text
12.50
```

**Critério de aprovação:** o valor calculado deve corresponder a 50% do valor-base.

### CT-F02 — Cálculo para professor

**Tipo:** Positivo.

**Descrição:** verificar se professores recebem 30% de desconto.

**Pré-condições:**
- Participante 11 cadastrado como professor.
- Evento 2 com valor-base de R$ 25,00.

**Execução:**

```sql
SELECT fn_calcular_valor_inscricao(11, 2);
```

**Resultado esperado:**

```text
17.50
```

**Critério de aprovação:** o valor calculado deve corresponder a 70% do valor-base.

### CT-F03 — Cálculo para participante externo

**Tipo:** Positivo.

**Descrição:** verificar se participantes externos pagam o valor integral.

**Pré-condições:**
- Participante 15 cadastrado como externo.
- Evento 2 com valor-base de R$ 25,00.

**Execução:**

```sql
SELECT fn_calcular_valor_inscricao(15, 2);
```

**Resultado esperado:**

```text
25.00
```

**Critério de aprovação:** o valor calculado deve ser igual ao valor-base.

### CT-F04 — Participante inexistente

**Tipo:** Negativo.

**Descrição:** verificar se a função impede o cálculo para participantes inexistentes.

**Execução:**

```sql
SELECT fn_calcular_valor_inscricao(9999, 2);
```

**Resultado esperado:** ocorrência de exceção informando que o participante não foi encontrado.

**Critério de aprovação:** a função não deve retornar um valor para um participante inexistente.

### CT-F05 — Evento inexistente

**Tipo:** Negativo.

**Descrição:** verificar se a função impede o cálculo para eventos inexistentes.

**Execução:**

```sql
SELECT fn_calcular_valor_inscricao(1, 9999);
```

**Resultado esperado:** ocorrência de exceção informando que o evento não foi encontrado.

**Critério de aprovação:** a função não deve retornar um valor para um evento inexistente.

---

## 2.2. `fn_relatorio_ocupacao()`

**Objetivo:** verificar se a função retorna corretamente os indicadores de ocupação e arrecadação dos eventos.

### CT-F06 — Consulta geral de ocupação

**Tipo:** Positivo.

**Descrição:** consultar os indicadores de todos os eventos cadastrados.

**Execução:**

```sql
SELECT *
FROM fn_relatorio_ocupacao()
ORDER BY evento_id;
```

**Resultado esperado:**

A função deve retornar informações consolidadas, incluindo:

- Identificador do evento.
- Título.
- Quantidade de vagas.
- Quantidade de inscrições confirmadas.
- Quantidade de inscrições em lista de espera.
- Percentual de ocupação.
- Arrecadação.

**Critério de aprovação:** os valores retornados devem corresponder às inscrições registradas no banco.

### CT-F07 — Conferência do percentual de ocupação

**Tipo:** Integridade.

**Descrição:** verificar se o percentual de ocupação corresponde à quantidade de inscrições confirmadas em relação ao total de vagas.

**Execução:**

```sql
SELECT
    evento_id,
    titulo,
    vagas,
    confirmados,
    percentual_ocupacao,
    ROUND(
        confirmados * 100.0 / NULLIF(vagas, 0),
        2
    ) AS percentual_calculado
FROM fn_relatorio_ocupacao()
ORDER BY evento_id;
```

**Resultado esperado:** os campos `percentual_ocupacao` e `percentual_calculado` devem apresentar valores equivalentes.

**Critério de aprovação:** o percentual retornado pela função deve corresponder ao cálculo independente.

### CT-F08 — Conferência da arrecadação

**Tipo:** Integridade.

**Descrição:** verificar se a arrecadação considera os valores das inscrições confirmadas.

**Execução:**

```sql
SELECT
    e.id AS evento_id,
    e.titulo,
    COALESCE(
        SUM(i.valor_pago)
            FILTER (WHERE i.status = 'confirmada'),
        0
    ) AS arrecadacao_calculada
FROM evento e
LEFT JOIN inscricao i
    ON i.evento_id = e.id
GROUP BY e.id, e.titulo
ORDER BY e.id;
```

**Resultado esperado:** os valores calculados devem corresponder à arrecadação apresentada por `fn_relatorio_ocupacao()`.

**Critério de aprovação:** a arrecadação deve considerar somente inscrições confirmadas.

---

# 3. Testes de procedures

## 3.1. `sp_realizar_inscricao()`

**Objetivo:** verificar se o processo de inscrição funciona corretamente, considerando disponibilidade de vagas, status do evento, existência do participante e cálculo do valor.

### CT-P01 — Inscrição com vagas disponíveis

**Tipo:** Positivo.

**Descrição:** verificar se uma inscrição é confirmada quando existem vagas disponíveis.

**Pré-condições:**
- Participante 20 cadastrado.
- Participante ainda não possui inscrição ativa no evento 1.
- Evento 1 aberto e com vagas disponíveis.

**Execução:**

```sql
BEGIN;

CALL sp_realizar_inscricao(20, 1);

SELECT
    participante_id,
    evento_id,
    status,
    valor_pago
FROM inscricao
WHERE participante_id = 20
  AND evento_id = 1;

ROLLBACK;
```

**Resultado esperado:**

- A procedure deve executar sem erros.
- A inscrição deve ser criada com status `confirmada`.
- O valor deve ser calculado conforme o tipo do participante.

**Critério de aprovação:** o participante deve receber uma inscrição confirmada.

### CT-P02 — Participante já inscrito

**Tipo:** Negativo.

**Descrição:** impedir que um participante realize uma segunda inscrição ativa no mesmo evento.

**Pré-condições:** participante 20 já possui inscrição ativa no evento 9.

**Execução:**

```sql
CALL sp_realizar_inscricao(20, 9);
```

**Resultado esperado:**

```text
Participante 20 já está inscrito no evento 9.
```

**Critério de aprovação:** a procedure deve impedir a criação de uma inscrição duplicada.

### CT-P03 — Evento inexistente

**Tipo:** Negativo.

**Descrição:** impedir a inscrição em um evento inexistente.

**Execução:**

```sql
CALL sp_realizar_inscricao(1, 9999);
```

**Resultado esperado:** ocorrência de exceção informando que o evento não foi encontrado.

**Critério de aprovação:** nenhuma inscrição deve ser criada.

### CT-P04 — Participante inexistente

**Tipo:** Negativo.

**Descrição:** impedir inscrições para participantes não cadastrados.

**Execução:**

```sql
CALL sp_realizar_inscricao(9999, 1);
```

**Resultado esperado:** ocorrência de exceção informando que o participante não foi encontrado.

**Critério de aprovação:** nenhuma inscrição deve ser criada.

### CT-P05 — Inscrição em evento encerrado

**Tipo:** Negativo.

**Descrição:** verificar se a procedure impede inscrições em eventos encerrados.

**Pré-condições:** evento 11 cadastrado e encerrado.

**Execução:**

```sql
CALL sp_realizar_inscricao(1, 11);
```

**Resultado esperado:**

```text
Não é possível realizar inscrições no evento 11, pois ele está encerrado.
```

**Critério de aprovação:** a operação deve ser impedida.

### CT-P06 — Inscrição em evento cancelado

**Tipo:** Negativo.

**Descrição:** verificar se a procedure impede inscrições em eventos cancelados.

**Execução:**

```sql
BEGIN;

UPDATE evento
SET status = 'cancelado'
WHERE id = 1;

CALL sp_realizar_inscricao(20, 1);

ROLLBACK;
```

**Resultado esperado:** ocorrência de exceção informando que o evento está cancelado.

**Critério de aprovação:** a inscrição não deve ser realizada.

### CT-P07 — Capacidade do local insuficiente

**Tipo:** Negativo.

**Descrição:** verificar se a procedure impede inscrições quando a quantidade de vagas do evento ultrapassa a capacidade do local.

**Execução:**

```sql
BEGIN;

UPDATE local
SET capacidade = 100
WHERE id = 1;

CALL sp_realizar_inscricao(20, 1);

ROLLBACK;
```

**Resultado esperado:** ocorrência de exceção informando que o evento possui mais vagas do que a capacidade do local.

**Critério de aprovação:** a inscrição deve ser impedida.

### CT-P08 — Inscrição em lista de espera

**Tipo:** Positivo.

**Descrição:** verificar se participantes são encaminhados para a lista de espera quando não existem vagas disponíveis.

**Pré-condições:** evento aberto, capacidade válida e quantidade de inscrições confirmadas igual à quantidade de vagas.

**Preparação e execução:**

```sql
BEGIN;

-- Ajustar temporariamente as vagas para a
-- quantidade atual de inscrições confirmadas.
UPDATE evento
SET vagas = (
    SELECT COUNT(*)
    FROM inscricao
    WHERE evento_id = 1
      AND status = 'confirmada'
)
WHERE id = 1;

-- Conferir se o evento possui capacidade suficiente
-- para a quantidade temporária de vagas.
SELECT
    e.id,
    e.vagas,
    l.capacidade
FROM evento e
JOIN local l ON l.id = e.local_id
WHERE e.id = 1;

-- Tentar realizar uma nova inscrição.
CALL sp_realizar_inscricao(20, 1);

SELECT
    participante_id,
    evento_id,
    status,
    valor_pago
FROM inscricao
WHERE participante_id = 20
  AND evento_id = 1;

ROLLBACK;
```

**Resultado esperado:** a nova inscrição deve ser registrada com status `lista_espera` e valor `0.00`.

**Critério de aprovação:** o sistema deve encaminhar o participante para a lista de espera quando não houver vagas.

**Observação:** esse teste pressupõe que o participante 20 não possua inscrição ativa no evento 1. Se já possuir, utilize outro participante disponível.

---

## 3.2. `sp_cancelar_inscricao()`

**Objetivo:** verificar se o cancelamento de inscrições funciona corretamente e se a lista de espera é administrada automaticamente.

### CT-P09 — Cancelamento de inscrição confirmada

**Tipo:** Positivo.

**Descrição:** verificar se uma inscrição confirmada pode ser cancelada.

**Pré-condições:** inscrição 18 confirmada no evento 4.

**Execução:**

```sql
BEGIN;

CALL sp_cancelar_inscricao(18);

SELECT
    id,
    participante_id,
    evento_id,
    status
FROM inscricao
WHERE id = 18;

ROLLBACK;
```

**Resultado esperado:** a inscrição deve apresentar status `cancelada` dentro da transação.

**Critério de aprovação:** o cancelamento deve ser executado corretamente.

### CT-P10 — Cancelamento duplicado

**Tipo:** Negativo.

**Descrição:** impedir que uma inscrição já cancelada seja cancelada novamente.

**Pré-condições:** inscrição 17 com status `cancelada`.

**Execução:**

```sql
CALL sp_cancelar_inscricao(17);
```

**Resultado esperado:**

```text
A inscrição 17 já está cancelada.
```

**Critério de aprovação:** a procedure deve impedir o cancelamento duplicado.

### CT-P11 — Inscrição inexistente

**Tipo:** Negativo.

**Descrição:** verificar o comportamento diante de uma inscrição inexistente.

**Execução:**

```sql
CALL sp_cancelar_inscricao(9999);
```

**Resultado esperado:**

```text
Inscrição 9999 não encontrada.
```

**Critério de aprovação:** a procedure deve informar que a inscrição não existe.

### CT-P12 — Promoção automática da lista de espera

**Tipo:** Positivo.

**Descrição:** verificar se o cancelamento de uma inscrição confirmada promove automaticamente o próximo participante da lista de espera.

**Pré-condições:**
- Evento 4 aberto.
- Inscrição 18 confirmada.
- Existência de pelo menos uma inscrição em lista de espera.
- Participante da lista de espera elegível para promoção.

**Preparação e execução:**

```sql
BEGIN;

-- Criar um participante temporário.
INSERT INTO participante (
    nome,
    email,
    tipo
)
VALUES (
    'Participante Teste Promocao',
    'teste.promocao@example.com',
    'estudante'
)
RETURNING id;

-- Utilize o ID retornado na instrução anterior.
-- Substitua <ID_PARTICIPANTE> pelo identificador obtido.

INSERT INTO inscricao (
    participante_id,
    evento_id,
    status,
    valor_pago
)
VALUES (
    <ID_PARTICIPANTE>,
    4,
    'lista_espera',
    0.00
);

-- Cancelar uma inscrição confirmada.
CALL sp_cancelar_inscricao(18);

-- Conferir a situação do participante promovido.
SELECT
    i.id,
    p.nome,
    i.status,
    i.valor_pago
FROM inscricao i
JOIN participante p
    ON p.id = i.participante_id
WHERE p.email = 'teste.promocao@example.com';

ROLLBACK;
```

**Resultado esperado:**

- A inscrição 18 deve ser cancelada.
- O participante temporário deve ser promovido para `confirmada`.
- O valor da inscrição deve ser recalculado.
- A auditoria deve registrar as duas alterações.

Como o participante temporário é estudante, o valor final deve corresponder a 50% do valor-base do evento.

**Critério de aprovação:** a procedure deve promover o primeiro participante elegível e recalcular seu valor.

### CT-P13 — Cancelamento sem promoção em evento encerrado

**Tipo:** Positivo / Integridade.

**Descrição:** verificar se uma inscrição pode ser cancelada sem promover participantes quando o evento está encerrado.

**Execução:**

```sql
BEGIN;

UPDATE evento
SET status = 'encerrado'
WHERE id = 4;

CALL sp_cancelar_inscricao(18);

ROLLBACK;
```

**Resultado esperado:**

- O cancelamento deve ser executado.
- Nenhum participante da lista de espera deve ser promovido.
- A transação deve poder ser desfeita normalmente.

**Critério de aprovação:** a procedure deve permitir o cancelamento, mas impedir a promoção em eventos encerrados.

---

# 4. Testes de triggers

As triggers são mecanismos automáticos executados pelo PostgreSQL em resposta a operações realizadas nas tabelas.

No projeto, existem duas triggers principais:

- `trg_valida_inscricao`
- `trg_auditoria_inscricao`

As funções associadas às triggers são executadas automaticamente. Portanto, seus testes devem ser realizados por meio de operações de inserção e atualização nas tabelas correspondentes.

## 4.1. `trg_valida_inscricao`

**Objetivo:** verificar se as regras de validação são aplicadas automaticamente antes de inserir ou atualizar uma inscrição.

### CT-T01 — Validação automática de inscrição válida

**Tipo:** Positivo.

**Descrição:** verificar se a trigger permite uma inscrição válida.

**Execução:**

```sql
BEGIN;

INSERT INTO inscricao (
    participante_id,
    evento_id,
    status,
    valor_pago
)
VALUES (
    20,
    1,
    'confirmada',
    0.00
);

ROLLBACK;
```

**Resultado esperado:** a operação deve ser permitida, desde que o participante não possua inscrição ativa no evento 1 e não exista conflito de horário.

**Critério de aprovação:** a trigger deve permitir uma operação válida.

### CT-T02 — Bloqueio de inscrição em evento encerrado

**Tipo:** Negativo.

**Descrição:** verificar se a trigger impede inscrições em eventos encerrados, mesmo quando a operação é realizada diretamente por SQL, sem utilizar a procedure.

**Execução:**

```sql
BEGIN;

INSERT INTO inscricao (
    participante_id,
    evento_id,
    status,
    valor_pago
)
VALUES (
    1,
    11,
    'confirmada',
    0.00
);

ROLLBACK;
```

**Resultado esperado:** ocorrência de exceção informando que o evento está encerrado.

**Critério de aprovação:** a trigger deve impedir a operação independentemente da camada da aplicação utilizada.

### CT-T03 — Bloqueio por capacidade insuficiente

**Tipo:** Negativo.

**Descrição:** verificar se a trigger impede inscrições quando a quantidade de vagas ultrapassa a capacidade do local.

**Execução:**

```sql
BEGIN;

UPDATE local
SET capacidade = 100
WHERE id = 1;

INSERT INTO inscricao (
    participante_id,
    evento_id,
    status,
    valor_pago
)
VALUES (
    20,
    1,
    'confirmada',
    0.00
);

ROLLBACK;
```

**Resultado esperado:** ocorrência de exceção informando que a quantidade de vagas do evento ultrapassa a capacidade do local.

**Critério de aprovação:** a trigger deve impedir a inserção.

### CT-T04 — Bloqueio de conflito de horário

**Tipo:** Negativo.

**Descrição:** verificar se a trigger impede que um participante tenha duas inscrições confirmadas em eventos com horários sobrepostos.

**Pré-condições:**
- Participante 20 com inscrição confirmada no evento 7.
- Evento 8 sem inscrição ativa do participante 20.

**Execução:**

```sql
BEGIN;

-- Alterar temporariamente o horário do evento 8
-- para sobrepor o horário do evento 7.
UPDATE evento
SET
    data_inicio = '2026-12-26 14:00:00',
    data_fim = '2026-12-26 16:00:00'
WHERE id = 8;

-- Tentar inserir uma inscrição conflitante.
INSERT INTO inscricao (
    participante_id,
    evento_id,
    status,
    valor_pago
)
VALUES (
    20,
    8,
    'confirmada',
    0.00
);

ROLLBACK;
```

**Resultado esperado:** ocorrência de exceção informando que o participante já possui inscrição confirmada em evento com horário conflitante.

**Critério de aprovação:** a trigger deve impedir inscrições confirmadas em horários sobrepostos.

### CT-T05 — Permissão de cancelamento

**Tipo:** Positivo.

**Descrição:** verificar se uma inscrição pode ser cancelada mesmo quando outras validações de inscrição não seriam satisfeitas.

**Pré-condições:** inscrição 18 confirmada.

**Execução:**

```sql
BEGIN;

UPDATE inscricao
SET status = 'cancelada'
WHERE id = 18;

SELECT
    id,
    status
FROM inscricao
WHERE id = 18;

ROLLBACK;
```

**Resultado esperado:** a atualização deve ser permitida e o status deve aparecer como `cancelada` durante a transação.

**Critério de aprovação:** a trigger deve permitir o cancelamento sem executar indevidamente as validações destinadas a novas inscrições.

---

## 4.2. `trg_auditoria_inscricao`

**Objetivo:** verificar se a trigger registra automaticamente as inserções e alterações de status na tabela `inscricao`.

### CT-T06 — Auditoria de inserção

**Tipo:** Positivo.

**Descrição:** verificar se uma nova inscrição gera automaticamente um registro de auditoria.

**Execução:**

```sql
BEGIN;

INSERT INTO inscricao (
    participante_id,
    evento_id,
    status,
    valor_pago
)
VALUES (
    20,
    1,
    'confirmada',
    0.00
)
RETURNING id;
```

Utilize o identificador retornado para consultar a auditoria:

```sql
SELECT
    inscricao_id,
    status_anterior,
    status_novo,
    data_hora,
    usuario
FROM log_inscricao
WHERE inscricao_id = <ID_INSCRICAO>
ORDER BY data_hora DESC;
```

Finalize o teste:

```sql
ROLLBACK;
```

**Resultado esperado:**

- Deve existir um registro de auditoria.
- O status anterior deve ser `NULL`.
- O novo status deve ser `confirmada`.
- A data e o horário devem ser preenchidos.

**Critério de aprovação:** a inserção deve gerar automaticamente um registro de auditoria.

### CT-T07 — Auditoria de alteração de status

**Tipo:** Positivo.

**Descrição:** verificar se a alteração de status gera um novo registro de auditoria.

**Pré-condições:** inscrição 18 confirmada.

**Execução:**

```sql
BEGIN;

UPDATE inscricao
SET status = 'cancelada'
WHERE id = 18;

SELECT
    inscricao_id,
    status_anterior,
    status_novo,
    data_hora,
    usuario
FROM log_inscricao
WHERE inscricao_id = 18
ORDER BY data_hora DESC;

ROLLBACK;
```

**Resultado esperado:**

Um novo registro de auditoria contendo:

| Campo | Valor esperado |
|---|---|
| `inscricao_id` | 18 |
| `status_anterior` | confirmada |
| `status_novo` | cancelada |
| `data_hora` | Data e horário da alteração |
| `usuario` | Usuário registrado pela rotina |

**Critério de aprovação:** a alteração deve gerar um registro com os estados anterior e novo.

### CT-T08 — Não registrar alterações sem mudança de status

**Tipo:** Integridade.

**Descrição:** verificar se a trigger evita registros desnecessários quando uma inscrição é atualizada sem alteração de status.

**Execução:**

```sql
BEGIN;

-- Contar os registros de auditoria antes da atualização.
SELECT COUNT(*) AS total_antes
FROM log_inscricao
WHERE inscricao_id = 18;

-- Atualizar um campo diferente do status.
UPDATE inscricao
SET valor_pago = valor_pago
WHERE id = 18;

-- Conferir novamente a quantidade de registros.
SELECT COUNT(*) AS total_depois
FROM log_inscricao
WHERE inscricao_id = 18;

ROLLBACK;
```

**Resultado esperado:** a quantidade de registros de auditoria deve permanecer igual.

**Critério de aprovação:** a trigger deve registrar alterações de status, sem gerar auditorias desnecessárias para atualizações que não modificam esse campo.

---

# 5. Testes de integridade do banco de dados

Além das funções, procedures e triggers, é importante verificar se as restrições e os relacionamentos do banco estão preservando a consistência dos dados.

## CT-I01 — Verificar inscrições ativas duplicadas

**Objetivo:** verificar se existem participantes com mais de uma inscrição não cancelada no mesmo evento.

**Execução:**

```sql
SELECT
    participante_id,
    evento_id,
    COUNT(*) AS quantidade
FROM inscricao
WHERE status <> 'cancelada'
GROUP BY participante_id, evento_id
HAVING COUNT(*) > 1;
```

**Resultado esperado:** `0 rows`.

## CT-I02 — Verificar capacidade dos locais

**Objetivo:** verificar se algum evento possui mais vagas do que a capacidade do local associado.

**Execução:**

```sql
SELECT
    e.id AS evento_id,
    e.titulo,
    l.nome AS local,
    e.vagas,
    l.capacidade
FROM evento e
JOIN local l
    ON l.id = e.local_id
WHERE e.vagas > l.capacidade
ORDER BY e.id;
```

**Resultado esperado:** `0 rows`.

## CT-I03 — Verificar eventos passados ainda abertos

**Objetivo:** identificar eventos cuja data de encerramento já passou, mas que continuam com status aberto.

**Execução:**

```sql
SELECT
    id,
    titulo,
    data_inicio,
    data_fim,
    status
FROM evento
WHERE data_fim < CURRENT_TIMESTAMP
  AND status = 'aberto'
ORDER BY data_fim;
```

**Resultado esperado:** `0 rows`.

## CT-I04 — Verificar inscrições ativas em eventos encerrados ou cancelados

**Objetivo:** identificar inscrições confirmadas ou em lista de espera associadas a eventos encerrados ou cancelados.

**Execução:**

```sql
SELECT
    i.id AS inscricao_id,
    p.nome AS participante,
    e.titulo AS evento,
    i.status AS status_inscricao,
    e.status AS status_evento
FROM inscricao i
JOIN participante p
    ON p.id = i.participante_id
JOIN evento e
    ON e.id = i.evento_id
WHERE i.status IN ('confirmada', 'lista_espera')
  AND e.status IN ('encerrado', 'cancelado')
ORDER BY e.id, i.id;
```

**Resultado esperado:** deve ser analisado conforme as regras do sistema.

Uma inscrição confirmada em um evento encerrado pode representar um registro histórico válido. O encerramento impede novas inscrições, mas não cancela automaticamente as inscrições anteriores.

## CT-I05 — Conferir os registros de auditoria

**Objetivo:** verificar se a tabela de auditoria possui registros relacionados às operações realizadas.

**Execução:**

```sql
SELECT
    inscricao_id,
    status_anterior,
    status_novo,
    data_hora,
    usuario
FROM log_inscricao
ORDER BY data_hora DESC;
```

**Resultado esperado:** os registros devem apresentar os históricos de inserção e alteração de status das inscrições.

---

# 6. Resumo dos casos de teste

| Código | Componente | Caso de teste | Tipo |
|---|---|---|---|
| CT-F01 | `fn_calcular_valor_inscricao()` | Cálculo para estudante | Positivo |
| CT-F02 | `fn_calcular_valor_inscricao()` | Cálculo para professor | Positivo |
| CT-F03 | `fn_calcular_valor_inscricao()` | Cálculo para externo | Positivo |
| CT-F04 | `fn_calcular_valor_inscricao()` | Participante inexistente | Negativo |
| CT-F05 | `fn_calcular_valor_inscricao()` | Evento inexistente | Negativo |
| CT-F06 | `fn_relatorio_ocupacao()` | Consulta geral | Positivo |
| CT-F07 | `fn_relatorio_ocupacao()` | Percentual de ocupação | Integridade |
| CT-F08 | `fn_relatorio_ocupacao()` | Conferência da arrecadação | Integridade |
| CT-P01 | `sp_realizar_inscricao()` | Inscrição com vagas | Positivo |
| CT-P02 | `sp_realizar_inscricao()` | Inscrição duplicada | Negativo |
| CT-P03 | `sp_realizar_inscricao()` | Evento inexistente | Negativo |
| CT-P04 | `sp_realizar_inscricao()` | Participante inexistente | Negativo |
| CT-P05 | `sp_realizar_inscricao()` | Evento encerrado | Negativo |
| CT-P06 | `sp_realizar_inscricao()` | Evento cancelado | Negativo |
| CT-P07 | `sp_realizar_inscricao()` | Capacidade insuficiente | Negativo |
| CT-P08 | `sp_realizar_inscricao()` | Lista de espera | Positivo |
| CT-P09 | `sp_cancelar_inscricao()` | Cancelamento | Positivo |
| CT-P10 | `sp_cancelar_inscricao()` | Cancelamento duplicado | Negativo |
| CT-P11 | `sp_cancelar_inscricao()` | Inscrição inexistente | Negativo |
| CT-P12 | `sp_cancelar_inscricao()` | Promoção da lista de espera | Positivo |
| CT-P13 | `sp_cancelar_inscricao()` | Evento encerrado sem promoção | Integridade |
| CT-T01 | `trg_valida_inscricao` | Inscrição válida | Positivo |
| CT-T02 | `trg_valida_inscricao` | Evento encerrado | Negativo |
| CT-T03 | `trg_valida_inscricao` | Capacidade insuficiente | Negativo |
| CT-T04 | `trg_valida_inscricao` | Conflito de horário | Negativo |
| CT-T05 | `trg_valida_inscricao` | Permissão de cancelamento | Positivo |
| CT-T06 | `trg_auditoria_inscricao` | Auditoria de inserção | Positivo |
| CT-T07 | `trg_auditoria_inscricao` | Auditoria de alteração | Positivo |
| CT-T08 | `trg_auditoria_inscricao` | Atualização sem mudança de status | Integridade |
| CT-I01 | Integridade | Inscrições duplicadas | Integridade |
| CT-I02 | Integridade | Capacidade dos locais | Integridade |
| CT-I03 | Integridade | Eventos passados abertos | Integridade |
| CT-I04 | Integridade | Inscrições em eventos encerrados | Integridade |
| CT-I05 | Integridade | Registros de auditoria | Integridade |

---

# 7. Resultado da execução dos testes

Utilize esta seção para registrar os resultados efetivamente obtidos durante a execução dos casos de teste.

| Situação | Significado |
|---|---|
| Aprovado | O resultado obtido correspondeu ao esperado |
| Reprovado | O resultado obtido foi diferente do esperado |
| Pendente | O teste ainda não foi executado |
| Não aplicável | O cenário não se aplica à configuração atual |

**Importante:** os casos de teste descritos neste documento representam os cenários planejados e seus resultados esperados. O status de aprovação deve ser preenchido somente após a execução efetiva de cada teste.

---

# 8. Considerações finais

A realização dos testes permite verificar se as regras de negócio implementadas no PostgreSQL estão funcionando corretamente, garantindo a consistência dos dados e o comportamento esperado das operações.

Os testes abrangem:

- Cálculo de valores e aplicação de descontos.
- Validação de participantes e eventos.
- Controle de vagas e capacidade dos locais.
- Gerenciamento de inscrições e listas de espera.
- Cancelamento e promoção automática de participantes.
- Prevenção de conflitos de horário.
- Auditoria de operações.
- Integridade e consistência dos dados.

A utilização de transações durante os testes permite validar diferentes cenários sem comprometer permanentemente os registros do banco de dados.

Dessa forma, o roteiro funciona como documentação técnica das regras implementadas e como referência para futuras manutenções e evoluções do sistema.
