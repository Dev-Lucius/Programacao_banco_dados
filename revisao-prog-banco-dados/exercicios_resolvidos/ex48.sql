-- Exercício 48 – Histórico em texto

-- Crie:

-- historico_apostas_texto(usuario_id)

-- que percorra as apostas e construa um texto:

-- Jogo: SAO PAULO DE RG x RIO GRANDE
-- Valor: R$ 100,00
-- Odd: 2.50

-- Jogo: PELOTAS x BRASIL
-- Valor: R$ 50,00
-- Odd: 1.80

CREATE OR REPLACE FUNCTION historico_apostas_texto(var_usuario_id_aux INTEGER) RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    registro RECORD;
BEGIN
    FOR registro IN
        SELECT
            aposta.id,
            jogo.id,
            valor,
            odd,
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
            odd,
            aposta.gols_da_casa,
            aposta.gols_do_visitante
    LOOP
        RAISE NOTICE E'\n Jogo: % \n Valor: % \n odd: %', registro.times, registro.valor, registro.odd;
    END LOOP;
END;
$$;
