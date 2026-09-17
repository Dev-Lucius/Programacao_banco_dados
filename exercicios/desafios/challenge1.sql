CREATE OR REPLACE FUNCTION desafio_um()
RETURNS TABLE(
    var_nome TEXT,
    var_id_equipe_casa INTEGER,
    var_id_equipe_visitante INTEGER,
    var_data_hora_jogo TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        e.nome,
        j.equipe_casa_id,
        j.equipe_visitante_id,
        j.data_hora
    FROM jogo j
    left join equipe e
    on e.id = j.equipe_casa_id AND e.id = j.equipe_visitante_id
    where j.equipe_casa_id is not null and j.equipe_visitante_id IS not null;
END;
$$;