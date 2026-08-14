/*
Crie uma função quantidade_apostas(usuario_id) que retorne o número total de apostas realizadas por um usuário.
*/
CREATE OR REPLACE FUNCTION quantidade_apostas(var_usuario_id int) RETURNS int
LANGUAGE 'plpgsql'
AS $func$
DECLARE
    total_apostas int := 0;
BEGIN
    SELECT COUNT(*)
    INTO total_apostas
    FROM aposta a
    WHERE a.usuario_id = var_usuario_id;

    RETURN total_apostas;
END;
$func$;
