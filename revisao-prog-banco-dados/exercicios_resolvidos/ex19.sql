-- Exercício 19 – Apostas do usuário

-- Crie: listar_apostas_usuario(usuario_id)

-- retornando:
--     ID da aposta;
--     valor;
--     odd.

-- Utilize:
-- RETURNS TABLE

CREATE OR REPLACE FUNCTION listar_apostas_usuario(var_usuario_id INTEGER) RETURNS TABLE(
    id_aposta INTEGER,
    valor_aposta MONEY,
    odd_aposta REAL
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        a.id,
        a.valor,
        a.odd
    FROM aposta a
    WHERE a.usuario_id = var_usuario_id;

END;
$$;
