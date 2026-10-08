-- =====================================================================
-- DESAFIO 3: campeonato completo (todos contra todos, ida e volta)
-- Cada par (casa, visitante) é um jogo: com 6 equipes são 30 jogos.
--  - se o confronto já foi disputado, é ignorado;
--  - se existe jogo agendado sem resultado (ex.: jogo 1), ele é resolvido;
--  - caso contrário, o jogo é criado já com o resultado.
-- Por isso, chamar de novo não duplica jogos.
-- =====================================================================

CREATE OR REPLACE procedure realizar_campeonato()
LANGUAGE plpgsql
AS $$
DECLARE
    confronto record;
    v_jogo_id INTEGER;
    v_gols_casa INTEGER;
    v_gols_visitante INTEGER;
    v_total INTEGER := 0;
BEGIN

    FOR confronto IN
        SELECT
            c.id AS casa_id,
            c.nome AS casa_nome,
            v.id AS visit_id,
            v.nome AS visit_nome
        FROM equipe c
        CROSS JOIN equipe v
        WHERE c.id <> v.id
        ORDER BY c.id, v.id
    LOOP

        -- Confronto Já Disputado --> Não repete
        IF EXISTS(
            SELECT 1 
            FROM jogo
            WHERE equipe_casa_id = confronto.casa_id
                AND equipe_visitante_id = confronto.visit_id
                AND gols_da_casa IS NOT NULL
                AND gols_do_visitante IS NOT NULL
        ) THEN CONTINUE;
        END IF;

        -- Placar Aleatório de 0 a 5 Gols
        v_gols_casa := floor(random() * 6)::integer; 
        v_gols_visitante := floor(random() * 6)::integer;

        -- Existe Jogo agendado, ainda sem resultado?
        SELECT 
            id INTO v_jogo_id
        FROM jogo
        WHERE equipe_casa_id = confronto.casa_id
            AND equipe_visitante_id = confronto.visit_id
            AND (gols_da_casa IS NULL OR gols_do_visitante IS NULL)
        ORDER BY id
        LIMIT 1;

        IF FOUND THEN
            UPDATE jogo
                SET gols_da_casa = v_gols_casa,
                    gols_do_visitante = v_gols_visitante
                WHERE id = v_jogo_id;
        ELSE 
            INSERT INTO jogo (equipe_casa_id, equipe_visitante_id, gols_da_casa, gols_do_visitante)
            VALUES (confronto.casa_id, confronto.visit_id, v_gols_casa, v_gols_visitante);
        END IF;

        RAISE NOTICE '% % x % %', confronto.casa_nome, v_gols_casa, v_gols_visitante, confronto.visit_nome;
        v_total := v_total + 1;

    END LOOP;

    RAISE NOTICE 'Campeonato Concluído: % jogo(s) realizado(s)', v_total;
END;
$$;
