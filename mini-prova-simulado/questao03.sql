-- Questão 3 (1,5 ponto) – Premiação dos acertos exatos

-- Implemente uma função:

-- premiacao_acertos_exatos()
-- RETURNS TABLE (
--     usuario_id          INTEGER,
--     nome_usuario        TEXT,
--     apostas_encerradas  BIGINT,
--     acertos_exatos      BIGINT,
--     total_apostado      MONEY,
--     premio_total        MONEY
-- )

-- A função deve gerar um relatório dos usuários que possuem apostas em jogos encerrados. Para cada usuário, retorne:

--     apostas_encerradas: quantidade de apostas do usuário em jogos encerrados;
--     acertos_exatos: quantidade dessas apostas em que o placar previsto é igual ao placar real;
--     total_apostado: soma dos valores de todas essas apostas;
--     premio_total: soma do prêmio de cada acerto exato, onde prêmio = valor apostado × odd.

-- Requisitos

--     Considere somente apostas de jogos encerrados. Apostas em jogos pendentes devem ser ignoradas.
--     Um usuário sem nenhum acerto exato deve aparecer com premio_total igual a zero (e não NULL).
--     Usuários sem apostas em jogos encerrados não devem aparecer.
--     Ordene pelo premio_total em ordem decrescente e, em caso de empate, pelo

CREATE OR REPLACE FUNCTION premiacao_acertos_exatos() RETURN TABLE(
    usuario_id INTEGER,
    nome_usuario TEXT,
    apostas_encerradas BIGINT,
    acertos_exatos BIGINT,
    total_apostados MONEY,
    premio_total MONEY
)
LANGUAGE plpgsql
AS $$
DECLARE
    var_acertos_exatos BIGINT := 0;
BEGIN

    RETURN QUERY
    SELECT
        u.id,
        u.nome::TEXT,

        -- Apostas Encerradas
        COUNT(*) AS apostas_encerradas,

        -- Acertos Exatos
        COUNT(*) FILTER(
            WHERE a.gols_da_casa = j.gols_da_casa 
                AND a.gols_do_visitante = j.gols_do_visitante
        ) AS acertos_exatos,

        -- Total Apostado
        SUM(a.valor::NUMERIC) AS total_apost,

        -- Premiacao
        COALESCE(
            SUM(
                CASE
                    WHEN a.gols_da_casa = j.gols_da_casa AND a.gols_do_visitante = j.gols_do_visitante
                    THEN (a.valor::NUMERIC * a.odd::NUMERIC)::MONEY
                    ELSE 0::MONEY
                END
            ),
            0::MONEY
        ) AS premio_total
    FROM usuario u
    LEFT JOIN aposta a
        ON u.id = a.usuario_id
    LEFT JOIN jogo j
        ON j.id = a.jogo_id

    -- Considera Encerrados Jogos com placar Registrado
    WHERE j,.gols
    GROUP BY u.id, u.nome; 
END;
$$;
