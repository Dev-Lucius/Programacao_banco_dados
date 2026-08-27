-- Crie uma função media_valor_apostas() que retorne a média dos valores apostados.
CREATE OR REPLACE FUNCTION media_valor_apostas() 
RETURNS MONEY
LANGUAGE plpgsql
AS $$
DECLARE 
    somatorio_apostas MONEY := 0::MONEY;
    media MONEY := 0::MONEY;
BEGIN 
    SELECT SUM(valor) INTO somatorio_apostas FROM aposta WHERE id IS NOT NULL;
    media := AVG(somatorio_apostas::NUMERIC);
    RETURN media;
END;
$$;
