-- Exercício 35 – Simulação de apostas

-- Crie uma função:

-- simular_valores(quantidade)

-- que utilize WHILE para gerar determinada quantidade de valores aleatórios.
-- Utilize:

-- random() => gera um número decimal pseudoaleatório maior ou igual a 0 e menor que 1.

CREATE OR REPLACE FUNCTION simular_valores(var_quantidade INTEGER) RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    var_contador INTEGER := 0;
    var_valor NUMERIC(10, 2);
BEGIN

    -- Tratando quantidade Nulas ou negativas
    IF var_quantidade IS NULL OR var_quantidade < 0 THEN
        RAISE EXCEPTION 'A quantidade deve ser maior ou igual a Zero.';
    END IF;

    WHILE var_contador < var_quantidade
    LOOP
        -- Gera um valor aleatório entre R$ 1.00 e R$ 1.000,00
        var_valor := ROUND((1 + RANDOM() * 999)::NUMERIC, 2);

        RAISE NOTICE 'Valor Gerado: R$ %', TO_CHAR(var_valor, 'FM999G999G990D00');

        var_contador := var_contador + 1;
    END LOOP;
END;
$$;

SELECT simular_valores(5);
