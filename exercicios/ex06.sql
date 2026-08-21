-- Crie uma função possui_saldo(usuario_id, valor) que retorne TRUE ou FALSE.
CREATE OR REPLACE FUNCTION possui_saldo(var_usuario_id INTEGER, var_valor MONEY) 
RETURNS BOOLEAN
LANGUAGE plpgsql        
AS $$
DECLARE 
    saldo_atual money := 0::money;
BEGIN
    saldo_atual := obter_saldo(var_usuario_id);
    
    -- Compara se o saldo é suficiente para o valor solicitado
    IF saldo_atual IS NULL OR saldo_atual < var_valor THEN
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
END;
$$;
