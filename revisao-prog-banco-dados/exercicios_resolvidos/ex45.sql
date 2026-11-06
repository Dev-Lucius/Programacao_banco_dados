-- Exercício 45 – Erro genérico

-- Crie uma function que execute uma operação de atualização e trate:

-- WHEN OTHERS
-- Utilize:
-- RAISE NOTICE

-- para apresentar uma mensagem de erro.

-- Elemento	Finalidade
-- EXCEPTION	 |  Inicia o bloco de tratamento de erros.
-- WHEN OTHERS	 |  Captura exceções não tratadas anteriormente.
-- RAISE NOTICE	 |  Exibe uma mensagem informativa.
-- SQLERRM	     |  Recupera a mensagem original do erro.
-- FOUND	     |  Verifica se o último comando relevante encontrou ou afetou registros.

CREATE OR REPLACE FUNCTION atualizar_saldo(var_usuario_id INTEGER, var_novo_saldo MONEY) RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN

    -- Realizando a Atualização
    UPDATE usuario
    SET saldo = var_novo_saldo
    WHERE id = var_usuario_id;

    RAISE NOTICE 'Saldo do Usuário % atualizado com Sucesso', var_usuario_id;

    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Erro ao Atualizar Saldo do Usuárioo %: %', var_usuario_id, SQLERRM;
END;
$$;
