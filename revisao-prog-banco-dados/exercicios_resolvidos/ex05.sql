-- Exercício 5 – Saldo suficiente
-- Crie uma função:
-- saldo_suficiente(usuario_id, valor)
-- - que retorne TRUE quando o usuário possuir saldo suficiente para realizar uma operação.

CREATE OR REPLACE FUNCTION saldo_suficiente(var_usuario_id INTEGER, var_valor NUMERIC(10, 2)) RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    aposta_valida BOOLEAN := FALSE;
BEGIN
    IF EXISTS(
        SELECT 1
        FROM usuario
        WHERE saldo::NUMERIC(10,2) >= var_valor
    ) THEN
        aposta_valida := TRUE;
    END IF;

    RETURN aposta_valida;
END;
$$;
