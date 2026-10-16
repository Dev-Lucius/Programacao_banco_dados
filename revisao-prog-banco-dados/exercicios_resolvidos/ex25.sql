-- Exercício 25 – Ranking de apostadores

-- Crie: ranking_apostadores()

-- retornando:
-- Usuário  Apostas Total Apostado

-- Ordene pelo maior valor total apostado.
-- Utilize RETURN QUERY.

CREATE OR REPLACE FUNCTION ranking_apostadores() RETURNS TABLE(
    -- Colunas de "usuario"
    usuario_id INTEGER,
    usuario_nome VARCHAR(200),
    usuario_saldo MONEY,

    -- Colunas de "aposta"
    valor_aposatado MONEY,
    odd_aposta REAL
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id,
        u.nome,
        u.saldo,
        a.valor,
        a.odd
    FROM usuario u
    LEFT JOIN aposta a
        ON u.id = a.usuario_id
    ORDER BY a.valor DESC
    LIMIT 10;
END;
$$;
