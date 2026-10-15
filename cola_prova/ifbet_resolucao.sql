-- =====================================================================
--  IFBET – Stored Procedures e Functions (PostgreSQL / PL/pgSQL)
--  Resolução dos Exercícios 19 a 57 + Desafios 1 a 9
--
--  Requisitos : PostgreSQL 11 ou superior (PROCEDURE, CALL e COMMIT
--               dentro de procedures).
--  Execução   : psql -U postgres -d ifbet -f ifbet_resolucao.sql
--
--  Organização do arquivo
--    0. Esquema assumido (ajuste os nomes se o seu banco for diferente)
--    1. Funções de apoio (equivalentes aos Exercícios 1–18 usados adiante)
--    2. Exercícios 19–57
--    3. Desafios 1–9
--
--  Observações gerais
--    * Parâmetros usam o prefixo p_ e variáveis locais usam v_ para não
--      colidir com nomes de colunas.
--    * Em funções RETURNS TABLE as colunas de saída também são variáveis
--      PL/pgSQL; por isso todas as colunas das consultas são qualificadas
--      com alias (a.valor, u.nome ...).
--    * Procedures que usam COMMIT devem ser chamadas com CALL fora de um
--      bloco de transação explícito (BEGIN ... COMMIT).
-- =====================================================================


-- =====================================================================
-- 0. ESQUEMA ASSUMIDO
--    A lista não traz o DDL da base IFBET. Foi assumido o esquema abaixo.
--    CREATE TABLE IF NOT EXISTS não altera tabelas já existentes; se os
--    seus nomes de tabelas/colunas forem outros, basta adaptá-los.
--
--    transacao.valor é "com sinal": créditos positivos, débitos negativos.
--    aposta.palpite: 'C' = vitória da casa, 'E' = empate, 'V' = visitante.
-- =====================================================================

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
    data_aposta TIMESTAMP NOT NULL DEFAULT now()
);

-- Colunas extras usadas pelos exercícios de integração
ALTER TABLE aposta ADD COLUMN IF NOT EXISTS palpite    CHAR(1) NOT NULL DEFAULT 'C';
ALTER TABLE aposta ADD COLUMN IF NOT EXISTS processada BOOLEAN NOT NULL DEFAULT FALSE;

-- Registro de operações financeiras (extrato, auditoria de lotes etc.)
CREATE TABLE IF NOT EXISTS transacao (
    id             SERIAL PRIMARY KEY,
    id_usuario     INT NOT NULL REFERENCES usuario(id),
    tipo           VARCHAR(30) NOT NULL,
    valor          NUMERIC(12,2) NOT NULL,
    descricao      TEXT,
    data_transacao TIMESTAMP NOT NULL DEFAULT now()
);


-- =====================================================================
-- 1. FUNÇÕES DE APOIO
--    Versões mínimas das funções dos Exercícios 1–18 que são reutilizadas
--    abaixo. Se você já as criou, pode ignorar esta seção (se o tipo de
--    retorno for diferente, use DROP FUNCTION antes de recriar).
-- =====================================================================

-- Formata valores como moeda brasileira: 1500 -> R$ 1.500,00
CREATE OR REPLACE FUNCTION fmt_moeda(p_valor NUMERIC)
RETURNS TEXT
LANGUAGE sql IMMUTABLE AS $$
    SELECT 'R$ ' || translate(to_char(p_valor, 'FM999,999,999,990.00'), ',.', '.,');
$$;

CREATE OR REPLACE FUNCTION usuario_existe(p_usuario_id INT)
RETURNS BOOLEAN
LANGUAGE sql STABLE AS $$
    SELECT EXISTS (SELECT 1 FROM usuario WHERE id = p_usuario_id);
$$;

CREATE OR REPLACE FUNCTION equipe_existe(p_equipe_id INT)
RETURNS BOOLEAN
LANGUAGE sql STABLE AS $$
    SELECT EXISTS (SELECT 1 FROM equipe WHERE id = p_equipe_id);
$$;

CREATE OR REPLACE FUNCTION jogo_existe(p_jogo_id INT)
RETURNS BOOLEAN
LANGUAGE sql STABLE AS $$
    SELECT EXISTS (SELECT 1 FROM jogo WHERE id = p_jogo_id);
$$;

CREATE OR REPLACE FUNCTION saldo_suficiente(p_usuario_id INT, p_valor NUMERIC)
RETURNS BOOLEAN
LANGUAGE sql STABLE AS $$
    SELECT COALESCE((SELECT saldo >= p_valor FROM usuario WHERE id = p_usuario_id), FALSE);
$$;

CREATE OR REPLACE FUNCTION obter_saldo(p_usuario_id INT)
RETURNS NUMERIC
LANGUAGE plpgsql AS $$
DECLARE
    v_saldo NUMERIC;
BEGIN
    SELECT u.saldo INTO v_saldo FROM usuario u WHERE u.id = p_usuario_id;
    RETURN v_saldo;
END;
$$;

CREATE OR REPLACE FUNCTION nome_usuario(p_usuario_id INT)
RETURNS TEXT
LANGUAGE plpgsql AS $$
DECLARE
    v_nome TEXT;
BEGIN
    SELECT u.nome INTO v_nome FROM usuario u WHERE u.id = p_usuario_id;
    RETURN v_nome;
END;
$$;

CREATE OR REPLACE FUNCTION nome_jogo(p_jogo_id INT)
RETURNS TEXT
LANGUAGE plpgsql AS $$
DECLARE
    v_texto TEXT;
BEGIN
    SELECT ec.nome || ' x ' || ev.nome
      INTO v_texto
      FROM jogo j
      JOIN equipe ec ON ec.id = j.id_casa
      JOIN equipe ev ON ev.id = j.id_visitante
     WHERE j.id = p_jogo_id;
    RETURN v_texto;
END;
$$;

CREATE OR REPLACE FUNCTION quantidade_apostas(p_usuario_id INT)
RETURNS BIGINT
LANGUAGE plpgsql AS $$
DECLARE
    v_qtd BIGINT;
BEGIN
    SELECT COUNT(a.id) INTO v_qtd FROM aposta a WHERE a.id_usuario = p_usuario_id;
    RETURN v_qtd;
END;
$$;

CREATE OR REPLACE FUNCTION valor_total_apostado(p_usuario_id INT)
RETURNS NUMERIC
LANGUAGE plpgsql AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(a.valor), 0) INTO v_total FROM aposta a WHERE a.id_usuario = p_usuario_id;
    RETURN v_total;
END;
$$;

-- Resultado de uma partida: C (casa), E (empate) ou V (visitante)
CREATE OR REPLACE FUNCTION resultado_partida(p_gols_casa INT, p_gols_visitante INT)
RETURNS TEXT
LANGUAGE sql IMMUTABLE AS $$
    SELECT CASE
               WHEN p_gols_casa > p_gols_visitante THEN 'C'
               WHEN p_gols_casa < p_gols_visitante THEN 'V'
               ELSE 'E'
           END;
$$;

-- Cada partida encerrada vista sob a ótica de cada equipe
-- (usada pelos Exercícios 49, 50 e Desafio 4)
CREATE OR REPLACE VIEW vw_partidas_equipe AS
SELECT j.id             AS id_jogo,
       j.id_casa        AS id_equipe,
       j.id_visitante   AS id_adversario,
       j.gols_casa      AS gols_pro,
       j.gols_visitante AS gols_contra
  FROM jogo j
 WHERE j.encerrado AND j.gols_casa IS NOT NULL AND j.gols_visitante IS NOT NULL
