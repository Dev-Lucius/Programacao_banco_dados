/*
Exercício 2 – Verificar usuário
Crie uma função usuario_existe(usuario_id) que retorne:

- TRUE
* caso o usuário exista e:

- FALSE
    * caso contrário.
*/

CREATE OR REPLACE FUNCTION usuario_existe(var_usuario_id INTEGER) RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    usuario_exists BOOLEAN := FALSE;
BEGIN 

    -- Versão Mais Direta
    /*
    RETURNS EXISTS(
        SELECT 1
        FROM usuario
        WHERE id = var_usuario_id
    );
    */

    IF EXISTS(
        SELECT 1
        FROM usuario
        WHERE id = var_usuario_id
    ) THEN 
        usuario_exists:= TRUE;
    END IF;
    
    RETURN usuario_exists;
END;
$$;
