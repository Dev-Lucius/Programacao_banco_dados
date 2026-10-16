-- Exercício 22 – Jogos encerrados

-- Crie: jogos_encerrados()
-- retornando todos os jogos já realizados.

CREATE OR REPLACE FUNCTION jogos_encerrados() RETURNS TABLE(
    id_jogo INTEGER,
    data_hora_jogo TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        j.id,
        j.data_hora
    FROM jogo j
    WHERE j.data_hora <= NOW();
END;
$$;
