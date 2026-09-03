-- Crie uma função listar_jogos() que retorne:

--  * equipe casa
--  * equipe visitante
--  * data
CREATE OR REPLACE FUNCTION listar_jogos(var_jogo_id INTEGER)
RETURNS TABLE(
    var_equipe_casa INTEGER,
    var_equipe_visitante INTEGER,
    var_data_hora TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        j.equipe_casa_id,
        j.equipe_visitante_id,
        j.data_hora
    FROM jogo j
    WHERE j.id = var_jogo_id;

    RETURN;
END;
$$;
