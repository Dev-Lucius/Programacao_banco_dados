-- Exercício 27 – Usuários sem apostas

-- Crie:
-- usuarios_sem_apostas()

-- utilizando LEFT JOIN.

CREATE OR REPLACE FUNCTION usuarios_sem_apostas() RETURNS TABLE(
    var_usuario_nome VARCHAR(200),
    var_usuario_email VARCHAR(200),
    var_usuario_saldo MONEY
)
LANGUAGE plpgsql
AS $$
DECLARE

BEGIN
    RETURN QUERY
        SELECT
            u.nome,
            u.email,
            u.saldo
        FROM usuario u
        LEFT JOIN aposta a
            ON u.id = a.usuario_id
        WHERE a.usuario_id IS NULL;
END;
$$;
