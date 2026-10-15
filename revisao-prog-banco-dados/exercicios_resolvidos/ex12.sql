-- Exercício 12 – Dados do jogo

-- Crie: dados_jogo(jogo_id)

-- que retorne: SAO PAULO DE RG x RIO GRANDE
-- utilizando SELECT INTO.


CREATE OR REPLACE FUNCTION dados_jogos(var_jogo_id INTEGER) RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    var_dados_jogo TEXT;
BEGIN
    SELECT
        ec.nome || ' x ' || ev.nome
    INTO var_dados_jogo
    FROM jogo j
    JOIN equipe ec
        ON j.equipe_casa_id = ec.id
    JOIN equipe ev
        ON j.equipe_visitante_id = ev.id
    WHERE j.id = var_jogo_id;

    IF NOT FOUND THEN
        RETURN 'JOGO NAO ENCONTRADO';
    END IF;

    RETURN var_dados_jogo;
END;
$$;
