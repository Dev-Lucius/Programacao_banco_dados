CREATE OR REPLACE FUNCTION historico_apostas(var_usuario_id_aux INTEGER)
RETURNS TABLE(
    var_aposta_id INTEGER,
    var_usuario_id INTEGER,
    var_jogo_id INTEGER,
    var_jogo MONEY,
    var_times TEXT,
    var_gols_da_casa INTEGER,
    var_gols_do_visitante INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN 
    RETURN QUERY
    SELECT
        aposta.id,
        usuario_id,
        jogo.id,
        valor,
        (SELECT nome FROM equipe WHERE id = jogo.equipe_casa_id) || ' x ' || (SELECT nome FROM equipe WHERE id = jogo.equipe_visitante_id) AS times,
        aposta.gols_da_casa,
        aposta.gols_do_visitante
    FROM aposta
    LEFT JOIN jogo  
        ON aposta.jogo_id = jogo.id
    LEFT JOIN equipe    
        ON equipe.id = jogo.equipe_casa_id OR equipe.id = jogo.equipe_visitante_id
    WHERE aposta.usuario_id = var_usuario_id_aux
    GROUP BY
        aposta.id,
        aposta.usuario_id,
        jogo.id,
        valor,
        aposta.gols_da_casa,
        aposta.gols_do_visitante;
END;
$$;
