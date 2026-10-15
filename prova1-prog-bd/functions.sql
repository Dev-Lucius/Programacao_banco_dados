-- 1. Relatório de Acertos por Usuário em um Jogo

-- Função Auxiliar -> Apostas Certas
CREATE OR REPLACE FUNCTION apostas_certas(var_aposta_id INTEGER, var_jogo_id INTEGER) RETURNS TABLE(
    gols_csa INTEGER,
    gols_visit INTEGER,
    gols_casa_apost INTEGER,
    gols_visit_apost INTEGER,
    check_de_apostas BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
    aposta_check BOOLEAN := FALSE;
BEGIN
    -- Selecionado a Aposta Comparando com o Jogo
    RETURN QUERY
    SELECT
        a.gols_da_casa,
        a.gols_do_visitante,
        j.gols_casa,
        j.gols_visitante,
        aposta_check
    FROM aposta a
    LEFT JOIN jogo j
        ON j.id = a.id_jogo
    WHERE (a.id = var_aposta_id) AND (j.id = var_jogo_id);

    IF (gols_csa = gols_casa_apost) OR (gols_visit = gols_visit_apost) THEN
        aposta_check := TRUE;
    END IF;

END;
$$;
-- SELECT  apostas_certas(2, 6);

CREATE OR REPLACE FUNCTION relatorio_acertos_jogo(var_jogo_id INTEGER) RETURNS TABLE(
    usuario_id INTEGER,
    nome_usuario TEXT,
    acertos_exatos BIGINT,
    acertos_resultados BIGINT,
    total_apostas BIGINT
)
LANGUAGE plpgsql
DECLARE
    acertos_exts BIGINT := 0;
    acertos_resultados BIGINT := 0;
    aposta_check BOOLEAN := FALSE;
    apostas_tt BIGINT;
AS $$
BEGIN

    SELECT
        a.gols_da_casa,
        a.gols_do_visitante,
        j.gols_casa,
        j.gols_visitante,
        aposta_check
    FROM aposta a
    LEFT JOIN jogo j
        ON j.id = a.id_jogo;

    IF (gols_csa = gols_casa_apost) OR (gols_visit = gols_visit_apost) THEN
        aposta_check := TRUE;
        COUNT(acertos_exts);
        COUNT(acertos_resultados);
    END IF;

    RETURN QUERY
    SELECT
        u.id,
        u.nome,
        acertos_exts,
        acertos_resultados,
        apostas_tt
    FROM usuario u
END;
$$;

-- 2. Cancelamento em Lote das Apostas de um Usuário para um Jogo
CREATE OR REPLACE PROCEDURE cancelar_aposta(p_aposta_id INT)
LANGUAGE plpgsql AS $$
DECLARE
    v_usuario_id INT;
    v_valor      NUMERIC;
    v_processada BOOLEAN;
    v_encerrado  BOOLEAN;
BEGIN
    -- 1 e 2. localizar a aposta e descobrir o usuário
    SELECT a.id_usuario, a.valor, a.processada, j.encerrado
      INTO v_usuario_id, v_valor, v_processada, v_encerrado
      FROM aposta a
      JOIN jogo j ON j.id = a.id_jogo
     WHERE a.id = p_aposta_id
       FOR UPDATE OF a;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Aposta % não existe', p_aposta_id;
    END IF;

    IF v_processada OR v_encerrado THEN
        RAISE EXCEPTION 'A aposta % não pode ser cancelada: o jogo já foi encerrado', p_aposta_id;
    END IF;

    -- 3. devolver o valor ao usuário
    UPDATE usuario SET saldo = saldo + v_valor WHERE id = v_usuario_id;

    INSERT INTO transacao (id_usuario, tipo, valor, descricao)
    VALUES (v_usuario_id, 'ESTORNO', v_valor, 'Cancelamento da aposta ' || p_aposta_id);

    -- 4. remover a aposta
    DELETE FROM aposta WHERE id = p_aposta_id;

    RAISE NOTICE 'Aposta % cancelada; % devolvidos ao usuário %',
                 p_aposta_id, fmt_moeda(v_valor), v_usuario_id;
END;
$$;

-- 3. Auditoria de Apostas Pendentes
CREATE OR REPLACE FUNCTION processar_apostas() RETURNS TEXT
LANGUAGE plpgsql 
AS $$
DECLARE
    registro        RECORD;
    v_premio        NUMERIC(12,2);
    v_processadas   INT := 0;
    v_vencedoras    INT := 0;
    v_total_premios NUMERIC := 0;
BEGIN
    FOR registro IN
        SELECT a.id, a.id_usuario, a.valor, a.odd, a.palpite,
               j.id AS id_jogo, j.gols_casa, j.gols_visitante
          FROM aposta a
          JOIN jogo j ON j.id = a.id_jogo
         WHERE j.encerrado
           AND j.gols_casa IS NOT NULL
           AND j.gols_visitante IS NOT NULL
           AND NOT a.processada
         ORDER BY a.id
    LOOP
        -- 1. identificar os vencedores
        IF registro.palpite = resultado_partida(registro.gols_casa, registro.gols_visitante) THEN
            -- 2. calcular o prêmio
            v_premio := ROUND(registro.valor * registro.odd, 2);

            -- 3. creditar o usuário
            UPDATE usuario SET saldo = saldo + v_premio WHERE id = registro.id_usuario;

            -- 4. registrar o pagamento
            INSERT INTO transacao (id_usuario, tipo, valor, descricao)
            VALUES (registro.id_usuario, 'PREMIO', v_premio,
                    'Prêmio da aposta ' || registro.id || ' (jogo ' || registro.id_jogo || ')');

            v_vencedoras    := v_vencedoras + 1;
            v_total_premios := v_total_premios + v_premio;
        END IF;

        -- 5. marcar a aposta como processada (vencedora ou não)
        UPDATE aposta SET processada = TRUE WHERE id = registro.id;

        v_processadas := v_processadas + 1;

        IF v_processadas % 100 = 0 THEN
            COMMIT;
        END IF;
    END LOOP;

    COMMIT;
    RETURN '% aposta(s) processada(s) | % vencedora(s) | prêmios pagos: %',
                 v_processadas, v_vencedoras, fmt_moeda(v_total_premios);
END;
$$;