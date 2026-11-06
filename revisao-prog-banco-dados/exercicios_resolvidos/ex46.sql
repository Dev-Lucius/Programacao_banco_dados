-- Exercício 46 – Depósito seguro

-- Crie uma function ou procedure para depósito que trate erros utilizando EXCEPTION.

-- Em caso de erro:
-- Depósito não realizado.

CREATE OR REPLACE PROCEDURE deposito_seguro(var_usuario_id INTEGER, var_saldo NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Verificando se o Usuário Existe
    PERFORM 1 FROM usuario u WHERE u.id = var_usuario_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Usuário % não Existe', var_usuario_id;
    END IF;

    -- Verificando se o Saldo é Negativo ou Igual à Zero
    IF var_saldo::NUMERIC <= 0 THEN
        RAISE EXCEPTION 'Saldo Inválido';
    END IF;

    UPDATE usuario u
    set saldo = (saldo::NUMERIC + var_saldo)::MONEY 
    WHERE u.id = var_usuario_id;

    RAISE NOTICE 'Saldo do Usuário % atualizado com Sucesso', var_usuario_id;

     EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Depósito não realizado: %', SQLERRM;
END;
$$;

CALL deposito_seguro(3, 100);
