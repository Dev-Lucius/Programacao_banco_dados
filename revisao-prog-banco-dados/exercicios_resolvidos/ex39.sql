-- Exercício 39 – Saque com validação

-- Crie:

-- sacar(usuario_id, valor)

-- Regras:

--     usuário deve existir;
--     valor deve ser positivo;
--     saldo deve ser suficiente;
--     saldo não pode ficar negativo.

CREATE OR REPLACE PROCEDURE sacar(var_usuario_id INTEGER, var_valor NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validando a Existência de um Usuário
    PERFORM 1 FROM usuario u WHERE u.id = var_usuario_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Usuário % Não existe !', var_usuario_id;
    END IF;

    -- Validando o valor a ser sacado
    IF var_valor IS NULL OR var_valor < 0 THEN
        RAISE EXCEPTION 'O Valor para deposito deve ser maior que 0';
    END IF;

    -- Validando se o Usuário tem Saldo suficiente para um Saque
    PERFORM 1 
    FROM usuario u 
    WHERE u.id = var_usuario_id AND u.saldo::NUMERIC >= var_valor;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Usuário % Não Possui Saldo Suficiente para um Saque !', var_usuario_id;
    END IF;

    -- Tendo Validado os Parâmetros ... Podemos fazer o Saque
    UPDATE usuario 
    SET saldo = saldo::NUMERIC - var_valor
    WHERE id = var_usuario_id;

    RAISE NOTICE 'Saque Realizado com Sucesso';
END;
$$;

CALL sacar(3, 100);
