-- 4. Crie uma função nome_equipe(equipe_id) que retorne o nome da equipe.
CREATE OR REPLACE FUNCTION nome_equipe(var_equipe_id INTEGER) RETURNS TEXT AS
$$
DECLARE 
    resultado TEXT;
BEGIN
    SELECT nome FROM equipe WHERE id = var_equipe_id INTO resultado;
    RETURN resultado;
END
$$ LANGUAGE 'plpgsql';
