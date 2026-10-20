-- 1. Desempenho de uma Equipe como Mandante 
-- Implemente a função abaixo.
-- 
-- desempenho_mandante(var_equipe_id INTEGER)
-- RETURNS TABLE (
    -- jogo_id           INTEGER,
    -- equipe_visitante  TEXT,
    -- placar            TEXT,
    -- resultado         TEXT
-- )
-- 
-- A função deve listar os jogos encerrados em que a equipe informada atuou como mandante (time da casa).
-- 
    -- placar deve seguir o formato gols_casa x gols_visitante, por exemplo 2 x 1.
    -- resultado deve ser VITORIA, EMPATE ou DERROTA, sempre sob a ótica da equipe informada.
-- 
-- Requisitos
-- 
    -- Considere apenas jogos encerrados.
    -- Se a equipe não existir ou não tiver jogos encerrados como mandante, a função não deve retornar linhas.
    -- Utilize CASE para classificar o resultado.
    -- Ordene pelo identificador do jogo em ordem crescente.

CREATE OR REPLACE FUNCTION desempenho_mandante(var_equipe_id INTEGER) RETURNS TABLE(
    jogo_id INTEGER,
    equipe_visitante TEXT,
    placar TEXT,
    resultado TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN

    RETURN QUERY
    SELECT
        j.id,
        ev.nome::TEXT,
        -- placar
        -- Usando o Operador || para concatenar os gols da casa e do visitante em um text com um  " ' x ' " no meio deles
        j.gols_da_casa::TEXT || ' x ' || j.gols_do_visitante,
        -- Resultado
        -- Usando um CASE ... WHEN para estruturar o resultado com base em validações dos gols da casa e do visitante
        CASE
            WHEN j.gols_da_casa > j.gols_do_visitante THEN 'VITORIA'
            WHEN j.gols_da_casa < j.gols_do_visitante THEN 'DERROTA'
            ELSE 'EMPATE'
        END CASE
    FROM jogo j
    LEFT JOIN equipe ev
        ON ev.id = j.equipe_casa_id
    WHERE ev.id = var_equipe_id
    ORDER BY j.id ASC;
END;
$$;
-- SELECT * FROM desempenho_mandante(5);


