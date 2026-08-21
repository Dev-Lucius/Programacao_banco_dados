-- Crie uma função total_usuarios() que retorne a quantidade de usuários cadastrados.
CREATE OR REPLACE FUNCTION total_usuarios(var_usuario_id INTEGER) 
RETURNS INTEGER 
LANGUAGE plpgsql   
AS $$ 
DECLARE
    total_user integer := 0;
BEGIN
    SELECT COUNT(*) INTO total_user FROM usuario WHERE id = var_usuario_id;

    RETURN total_user;
END;
$$;
