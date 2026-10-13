-- Exercício 4 – Verificar jogo
-- Crie uma função jogo_existe(jogo_id) que retorne TRUE ou FALSE.

CREATE OR REPLACE FUNCTION jogo_existe(var_jogo_id INTEGER) RETURNS BOOLEAN 
LANGUAGE plpgsql
AS $$
BEGIN   
    RETURN EXISTS(
        SELECT 1
        FROM jogo
        WHERE id = var_jogo_id
    );
END;
$$;
