-- Exercício 44 – Divisão por zero

-- Crie uma função:
-- divisao(valor, quantidade)

-- que realize uma divisão.
-- Trate o caso de quantidade = 0 utilizando EXCEPTION.

-- NO_DATA_FOUND	|    Nenhum registro encontrado com SELECT INTO STRICT.
-- TOO_MANY_ROWS	|    Mais de um registro encontrado com SELECT INTO STRICT.
-- DIVISION_BY_ZERO	|    Tentativa de divisão por zero.

CREATE OR REPLACE FUNCTION divisao(var_valor NUMERIC, var_quantidade INTEGER) RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    var_resultado_divisao NUMERIC := 0;
BEGIN

    var_resultado_divisao := var_valor / var_quantidade;

    RETURN var_resultado_divisao;

    EXCEPTION
        WHEN DIVISION_BY_ZERO THEN
            RAISE NOTICE 'Erro: Impossível Dividir por zero';
            RETURN NULL;
END;
$$;
