-- Exercício 36 – LOOP com EXIT

-- Crie uma função que utilize:

-- LOOP
-- ...
-- EXIT WHEN ...
-- END LOOP;

-- para gerar números de 1 até 10.

-- Não utilize FOR ou WHILE.

CREATE OR REPLACE FUNCTION gerar_numeros() RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    var_contador INTEGER := 0;
    var_numeros INTEGER := 1;
BEGIN

    LOOP
        RAISE NOTICE '%', TO_CHAR(var_numeros, 'FM999G999G990D00');
        var_contador := var_contador + 1;
        var_numeros := var_numeros + 1;
        EXIT WHEN var_contador = 10;
    END LOOP;
END;
$$;

SELECT * FROM gerar_numeros();
