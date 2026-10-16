-- Exercício 24 – Usuários com saldo mínimo

-- Crie: usuarios_com_saldo_minimo(valor)

-- utilizando RETURN QUERY.

CREATE OR REPLACE FUNCTION usuarios_com_saldo_minimo(valor_saldo_esperado NUMERIC) RETURNS TABLE(
    id_usuario INTEGER,
    nome_usuario VARCHAR(200),
    email_usuario VARCHAR(200),
    saldo MONEY
)
LANGUAGE plpgsql
AS $$
BEGIN

    RETURN QUERY
    SELECT
        u.id,
        u.nome,
        u.email,
        u.saldo
    FROM usuario u
    WHERE u.saldo::NUMERIC > valor_saldo_esperado AND u.status IS TRUE;
    
END;
$$;
