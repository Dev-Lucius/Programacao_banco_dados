-- Crie uma função possui_saldo(usuario_id, valor) que retorne TRUE ou FALSE.
CREATE OR REPLACE FUNCTION possui_saldo(var_usuario_id INTEGER) RETURNS BOOLEAN
AS
$$
DECLARE 
    saldo_atual money := 0::money;
BEGIN
    saldo_atual := obter_saldo(var_usuario_id);
    IF(saldo_atual IS NULL OR saldo_atual <= 0::money) THEN
        return FALSE;
    END IF;
    RETURN TRUE;
END;
$$ 'plpgsql';
