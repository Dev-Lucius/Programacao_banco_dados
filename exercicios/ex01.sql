/*
Crie uma função obter_saldo(usuario_id) que retorne o saldo do usuário.
*/
CREATE OR REPLACE FUNCTION obter_saldo(usuario_id int) RETURNS money
LANGUAGE 'plpgsql'
AS $func$
DECLARE
    saldo_atual money := 0::money;
BEGIN
    SELECT u.saldo 
    INTO saldo_atual 
    FROM usuario u 
    WHERE u.id = usuario_id;
    
    RETURN saldo_atual;
END;
$func$;