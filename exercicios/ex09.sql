-- Crie uma função total_jogos() que retorne a quantidade de jogos cadastrados.
CREATE OR REPLACE FUNCTION total_jogos(var_jogos_id INTEGER) 
RETURNS INTEGER
LANGUAGE plpgsql
AS $$ 
DECLARE 
    todos_jogos integer := 0;
BEGIN
    SELECT COUNT(*) INTO todos_jogos FROM jogo WHERE id = var_jogos_id;
    RETURN todos_jogos;
END;
$$;
