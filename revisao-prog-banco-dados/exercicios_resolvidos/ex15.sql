-- Exercício 15 – Menor aposta do usuário

-- Crie: menor_aposta_usuario(usuario_id)

-- utilizando MIN()

CREATE OR REPLACE FUNCTION menor_aposta_usuario(var_usuario_id INTEGER) RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    menor_apst_user NUMERIC := 0;
BEGIN
    SELECT MIN(valor::NUMERIC)
    INTO menor_apst_user
    FROM aposta
    LEFT JOIN usuario
        ON usuario.id = aposta.usuario_id
    WHERE usuario.id = var_usuario_id;

    RETURN menor_apst_user;
END;
$$;
