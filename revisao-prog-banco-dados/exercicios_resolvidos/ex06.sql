-- Exercício 6 – Classificação de saldo
-- Crie uma função:
-- classificar_saldo(usuario_id) que retorne:
--  * SEM SALDO
--  * SALDO BAIXO
--  * SALDO MEDIO
--  * SALDO ALTO

-- Utilize IF / ELSIF / ELSE.
-- Sintaxe Básica
IF condição THEN
    -- Executa se a condição for verdadeira

ELSIF outra_condição THEN
    -- Executa se a primeira condição for falsa
    -- e esta condição for verdadeira

ELSE
    -- Executa se nenhuma condição anterior for verdadeira
END IF;

-- Função Completa
CREATE OR REPLACE FUNCTION classificar_saldo(var_usuario_id INTEGER) RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    -- Variável para Guardar o Saldo Consultado
    var_saldo MONEY;
    saldo_classificado TEXT;
BEGIN
    SELECT saldo
    INTO var_saldo
    FROM usuario
    WHERE id = var_usuario_id;

    IF NOT FOUND THEN
        RETURN 'USUARIO NAO ENCONTRADO';
    END IF;

    IF var_saldo::NUMERIC::NUMERIC IS NULL THEN
        RETURN 'SALDO NAO INFORMADO';
    ELSIF var_saldo::NUMERIC = 0 THEN
        saldo_classificado := 'SEM SALDO';
    ELSIF var_saldo::NUMERIC > 0 AND var_saldo::NUMERIC < 250 THEN
        saldo_classificado := 'SALDO BAIXO';
    ELSIF var_saldo::NUMERIC >= 250 AND var_saldo::NUMERIC <= 1000 THEN
        saldo_classificado := 'SALDO MEDIO';
    ELSE
        saldo_classificado := 'SALDO ALTO';
    END IF;

    RETURN saldo_classificado;
END;
$$;
