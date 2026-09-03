-- Crie uma função tempo_desde_jogo(jogo_id) que retorne quantos dias passaram desde a realização do jogo.
CREATE OR REPLACE FUNCTION tempo_desde_jogo(jogo_id INTEGER)
RETURNS TIMESTAMP
LANGUAGE plpgsql
AS $$
DECLARE
    tempo_decorrido TIMESTAMP;
BEGIN
    IF(EXISTS(SELECT * FROM jogo WHERE id = $1)) THEN
        SELECT
            data_hora AS dia_partida,
            NOW() - data_hora INTO tempo_decorrido
        FROM jogo
        WHERE id = jogo_id;
    END IF;
    RETURN tempo_decorrido;
END;
$$;
