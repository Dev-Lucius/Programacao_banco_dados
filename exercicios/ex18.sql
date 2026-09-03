-- Crie uma função apostas_acima(valor) que retorne todas as apostas acima de determinado valor.
CREATE OR REPLACE FUNCTION apostas_acima(var_value NUMERIC)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    qtd_apostas_acima INTEGER := 0; 
BEGIN
    IF((SELECT valor::NUMERIC FROM aposta WHERE id IS NOT NULL) > var_value) THEN
        SELECT
            COUNT(id) INTO qtd_apostas_acima
        FROM aposta; 
    END IF;
    RETURN qtd_apostas_acima;
END;
$$;
