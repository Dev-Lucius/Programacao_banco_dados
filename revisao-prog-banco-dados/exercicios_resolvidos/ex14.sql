-- Exercício 14 – Maior aposta do usuário

-- Crie: maior_aposta_usuario(usuario_id)

-- utilizando MAX().

CREATE OR REPLACE FUNCTION maior_aposta_usuario(var_usuario_id INTEGER) RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    maior_apst_user NUMERIC := 0;
BEGIN
    SELECT MAX(valor::NUMERIC)
    INTO maior_apst_user
    FROM aposta
    LEFT JOIN usuario
        ON usuario.id = aposta.usuario_id
    WHERE usuario.id = var_usuario_id;

    RETURN maior_apst_user;
END;
$$;
