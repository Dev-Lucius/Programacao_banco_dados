-- Exercício 23 – Apostas acima de determinado valor

-- Crie: apostas_acima(valor)
-- utilizando RETURN QUERY.

CREATE OR REPLACE FUNCTION apostas_acima(valor_acima_esperado NUMERIC) RETURNS TABLE(
    id_aposta INTEGER,
    valor_aposta MONEY,
    odd_aposta REAL
)
LANGUAGE plpgsql
AS $$
DECLARE

BEGIN

    RETURN QUERY
    SELECT
        a.id,
        a.valor,
        a.odd
    FROM aposta a
    WHERE a.valor::NUMERIC > valor_acima_esperado;

END;
$$;
