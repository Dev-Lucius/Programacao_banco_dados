-- Exercício 28 – Usuários com apostas

-- Crie:
-- usuarios_com_apostas()

-- retornando somente usuários que possuem pelo menos uma aposta.

CREATE OR REPLACE FUNCTION usuarios_com_apostas() RETURNS TABLE(
    var_usuario_nome VARCHAR(200),
    var_usuario_email VARCHAR(200),
    var_usuario_saldo MONEY,
    var_valor_da_aposta MONEY,
    var_odd_aposta REAL
)
LANGUAGE plpgsql
AS $$
DECLARE

BEGIN
    RETURN QUERY
        SELECT
            u.nome,
            u.email,
            u.saldo,
            a.valor,
            a.odd
        FROM usuario u
        LEFT JOIN aposta a
            ON u.id = a.usuario_id
        WHERE a.usuario_id IS NOT NULL;
END;
$$;
