-- Exercício 21 – Jogos futuros

-- Crie: jogos_futuros()
-- que retorne todos os jogos que ainda não foram encerrados.
CREATE OR REPLACE FUNCTION jogos_futuros() RETURNS TABLE(
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
    WHERE j.data_hora >= NOW();
END;
$$;
