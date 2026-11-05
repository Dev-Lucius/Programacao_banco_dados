-- Exercício 43 – Usuário inexistente

-- Crie uma função que utilize:
-- SELECT ... INTO ...

-- e trate:
-- NO_DATA_FOUND

-- utilizando:
-- EXCEPTION

CREATE OR REPLACE FUNCTION verificar_usuario_existente(var_usuario_id INTEGER) RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    var_nome VARCHAR(200);
    var_saldo MONEY;
BEGIN
    -- Consultando Dados do Usuário
    SELECT
        u.nome,
        u.saldo
    INTO STRICT 
        var_nome,
        var_saldo
    FROM usuario u
    WHERE u.id = var_usuario_id;

    RAISE NOTICE 'Usuário: % | Saldo: %', var_nome, var_saldo;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE NOTICE 'Usuário % Não Existe !', var_usuario_id;
END;
$$;
