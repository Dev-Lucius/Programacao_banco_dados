-- Crie uma procedure criar_jogo(casa, visitante, data).
CREATE OR REPLACE PROCEDURE criar_jogo(
    p_casa integer,        -- id da equipe da casa
    p_visitante integer,   -- id da equipe visitante
    p_data timestamp
)
LANGUAGE plpgsql
AS $$
BEGIN
    /*
       Validação: casa e visitante devem ser equipes diferentes.
       Um jogo não pode ser contra si mesmo.
    */
    IF p_casa = p_visitante THEN
        RAISE EXCEPTION 'Uma equipe não pode jogar contra ela mesma';
    END IF;

    INSERT INTO jogo (equipe_casa_id, equipe_visitante_id, data_hora)
    VALUES (p_casa, p_visitante, p_data);

    COMMIT;

    RAISE NOTICE 'Jogo criado: Casa % x Visitante % em %', p_casa, p_visitante, p_data;
END;
$$;
