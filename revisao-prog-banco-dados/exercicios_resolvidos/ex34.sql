-- Exercício 34 – Contador

-- Crie uma função:
-- contar_apostas(usuario_id)

-- que percorra as apostas utilizando WHILE.

-- Uma forma didática de fazer isso é buscar o ID de cada aposta em ordem crescente e usar um contador para avançar pela lista!

CREATE OR REPLACE FUNCTION contar_apostas(
    var_usuario_id INTEGER
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    var_total_apostas INTEGER := 0;
    var_indice INTEGER := 0;
    var_id_aposta INTEGER;
    var_ids_apostas INTEGER[];
BEGIN
    -- Armazenando os IDs das apostas do usuário
    SELECT ARRAY(
        SELECT a.id
        FROM aposta a
        WHERE a.usuario_id = var_usuario_id
        ORDER BY a.id
    )
    INTO var_ids_apostas;

    -- Percorrendo as apostas com WHILE
    WHILE var_indice < COALESCE(ARRAY_LENGTH(var_ids_apostas, 1), 0)
    LOOP
        var_indice := var_indice + 1;

        var_id_aposta := var_ids_apostas[var_indice];

        var_total_apostas := var_total_apostas + 1;

        RAISE NOTICE 'Aposta encontrada: %', var_id_aposta;
    END LOOP;

    -- Retornando a quantidade de apostas
    RETURN var_total_apostas;
END;
$$;
