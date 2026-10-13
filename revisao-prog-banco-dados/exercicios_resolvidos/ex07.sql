-- Exercício 7 – Classificação utilizando CASE
-- Reescreva o exercício anterior utilizando CASE em vez de IF.

CREATE OR REPLACE FUNCTION classificar_saldo_alternativo(var_usuario_id INTEGER) RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    -- Variável para Guardar o Saldo Consultado
    var_saldo MONEY;
    saldo_classificado TEXT;
BEGIN
    SELECT saldo
    INTO var_saldo
    FROM usuario
    WHERE id = var_usuario_id;

    IF NOT FOUND THEN
        RETURN 'USUARIO NAO ENCONTRADO';
    END IF;

    CASE
        WHEN var_saldo::NUMERIC IS NULL THEN
            saldo_classificado := 'SALDO NÂO INFORMADO';
        WHEN var_saldo::NUMERIC < 0 THEN
            saldo_classificado := 'SALDO NEGATIVO';
        WHEN var_saldo::NUMERIC < 250 THEN
            saldo_classificado := 'SALDO BAIXO';
        WHEN var_saldo::NUMERIC <= 1000 THEN
            saldo_classificado := 'SALDO MEDIO';
        ELSE
            saldo_classificado := 'SALDO ALTO';
        END CASE;

    RETURN saldo_classificado;
END;
$$;
