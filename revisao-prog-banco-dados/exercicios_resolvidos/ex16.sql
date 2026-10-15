-- Exercício 16 – Média das apostas

-- Crie: media_apostas_usuario(usuario_id)

-- utilizando AVG().

CREATE OR REPLACE FUNCTION media_apostas_usuario(var_usuario_id INTEGER) RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    media NUMERIC := 0;
BEGIN
    SELECT AVG(valor::NUMERIC)
    INTO media
    FROM aposta
    WHERE usuario_id = var_usuario_id;

    RETURN media;
END;
$$;
