-- Crie uma função total_equipes() que retorne a quantidade de equipes.
CREATE OR REPLACE FUNCTION total_equipes(var_equipes_id INTEGER)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    todas_equipes integer := 0;
BEGIN
    SELECT COUNT(*) INTO todas_equipes FROM equipe WHERE id = var_equipes_id;
    RETURN todas_equipes;
END;
$$; 
