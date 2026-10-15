CREATE TABLE IF NOT EXISTS usuario (
    id     SERIAL PRIMARY KEY,
    nome   VARCHAR(100) NOT NULL,
    email  VARCHAR(150),
    saldo  NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (saldo >= 0),
    ativo  BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS equipe (
    id     SERIAL PRIMARY KEY,
    nome   VARCHAR(100) NOT NULL,
    local  VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS jogo (
    id             SERIAL PRIMARY KEY,
    id_casa        INT NOT NULL REFERENCES equipe(id),
    id_visitante   INT NOT NULL REFERENCES equipe(id),
    data_jogo      TIMESTAMP NOT NULL DEFAULT now(),
    gols_casa      INT,
    gols_visitante INT,
    encerrado      BOOLEAN NOT NULL DEFAULT FALSE,
    CHECK (id_casa <> id_visitante)
);

CREATE TABLE IF NOT EXISTS aposta (
    id          SERIAL PRIMARY KEY,
    id_usuario  INT NOT NULL REFERENCES usuario(id),
    id_jogo     INT NOT NULL REFERENCES jogo(id),
    valor       NUMERIC(12,2) NOT NULL CHECK (valor > 0),
    odd         NUMERIC(6,2)  NOT NULL CHECK (odd > 0),
    data_aposta TIMESTAMP NOT NULL DEFAULT now(),
    gols_da_casa INTEGER,
    gols_do_visitante INTEGER
);
INSERT INTO aposta(id_usuario, id_jogo, valor, odd, gols_da_casa, gols_do_visitante) VALUES
(1, 1, 100, 0.25, 2, 1), -- Aposta do Igor de que o Time da Casa Ganhou de 2 x 1 do time visitante
(2, 6, 200, 0.15, 1, 1); -- Aposta do Igor de que o Time da Casa Empatou com o time visitante no placar de 1 x 1


-- Registro de operações financeiras (extrato, auditoria de lotes etc.)
CREATE TABLE IF NOT EXISTS transacao (
    id             SERIAL PRIMARY KEY,
    id_usuario     INT NOT NULL REFERENCES usuario(id),
    tipo           VARCHAR(30) NOT NULL,
    valor          NUMERIC(12,2) NOT NULL,
    descricao      TEXT,
    data_transacao TIMESTAMP NOT NULL DEFAULT now()
);

-- Inserts
INSERT INTO usuario (nome, email, saldo, ativo) VALUES
    ('Igor',   'igor@exemplo.com',   1000.00, TRUE),    -- id 1
    ('Maria',  'maria@exemplo.com',  1500.00, TRUE),    -- id 2
    ('Joao',   'joao@exemplo.com',     50.00, TRUE),    -- id 3
    ('Ana',    'ana@exemplo.com',     300.00, FALSE),   -- id 4 (inativa, com saldo)
    ('Carlos', 'carlos@exemplo.com',    0.00, TRUE);    -- id 5 (sem saldo)

INSERT INTO equipe (nome, local) VALUES
    ('SAO PAULO DE RG', 'Rio Grande'),   -- id 1
    ('RIO GRANDE',      'Rio Grande'),   -- id 2
    ('PELOTAS',         'Pelotas'),      -- id 3
    ('BRASIL',          'Pelotas');      -- id 4

-- Jogos em aberto (ids 1 a 4)
INSERT INTO jogo (id_casa, id_visitante, data_jogo) VALUES
    (1, 2, now() + interval '1 day'),    -- id 1: SAO PAULO DE RG x RIO GRANDE
    (3, 4, now() + interval '2 days'),   -- id 2: PELOTAS x BRASIL
    (2, 3, now() + interval '3 days'),   -- id 3: RIO GRANDE x PELOTAS
    (1, 4, now() + interval '4 days');   -- id 4: BRASIL x PELOTAS

-- Um jogo já encerrado (id 5), para a classificação e a artilharia
INSERT INTO jogo (id_casa, id_visitante, data_jogo, gols_casa, gols_visitante, encerrado) VALUES
    (4, 1, now() - interval '1 day', 1, 0, TRUE),   -- id 5: BRASIL 1 x 0 SAO PAULO DE RG
    (4, 3, now() - interval '1 day', 2, 1, TRUE);   -- id 6: SAO PAULO DE RG 2 x 1 SAO PAULO DE RG

-- Alguns registros no extrato, para o Desafio 2
INSERT INTO transacao (id_usuario, tipo, valor, descricao) VALUES
    (1, 'DEPOSITO', 1000.00, 'Saldo inicial'),
    (2, 'DEPOSITO', 1500.00, 'Saldo inicial'),
    (3, 'DEPOSITO',   50.00, 'Saldo inicial'),
    (4, 'DEPOSITO',  300.00, 'Saldo inicial');


-- Resolução

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