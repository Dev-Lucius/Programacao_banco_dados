-- Exercício 20 – Jogos de uma equipe

-- Crie: jogos_equipe(equipe_id)

-- Retorne:
--     jogo;
--     adversário;
--     data;
--     resultado.

CREATE OR REPLACE FUNCTION jogos_equipe(
    var_equipe_id INTEGER
)
RETURNS TABLE (
    id_jogo INTEGER,
    nome_equipe_casa TEXT,
    nome_equipe_adversaria TEXT,
    equipe_adversaria INTEGER,
    data_jogo TIMESTAMP,
    gols_casa INTEGER,
    gols_visitante INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    resultado TEXT;
BEGIN
    RETURN QUERY
    SELECT
        j.id,
        ec.nome::TEXT,
        ea.nome::TEXT,

        -- O CASE identifica o adversário:
        -- se a equipe consultada for a mandante, retorna o ID da visitante; 
        -- caso contrário, retorna o ID da mandante.
        CASE
            WHEN j.equipe_casa_id = var_equipe_id
                THEN j.equipe_visitante_id
            ELSE j.equipe_casa_id
        END,
        j.data_hora,
        j.gols_da_casa,
        j.gols_do_visitante
    FROM jogo j
    LEFT JOIN equipe ec
        ON ec.id = j.equipe_casa_id
    LEFT JOIN equipe ea
        ON ea.id = j.equipe_visitante_id
    WHERE j.equipe_casa_id = var_equipe_id
       OR j.equipe_visitante_id = var_equipe_id;
END;
$$;

