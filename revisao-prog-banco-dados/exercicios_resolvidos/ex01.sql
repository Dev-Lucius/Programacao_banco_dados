/*
Exercício 1 – Saldo formatado
Crie uma função saldo_formatado(usuario_id) que retorne o saldo do usuário como texto.

Exemplo:
R$ 1.500,00
*/
CREATE OR REPLACE FUNCTION saldo_formatado(var_usuario_id INTEGER) RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    saldo_formatado TEXT;
BEGIN
    SELECT
        saldo::TEXT
    FROM usuario
    WHERE id = var_usuario_id
    INTO saldo_formatado;

    -- Eh possivel usar a Função CAST para fazer essa lógica
    /*
    SELECT
        CAST(saldo AS TEXT)
    FROM usuario
    WHERE id = var_usuario_id
    INTO saldo_formatado;
    */

    RETURN saldo_formatado;
END;
$$;
