-- Exercício 29 – Percorrer usuários

-- Crie uma função que percorra todos os usuários utilizando:
-- FOR registro IN
--     SELECT ...
-- LOOP

-- e apresente cada usuário utilizando:
-- RAISE NOTICE

-- Formato:
-- Usuário: Igor | Saldo: R$ 1000,00
CREATE OR REPLACE FUNCTION percorrer_usuarios() RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    registro RECORD;
BEGIN
    FOR registro IN
        SELECT
            u.nome,
            u.saldo
        FROM usuario u
        ORDER BY u.id
    LOOP
        RAISE NOTICE 'Usuario: % | Saldo: %',
        registro.nome,
        registro.saldo;
    END LOOP; 
END;
$$;
