-- Crie uma função saldo_total_sistema().
CREATE OR REPLACE FUNCTION saldo_total_sistema()
RETURNS MONEY
LANGUAGE plpgsql
AS $$
DECLARE
    total_saldo MONEY := 0;
BEGIN
    SELECT
        SUM(saldo::NUMERIC)
        INTO total_saldo
        FROM usuario
        WHERE id IS NOT NULL AND saldo::NUMERIC != 0;

        RETURN total_saldo;
END;
$$;

     
