-- Exercício 26 – Ranking de equipes

-- Crie: ranking_equipes()

-- retornando:
-- Equipe 	Jogos

-- Ordene da equipe com mais jogos para a equipe com menos jogos.

CREATE OR REPLACE FUNCTION ranking_equipes() RETURNS TABLE(
    var_equipe_nome TEXT,
    var_qtd_jogos BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        e.nome,
        COUNT(*) FILTER(
            WHERE e.id = j.equipe_casa_id OR e.id = j.equipe_visitante_id
        ) AS jogos
    FROM jogo j
    LEFT JOIN equipe e
        ON e.id = equipe_casa_id OR e.id = equipe_visitante_id
    WHERE j.equipe_casa_id IS NOT NULL 
        AND j.equipe_visitante_id IS NOT NULL
    GROUP BY e.nome
    ORDER BY jogos DESC;
END;
$$;