UNION ALL
SELECT j.id,
       j.id_visitante,
       j.id_casa,
       j.gols_visitante,
       j.gols_casa
  FROM jogo j
 WHERE j.encerrado AND j.gols_casa IS NOT NULL AND j.gols_visitante IS NOT NULL;


-- =====================================================================
-- 2. EXERCÍCIOS
-- =====================================================================

-- =====================================================================
-- PARTE 4 – Functions com retorno de tabela
-- =====================================================================

-- Exercício 19 – Apostas do usuário
CREATE OR REPLACE FUNCTION listar_apostas_usuario(p_usuario_id INT)
RETURNS TABLE (id_aposta INT, valor NUMERIC, odd NUMERIC)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT a.id, a.valor, a.odd
      FROM aposta a
     WHERE a.id_usuario = p_usuario_id
     ORDER BY a.id;
END;
$$;
-- SELECT * FROM listar_apostas_usuario(1);


-- Exercício 20 – Jogos de uma equipe
CREATE OR REPLACE FUNCTION jogos_equipe(p_equipe_id INT)
RETURNS TABLE (id_jogo INT, adversario TEXT, data_jogo TIMESTAMP, resultado TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT j.id,
           (CASE WHEN j.id_casa = p_equipe_id THEN ev.nome ELSE ec.nome END)::TEXT,
           j.data_jogo::TIMESTAMP,
           CASE
               WHEN j.encerrado THEN j.gols_casa::TEXT || ' x ' || j.gols_visitante::TEXT
               ELSE 'A REALIZAR'
           END
      FROM jogo j
      JOIN equipe ec ON ec.id = j.id_casa
      JOIN equipe ev ON ev.id = j.id_visitante
     WHERE j.id_casa = p_equipe_id
        OR j.id_visitante = p_equipe_id
     ORDER BY j.data_jogo, j.id;
END;
$$;
-- SELECT * FROM jogos_equipe(1);


-- Exercício 21 – Jogos futuros (ainda não encerrados)
CREATE OR REPLACE FUNCTION jogos_futuros()
RETURNS TABLE (id_jogo INT, equipe_casa TEXT, equipe_visitante TEXT, data_jogo TIMESTAMP)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT j.id, ec.nome::TEXT, ev.nome::TEXT, j.data_jogo::TIMESTAMP
      FROM jogo j
      JOIN equipe ec ON ec.id = j.id_casa
      JOIN equipe ev ON ev.id = j.id_visitante
     WHERE NOT j.encerrado
     ORDER BY j.data_jogo, j.id;
END;
$$;
-- SELECT * FROM jogos_futuros();


-- Exercício 22 – Jogos encerrados
CREATE OR REPLACE FUNCTION jogos_encerrados()
RETURNS TABLE (id_jogo INT, equipe_casa TEXT, equipe_visitante TEXT,
               gols_casa INT, gols_visitante INT, data_jogo TIMESTAMP)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT j.id, ec.nome::TEXT, ev.nome::TEXT,
           j.gols_casa, j.gols_visitante, j.data_jogo::TIMESTAMP
      FROM jogo j
      JOIN equipe ec ON ec.id = j.id_casa
      JOIN equipe ev ON ev.id = j.id_visitante
     WHERE j.encerrado
     ORDER BY j.data_jogo, j.id;
END;
$$;
-- SELECT * FROM jogos_encerrados();


-- Exercício 23 – Apostas acima de determinado valor
CREATE OR REPLACE FUNCTION apostas_acima(p_valor NUMERIC)
RETURNS TABLE (id_aposta INT, usuario TEXT, id_jogo INT, valor NUMERIC, odd NUMERIC)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT a.id, u.nome::TEXT, a.id_jogo, a.valor, a.odd
      FROM aposta a
      JOIN usuario u ON u.id = a.id_usuario
     WHERE a.valor > p_valor
     ORDER BY a.valor DESC, a.id;
END;
$$;
-- SELECT * FROM apostas_acima(100);


-- Exercício 24 – Usuários com saldo mínimo
CREATE OR REPLACE FUNCTION usuarios_com_saldo_minimo(p_valor NUMERIC)
RETURNS TABLE (id_usuario INT, nome TEXT, saldo NUMERIC)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT u.id, u.nome::TEXT, u.saldo
      FROM usuario u
     WHERE u.saldo >= p_valor
     ORDER BY u.saldo DESC, u.nome;
END;
$$;
-- SELECT * FROM usuarios_com_saldo_minimo(500);


-- =====================================================================
-- PARTE 5 – RETURN QUERY
-- =====================================================================

-- Exercício 25 – Ranking de apostadores
CREATE OR REPLACE FUNCTION ranking_apostadores()
RETURNS TABLE (usuario TEXT, apostas BIGINT, total_apostado NUMERIC)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT u.nome::TEXT,
           COUNT(a.id),
           SUM(a.valor)
      FROM usuario u
      JOIN aposta a ON a.id_usuario = u.id
     GROUP BY u.id, u.nome
     ORDER BY 3 DESC, 1;
END;
$$;
-- SELECT * FROM ranking_apostadores();


-- Exercício 26 – Ranking de equipes (quantidade de jogos)
CREATE OR REPLACE FUNCTION ranking_equipes()
RETURNS TABLE (equipe TEXT, jogos BIGINT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT eq.nome::TEXT,
           COUNT(j.id)
      FROM equipe eq
      LEFT JOIN jogo j ON eq.id IN (j.id_casa, j.id_visitante)
     GROUP BY eq.id, eq.nome
     ORDER BY 2 DESC, 1;
END;
$$;
-- SELECT * FROM ranking_equipes();


-- Exercício 27 – Usuários sem apostas (LEFT JOIN)
CREATE OR REPLACE FUNCTION usuarios_sem_apostas()
RETURNS TABLE (id_usuario INT, nome TEXT, saldo NUMERIC)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT u.id, u.nome::TEXT, u.saldo
      FROM usuario u
      LEFT JOIN aposta a ON a.id_usuario = u.id
     WHERE a.id IS NULL
     ORDER BY u.nome;
END;
$$;
-- SELECT * FROM usuarios_sem_apostas();


-- Exercício 28 – Usuários com apostas
CREATE OR REPLACE FUNCTION usuarios_com_apostas()
RETURNS TABLE (id_usuario INT, nome TEXT, quantidade_apostas BIGINT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT u.id, u.nome::TEXT, COUNT(a.id)
      FROM usuario u
      JOIN aposta a ON a.id_usuario = u.id
     GROUP BY u.id, u.nome
     ORDER BY u.nome;
END;
$$;
-- SELECT * FROM usuarios_com_apostas();


-- =====================================================================
-- PARTE 6 – Loops
-- =====================================================================

-- Exercício 29 – Percorrer usuários
CREATE OR REPLACE FUNCTION percorrer_usuarios()
RETURNS VOID
LANGUAGE plpgsql AS $$
DECLARE
    registro RECORD;
BEGIN
    FOR registro IN
        SELECT u.nome, u.saldo
          FROM usuario u
         ORDER BY u.id
    LOOP
        RAISE NOTICE 'Usuário: % | Saldo: %', registro.nome, fmt_moeda(registro.saldo);
    END LOOP;
END;
$$;
-- SELECT percorrer_usuarios();


-- Exercício 30 – Percorrer apostas de um usuário
CREATE OR REPLACE FUNCTION percorrer_apostas(p_usuario_id INT)
RETURNS VOID
LANGUAGE plpgsql AS $$
DECLARE
    registro RECORD;
BEGIN
    FOR registro IN
        SELECT a.id, a.valor, a.odd
          FROM aposta a
         WHERE a.id_usuario = p_usuario_id
         ORDER BY a.id
    LOOP
        RAISE NOTICE 'Aposta: %', registro.id;
        RAISE NOTICE 'Valor: %', fmt_moeda(registro.valor);
        RAISE NOTICE 'Odd: %', to_char(registro.odd, 'FM990.00');
    END LOOP;
END;
$$;
-- SELECT percorrer_apostas(1);


-- Exercício 31 – Percorrer equipes
CREATE OR REPLACE FUNCTION percorrer_equipes()
RETURNS VOID
LANGUAGE plpgsql AS $$
DECLARE
    registro RECORD;
BEGIN
    FOR registro IN
        SELECT eq.nome, eq.local
          FROM equipe eq
         ORDER BY eq.id
    LOOP
        RAISE NOTICE 'Equipe: %', registro.nome;
        RAISE NOTICE 'Local: %', registro.local;
    END LOOP;
END;
$$;
-- SELECT percorrer_equipes();


-- Exercício 32 – Somatório utilizando LOOP (sem SUM)
CREATE OR REPLACE FUNCTION total_apostado_loop(p_usuario_id INT)
RETURNS NUMERIC
LANGUAGE plpgsql AS $$
DECLARE
    registro RECORD;
    v_total  NUMERIC := 0;
BEGIN
    FOR registro IN
        SELECT a.valor FROM aposta a WHERE a.id_usuario = p_usuario_id
    LOOP
        v_total := v_total + registro.valor;
    END LOOP;

    RETURN v_total;
END;
$$;
-- SELECT total_apostado_loop(1);


-- Exercício 33 – Contagem utilizando LOOP (sem COUNT)
CREATE OR REPLACE FUNCTION contar_apostas_loop(p_usuario_id INT)
RETURNS INT
LANGUAGE plpgsql AS $$
DECLARE
    registro RECORD;
    v_qtd    INT := 0;
BEGIN
    FOR registro IN
        SELECT a.id FROM aposta a WHERE a.id_usuario = p_usuario_id
    LOOP
        v_qtd := v_qtd + 1;
    END LOOP;

    RETURN v_qtd;
END;
$$;
-- SELECT contar_apostas_loop(1);


-- =====================================================================
-- PARTE 7 – WHILE e LOOP
-- =====================================================================

-- Exercício 34 – Contador com WHILE
-- O WHILE precisa de uma condição; aqui ela é FOUND, atualizado a cada
-- FETCH de um cursor explícito sobre as apostas do usuário.
CREATE OR REPLACE FUNCTION contar_apostas(p_usuario_id INT)
RETURNS INT
LANGUAGE plpgsql AS $$
DECLARE
    c_apostas CURSOR FOR
        SELECT a.id FROM aposta a WHERE a.id_usuario = p_usuario_id;
    v_id  INT;
    v_qtd INT := 0;
BEGIN
    OPEN c_apostas;
    FETCH c_apostas INTO v_id;

    WHILE FOUND LOOP
        v_qtd := v_qtd + 1;
        FETCH c_apostas INTO v_id;
    END LOOP;

    CLOSE c_apostas;
    RETURN v_qtd;
END;
$$;
-- SELECT contar_apostas(1);


-- Exercício 35 – Simulação de valores aleatórios com WHILE
CREATE OR REPLACE FUNCTION simular_valores(p_quantidade INT)
RETURNS SETOF NUMERIC
LANGUAGE plpgsql AS $$
DECLARE
    v_i     INT := 0;
    v_valor NUMERIC;
BEGIN
    WHILE v_i < p_quantidade LOOP
        v_valor := ROUND((10 + random() * 490)::NUMERIC, 2);   -- entre 10 e 500
        RETURN NEXT v_valor;
        v_i := v_i + 1;
    END LOOP;
    RETURN;
END;
$$;
-- SELECT * FROM simular_valores(5);


-- Exercício 36 – LOOP com EXIT (números de 1 a 10)
CREATE OR REPLACE FUNCTION gerar_1_a_10()
RETURNS SETOF INT
LANGUAGE plpgsql AS $$
DECLARE
    v_i INT := 1;
BEGIN
    LOOP
        RETURN NEXT v_i;
        v_i := v_i + 1;
        EXIT WHEN v_i > 10;
    END LOOP;
    RETURN;
END;
$$;
-- SELECT * FROM gerar_1_a_10();


-- Exercício 37 – Encontrar a primeira aposta acima de R$ 500
-- Retorna o ID da aposta encontrada (ou NULL se não houver).
CREATE OR REPLACE FUNCTION encontrar_aposta_alta(p_usuario_id INT, p_limite NUMERIC DEFAULT 500)
RETURNS INT
LANGUAGE plpgsql AS $$
DECLARE
    c_apostas CURSOR FOR
        SELECT a.id, a.valor
          FROM aposta a
         WHERE a.id_usuario = p_usuario_id
         ORDER BY a.id;
    v_id        INT;
    v_valor     NUMERIC;
    v_resultado INT := NULL;
BEGIN
    OPEN c_apostas;

    LOOP
        FETCH c_apostas INTO v_id, v_valor;
        EXIT WHEN NOT FOUND;               -- acabaram as apostas

        IF v_valor > p_limite THEN
            v_resultado := v_id;
        END IF;

        EXIT WHEN v_resultado IS NOT NULL; -- encontrou: interrompe o processamento
    END LOOP;

    CLOSE c_apostas;

    IF v_resultado IS NULL THEN
        RAISE NOTICE 'Nenhuma aposta acima de % para o usuário %', fmt_moeda(p_limite), p_usuario_id;
    ELSE
        RAISE NOTICE 'Aposta encontrada: %', v_resultado;
    END IF;

    RETURN v_resultado;
END;
$$;
-- SELECT encontrar_aposta_alta(1);


-- =====================================================================
-- PARTE 8 – Procedures
--   Todas registram a operação em "transacao" (valor com sinal) para
--   alimentar o extrato do Desafio 2.
-- =====================================================================

-- Exercício 38 – Depósito com validação
CREATE OR REPLACE PROCEDURE depositar(p_usuario_id INT, p_valor NUMERIC)
LANGUAGE plpgsql AS $$
BEGIN
    IF p_valor IS NULL OR p_valor <= 0 THEN
        RAISE EXCEPTION 'O valor do depósito deve ser positivo (recebido: %)', p_valor;
    END IF;

    IF NOT usuario_existe(p_usuario_id) THEN
        RAISE EXCEPTION 'Usuário % não existe', p_usuario_id;
    END IF;

    UPDATE usuario SET saldo = saldo + p_valor WHERE id = p_usuario_id;

    INSERT INTO transacao (id_usuario, tipo, valor, descricao)
    VALUES (p_usuario_id, 'DEPOSITO', p_valor, 'Depósito em conta');

    RAISE NOTICE 'Depósito de % realizado. Novo saldo: %',
                 fmt_moeda(p_valor), fmt_moeda(obter_saldo(p_usuario_id));
END;
$$;
-- CALL depositar(1, 500);


-- Exercício 39 – Saque com validação
CREATE OR REPLACE PROCEDURE sacar(p_usuario_id INT, p_valor NUMERIC)
LANGUAGE plpgsql AS $$
DECLARE
    v_saldo NUMERIC;
BEGIN
    -- FOR UPDATE trava a linha para evitar dois saques simultâneos
    SELECT u.saldo INTO v_saldo
      FROM usuario u
     WHERE u.id = p_usuario_id
       FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Usuário % não existe', p_usuario_id;
    END IF;

    IF p_valor IS NULL OR p_valor <= 0 THEN
        RAISE EXCEPTION 'O valor do saque deve ser positivo (recebido: %)', p_valor;
    END IF;

    IF v_saldo < p_valor THEN
        RAISE EXCEPTION 'Saldo insuficiente: saldo %, saque %',
                        fmt_moeda(v_saldo), fmt_moeda(p_valor);
    END IF;

    -- Chegando aqui, v_saldo - p_valor >= 0 (o CHECK da tabela é a última barreira)
    UPDATE usuario SET saldo = saldo - p_valor WHERE id = p_usuario_id;

    INSERT INTO transacao (id_usuario, tipo, valor, descricao)
    VALUES (p_usuario_id, 'SAQUE', -p_valor, 'Saque em conta');

    RAISE NOTICE 'Saque de % realizado. Novo saldo: %',
                 fmt_moeda(p_valor), fmt_moeda(v_saldo - p_valor);
END;
$$;
-- CALL sacar(1, 100);


-- Exercício 40 – Transferência
CREATE OR REPLACE PROCEDURE transferir(p_origem INT, p_destino INT, p_valor NUMERIC)
LANGUAGE plpgsql AS $$
BEGIN
    IF p_valor IS NULL OR p_valor <= 0 THEN
        RAISE EXCEPTION 'O valor da transferência deve ser positivo (recebido: %)', p_valor;
    END IF;

    IF p_origem = p_destino THEN
        RAISE EXCEPTION 'Origem e destino não podem ser o mesmo usuário';
    END IF;

    -- 1. validar origem
    IF NOT usuario_existe(p_origem) THEN
        RAISE EXCEPTION 'Usuário de origem % não existe', p_origem;
    END IF;

    -- 2. validar destino
    IF NOT usuario_existe(p_destino) THEN
        RAISE EXCEPTION 'Usuário de destino % não existe', p_destino;
    END IF;

    -- 3. verificar saldo
    IF NOT saldo_suficiente(p_origem, p_valor) THEN
        RAISE EXCEPTION 'Saldo insuficiente na origem (%)', p_origem;
    END IF;

    -- 4. retirar da origem
    UPDATE usuario SET saldo = saldo - p_valor WHERE id = p_origem;

    -- 5. adicionar ao destino
    UPDATE usuario SET saldo = saldo + p_valor WHERE id = p_destino;

    INSERT INTO transacao (id_usuario, tipo, valor, descricao) VALUES
        (p_origem,  'TRANSF_ENVIADA',  -p_valor, 'Transferência para o usuário '   || p_destino),
        (p_destino, 'TRANSF_RECEBIDA',  p_valor, 'Transferência do usuário ' || p_origem);

    RAISE NOTICE 'Transferência de % de % para % concluída',
                 fmt_moeda(p_valor), p_origem, p_destino;
END;
$$;
-- CALL transferir(1, 2, 200);


-- Exercício 41 – Alterar odd
CREATE OR REPLACE PROCEDURE alterar_odd(p_aposta_id INT, p_nova_odd NUMERIC)
LANGUAGE plpgsql AS $$
BEGIN
    IF p_nova_odd IS NULL OR p_nova_odd <= 0 THEN
        RAISE EXCEPTION 'A odd deve ser maior que zero (recebido: %)', p_nova_odd;
    END IF;

    UPDATE aposta
       SET odd = p_nova_odd
     WHERE id = p_aposta_id
       AND NOT processada;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Aposta % não existe ou já foi processada', p_aposta_id;
    END IF;

    RAISE NOTICE 'Odd da aposta % alterada para %', p_aposta_id, to_char(p_nova_odd, 'FM990.00');
END;
$$;
-- CALL alterar_odd(1, 3.10);


-- Exercício 42 – Alterar saldo
CREATE OR REPLACE PROCEDURE alterar_saldo(p_usuario_id INT, p_novo_saldo NUMERIC)
LANGUAGE plpgsql AS $$
DECLARE
    v_saldo_atual NUMERIC;
BEGIN
    IF p_novo_saldo IS NULL OR p_novo_saldo < 0 THEN
        RAISE EXCEPTION 'O saldo não pode ser negativo (recebido: %)', p_novo_saldo;
    END IF;

    SELECT u.saldo INTO v_saldo_atual
      FROM usuario u
     WHERE u.id = p_usuario_id
       FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Usuário % não existe', p_usuario_id;
    END IF;

    UPDATE usuario SET saldo = p_novo_saldo WHERE id = p_usuario_id;

    INSERT INTO transacao (id_usuario, tipo, valor, descricao)
    VALUES (p_usuario_id, 'AJUSTE', p_novo_saldo - v_saldo_atual,
            'Ajuste de saldo de ' || fmt_moeda(v_saldo_atual) || ' para ' || fmt_moeda(p_novo_saldo));
END;
$$;
-- CALL alterar_saldo(1, 800);


-- =====================================================================
-- PARTE 9 – EXCEPTION
-- =====================================================================

-- Exercício 43 – Usuário inexistente (NO_DATA_FOUND)
-- Atenção: o PostgreSQL só dispara NO_DATA_FOUND em SELECT INTO se
-- usarmos STRICT. Sem STRICT, a variável apenas fica NULL.
CREATE OR REPLACE FUNCTION nome_usuario_seguro(p_usuario_id INT)
RETURNS TEXT
LANGUAGE plpgsql AS $$
DECLARE
    v_nome TEXT;
BEGIN
    SELECT u.nome INTO STRICT v_nome
      FROM usuario u
     WHERE u.id = p_usuario_id;

    RETURN v_nome;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE NOTICE 'Usuário % não encontrado', p_usuario_id;
        RETURN 'USUÁRIO NÃO ENCONTRADO';
END;
$$;
-- SELECT nome_usuario_seguro(1);
-- SELECT nome_usuario_seguro(9999);


-- Exercício 44 – Divisão por zero
CREATE OR REPLACE FUNCTION calcular_odds(p_valor NUMERIC, p_quantidade NUMERIC)
RETURNS NUMERIC
LANGUAGE plpgsql AS $$
BEGIN
    RETURN ROUND(p_valor / p_quantidade, 2);
EXCEPTION
    WHEN division_by_zero THEN
        RAISE NOTICE 'Quantidade igual a zero: divisão não realizada';
        RETURN NULL;
END;
$$;
-- SELECT calcular_odds(100, 4);
-- SELECT calcular_odds(100, 0);


-- Exercício 45 – Erro genérico (WHEN OTHERS)
-- Tentar gravar um saldo negativo viola o CHECK da tabela e cai no handler.
CREATE OR REPLACE FUNCTION atualizar_saldo_seguro(p_usuario_id INT, p_novo_saldo NUMERIC)
RETURNS BOOLEAN
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE usuario SET saldo = p_novo_saldo WHERE id = p_usuario_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Usuário % não existe', p_usuario_id;
    END IF;

    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Erro ao atualizar o saldo (SQLSTATE %): %', SQLSTATE, SQLERRM;
        RETURN FALSE;
END;
$$;
-- SELECT atualizar_saldo_seguro(1, -50);    -- FALSE (viola o CHECK)
-- SELECT atualizar_saldo_seguro(1, 900);    -- TRUE


-- Exercício 46 – Depósito seguro
CREATE OR REPLACE PROCEDURE depositar_seguro(p_usuario_id INT, p_valor NUMERIC)
LANGUAGE plpgsql AS $$
BEGIN
    CALL depositar(p_usuario_id, p_valor);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Depósito não realizado. Motivo: %', SQLERRM;
END;
$$;
-- CALL depositar_seguro(1, 100);
-- CALL depositar_seguro(1, -100);
-- CALL depositar_seguro(9999, 100);


-- =====================================================================
-- PARTE 10 – Operações envolvendo várias tabelas
-- =====================================================================

-- Exercício 47 – Histórico completo
CREATE OR REPLACE FUNCTION historico_apostas(p_usuario_id INT)
RETURNS TABLE (id_jogo INT, equipe_casa TEXT, equipe_visitante TEXT,
               valor_apostado NUMERIC, odd NUMERIC, data_aposta TIMESTAMP)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT j.id,
           ec.nome::TEXT,
           ev.nome::TEXT,
           a.valor,
           a.odd,
           a.data_aposta::TIMESTAMP
      FROM aposta a
      JOIN jogo   j  ON j.id  = a.id_jogo
      JOIN equipe ec ON ec.id = j.id_casa
      JOIN equipe ev ON ev.id = j.id_visitante
     WHERE a.id_usuario = p_usuario_id
     ORDER BY a.data_aposta, a.id;
END;
$$;
-- SELECT * FROM historico_apostas(1);


-- Exercício 48 – Histórico em texto
CREATE OR REPLACE FUNCTION historico_apostas_texto(p_usuario_id INT)
RETURNS TEXT
LANGUAGE plpgsql AS $$
DECLARE
    registro RECORD;
    v_texto  TEXT := '';
BEGIN
    FOR registro IN
        SELECT ec.nome AS casa, ev.nome AS visitante, a.valor, a.odd
          FROM aposta a
          JOIN jogo   j  ON j.id  = a.id_jogo
          JOIN equipe ec ON ec.id = j.id_casa
          JOIN equipe ev ON ev.id = j.id_visitante
         WHERE a.id_usuario = p_usuario_id
         ORDER BY a.data_aposta, a.id
    LOOP
        v_texto := v_texto
                || 'Jogo: '  || registro.casa || ' x ' || registro.visitante || E'\n'
                || 'Valor: ' || fmt_moeda(registro.valor)                    || E'\n'
                || 'Odd: '   || to_char(registro.odd, 'FM990.00')            || E'\n\n';
    END LOOP;

    IF v_texto = '' THEN
        RETURN 'Nenhuma aposta encontrada.';
    END IF;

    RETURN RTRIM(v_texto, E'\n');
END;
$$;
-- SELECT historico_apostas_texto(1);


-- Exercício 49 – Estatísticas por equipe
CREATE OR REPLACE FUNCTION estatisticas_equipe(p_equipe_id INT)
RETURNS TABLE (jogos BIGINT, vitorias BIGINT, empates BIGINT, derrotas BIGINT,
               gols_marcados BIGINT, gols_sofridos BIGINT)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT equipe_existe(p_equipe_id) THEN
        RAISE EXCEPTION 'Equipe % não existe', p_equipe_id;
    END IF;

    RETURN QUERY
    SELECT COUNT(*)::BIGINT,
           (COUNT(*) FILTER (WHERE pe.gols_pro >  pe.gols_contra))::BIGINT,
           (COUNT(*) FILTER (WHERE pe.gols_pro =  pe.gols_contra))::BIGINT,
           (COUNT(*) FILTER (WHERE pe.gols_pro <  pe.gols_contra))::BIGINT,
           COALESCE(SUM(pe.gols_pro),    0)::BIGINT,
           COALESCE(SUM(pe.gols_contra), 0)::BIGINT
      FROM vw_partidas_equipe pe
     WHERE pe.id_equipe = p_equipe_id;
END;
$$;
-- SELECT * FROM estatisticas_equipe(1);


-- Exercício 50 – Classificação do campeonato
-- Critérios: pontos (3 por vitória, 1 por empate), vitórias, saldo de
-- gols, gols pró e nome. Os nomes das colunas de saída (p, j, v, e, d,
-- gp, gc, sg) seguem o enunciado; a diretiva abaixo faz o PL/pgSQL dar
-- preferência às colunas em caso de ambiguidade.
CREATE OR REPLACE FUNCTION classificacao_campeonato()
RETURNS TABLE (equipe TEXT, p BIGINT, j BIGINT, v BIGINT, e BIGINT, d BIGINT,
               gp BIGINT, gc BIGINT, sg BIGINT)
LANGUAGE plpgsql AS $$
#variable_conflict use_column
BEGIN
    RETURN QUERY
    SELECT eq.nome::TEXT,
           (3 * COUNT(*) FILTER (WHERE pe.gols_pro > pe.gols_contra)
              + COUNT(*) FILTER (WHERE pe.gols_pro = pe.gols_contra))::BIGINT,
           COUNT(pe.id_jogo)::BIGINT,
           (COUNT(*) FILTER (WHERE pe.gols_pro >  pe.gols_contra))::BIGINT,
           (COUNT(*) FILTER (WHERE pe.gols_pro =  pe.gols_contra))::BIGINT,
           (COUNT(*) FILTER (WHERE pe.gols_pro <  pe.gols_contra))::BIGINT,
           COALESCE(SUM(pe.gols_pro),    0)::BIGINT,
           COALESCE(SUM(pe.gols_contra), 0)::BIGINT,
           (COALESCE(SUM(pe.gols_pro), 0) - COALESCE(SUM(pe.gols_contra), 0))::BIGINT
      FROM equipe eq
      LEFT JOIN vw_partidas_equipe pe ON pe.id_equipe = eq.id
     GROUP BY eq.id, eq.nome
     ORDER BY 2 DESC, 4 DESC, 9 DESC, 7 DESC, 1;   -- P, V, SG, GP, equipe
END;
$$;
-- SELECT * FROM classificacao_campeonato();


-- =====================================================================
-- PARTE 11 – Transações e Procedures
-- =====================================================================

-- Exercício 51 – Transferência segura
-- Um bloco BEGIN ... EXCEPTION ... END funciona como um savepoint: se
-- qualquer comando falhar, TODAS as alterações feitas dentro do bloco
-- são desfeitas, então não sobra débito sem crédito. O erro é relançado
-- com uma mensagem amigável para quem chamou.
CREATE OR REPLACE PROCEDURE transferir_seguro(p_origem INT, p_destino INT, p_valor NUMERIC)
LANGUAGE plpgsql AS $$
BEGIN
    IF p_valor IS NULL OR p_valor <= 0 THEN
        RAISE EXCEPTION 'Transferência não realizada: valor inválido (%)', p_valor;
    END IF;

    BEGIN
        -- débito da origem
        UPDATE usuario SET saldo = saldo - p_valor WHERE id = p_origem;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'usuário de origem % não existe', p_origem;
        END IF;

        -- (simulação de falha para testes: descomente para ver o rollback)
        -- RAISE EXCEPTION 'falha simulada entre o débito e o crédito';

        -- crédito do destino
        UPDATE usuario SET saldo = saldo + p_valor WHERE id = p_destino;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'usuário de destino % não existe', p_destino;
        END IF;

        -- registro das operações
        INSERT INTO transacao (id_usuario, tipo, valor, descricao) VALUES
            (p_origem,  'TRANSF_ENVIADA',  -p_valor, 'Transferência segura para o usuário '   || p_destino),
            (p_destino, 'TRANSF_RECEBIDA',  p_valor, 'Transferência segura do usuário ' || p_origem);

    EXCEPTION
        WHEN OTHERS THEN
            -- neste ponto o débito (se ocorreu) já foi revertido
            RAISE EXCEPTION 'Transferência não realizada: %', SQLERRM;
    END;

    RAISE NOTICE 'Transferência segura de % de % para % concluída',
                 fmt_moeda(p_valor), p_origem, p_destino;
END;
$$;
-- CALL transferir_seguro(1, 2, 50);
-- CALL transferir_seguro(1, 9999, 50);   -- falha: nada é alterado


-- Exercício 52 – Processamento em lote (bônus de R$ 10,00)
CREATE OR REPLACE PROCEDURE processar_bonus()
LANGUAGE plpgsql AS $$
DECLARE
    registro RECORD;
    v_cont   INT := 0;
BEGIN
    FOR registro IN
        SELECT u.id FROM usuario u ORDER BY u.id
    LOOP
        UPDATE usuario SET saldo = saldo + 10 WHERE id = registro.id;

        INSERT INTO transacao (id_usuario, tipo, valor, descricao)
        VALUES (registro.id, 'BONUS', 10, 'Bônus de R$ 10,00');

        v_cont := v_cont + 1;
    END LOOP;

    RAISE NOTICE '% usuário(s) receberam o bônus', v_cont;
END;
$$;
-- CALL processar_bonus();


-- Exercício 53 – Bônus em lotes (COMMIT a cada 100 usuários)
-- Chame com CALL fora de um bloco de transação explícito.
CREATE OR REPLACE PROCEDURE processar_bonus_lotes()
LANGUAGE plpgsql AS $$
DECLARE
    registro RECORD;
    v_cont   INT := 0;
BEGIN
    FOR registro IN
        SELECT u.id FROM usuario u ORDER BY u.id
    LOOP
        UPDATE usuario SET saldo = saldo + 10 WHERE id = registro.id;

        INSERT INTO transacao (id_usuario, tipo, valor, descricao)
        VALUES (registro.id, 'BONUS', 10, 'Bônus de R$ 10,00');

        v_cont := v_cont + 1;

        IF v_cont % 100 = 0 THEN
            COMMIT;
            RAISE NOTICE 'Lote confirmado: % usuários processados', v_cont;
        END IF;
    END LOOP;

    COMMIT;   -- confirma o último lote (parcial)
    RAISE NOTICE 'Total de usuários processados: %', v_cont;
END;
$$;
-- CALL processar_bonus_lotes();


-- Exercício 54 – Limpeza de usuários inativos (em lotes)
CREATE OR REPLACE PROCEDURE limpar_usuarios_inativos()
LANGUAGE plpgsql AS $$
DECLARE
    registro RECORD;
    v_cont   INT := 0;
BEGIN
    -- 1. encontrar usuários inativos com saldo
    FOR registro IN
        SELECT u.id, u.saldo
          FROM usuario u
         WHERE NOT u.ativo
           AND u.saldo > 0
         ORDER BY u.id
    LOOP
        -- 2. zerar o saldo
        UPDATE usuario SET saldo = 0 WHERE id = registro.id;

        -- 3. registrar a operação
        INSERT INTO transacao (id_usuario, tipo, valor, descricao)
        VALUES (registro.id, 'LIMPEZA', -registro.saldo,
                'Saldo de ' || fmt_moeda(registro.saldo) || ' zerado por inatividade');

        v_cont := v_cont + 1;

        -- 4. processamento em lote
        IF v_cont % 100 = 0 THEN
            COMMIT;
        END IF;
    END LOOP;

    COMMIT;
    RAISE NOTICE '% usuário(s) inativo(s) tiveram o saldo zerado', v_cont;
END;
$$;
-- CALL limpar_usuarios_inativos();


-- =====================================================================
-- PARTE 12 – Exercícios de integração
-- =====================================================================

-- Exercício 55 – Criar aposta
-- O 5º parâmetro (palpite) é opcional (padrão 'C' = vitória da casa),
-- de modo que CALL criar_aposta(1, 1, 100, 2.50) continua válido.
CREATE OR REPLACE PROCEDURE criar_aposta(p_usuario_id INT, p_jogo_id INT,
                                         p_valor NUMERIC, p_odd NUMERIC,
                                         p_palpite TEXT DEFAULT 'C')
LANGUAGE plpgsql AS $$
DECLARE
    v_encerrado BOOLEAN;
    v_aposta_id INT;
BEGIN
    IF p_valor IS NULL OR p_valor <= 0 THEN
        RAISE EXCEPTION 'O valor da aposta deve ser positivo (recebido: %)', p_valor;
    END IF;

    IF p_odd IS NULL OR p_odd <= 0 THEN
        RAISE EXCEPTION 'A odd deve ser maior que zero (recebido: %)', p_odd;
    END IF;

    IF p_palpite NOT IN ('C', 'E', 'V') THEN
        RAISE EXCEPTION 'Palpite inválido "%": use C (casa), E (empate) ou V (visitante)', p_palpite;
    END IF;

    -- 1. o usuário existe?
    IF NOT usuario_existe(p_usuario_id) THEN
        RAISE EXCEPTION 'Usuário % não existe', p_usuario_id;
    END IF;

    -- 2. o usuário possui saldo?
    IF NOT saldo_suficiente(p_usuario_id, p_valor) THEN
        RAISE EXCEPTION 'Saldo insuficiente para apostar %', fmt_moeda(p_valor);
    END IF;

    -- 3. o jogo existe?
    IF NOT jogo_existe(p_jogo_id) THEN
        RAISE EXCEPTION 'Jogo % não existe', p_jogo_id;
    END IF;

    -- 4. o jogo ainda não foi encerrado?
    SELECT j.encerrado INTO v_encerrado FROM jogo j WHERE j.id = p_jogo_id;
    IF v_encerrado THEN
        RAISE EXCEPTION 'O jogo % já foi encerrado', p_jogo_id;
    END IF;

    -- 5. retirar o valor do saldo
    UPDATE usuario SET saldo = saldo - p_valor WHERE id = p_usuario_id;

    -- 6. criar a aposta
    INSERT INTO aposta (id_usuario, id_jogo, valor, odd, palpite)
    VALUES (p_usuario_id, p_jogo_id, p_valor, p_odd, p_palpite)
    RETURNING id INTO v_aposta_id;

    INSERT INTO transacao (id_usuario, tipo, valor, descricao)
    VALUES (p_usuario_id, 'APOSTA', -p_valor, 'Aposta ' || v_aposta_id || ' no jogo ' || p_jogo_id);

    RAISE NOTICE 'Aposta % criada: % no jogo "%" (odd %)',
                 v_aposta_id, fmt_moeda(p_valor), nome_jogo(p_jogo_id), to_char(p_odd, 'FM990.00');
END;
$$;
-- CALL criar_aposta(1, 1, 100, 2.50);
-- CALL criar_aposta(1, 1, 100, 2.50, 'V');


-- Exercício 56 – Cancelar aposta
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
-- CALL cancelar_aposta(1);


-- Exercício 57 – Encerrar jogo
-- Prêmio = valor apostado x odd (o valor da aposta já foi debitado na
-- criação, então o prêmio devolve a aposta mais o lucro). Todas as
-- apostas do jogo são marcadas como processadas, vencedoras ou não.
CREATE OR REPLACE PROCEDURE encerrar_jogo(p_jogo_id INT, p_gols_casa INT, p_gols_visitante INT)
LANGUAGE plpgsql AS $$
DECLARE
    v_encerrado       BOOLEAN;
    v_resultado       TEXT;
    v_premio          NUMERIC(12,2);
    v_vencedoras      INT := 0;
    v_total_premios   NUMERIC := 0;
    registro          RECORD;
BEGIN
    IF p_gols_casa IS NULL OR p_gols_visitante IS NULL
       OR p_gols_casa < 0 OR p_gols_visitante < 0 THEN
        RAISE EXCEPTION 'Placar inválido: % x %', p_gols_casa, p_gols_visitante;
    END IF;

    SELECT j.encerrado INTO v_encerrado
      FROM jogo j
     WHERE j.id = p_jogo_id
       FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Jogo % não existe', p_jogo_id;
    END IF;

    IF v_encerrado THEN
        RAISE EXCEPTION 'O jogo % já foi encerrado', p_jogo_id;
    END IF;

    -- 1 e 2. atualizar o placar e marcar o jogo como encerrado
    UPDATE jogo
       SET gols_casa      = p_gols_casa,
           gols_visitante = p_gols_visitante,
           encerrado      = TRUE
     WHERE id = p_jogo_id;

    v_resultado := resultado_partida(p_gols_casa, p_gols_visitante);

    -- 3. localizar as apostas do jogo
    FOR registro IN
        SELECT a.id, a.id_usuario, a.valor, a.odd, a.palpite
          FROM aposta a
         WHERE a.id_jogo = p_jogo_id
           AND NOT a.processada
         ORDER BY a.id
    LOOP
        -- 4. identificar os vencedores
        IF registro.palpite = v_resultado THEN
            -- 5. calcular o prêmio
            v_premio := ROUND(registro.valor * registro.odd, 2);

            -- 6. creditar o usuário vencedor
            UPDATE usuario SET saldo = saldo + v_premio WHERE id = registro.id_usuario;

            INSERT INTO transacao (id_usuario, tipo, valor, descricao)
            VALUES (registro.id_usuario, 'PREMIO', v_premio,
                    'Prêmio da aposta ' || registro.id || ' (jogo ' || p_jogo_id || ')');

            v_vencedoras    := v_vencedoras + 1;
            v_total_premios := v_total_premios + v_premio;
        END IF;

        UPDATE aposta SET processada = TRUE WHERE id = registro.id;
    END LOOP;

    RAISE NOTICE 'Jogo % encerrado: % x % | % aposta(s) vencedora(s) | prêmios: %',
                 p_jogo_id, p_gols_casa, p_gols_visitante, v_vencedoras, fmt_moeda(v_total_premios);
END;
$$;
-- CALL encerrar_jogo(1, 2, 1);


-- =====================================================================
-- 3. DESAFIOS
-- =====================================================================

-- Desafio 1 – Relatório completo do usuário
CREATE OR REPLACE FUNCTION relatorio_usuario(p_usuario_id INT)
RETURNS TABLE (nome TEXT, saldo NUMERIC, quantidade_apostas BIGINT, total_apostado NUMERIC,
               maior_aposta NUMERIC, menor_aposta NUMERIC, media_apostas NUMERIC)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT usuario_existe(p_usuario_id) THEN
        RAISE EXCEPTION 'Usuário % não existe', p_usuario_id;
    END IF;

    RETURN QUERY
    SELECT u.nome::TEXT,
           u.saldo,
           COUNT(a.id),
           COALESCE(SUM(a.valor), 0),
           COALESCE(MAX(a.valor), 0),
           COALESCE(MIN(a.valor), 0),
           COALESCE(ROUND(AVG(a.valor), 2), 0)
      FROM usuario u
      LEFT JOIN aposta a ON a.id_usuario = u.id
     WHERE u.id = p_usuario_id
     GROUP BY u.id, u.nome, u.saldo;
END;
$$;
-- SELECT * FROM relatorio_usuario(1);


-- Desafio 2 – Extrato completo
CREATE OR REPLACE FUNCTION extrato_usuario(p_usuario_id INT)
RETURNS TABLE (data TIMESTAMP, tipo TEXT, valor NUMERIC, descricao TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT t.data_transacao::TIMESTAMP,
           t.tipo::TEXT,
           t.valor,
           t.descricao
      FROM transacao t
     WHERE t.id_usuario = p_usuario_id
     ORDER BY t.data_transacao, t.id;
END;
$$;
-- SELECT * FROM extrato_usuario(1);


-- Desafio 3 – Ranking financeiro (ROW_NUMBER)
-- Ordenado pelo maior saldo; o desempate é o total apostado.
CREATE OR REPLACE FUNCTION ranking_financeiro()
RETURNS TABLE (posicao BIGINT, usuario TEXT, saldo NUMERIC, total_apostado NUMERIC)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT ROW_NUMBER() OVER (ORDER BY u.saldo DESC, COALESCE(SUM(a.valor), 0) DESC, u.nome),
           u.nome::TEXT,
           u.saldo,
           COALESCE(SUM(a.valor), 0)
      FROM usuario u
      LEFT JOIN aposta a ON a.id_usuario = u.id
     GROUP BY u.id, u.nome, u.saldo
     ORDER BY 1;
END;
$$;
-- SELECT * FROM ranking_financeiro();


-- Desafio 4 – Artilharia
CREATE OR REPLACE FUNCTION artilharia()
RETURNS TABLE (equipe TEXT, gols_marcados BIGINT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT eq.nome::TEXT,
           COALESCE(SUM(pe.gols_pro), 0)::BIGINT
      FROM equipe eq
      LEFT JOIN vw_partidas_equipe pe ON pe.id_equipe = eq.id
     GROUP BY eq.id, eq.nome
     ORDER BY 2 DESC, 1;
END;
$$;
-- SELECT * FROM artilharia();


-- Desafio 5 – Gerar campeonato (turno e returno, resultados aleatórios)
-- Para cada par (mandante, visitante) com mandante <> visitante cria o
-- jogo, sorteia o placar (0 a 4 gols) e o encerra via encerrar_jogo, que
-- também liquida eventuais apostas. Pares que já têm jogo são ignorados.
-- A classificação é calculada sob demanda por classificacao_campeonato(),
-- então "atualizá-la" significa consultá-la, o que é feito no final.
CREATE OR REPLACE PROCEDURE gerar_campeonato()
LANGUAGE plpgsql AS $$
DECLARE
    r_casa     RECORD;
    r_visit    RECORD;
    r_class    RECORD;
    v_jogo_id  INT;
    v_gols_c   INT;
    v_gols_v   INT;
    v_criados  INT := 0;
    v_pos      INT := 0;
BEGIN
    -- 1. percorrer todas as equipes (mandantes)
    FOR r_casa IN SELECT eq.id FROM equipe eq ORDER BY eq.id LOOP

        -- 2 e 3. gerar jogos contra as demais (nunca contra ela mesma)
        FOR r_visit IN
            SELECT eq.id FROM equipe eq WHERE eq.id <> r_casa.id ORDER BY eq.id
        LOOP
            IF NOT EXISTS (SELECT 1 FROM jogo j
                            WHERE j.id_casa = r_casa.id
                              AND j.id_visitante = r_visit.id) THEN

                INSERT INTO jogo (id_casa, id_visitante, data_jogo, encerrado)
                VALUES (r_casa.id, r_visit.id, now(), FALSE)
                RETURNING id INTO v_jogo_id;

                -- 4. resultado aleatório
                v_gols_c := floor(random() * 5)::INT;
                v_gols_v := floor(random() * 5)::INT;

                -- 5. encerrar o jogo
                CALL encerrar_jogo(v_jogo_id, v_gols_c, v_gols_v);

                v_criados := v_criados + 1;
            END IF;
        END LOOP;
    END LOOP;

    RAISE NOTICE '% jogo(s) gerado(s) e encerrado(s)', v_criados;

    -- 6. classificação atualizada
    RAISE NOTICE '--- CLASSIFICAÇÃO ---';
    FOR r_class IN SELECT * FROM classificacao_campeonato() LOOP
        v_pos := v_pos + 1;
        RAISE NOTICE '%º % | P:% J:% V:% E:% D:% GP:% GC:% SG:%',
                     v_pos, r_class.equipe, r_class.p, r_class.j, r_class.v,
                     r_class.e, r_class.d, r_class.gp, r_class.gc, r_class.sg;
    END LOOP;
END;
$$;
-- CALL gerar_campeonato();


-- Desafio 6 – Simulação de apostas
-- WHILE + random() + SELECT INTO + validação de saldo + INSERT + UPDATE.
-- O limite de tentativas evita laço infinito quando ninguém tem saldo.
CREATE OR REPLACE PROCEDURE simular_apostas(p_quantidade INT)
LANGUAGE plpgsql AS $$
DECLARE
    v_criadas    INT := 0;
    v_tentativas INT := 0;
    v_max        INT;
    v_usuario_id INT;
    v_saldo      NUMERIC;
    v_jogo_id    INT;
    v_valor      NUMERIC(12,2);
    v_odd        NUMERIC(6,2);
    v_palpite    TEXT;
BEGIN
    IF p_quantidade IS NULL OR p_quantidade <= 0 THEN
        RAISE EXCEPTION 'A quantidade deve ser positiva (recebido: %)', p_quantidade;
    END IF;

    v_max := p_quantidade * 10;

    WHILE v_criadas < p_quantidade AND v_tentativas < v_max LOOP
        v_tentativas := v_tentativas + 1;

        -- usuário ativo aleatório
        SELECT u.id, u.saldo INTO v_usuario_id, v_saldo
          FROM usuario u
         WHERE u.ativo
         ORDER BY random()
         LIMIT 1;

        IF NOT FOUND THEN
            RAISE NOTICE 'Não há usuários ativos.';
            EXIT;
        END IF;

        -- jogo aberto aleatório
        SELECT j.id INTO v_jogo_id
          FROM jogo j
         WHERE NOT j.encerrado
         ORDER BY random()
         LIMIT 1;

        IF NOT FOUND THEN
            RAISE NOTICE 'Não há jogos em aberto.';
            EXIT;
        END IF;

        v_valor   := ROUND((5 + random() * 195)::NUMERIC, 2);        -- R$ 5 a R$ 200
        v_odd     := ROUND((1.2 + random() * 3.8)::NUMERIC, 2);      -- 1,20 a 5,00
        v_palpite := (ARRAY['C', 'E', 'V'])[1 + floor(random() * 3)::INT];

        -- validação de saldo
        IF v_saldo < v_valor THEN
            CONTINUE;
        END IF;

        UPDATE usuario SET saldo = saldo - v_valor WHERE id = v_usuario_id;

        INSERT INTO aposta (id_usuario, id_jogo, valor, odd, palpite)
        VALUES (v_usuario_id, v_jogo_id, v_valor, v_odd, v_palpite);

        INSERT INTO transacao (id_usuario, tipo, valor, descricao)
        VALUES (v_usuario_id, 'APOSTA', -v_valor, 'Aposta simulada no jogo ' || v_jogo_id);

        v_criadas := v_criadas + 1;
    END LOOP;

    RAISE NOTICE '% de % aposta(s) criada(s) em % tentativa(s)', v_criadas, p_quantidade, v_tentativas;
END;
$$;
-- CALL simular_apostas(20);


-- Desafio 7 – Processamento de apostas
-- Liquida as apostas pendentes de jogos já encerrados (por exemplo,
-- jogos encerrados por UPDATE direto). Apostas já liquidadas por
-- encerrar_jogo são ignoradas graças ao campo "processada".
CREATE OR REPLACE PROCEDURE processar_apostas()
LANGUAGE plpgsql AS $$
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
    RAISE NOTICE '% aposta(s) processada(s) | % vencedora(s) | prêmios pagos: %',
                 v_processadas, v_vencedoras, fmt_moeda(v_total_premios);
END;
$$;
-- CALL processar_apostas();


-- =====================================================================
-- Desafio 8 – Sistema completo IFBET
--
-- O sistema é o conjunto dos subprogramas definidos neste arquivo:
--
--   FUNCTIONS                     ONDE ESTÁ
--   obter_saldo()                 Seção 1 (apoio)
--   nome_usuario()                Seção 1 (apoio)
--   nome_jogo()                   Seção 1 (apoio)
--   quantidade_apostas()          Seção 1 (apoio)
--   valor_total_apostado()        Seção 1 (apoio)
--   ranking_apostadores()         Exercício 25
--   historico_apostas()           Exercício 47
--   estatisticas_equipe()         Exercício 49
--   classificacao_campeonato()    Exercício 50
--
--   PROCEDURES                    ONDE ESTÁ
--   depositar()                   Exercício 38
--   sacar()                       Exercício 39
--   transferir()                  Exercício 40 (versão segura: Ex. 51)
--   criar_aposta()                Exercício 55
--   cancelar_aposta()             Exercício 56
--   encerrar_jogo()               Exercício 57
--   processar_apostas()           Desafio 7
--   gerar_campeonato()            Desafio 5
--
-- Recursos de PL/pgSQL cobertos: FUNCTION, PROCEDURE, IF/ELSE, CASE
-- (Ex. 20, 49, 50 e resultado_partida), SELECT INTO, FOR, WHILE, LOOP,
-- EXIT, RETURNS TABLE, RETURN QUERY, RAISE NOTICE, EXCEPTION, JOIN,
-- GROUP BY, ORDER BY, ROW_NUMBER() (Desafio 3) e COMMIT (Ex. 53, 54 e
-- Desafio 7).
--
-- Consulta de conferência: lista o que foi criado no schema public.
-- =====================================================================
SELECT p.proname AS subprograma,
       CASE p.prokind WHEN 'f' THEN 'FUNCTION' WHEN 'p' THEN 'PROCEDURE' END AS tipo
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
 WHERE n.nspname = 'public'
   AND p.proname IN ('obter_saldo', 'nome_usuario', 'nome_jogo', 'quantidade_apostas',
                     'valor_total_apostado', 'ranking_apostadores', 'historico_apostas',
                     'estatisticas_equipe', 'classificacao_campeonato',
                     'depositar', 'sacar', 'transferir', 'criar_aposta', 'cancelar_aposta',
                     'encerrar_jogo', 'processar_apostas', 'gerar_campeonato')
 ORDER BY tipo, subprograma;

-- Desafio 9 (script de testes): veja o arquivo ifbet_testes.sql
