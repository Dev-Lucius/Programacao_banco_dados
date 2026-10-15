-- Exercício 18 – Estatísticas completas

-- Crie uma função que receba usuario_id e retorne:

--     nome
--     quantidade
--     total
--     media
--     maior
--     menor

CREATE OR REPLACE FUNCTION estatistica_completa(var_usuario_id INTEGER) RETURNS TABLE(
    nome_user VARCHAR(200),
    qtd BIGINT,
    media NUMERIC,
    maior_aposta NUMERIC,
    menor_aposta NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN

    RETURN QUERY
    SELECT
        nome,
        COUNT(usuario_id),
        AVG(valor::NUMERIC),
        MAX(valor::NUMERIC),
        MIN(valor::NUMERIC)
    FROM aposta
    LEFT JOIN usuario
        ON usuario.id = aposta.usuario_id
    WHERE usuario.id = var_usuario_id
    GROUP BY nome;

END;
$$;
