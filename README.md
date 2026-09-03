# 🐘 Programação em Banco de Dados com PostgreSQL

> Repositório de estudos sobre programação server-side em PostgreSQL utilizando PL/pgSQL.  
> Baseado na ementa: **Funções, Estruturas de Controle, Procedures, Cursores, Gatilhos e Tratamento de Erros.**

---

## 📚 Índice

1. [Introdução](#1-introdução)
2. [Funções (Functions)](#2-funções-functions)
3. [Estruturas de Controle](#3-estruturas-de-controle)
4. [Procedures](#4-procedures)
5. [Cursores](#5-cursores)
6. [Gatilhos (Triggers)](#6-gatilhos-triggers)
7. [Tratamento de Erros e Mensagens](#7-tratamento-de-erros-e-mensagens)
8. [Exercícios Práticos](#8-exercícios-práticos)
9. [Boas Práticas](#9-boas-práticas)
10. [Referências](#10-referências)

---

## 1. Introdução

A **programação em banco de dados** permite encapsular lógica de negócio diretamente no servidor PostgreSQL, utilizando a linguagem procedural **PL/pgSQL** (Procedural Language/PostgreSQL Structured Query Language).

### Por que usar?

- **Performance**: reduz tráfego de rede entre aplicação e banco.
- **Segurança**: centraliza regras de negócio e restringe acesso direto às tabelas.
- **Consistência**: garante que operações complexas sejam executadas de forma padronizada.
- **Manutenção**: alterações na lógica são feitas em um único lugar.

### Estrutura básica de um bloco PL/pgSQL

```sql
-- Todo código PL/pgSQL é organizado em blocos BEGIN/END
DO $$
DECLARE
    -- Declaração de variáveis
    minha_variavel INTEGER := 10;
BEGIN
    -- Lógica executável
    RAISE NOTICE 'Valor: %', minha_variavel;
EXCEPTION
    -- Tratamento de erros (opcional)
    WHEN OTHERS THEN
        RAISE NOTICE 'Erro: %', SQLERRM;
END;
$$;
```

---

## 2. Funções (Functions)

Funções são blocos de código que **sempre retornam um valor** (escalar, registro, tabela ou void).

### 2.1 Sintaxe Geral

```sql
CREATE [OR REPLACE] FUNCTION nome_funcao(parametro TIPO)
RETURNS TIPO_RETORNO
LANGUAGE plpgsql
AS $$
DECLARE
    -- variáveis locais
BEGIN
    -- lógica
    RETURN valor;
END;
$$;
```

### 2.2 Função com retorno escalar

```sql
-- Converte Fahrenheit para Celsius
CREATE OR REPLACE FUNCTION ftoc(fahrenheit FLOAT)
RETURNS FLOAT
LANGUAGE SQL
AS $$
    SELECT ($1 - 32.0) * 5.0 / 9.0;
$$;

-- Chamada
SELECT ftoc(212);  -- Retorna: 100
```

### 2.3 Função com retorno escalar em PL/pgSQL

```sql
CREATE OR REPLACE FUNCTION soma_textos(primeiro TEXT, segundo TEXT)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    resultado TEXT;
BEGIN
    resultado := primeiro || segundo;  -- || é o operador de concatenação
    RETURN resultado;
END;
$$;

-- Chamada
SELECT soma_textos('Sidney ', 'Silva');  -- Retorna: 'Sidney Silva'
```

### 2.4 Função que retorna uma tabela

```sql
-- Retorna todas as apostas de um usuário específico
CREATE OR REPLACE FUNCTION apostas_usuario(p_usuario_id INTEGER)
RETURNS TABLE (
    aposta_id INTEGER,
    aposta_valor MONEY,
    aposta_odd REAL
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- RETURN QUERY executa o SELECT e devolve o resultado como tabela
    RETURN QUERY
    SELECT 
        a.id,
        a.valor,
        a.odd
    FROM aposta a
    WHERE a.usuario_id = p_usuario_id;

    RETURN;  -- Finaliza a função
END;
$$;

-- Chamada
SELECT * FROM apostas_usuario(5);
```

### 2.5 Usando SELECT INTO

```sql
-- INTO armazena o resultado de uma consulta em variáveis
CREATE OR REPLACE FUNCTION obter_saldo(p_usuario_id INTEGER)
RETURNS MONEY
LANGUAGE plpgsql
AS $$
DECLARE
    saldo_atual MONEY;
BEGIN
    SELECT u.saldo 
    INTO saldo_atual          -- INTO vem após as colunas, antes do FROM
    FROM usuario u
    WHERE u.id = p_usuario_id;

    RETURN COALESCE(saldo_atual, 0::MONEY);
END;
$$;
```

---

## 3. Estruturas de Controle

### 3.1 Declaração e Atribuição de Variáveis

```sql
DECLARE
    idade INTEGER := 25;                    -- com valor inicial
    nome TEXT NOT NULL := 'Sidney';          -- não permite NULL
    PI CONSTANT NUMERIC := 3.14159;         -- constante (imutável)
    salario_funcionario funcionarios.salario%TYPE;  -- herda tipo da coluna
    registro_funcionario funcionarios%ROWTYPE;      -- herda estrutura da tabela
    notas INTEGER[] := ARRAY[7, 8, 9];      -- array (vetor)
BEGIN
    idade := idade + 1;                      -- atribuição com :=
END;
```

### 3.2 Arrays (Vetores)

```sql
DECLARE
    frutas TEXT[] := ARRAY['maçã', 'banana', 'laranja'];
    primeira TEXT;
BEGIN
    primeira := frutas[1];                   -- índice começa em 1!
    frutas := array_append(frutas, 'uva');     -- adiciona elemento
END;
```

### 3.3 Condicionais

```sql
-- IF simples
IF nota >= 7 THEN
    RAISE NOTICE 'Aprovado!';
END IF;

-- IF/ELSE
IF saldo >= valor THEN
    UPDATE contas SET saldo = saldo - valor;
ELSE
    RAISE EXCEPTION 'Saldo insuficiente';
END IF;

-- IF/ELSIF/ELSE (atenção: é ELSIF, não ELSEIF!)
IF media >= 9 THEN
    conceito := 'A';
ELSIF media >= 7 THEN
    conceito := 'B';
ELSIF media >= 5 THEN
    conceito := 'C';
ELSE
    conceito := 'D';
END IF;

-- CASE (duas formas)
-- Forma 1: CASE simples
CASE dia
    WHEN 1 THEN RAISE NOTICE 'Domingo';
    WHEN 2 THEN RAISE NOTICE 'Segunda';
    ELSE RAISE NOTICE 'Dia inválido';
END CASE;

-- Forma 2: CASE pesquisado
CASE
    WHEN nota >= 90 THEN 'Excelente';
    WHEN nota >= 70 THEN 'Bom';
    ELSE 'Precisa melhorar';
END CASE;
```

### 3.4 Laços de Repetição

```sql
-- LOOP com EXIT
contador := 1;
LOOP
    RAISE NOTICE 'Contador: %', contador;
    contador := contador + 1;
    EXIT WHEN contador > 5;
END LOOP;

-- WHILE
WHILE contador <= 5 LOOP
    RAISE NOTICE 'Contador: %', contador;
    contador := contador + 1;
END LOOP;

-- FOR com range
FOR i IN 1..5 LOOP
    RAISE NOTICE 'i = %', i;
END LOOP;

-- FOR reverso
FOR i IN REVERSE 5..1 LOOP
    RAISE NOTICE 'i reverso = %', i;
END LOOP;

-- FOREACH (iterando arrays)
FOREACH nota IN ARRAY notas LOOP
    RAISE NOTICE 'Nota: %', nota;
END LOOP;

-- FOR com SELECT (cursor implícito)
FOR registro IN
    SELECT id, nome FROM clientes WHERE ativo = TRUE
LOOP
    RAISE NOTICE 'Cliente: %', registro.nome;
END LOOP;
```

---

## 4. Procedures

Procedures são similares a funções, mas **não retornam valores** e podem controlar transações (`COMMIT`/`ROLLBACK`).

### 4.1 Diferença entre Function e Procedure

| Característica | Function | Procedure |
|---|---|---|
| Retorno | Obrigatório (`RETURNS`) | Não retorna valor |
| `COMMIT`/`ROLLBACK` | ❌ Proibido | ✅ Permitido |
| Chamada | `SELECT nome_funcao();` | `CALL nome_procedure();` |
| Uso típico | Consultas, cálculos | Operações de escrita, ETL |

### 4.2 Exemplo de Procedure

```sql
CREATE OR REPLACE PROCEDURE transferir_fundos(
    p_origem INTEGER,
    p_destino INTEGER,
    p_valor NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    saldo_origem NUMERIC;
BEGIN
    -- Verifica saldo
    SELECT saldo INTO saldo_origem FROM contas WHERE id = p_origem;

    IF saldo_origem < p_valor THEN
        RAISE EXCEPTION 'Saldo insuficiente: % < %', saldo_origem, p_valor;
    END IF;

    -- Executa transferência
    UPDATE contas SET saldo = saldo - p_valor WHERE id = p_origem;
    UPDATE contas SET saldo = saldo + p_valor WHERE id = p_destino;

    -- Registra no histórico
    INSERT INTO historico_transacoes (origem, destino, valor, data)
    VALUES (p_origem, p_destino, p_valor, NOW());

    COMMIT;  -- Só é permitido em PROCEDURE!

    RAISE NOTICE 'Transferência de R$% realizada com sucesso', p_valor;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE NOTICE 'Erro na transferência: %', SQLERRM;
END;
$$;

-- Chamada
CALL transferir_fundos(101, 202, 500.00);
```

---

## 5. Cursores

Cursores permitem percorrer resultados de consultas linha por linha, oferecendo controle total sobre o processamento.

### 5.1 Cursor Implícito (FOR IN)

```sql
CREATE OR REPLACE FUNCTION listar_clientes_ativos()
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    registro RECORD;
BEGIN
    -- O FOR cria e gerencia o cursor automaticamente
    FOR registro IN
        SELECT id, nome, email FROM clientes WHERE ativo = TRUE
    LOOP
        RAISE NOTICE 'Cliente: % (%)', registro.nome, registro.email;
    END LOOP;
END;
$$;
```

### 5.2 Cursor Explícito

```sql
CREATE OR REPLACE FUNCTION processar_apostas()
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    cur_apostas CURSOR FOR
        SELECT id, valor, usuario_id FROM aposta WHERE processada = FALSE;

    registro RECORD;
BEGIN
    OPEN cur_apostas;                    -- Abre o cursor

    LOOP
        FETCH cur_apostas INTO registro; -- Busca próxima linha
        EXIT WHEN NOT FOUND;             -- Sai quando não houver mais linhas

        -- Processa cada aposta individualmente
        UPDATE aposta SET processada = TRUE WHERE id = registro.id;
        RAISE NOTICE 'Processada aposta % do usuário %', registro.id, registro.usuario_id;
    END LOOP;

    CLOSE cur_apostas;                   -- Fecha o cursor
END;
$$;
```

### 5.3 Cursor com Parâmetros

```sql
CREATE OR REPLACE FUNCTION apostas_por_usuario(p_usuario_id INTEGER)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    cur CURSOR (uid INTEGER) FOR
        SELECT id, valor FROM aposta WHERE usuario_id = uid;

    registro RECORD;
BEGIN
    OPEN cur(p_usuario_id);

    LOOP
        FETCH cur INTO registro;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE 'Aposta %: R$%', registro.id, registro.valor;
    END LOOP;

    CLOSE cur;
END;
$$;
```

---

## 6. Gatilhos (Triggers)

Gatilhos são funções executadas **automaticamente** quando ocorre um evento (`INSERT`, `UPDATE`, `DELETE`) em uma tabela.

### 6.1 Tipos de Gatilhos

| Tipo | Descrição |
|---|---|
| `BEFORE` | Executa **antes** da operação (permite modificar dados) |
| `AFTER` | Executa **depois** da operação (para auditoria, logs) |
| `INSTEAD OF` | Substitui a operação (usado em visões) |
| `FOR EACH ROW` | Executa uma vez para **cada linha** afetada |
| `FOR EACH STATEMENT` | Executa uma vez por **comando** |

### 6.2 Função de Gatilho

```sql
-- Função que será chamada pelo gatilho
CREATE OR REPLACE FUNCTION registrar_auditoria()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- NEW contém os dados da nova linha (INSERT/UPDATE)
    -- OLD contém os dados da linha antiga (UPDATE/DELETE)

    IF TG_OP = 'INSERT' THEN
        INSERT INTO auditoria (tabela, operacao, dados_novos, data)
        VALUES (TG_TABLE_NAME, 'INSERT', row_to_json(NEW), NOW());
        RETURN NEW;  -- Necessário em triggers BEFORE/AFTER INSERT

    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO auditoria (tabela, operacao, dados_antigos, dados_novos, data)
        VALUES (TG_TABLE_NAME, 'UPDATE', row_to_json(OLD), row_to_json(NEW), NOW());
        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO auditoria (tabela, operacao, dados_antigos, data)
        VALUES (TG_TABLE_NAME, 'DELETE', row_to_json(OLD), NOW());
        RETURN OLD;  -- Em DELETE, retorna OLD
    END IF;

    RETURN NULL;
END;
$$;
```

### 6.3 Criando o Gatilho

```sql
-- Cria a tabela de auditoria
CREATE TABLE auditoria (
    id SERIAL PRIMARY KEY,
    tabela TEXT,
    operacao TEXT,
    dados_antigos JSON,
    dados_novos JSON,
    data TIMESTAMP DEFAULT NOW()
);

-- Cria o gatilho na tabela de clientes
CREATE TRIGGER trg_auditoria_clientes
AFTER INSERT OR UPDATE OR DELETE ON clientes
FOR EACH ROW
EXECUTE FUNCTION registrar_auditoria();
```

### 6.4 Gatilho BEFORE para validação

```sql
CREATE OR REPLACE FUNCTION validar_saldo()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    saldo_atual MONEY;
BEGIN
    -- Verifica se o usuário tem saldo suficiente antes de inserir a aposta
    SELECT saldo INTO saldo_atual FROM usuario WHERE id = NEW.usuario_id;

    IF saldo_atual < NEW.valor THEN
        RAISE EXCEPTION 'Saldo insuficiente para realizar esta aposta';
    END IF;

    RETURN NEW;  -- Permite a inserção
END;
$$;

CREATE TRIGGER trg_validar_saldo
BEFORE INSERT ON aposta
FOR EACH ROW
EXECUTE FUNCTION validar_saldo();
```

---

## 7. Tratamento de Erros e Mensagens

### 7.1 Estrutura EXCEPTION

```sql
BEGIN
    -- Código que pode gerar erro
    SELECT 1/0;
EXCEPTION
    WHEN division_by_zero THEN
        RAISE NOTICE 'Divisão por zero detectada!';
    WHEN OTHERS THEN
        RAISE NOTICE 'Erro inesperado: %', SQLERRM;
END;
```

### 7.2 Condições de Exceção Comuns

| Condição | Quando ocorre |
|---|---|
| `division_by_zero` | Divisão por zero |
| `unique_violation` | Violação de chave única |
| `foreign_key_violation` | Violação de chave estrangeira |
| `not_null_violation` | Inserção de NULL em campo NOT NULL |
| `check_violation` | Violação de constraint CHECK |
| `no_data_found` | SELECT INTO não retornou linhas |
| `too_many_rows` | SELECT INTO retornou mais de uma linha |
| `undefined_table` | Tabela não existe |
| `OTHERS` | Qualquer outra exceção |

### 7.3 SQLSTATE e SQLERRM

```sql
CREATE OR REPLACE FUNCTION exemplo_diagnostico()
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_sqlstate TEXT;
    v_message TEXT;
BEGIN
    SELECT 1/0;
EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate = RETURNED_SQLSTATE,
            v_message = MESSAGE_TEXT;

        RAISE NOTICE 'Código do erro: %', v_sqlstate;
        RAISE NOTICE 'Mensagem: %', v_message;
END;
$$;
```

### 7.4 Lançando Erros com RAISE

```sql
-- Níveis de severidade
RAISE DEBUG   'Mensagem detalhada';     -- Logs internos
RAISE LOG     'Registro no servidor';   -- Log do PostgreSQL
RAISE INFO    'Informação';               -- Informativo
RAISE NOTICE  'Aviso ao cliente';         -- Aparece no cliente (padrão)
RAISE WARNING 'Alerta';                   -- Aviso
RAISE EXCEPTION 'Erro fatal!';           -- Interrompe a execução

-- Com formatação
RAISE EXCEPTION 'Usuário % não encontrado', p_id;

-- Com código SQLSTATE personalizado
RAISE EXCEPTION 'Idade inválida: %', idade
    USING ERRCODE = 'P0001';
```

---

## 8. Exercícios Práticos

### Exercício 1 — Função com retorno escalar
Crie uma função `ftoc(fahrenheit FLOAT)` que converta temperatura de Fahrenheit para Celsius.

<details>
<summary>Ver resposta</summary>

```sql
CREATE OR REPLACE FUNCTION ftoc(fahrenheit FLOAT)
RETURNS FLOAT
LANGUAGE SQL
AS $$
    SELECT ($1 - 32.0) * 5.0 / 9.0;
$$;
```
</details>

### Exercício 2 — SELECT INTO
Crie uma função `obter_saldo(usuario_id INT)` que retorne o saldo de um usuário.

<details>
<summary>Ver resposta</summary>

```sql
CREATE OR REPLACE FUNCTION obter_saldo(p_usuario_id INT)
RETURNS MONEY
LANGUAGE plpgsql
AS $$
DECLARE
    saldo_atual MONEY;
BEGIN
    SELECT u.saldo INTO saldo_atual
    FROM usuario u
    WHERE u.id = p_usuario_id;

    RETURN COALESCE(saldo_atual, 0::MONEY);
END;
$$;
```
</details>

### Exercício 3 — Função que retorna tabela
Crie uma função `apostas_usuario(usuario_id)` que retorne uma tabela com `id`, `valor` e `odd`.

<details>
<summary>Ver resposta</summary>

```sql
CREATE OR REPLACE FUNCTION apostas_usuario(p_usuario_id INTEGER)
RETURNS TABLE (aposta_id INTEGER, aposta_valor MONEY, aposta_odd REAL)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT a.id, a.valor, a.odd
    FROM aposta a
    WHERE a.usuario_id = p_usuario_id;
    RETURN;
END;
$$;
```
</details>

### Exercício 4 — Procedure com transação
Crie uma procedure `transferir_fundos(origem, destino, valor)` que realize uma transferência bancária.

<details>
<summary>Ver resposta</summary>

```sql
CREATE OR REPLACE PROCEDURE transferir_fundos(
    p_origem INTEGER,
    p_destino INTEGER,
    p_valor NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    saldo_origem NUMERIC;
BEGIN
    SELECT saldo INTO saldo_origem FROM contas WHERE id = p_origem;

    IF saldo_origem < p_valor THEN
        RAISE EXCEPTION 'Saldo insuficiente';
    END IF;

    UPDATE contas SET saldo = saldo - p_valor WHERE id = p_origem;
    UPDATE contas SET saldo = saldo + p_valor WHERE id = p_destino;

    COMMIT;
END;
$$;
```
</details>

### Exercício 5 — Gatilho de auditoria
Crie um gatilho que registre todas as alterações na tabela `clientes`.

<details>
<summary>Ver resposta</summary>

```sql
CREATE OR REPLACE FUNCTION registrar_auditoria()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO auditoria (tabela, operacao, dados_novos, data)
        VALUES (TG_TABLE_NAME, 'INSERT', row_to_json(NEW), NOW());
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO auditoria (tabela, operacao, dados_antigos, dados_novos, data)
        VALUES (TG_TABLE_NAME, 'UPDATE', row_to_json(OLD), row_to_json(NEW), NOW());
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO auditoria (tabela, operacao, dados_antigos, data)
        VALUES (TG_TABLE_NAME, 'DELETE', row_to_json(OLD), NOW());
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;

CREATE TRIGGER trg_auditoria_clientes
AFTER INSERT OR UPDATE OR DELETE ON clientes
FOR EACH ROW
EXECUTE FUNCTION registrar_auditoria();
```
</details>

---

## 9. Boas Práticas

1. **Sempre use `COALESCE`** quando uma função de agregação pode retornar `NULL`.
2. **Prefira `$func$` ou `$body$`** como delimitador em vez de `$$` para evitar conflitos.
3. **Use `%TYPE` e `%ROWTYPE`** para tornar seu código mais robusto a alterações de schema.
4. **Evite `SELECT *`** em produção; selecione apenas as colunas necessárias.
5. **Trate erros com `EXCEPTION`** para evitar que falhas expõem dados sensíveis.
6. **Documente suas funções** com comentários explicando parâmetros e retorno.
7. **Use `RAISE NOTICE`** para debug durante o desenvolvimento.
8. **Em Functions, nunca use `COMMIT`/`ROLLBACK`** — isso só é permitido em Procedures.

---

## 10. Referências

- [Documentação Oficial do PostgreSQL — PL/pgSQL](https://www.postgresql.org/docs/current/plpgsql.html)
- [PostgreSQL Tutorial — PL/pgSQL](https://www.postgresqltutorial.com/postgresql-plpgsql/)
- [PostgreSQL Wiki — Triggers](https://wiki.postgresql.org/wiki/A_Guide_to_C%2B%2B_Triggers)

---

> ✍️ **Autor**: [Seu Nome]  
> 🎓 **Disciplina**: Programação em Banco de Dados  
> 🐘 **SGBD**: PostgreSQL 15+
