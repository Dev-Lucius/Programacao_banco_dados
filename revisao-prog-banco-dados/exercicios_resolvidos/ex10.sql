-- Exercício 10 – E-mail do usuário

-- Crie: email_usuario(usuario_id)

-- utilizando SELECT INTO.

CREATE OR REPLACE FUNCTION email_usuario(var_usuario_id INTEGER) RETURNS VARCHAR(200)
LANGUAGE plpgsql
AS $$
DECLARE
    var_email_user VARCHAR(200);
BEGIN
    SELECT email
    INTO var_email_user
    FROM usuario
    WHERE id = var_usuario_id;

    RETURN var_email_user;
END;
$$;
