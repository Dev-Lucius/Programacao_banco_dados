-- Exercício 40 – Transferência

-- Crie:

-- transferir(origem, destino, valor)

-- A procedure deverá:

--     validar origem;
--     validar destino;
--     verificar saldo;
--     retirar da origem;
--     adicionar ao destino

CREATE OR REPLACE PROCEDURE transferir(var_usuario_origem INTEGER, var_usuario_destino INTEGER, var_valor NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validando a Existência de um Usuário de Origem
    PERFORM 1 FROM usuario u WHERE u.id = var_usuario_origem;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Usuário de Origem % Não existe !', var_usuario_origem;
    END IF;

    -- Validando a Existência de um Usuário de Destino
    PERFORM 1 FROM usuario u WHERE u.id = var_usuario_destino;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Usuário de Destino % Não existe !', var_usuario_destino;
    END IF;

    -- Validando o valor a ser sacado
    IF var_valor IS NULL OR var_valor < 0 THEN
        RAISE EXCEPTION 'O Valor para deposito deve ser maior que 0';
    END IF;

    -- Validando se o Usuário de Origem tem Saldo suficiente para um Saque
    PERFORM 1 
    FROM usuario u 
    WHERE u.id = var_usuario_origem AND u.saldo::NUMERIC >= var_valor;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Usuário % Não Possui Saldo Suficiente para um Saque !', var_usuario_origem;
    END IF;

    -- Tendo Validado os Parâmetros ... Podemos fazer o Transfência
    UPDATE usuario 
    SET saldo = saldo::NUMERIC - var_valor
    WHERE id = var_usuario_origem;

    UPDATE usuario 
    SET saldo = saldo::NUMERIC + var_valor
    WHERE id = var_usuario_destino;

    RAISE NOTICE 'Transferência Realizada com Sucesso';
END;
$$;

CALL transferir(3, 1, 100);
