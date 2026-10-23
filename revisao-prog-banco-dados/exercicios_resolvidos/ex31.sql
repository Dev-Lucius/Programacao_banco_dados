-- Exercício 31 – Percorrer equipes

-- Crie uma função que percorra todas as equipes e apresente:

-- Equipe: SAO PAULO DE RG
-- Local: Rio Grande

CREATE OR REPLACE FUNCTION percorrer_equipes() RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    registro_equipe RECORD;
BEGIN
    FOR registro_equipe IN
        SELECT
            e.nome,
            e.local
        FROM equipe e
    LOOP
        RAISE NOTICE
        '
        Equipe: %
        Local: % 
        ', registro_equipe.nome, registro_equipe.local;
    END LOOP;
END;
$$;
