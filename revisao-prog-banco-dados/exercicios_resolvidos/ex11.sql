-- Exercício 11 – Dados da equipe
-- Crie: dados_equipe(equipe_id)
-- que retorne o nome e o local da equipe em uma única string.

-- Exemplo:
-- SAO PAULO DE RG - Rio Grande

CREATE OR REPLACE FUNCTION dados_equipe(var_equipe_id INTEGER) RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    var_dados_equipe TEXT;
BEGIN
    SELECT nome || ' - ' || local
    INTO var_dados_equipe
    FROM equipe
    WHERE id = var_equipe_id;

    RETURN var_dados_equipe; 
END;
$$;
