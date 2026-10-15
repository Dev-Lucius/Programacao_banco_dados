-- Exercício 17 – Quantidade de apostas

-- Crie: quantidade_apostas_usuario(usuario_id)

-- utilizando COUNT().

CREATE OR REPLACE FUNCTION quantidade_apostas_usuario(var_usuario_id INTEGER) RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    total_apostas INTEGER := 0;    
BEGIN
    SELECT usuario_id
    INTO total_apostas
    FROM aposta
    WHERE usuario_id = var_usuario_id;

    RETURN total_apostas;
END;
$$;
