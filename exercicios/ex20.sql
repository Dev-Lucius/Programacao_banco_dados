-- Crie uma função ranking_apostadores() que retorne:
-- | Usuário | Número de apostas |
CREATE OR REPLACE FUNCTION ranking_apostadores()
RETURNS TABLE(
    var_id INTEGER,
    var_nome VARCHAR,
    var_qtde BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        usuario.id,
        usuario.nome,
        COALESCE(COUNT(aposta.id), 0) AS quantidade_apostas
    FROM usuario
    LEFT JOIN aposta
    ON usuario.id = aposta.usuario_id
    GROUP BY usuario.id, usuario.nome, aposta.id
    ORDER BY usuario.id;
END;
$$;
