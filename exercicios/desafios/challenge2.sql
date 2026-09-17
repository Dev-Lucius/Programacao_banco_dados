CREATE OR REPLACE FUNCTION estatistica(var_equipe_id_aux INTEGER)
RETURNS TABLE(
    var_equipe_id INTEGER,
    var_equipe_nome TEXT,
    var_qtde_jogos INTEGER,
    var_gols_realizados INTEGER,
    var_gols_sofridos INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE

    eq_id INTEGER;
    eq_nome INTEGER;
    eq_qtde_jogos INTEGER;
    eq_gols_realizados1 INTEGER;
    eq_gols_realizados2 INTEGER;
    eq_gols_realizados_total INTEGER;
    eq_gols_sofridos1 INTEGER;
    eq_gols_sofridos2 INTEGER;
    eq_gols_sofridos_total INTEGER;

BEGIN 

    SELECT
        id,
        nome,
    FROM equipe 
    WHERE id = var_equipe_id_aux INTO eq_id, eq_nome;

    SELECT 
        COALESCE(COUNT(*), 0)
    FROM jogo
    WHERE (jogo.equipe_casa_id = var_equipe_id_aux) OR (jogo.equipe_visitante_id = var_equipe_id_aux)
    INTO eq_qtde_jogos;

    -- Terminar Depois

END;
$$;
