-- Questão 4 (1,0 ponto) – Média de gols de uma equipe

-- Implemente a função:

-- media_gols_equipe(var_equipe_id INTEGER)
-- RETURNS NUMERIC

-- A função deve retornar a média de gols marcados pela equipe informada nos jogos encerrados, considerando tanto os jogos em que ela foi mandante quanto aqueles em que foi visitante. 
-- O resultado deve ser arredondado para 2 casas decimais.
-- Requisitos

--     Não utilize AVG(): calcule a média dividindo a soma de gols pela quantidade de jogos.
--     Obtenha a soma e a quantidade com SELECT ... INTO.
--     Se a equipe não existir, interrompa com RAISE EXCEPTION.
--     Se a equipe não tiver jogos encerrados, a divisão por zero deve ser tratada com EXCEPTION: exiba uma mensagem com RAISE NOTICE e retorne NULL.
--     Atenção: SUM() sobre nenhuma linha devolve NULL, e NULL / 0 não gera erro de divisão por zero. Pense em como garantir que a divisão realmente ocorra com o denominador igual a zero.

CREATE OR REPLACE FUNCTION media_gols_equipe(var_equipe_id INTEGER) RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    var_media NUMERIC(10, 2);
BEGIN
    
    -- 1. Verificando se a Equipe Existe
    PERFORM 1
    FROM equipe e
    WHERE e.id = var_equipe_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'A equipe % Não existe!', var_equipe_id;
    END IF;

    -- 2. Calculando a Média
    SELECT
        COALESCE(
            SUM(
                CASE
                    WHEN j.equipe_casa_id = var_equipe_id
                        THEN j.gols_da_casa
                    ELSE j.gols_do_visitante
                END
                -- NULLIF no PSQL compara dois valores
                --  * Se forem iguais retorna NULL;
                --  * Se forem diferentes retorna o primeiro Valor
                -- NULLIF(value1, value2)
            )::NUMERIC / NULLIF(COUNT(*), 0),
            0
        )
        INTO var_media
        FROM jogo j
        WHERE (
            j.equipe_casa_id = var_equipe_id 
            OR j.equipe_visitante_id = var_equipe_id
        )
        AND j.gols_da_casa IS NOT NULL
        AND j.gols_do_visitante IS NOT NULL;

        RETURN var_media;
END;    
$$;
