-- Exercício 13 – Total apostado

-- Crie uma função: total_apostado(usuario_id)

-- que utilize SUM().

CREATE OR REPLACE FUNCTION total_apostado(var_usuario_id INTEGER) RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    total_apts NUMERIC := 0;
BEGIN
    SELECT SUM(valor::NUMERIC)
    INTO total_apts
    FROM aposta
    LEFT JOIN usuario
        ON usuario.id = aposta.usuario_id
    WHERE usuario.id = var_usuario_id;

    RETURN total_apts;
END;
$$;
