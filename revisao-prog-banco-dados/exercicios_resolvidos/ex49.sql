-- Exercício 49 – Estatísticas por equipe

-- Crie:

-- estatisticas_equipe(equipe_id)

-- retornando:

--     quantidade de jogos;
--     vitórias;
--     empates;
--     derrotas;
--     gols marcados;
--     gols sofridos.

CREATE OR REPLACE FUNCTION estatisticas_equipe(var_equipe_id INTEGER)
RETURNS TABLE (
    id_equipe INTEGER,
    var_equipe_nome TEXT,
    qtd_jogos BIGINT,
    var_vitorias BIGINT,
    var_empates BIGINT,
    var_derrotas BIGINT,
    var_gols_marcados BIGINT,
    var_gols_sofridos BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
    eq_id INTEGER;
    eq_nome TEXT;
    eq_qtde_jogos BIGINT;

    eq_vitorias BIGINT;
    eq_empates BIGINT;
    eq_derrotas BIGINT;

    eq_gols_realizados1 BIGINT;
    eq_gols_realizados2 BIGINT;
    eq_gols_realizados_total BIGINT;

    eq_gols_sofridos1 BIGINT;
    eq_gols_sofridos2 BIGINT;
    eq_gols_sofridos_total BIGINT;

BEGIN

    -- ID e nome da equipe
    SELECT e.id, e.nome
    INTO eq_id, eq_nome
    FROM equipe e
    WHERE e.id = var_equipe_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Equipe % não existe!', var_equipe_id;
    END IF;


    -- Quantidade de jogos encerrados
    SELECT COUNT(*)
    INTO eq_qtde_jogos
    FROM jogo j
    WHERE (
        j.equipe_casa_id = var_equipe_id
        OR j.equipe_visitante_id = var_equipe_id
    )
    AND j.gols_da_casa IS NOT NULL
    AND j.gols_do_visitante IS NOT NULL;


    -- Vitórias, empates e derrotas
    SELECT
        COUNT(*) FILTER (
            WHERE
                (j.equipe_casa_id = var_equipe_id
                 AND j.gols_da_casa > j.gols_do_visitante)
                OR
                (j.equipe_visitante_id = var_equipe_id
                 AND j.gols_do_visitante > j.gols_da_casa)
        ),

        COUNT(*) FILTER (
            WHERE j.gols_da_casa = j.gols_do_visitante
        ),

        COUNT(*) FILTER (
            WHERE
                (j.equipe_casa_id = var_equipe_id
                 AND j.gols_da_casa < j.gols_do_visitante)
                OR
                (j.equipe_visitante_id = var_equipe_id
                 AND j.gols_do_visitante < j.gols_da_casa)
        )

    INTO eq_vitorias, eq_empates, eq_derrotas

    FROM jogo j
    WHERE (
        j.equipe_casa_id = var_equipe_id
        OR j.equipe_visitante_id = var_equipe_id
    )
    AND j.gols_da_casa IS NOT NULL
    AND j.gols_do_visitante IS NOT NULL;


    -- Gols realizados quando a equipe joga em casa
    SELECT COALESCE(SUM(j.gols_da_casa), 0)
    INTO eq_gols_realizados1
    FROM jogo j
    WHERE j.equipe_casa_id = var_equipe_id
    AND j.gols_da_casa IS NOT NULL
    AND j.gols_do_visitante IS NOT NULL;


    -- Gols realizados quando a equipe joga fora
    SELECT COALESCE(SUM(j.gols_do_visitante), 0)
    INTO eq_gols_realizados2
    FROM jogo j
    WHERE j.equipe_visitante_id = var_equipe_id
    AND j.gols_da_casa IS NOT NULL
    AND j.gols_do_visitante IS NOT NULL;


    -- Total de gols realizados
    eq_gols_realizados_total :=
        eq_gols_realizados1 + eq_gols_realizados2;


    -- Gols sofridos quando a equipe joga em casa
    SELECT COALESCE(SUM(j.gols_do_visitante), 0)
    INTO eq_gols_sofridos1
    FROM jogo j
    WHERE j.equipe_casa_id = var_equipe_id
    AND j.gols_da_casa IS NOT NULL
    AND j.gols_do_visitante IS NOT NULL;


    -- Gols sofridos quando a equipe joga fora
    SELECT COALESCE(SUM(j.gols_da_casa), 0)
    INTO eq_gols_sofridos2
    FROM jogo j
    WHERE j.equipe_visitante_id = var_equipe_id
    AND j.gols_da_casa IS NOT NULL
    AND j.gols_do_visitante IS NOT NULL;


    -- Total de gols sofridos
    eq_gols_sofridos_total :=
        eq_gols_sofridos1 + eq_gols_sofridos2;


    -- Tabela temporária
    CREATE TEMPORARY TABLE IF NOT EXISTS temp_tabela (
        id_equipe INTEGER,
        var_equipe_nome TEXT,
        qtd_jogos BIGINT,
        var_vitorias BIGINT,
        var_empates BIGINT,
        var_derrotas BIGINT,
        var_gols_marcados BIGINT,
        var_gols_sofridos BIGINT
    ) ON COMMIT DROP;


    -- Inserindo as estatísticas
    INSERT INTO temp_tabela (
        id_equipe,
        var_equipe_nome,
        qtd_jogos,
        var_vitorias,
        var_empates,
        var_derrotas,
        var_gols_marcados,
        var_gols_sofridos
    )
    VALUES (
        eq_id,
        eq_nome,
        eq_qtde_jogos,
        eq_vitorias,
        eq_empates,
        eq_derrotas,
        eq_gols_realizados_total,
        eq_gols_sofridos_total
    );


    -- Retornando os dados
    RETURN QUERY
    SELECT *
    FROM temp_tabela;
END;
$$;
