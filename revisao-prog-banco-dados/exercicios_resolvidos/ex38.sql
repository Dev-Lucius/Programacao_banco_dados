-- Exercício 38 – Depósito com validação

-- Crie uma procedure:

-- depositar(usuario_id, valor)

-- Regras:

--     valor deve ser positivo;
--     usuário deve existir;
--     adicionar o valor ao saldo.

-- Utilize IF.

CREATE OR REPLACE PROCEDURE depositar(var_usuario_id INTEGER, var_valor NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN

    -- Validando a Existência de um Usuário
    PERFORM 1 FROM usuario u WHERE u.id = var_usuario_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Usuário % Não existe !', var_usuario_id;
    END IF;

    -- Validando o valor a ser depositado
    IF var_valor IS NULL OR var_valor < 0 THEN
        RAISE EXCEPTION 'O Valor para deposito deve ser maior que 0';
    END IF;

    -- Tendo Validado os Parâmetros ... Podemos fazer o Deposito
    UPDATE usuario 
    SET saldo = saldo::NUMERIC + var_valor
    WHERE id = var_usuario_id;

    RAISE NOTICE 'Saldo Atualizado com Sucesso';
END;
$$;

-- Teste
CALL depositar(3, 100);
