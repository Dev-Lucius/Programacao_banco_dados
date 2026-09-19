-- Crie uma procedure simular_apostas(quantidade) que gere apostas aleatórias utilizando a função propor_aposta().

/*
   Supondo que propor_aposta() seja uma função que retorna um registro
   com os dados necessários para criar uma aposta (usuário, jogo, valor, odd).
   Exemplo de assinatura:

   CREATE FUNCTION propor_aposta()
   RETURNS TABLE(usuario_id int, jogo_id int, valor money, odd real)
   ...
*/
CREATE OR REPLACE FUNCTION propor_aposta(
    p_usuario_id INTEGER,
    p_jogo_id INTEGER,
    p_valor NUMERIC,
    p_gols_da_casa INTEGER,
    p_gols_do_visitante INTEGER,
    p_odd REAL
)
RETURNS TABLE(
    var_aposta_id INTEGER,
    var_usuario_id INTEGER,
    var_jogo_id INTEGER,
    var_valor NUMERIC,
    var_gols_da_casa INTEGER,
    var_gols_do_visitante INTEGER,
    var_odd REAL,
    var_saldo_restante NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_saldo NUMERIC;
    v_aposta_id INTEGER;
BEGIN

    -- 1. Bloqueia o usuário para evitar
    -- duas apostas consumindo o mesmo saldo
    SELECT u.saldo::NUMERIC
    INTO v_saldo
    FROM usuario u
    WHERE u.id = p_usuario_id
    FOR UPDATE;

    -- 2. Verifica se o usuário existe
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Usuário % não encontrado', p_usuario_id;
    END IF;

    -- 3. Valida o valor da aposta
    IF p_valor <= 0 THEN
        RAISE EXCEPTION 'O valor da aposta deve ser maior que zero';
    END IF;

    -- 4. Valida os gols
    IF p_gols_da_casa < 0 OR p_gols_do_visitante < 0 THEN
        RAISE EXCEPTION 'A quantidade de gols não pode ser negativa';
    END IF;

    -- 5. Valida a odd
    IF p_odd <= 0 OR p_odd > 1 THEN
        RAISE EXCEPTION 'A odd deve ser maior que 0 e menor ou igual a 1';
    END IF;

    -- 6. Verifica se o jogo existe
    IF NOT EXISTS (
        SELECT 1
        FROM jogo
        WHERE id = p_jogo_id
    ) THEN
        RAISE EXCEPTION 'Jogo % não encontrado', p_jogo_id;
    END IF;

    -- 7. Verifica se o usuário possui saldo suficiente
    IF v_saldo < p_valor THEN
        RAISE EXCEPTION
            'Saldo insuficiente. Saldo disponível: %, valor da aposta: %',
            v_saldo,
            p_valor;
    END IF;

    -- 8. Registra a aposta
    INSERT INTO aposta (
        usuario_id,
        valor,
        jogo_id,
        gols_da_casa,
        gols_do_visitante,
        odd
    )
    VALUES (
        p_usuario_id,
        p_valor::MONEY,
        p_jogo_id,
        p_gols_da_casa,
        p_gols_do_visitante,
        p_odd
    )
    RETURNING id INTO v_aposta_id;

    -- 9. Desconta o valor do saldo
    UPDATE usuario
    SET saldo = saldo::NUMERIC - p_valor::NUMERIC
    WHERE id = p_usuario_id;

    -- 10. Retorna os dados da aposta
    RETURN QUERY
    SELECT
        v_aposta_id,
        p_usuario_id,
        p_jogo_id,
        p_valor,
        p_gols_da_casa,
        p_gols_do_visitante,
        p_odd,
        v_saldo::NUMERIC - p_valor::NUMERIC;
END;
$$;

CREATE OR REPLACE PROCEDURE simular_apostas(p_quantidade INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE
    i               INTEGER;
    v_criadas       INTEGER := 0;
    v_usuario_id    INTEGER;
    v_saldo         NUMERIC;
    v_jogo_id       INTEGER;
    v_valor         NUMERIC;
    v_gols_casa     INTEGER;
    v_gols_visit    INTEGER;
    v_odd           REAL;
BEGIN
    IF p_quantidade IS NULL OR p_quantidade <= 0 THEN
        RAISE EXCEPTION 'A quantidade deve ser maior que zero';
    END IF;

    FOR i IN 1..p_quantidade LOOP

        -- Usuário aleatório com saldo mínimo
        SELECT u.id, u.saldo::NUMERIC
        INTO v_usuario_id, v_saldo
        FROM usuario u
        WHERE u.saldo >= 1::MONEY
        ORDER BY random()
        LIMIT 1;

        IF NOT FOUND THEN
            RAISE NOTICE 'Nenhum usuário com saldo disponível (iteração %)', i;
            EXIT;
        END IF;

        -- Jogo aleatório
        SELECT j.id
        INTO v_jogo_id
        FROM jogo j
        ORDER BY random()
        LIMIT 1;

        IF NOT FOUND THEN
            RAISE NOTICE 'Nenhum jogo disponível (iteração %)', i;
            EXIT;
        END IF;

        -- Valor entre 1 e min(saldo, 100)
        v_valor := round((1 + random() * (LEAST(v_saldo, 100) - 1))::NUMERIC, 2);

        -- Placar aleatório de 0 a 5 gols
        v_gols_casa  := floor(random() * 6)::INTEGER;
        v_gols_visit := floor(random() * 6)::INTEGER;

        -- Odd aleatória compatível com a validação da propor_aposta (0 < odd <= 1)
        v_odd := GREATEST(0.01, round(random()::NUMERIC, 2))::REAL;

        -- A propor_aposta já valida, insere a aposta e debita o saldo
        BEGIN
            PERFORM propor_aposta(
                v_usuario_id, v_jogo_id, v_valor,
                v_gols_casa, v_gols_visit, v_odd
            );
            v_criadas := v_criadas + 1;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Aposta % ignorada: %', i, SQLERRM;
        END;

    END LOOP;

    RAISE NOTICE '% de % apostas simuladas com sucesso', v_criadas, p_quantidade;
END;
$$;

-- Teste
CALL simular_apostas(10);
