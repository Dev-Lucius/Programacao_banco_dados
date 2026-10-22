-- Exercício 30 – Percorrer apostas

-- Crie uma função que receba usuario_id e percorra todas as suas apostas utilizando FOR.

-- Para cada aposta, apresente:

-- Aposta: 10
-- Valor: R$ 100,00
-- Odd: 2.50

CREATE OR REPLACE FUNCTION percorrer_aposta(var_usuario_id INTEGER) RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    registro_aposta RECORD;
BEGIN

    FOR registro_aposta IN
        SELECT
            u.nome,
            a.id,
            a.valor,
            a.odd
        FROM aposta a
        LEFT JOIN usuario u
            ON u.id = a.usuario_id
        WHERE u.id = var_usuario_id
    LOOP
        RAISE NOTICE 
        'Usuario: % | Aposta: % | Valor: % | nOdd: %',
        registro_aposta.nome, registro_aposta.id, registro_aposta.valor, registro_aposta.odd;
    END LOOP; 
END;
$$;
