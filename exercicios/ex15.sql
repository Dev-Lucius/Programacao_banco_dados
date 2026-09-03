-- Crie uma função lucro_potencial(aposta_id):
-- valor × odd
CREATE OR REPLACE FUNCTION lucro_potencial(aposta_id INTEGER) 
RETURNS TABLE(
    var_valor MONEY,
    var_odd REAL,
    var_lucro MONEY
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        valor,
        odd,
        valor + (valor * odd) AS lucro
    FROM aposta;
END;
$$;
