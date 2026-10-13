-- Exercício 3 – Verificar equipe
-- Crie uma função equipe_existe(equipe_id) que realize a mesma verificação para equipes.

CREATE OR REPLACE FUNCTION equipe_existe(var_equipe_id INTEGER) RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN

    RETURN EXISTS(
        SELECT 1
        FROM equipe
        WHERE id = var_equipe_id
    );
END;
$$;
