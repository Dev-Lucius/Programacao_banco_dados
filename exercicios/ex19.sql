-- Crie uma função usuarios_sem_apostas().
CREATE OR REPLACE FUNCTION usuarios_sem_apostas()
RETURNS TABLE(
    var_nome_usuario VARCHAR(200),
    var_saldo_usuario MONEY
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        u.nome,
        u.saldo
    FROM usuario u
    WHERE NOT EXISTS (
        SELECT 1 FROM aposta a WHERE a.usuario_id = a.id
    );
    RETURN;
END;
$$;
