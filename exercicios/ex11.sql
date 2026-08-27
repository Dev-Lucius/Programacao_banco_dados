-- Crie uma função usuario_mais_rico() que retorne o nome do usuário com maior saldo.
CREATE OR REPLACE FUNCTION usuario_mais_rico()
RETURNS MONEY
LANGUAGE plpgsql
AS $$
DECLARE
    maior_saldo MONEY := 0;
BEGIN
    SELECT MAX(saldo::NUMERIC) INTO maior_saldo FROM usuario WHERE id IS NOT NULL;
    RETURN maior_saldo;
END;
$$;
