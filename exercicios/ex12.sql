-- Crie uma função maior_aposta() que retorne o maior valor apostado.
CREATE OR REPLACE FUNCTION maior_aposta()
RETURNS MONEY
LANGUAGE plpgsql
AS $$
DECLARE
    aposta_maior money := 0;
BEGIN
    SELECT MAX(valor::NUMERIC) INTO aposta_maior FROM aposta WHERE id IS NOT NULL AND valor::NUMERIC != 0;
    RETURN aposta_maior;
END;
$$;
