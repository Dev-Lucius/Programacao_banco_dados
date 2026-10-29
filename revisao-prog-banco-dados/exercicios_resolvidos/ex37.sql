-- Exercício 37 – Encontrar aposta

-- Percorra as apostas de um usuário utilizando LOOP.

-- Interrompa o processamento com:

-- EXIT WHEN ...

-- quando encontrar uma aposta superior a R$ 500.

CREATE OR REPLACE FUNCTION encontrar_apostas_por_valor() RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    registro_aposta_percorrida RECORD;
BEGIN

    FOR registro_aposta_percorrida IN
        SELECT
            u.nome,
            a.id,
            a.valor,
            a.odd
        FROM aposta a
        LEFT JOIN usuario u
            ON u.id = a.usuario_id
        WHERE a.valor::NUMERIC > 500
    LOOP
        RAISE NOTICE
        'Usuario: % | Aposta: % | Valor: % | Odd: %',
        registro_aposta_percorrida.nome, registro_aposta_percorrida.id, registro_aposta_percorrida.valor, registro_aposta_percorrida.odd;
    END LOOP;
END;
$$;

-- Versão Generica
CREATE OR REPLACE FUNCTION encontrar_apostas_por_valor_qualquer(var_valor NUMERIC) RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    registro_aposta_percorrida RECORD;
BEGIN

    IF var_valor IS NULL OR var_valor < 0 THEN
        RAISE EXCEPTION 'O Valor deve ser maior ou igual a Zero.';
    END IF;

    FOR registro_aposta_percorrida IN
        SELECT
            u.nome,
            a.id,
            a.valor,
            a.odd
        FROM aposta a
        LEFT JOIN usuario u
            ON u.id = a.usuario_id
        WHERE a.valor::NUMERIC >= var_valor
    LOOP
        RAISE NOTICE
        'Usuario: % | Aposta: % | Valor: % | Odd: %',
        registro_aposta_percorrida.nome, registro_aposta_percorrida.id, registro_aposta_percorrida.valor, registro_aposta_percorrida.odd;
    END LOOP;
END;
$$;

SELECT * FROM encontrar_apostas_por_valor();
