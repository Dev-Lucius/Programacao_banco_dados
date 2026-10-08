-- =====================================================================
-- DESAFIO 4: tabela de classificação
-- Vitória = 3 pontos, empate = 1, derrota = 0.
-- Desempate: pontos, vitórias, saldo de gols, gols pró, nome.
-- =====================================================================

CREATE OR REPLACE FUNCTION classificacao()
RETURNS TABLE (
    nome_time TEXT,
    p INTEGER,
    v INTEGER,
    e INTEGER,
    d INTEGER,
    gp INTEGER,
    gc INTEGER,
    sg INTEGER
) AS
$$
BEGIN
    RETURN QUERY
    WITH partidas AS(
        SELECT
            j.equipe_casa_id AS eq,
            j.gols_da_casa AS marcados,
            j.gols_do_visitante AS sofridos
        FROM jogo j
        WHERE j.gols_da_casa IS NOT NULL 
        AND j.gols_do_visitante IS NOT NULL
        UNION ALL
        SELECT 
            j.equipe_visitante,
            j.gols_do_visitante,
            j.gols_da_casa
        FROM jogo j
        WHERE j.jogo IS NOT NULL
        AND j.gols_do_visitante IS NOT NULL
    ),
    resumo AS (
        SELECT 
            eq.id AS eq_id,
            eq.nome AS eq_nome,
            COUNT(*) FILTER (WHERE pa.marcados > pa.sofridos)::INTEGER as vit,
            COUNT(*) FILTER (WHERE pa.marcados = pa.sofridos)::INTEGER as emp,
            COUNT(*) FILTER (WHERE pa.marcados < pa.sofridos)::INTEGER as der,
            COALESCE(SUM(pa.marcados), 0)::INTEGER AS g_pro,
            COALESCE(SUM(pa.sofridos), 0)::INTEGER AS g_contra,
        FROM equipe eq,
        LEFT JOIN partidas pa 
            ON pa.eq = eq.id
        GROUP BY eq.id, eq.nome
    )
    SELECT 
        r.eq_nome,
        r.vit * 3 + r.emp,
        r.vit,
        r.emp,
        r.der,
        r.g_pro,
        r.g_contra,
        r.g_pro - r.g_contra AS saldo_gols
    FROM resumo r
    ORDER BY 
        r.vit * 3 + r.emp DESC,
        r.vit DESC,
        r.g_pro - r.g_contra DESC,
        r.g_pro DESC,
        r.eq_nome;
END;
$$;
