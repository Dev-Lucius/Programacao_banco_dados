-- Exercício 41 – Alterar odd

-- Crie:

-- alterar_odd(aposta_id, nova_odd)

-- que altere a odd de uma aposta.

-- Impeça valores menores ou iguais a zero.

CREATE OR REPLACE PROCEDURE alterar_odd(aposta_id INTEGER, nova_odd REAL)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validando a Existência de uma Aposta
    PERFORM 1 FROM aposta a WHERE a.id = aposta_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Aposta % Não existe !', aposta_id;
    END IF;

    -- Validando se o valor da nova_odd é válida
    IF nova_odd IS NULL THEN
        RAISE EXCEPTION 'Valor % é Inválido para a Nova odd', nova_odd;
    END IF;

    IF nova_odd <= 0 AND nova_odd >= 1 THEN
        RAISE EXCEPTION 'Valor % é Inválido para a Nova odd', nova_odd;
    END IF;

    -- Fazendo a Alteração
    UPDATE aposta a
    SET odd = nova_odd
    WHERE a.id = aposta_id;

    RAISE NOTICE 'Odd da Aposta % foi alterada com sucesso para % ', aposta_id, nova_odd; 
END;
$$;
