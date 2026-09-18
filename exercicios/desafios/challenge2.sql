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
    eq_nome TEXT;
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
        nome
    FROM equipe 
    WHERE id = var_equipe_id_aux INTO eq_id, eq_nome;

    SELECT 
        COALESCE(COUNT(*), 0)
    FROM jogo
    WHERE (jogo.equipe_casa_id = var_equipe_id_aux) OR (jogo.equipe_visitante_id = var_equipe_id_aux)
    INTO eq_qtde_jogos;

    -- gols realizados
    SELECT
        COALESCE(SUM(gols_da_casa), 0)
    FROM jogo
    WHERE equipe_casa_id = var_equipe_id_aux INTO eq_gols_realizados1;

    SELECT
        COALESCE(SUM(gols_do_visitante), 0)
    FROM jogo
    WHERE equipe_visitante_id = var_equipe_id_aux INTO eq_gols_realizados2;

    eq_gols_realizados_total := eq_gols_realizados1 + eq_gols_realizados2;

    -- gols sofridos
    SELECT
        COALESCE(SUM(gols_do_visitante), 0)
    FROM jogo
    WHERE equipe_casa_id = var_equipe_id_aux INTO eq_gols_sofridos1;

    SELECT
        COALESCE(SUM(gols_da_casa), 0)
    FROM jogo
    WHERE equipe_visitante_id = var_equipe_id_aux INTO eq_gols_sofridos2;

    eq_gols_sofridos_total := eq_gols_sofridos1 + eq_gols_sofridos2;

    -- Criando uma Tabela Temporária
    CREATE TEMPORARY TABLE IF NOT EXISTS temp_tabela(
        var_equipe_id INTEGER,
        var_equipe_nome TEXT,
        var_qtde_jogos INTEGER,
        var_gols_realizados INTEGER,
        var_gols_sofridos INTEGER
    ) ON COMMIT DROP;

    INSERT INTO temp_tabela(var_equipe_id, var_equipe_nome, var_qtde_jogos, var_gols_realizados, var_gols_sofridos) VALUES
    (eq_id, eq_nome, eq_qtde_jogos, eq_gols_realizados_total, eq_gols_sofridos_total);

    RETURN QUERY
    SELECT * 
    FROM temp_tabela ;

END;
$$;
