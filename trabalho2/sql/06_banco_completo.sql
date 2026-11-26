\encoding UTF8
CREATE DATABASE sistemas_eventos_inscricoes;
\c sistemas_eventos_inscricoes
\encoding UTF8

-- Tipos enumerados
CREATE TYPE status_evento     AS ENUM ('aberto', 'encerrado', 'cancelado');
CREATE TYPE tipo_participante AS ENUM ('estudante', 'professor', 'externo');
CREATE TYPE status_inscricao  AS ENUM ('confirmada', 'lista_espera', 'cancelada');

-- Tabelas
CREATE TABLE categoria (
    id   SERIAL PRIMARY KEY,
    nome VARCHAR(200) NOT NULL UNIQUE
);

CREATE TABLE local (
    id         SERIAL PRIMARY KEY,
    nome       VARCHAR(200) NOT NULL,
    capacidade INTEGER NOT NULL CHECK (capacidade > 0)
);

CREATE TABLE evento (
    id           SERIAL PRIMARY KEY,
    titulo       VARCHAR(100) NOT NULL,
    categoria_id INTEGER NOT NULL REFERENCES categoria(id),
    local_id     INTEGER NOT NULL REFERENCES local(id),
    data_inicio  TIMESTAMP NOT NULL,
    data_fim     TIMESTAMP NOT NULL,
    vagas        INTEGER NOT NULL CHECK (vagas > 0),
    valor_base   NUMERIC(10,2) NOT NULL CHECK (valor_base >= 0),
    status       status_evento NOT NULL DEFAULT 'aberto',
    CONSTRAINT ck_evento_datas CHECK (data_fim > data_inicio)
);

CREATE TABLE participante (
    id    SERIAL PRIMARY KEY,
    nome  VARCHAR(200) NOT NULL,
    email VARCHAR(200) NOT NULL UNIQUE,
    tipo  tipo_participante NOT NULL
);

CREATE TABLE inscricao (
    id              SERIAL PRIMARY KEY,
    participante_id INTEGER NOT NULL REFERENCES participante(id) ON DELETE RESTRICT,
    evento_id       INTEGER NOT NULL REFERENCES evento(id)       ON DELETE RESTRICT,
    data_inscricao  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status          status_inscricao NOT NULL,
    valor_pago      NUMERIC(10,2) NOT NULL CHECK (valor_pago >= 0)
);

-- Impede inscrição duplicada ativa, mas permite reinscrever após cancelar
CREATE UNIQUE INDEX uq_inscricao_ativa
    ON inscricao (participante_id, evento_id)
    WHERE status <> 'cancelada';

-- Acelera a contagem de vagas por evento
CREATE INDEX idx_inscricao_evento_status
    ON inscricao (evento_id, status);

CREATE TABLE log_inscricao (
    id              SERIAL PRIMARY KEY,
    inscricao_id    INTEGER NOT NULL REFERENCES inscricao(id) ON DELETE RESTRICT,
    status_anterior status_inscricao,           -- NULL quando é a criação
    status_novo     status_inscricao NOT NULL,
    data_hora       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usuario         VARCHAR(100) NOT NULL DEFAULT current_user
);

CREATE INDEX idx_log_inscricao ON log_inscricao (inscricao_id);

\encoding UTF8
-- ============================================================
-- 1. CATEGORIAS
-- ============================================================

INSERT INTO categoria (nome) VALUES
('Tecnologia'),
('Programação'),
('Ciência'),
('Empreendedorismo'),
('Educação'),
('Segurança da Informação'),
('Inteligência Artificial'),
('Desenvolvimento Web');


-- ============================================================
-- 2. LOCAIS
-- ============================================================

INSERT INTO local (nome, capacidade) VALUES
('Auditório Central', 200),
('Laboratório de Informática 1', 40),
('Laboratório de Informática 2', 30),
('Sala de Conferências', 100),
('Sala Multimídia', 50),
('Espaço Maker', 25);


-- ============================================================
-- 3. EVENTOS
-- ============================================================

INSERT INTO evento (
    titulo,
    categoria_id,
    local_id,
    data_inicio,
    data_fim,
    vagas,
    valor_base,
    status
) VALUES
(
    'Semana de Tecnologia 2026',
    1,
    1,
    '2026-12-10 08:00:00',
    '2026-12-10 18:00:00',
    150,
    0.00,
    'aberto'
),
(
    'Introdução à Programação com Python',
    2,
    2,
    '2026-12-12 09:00:00',
    '2026-12-12 12:00:00',
    40,
    25.00,
    'aberto'
),
(
    'Inteligência Artificial na Atualidade',
    7,
    4,
    '2026-12-15 14:00:00',
    '2026-12-15 17:00:00',
    80,
    50.00,
    'aberto'
),
(
    'Hackathon de Desenvolvimento Web',
    8,
    3,
    '2026-12-18 08:00:00',
    '2026-12-19 18:00:00',
    30,
    35.00,
    'aberto'
),
(
    'Segurança Digital para Iniciantes',
    6,
    5,
    '2026-12-20 14:00:00',
    '2026-12-20 16:00:00',
    50,
    20.00,
    'aberto'
),
(
    'Workshop de Banco de Dados',
    2,
    2,
    '2026-12-22 08:00:00',
    '2026-12-22 12:00:00',
    40,
    30.00,
    'aberto'
),
(
    'Feira de Inovação e Empreendedorismo',
    4,
    1,
    '2026-12-26 10:00:00',
    '2026-12-26 18:00:00',
    180,
    10.00,
    'aberto'
),
(
    'Ciência e Tecnologia no Cotidiano',
    3,
    4,
    '2026-12-28 09:00:00',
    '2026-12-28 11:00:00',
    70,
    15.00,
    'aberto'
),
(
    'Git e GitHub na Prática',
    2,
    6,
    '2026-12-30 14:00:00',
    '2026-12-30 17:00:00',
    25,
    0.00,
    'aberto'
),
(
    'Palestra: O Futuro da Computação',
    1,
    1,
    '2027-01-10 19:00:00',
    '2027-01-10 21:00:00',
    150,
    45.00,
    'aberto'
);


-- ============================================================
-- 4. PARTICIPANTES
-- ============================================================

INSERT INTO participante (nome, email, tipo) VALUES
('Lucas Oliveira', 'lucas.oliveira@email.com', 'estudante'),
('Ana Souza', 'ana.souza@email.com', 'estudante'),
('Pedro Henrique', 'pedro.henrique@email.com', 'estudante'),
('Mariana Costa', 'mariana.costa@email.com', 'estudante'),
('Gabriel Almeida', 'gabriel.almeida@email.com', 'estudante'),
('Julia Martins', 'julia.martins@email.com', 'estudante'),
('Rafael Ferreira', 'rafael.ferreira@email.com', 'estudante'),
('Beatriz Santos', 'beatriz.santos@email.com', 'estudante'),
('Carlos Eduardo', 'carlos.eduardo@email.com', 'estudante'),
('Camila Rodrigues', 'camila.rodrigues@email.com', 'estudante'),
('Roberto Mendes', 'roberto.mendes@email.com', 'professor'),
('Fernanda Lima', 'fernanda.lima@email.com', 'professor'),
('Paulo Ricardo', 'paulo.ricardo@email.com', 'professor'),
('Aline Barbosa', 'aline.barbosa@email.com', 'professor'),
('Bruno Carvalho', 'bruno.carvalho@email.com', 'externo'),
('Leticia Gomes', 'leticia.gomes@email.com', 'externo'),
('Thiago Pereira', 'thiago.pereira@email.com', 'externo'),
('Isabela Nunes', 'isabela.nunes@email.com', 'externo'),
('Daniel Rocha', 'daniel.rocha@email.com', 'externo'),
('Eduarda Freitas', 'eduarda.freitas@email.com', 'externo');


-- ============================================================
-- 5. INSCRIÇÕES
-- ============================================================

INSERT INTO inscricao (
    participante_id,
    evento_id,
    status,
    valor_pago
) VALUES

-- Semana de Tecnologia
(1, 1, 'confirmada', 0.00),
(2, 1, 'confirmada', 0.00),
(3, 1, 'confirmada', 0.00),
(11, 1, 'confirmada', 0.00),
(15, 1, 'confirmada', 0.00),

-- Introdução à Programação com Python
(1, 2, 'confirmada', 25.00),
(4, 2, 'confirmada', 25.00),
(5, 2, 'confirmada', 25.00),
(6, 2, 'confirmada', 25.00),
(11, 2, 'confirmada', 25.00),
(15, 2, 'lista_espera', 0.00),

-- Inteligência Artificial na Atualidade
(2, 3, 'confirmada', 50.00),
(7, 3, 'confirmada', 50.00),
(8, 3, 'confirmada', 50.00),
(12, 3, 'confirmada', 50.00),
(16, 3, 'lista_espera', 0.00),

-- Hackathon de Desenvolvimento Web
(3, 4, 'confirmada', 35.00),
(4, 4, 'confirmada', 35.00),
(5, 4, 'confirmada', 35.00),
(6, 4, 'confirmada', 35.00),
(7, 4, 'confirmada', 35.00),
(8, 4, 'lista_espera', 0.00),

-- Segurança Digital para Iniciantes
(9, 5, 'confirmada', 20.00),
(10, 5, 'confirmada', 20.00),
(13, 5, 'confirmada', 20.00),
(17, 5, 'confirmada', 20.00),
(18, 5, 'cancelada', 0.00),

-- Workshop de Banco de Dados
(1, 6, 'confirmada', 30.00),
(2, 6, 'confirmada', 30.00),
(9, 6, 'confirmada', 30.00),
(11, 6, 'confirmada', 30.00),
(19, 6, 'lista_espera', 0.00),

-- Feira de Inovação e Empreendedorismo
(3, 7, 'confirmada', 10.00),
(10, 7, 'confirmada', 10.00),
(12, 7, 'confirmada', 10.00),
(14, 7, 'confirmada', 10.00),
(20, 7, 'confirmada', 10.00),

-- Ciência e Tecnologia no Cotidiano
(5, 8, 'confirmada', 15.00),
(6, 8, 'confirmada', 15.00),
(13, 8, 'confirmada', 15.00),
(16, 8, 'lista_espera', 0.00),

-- Git e GitHub na Prática
(7, 9, 'confirmada', 0.00),
(8, 9, 'confirmada', 0.00),
(9, 9, 'confirmada', 0.00),
(14, 9, 'confirmada', 0.00),

-- Palestra: O Futuro da Computação
(1, 10, 'confirmada', 45.00),
(10, 10, 'confirmada', 45.00),
(15, 10, 'confirmada', 45.00),
(17, 10, 'lista_espera', 0.00);


-- ============================================================
-- 6. LOG_INSCRICAO
-- ============================================================
-- Exemplos de registros de auditoria.
-- O status_anterior será NULL para novas inscrições.

INSERT INTO log_inscricao (
    inscricao_id,
    status_anterior,
    status_novo,
    data_hora,
    usuario
) VALUES
(1, NULL, 'confirmada', '2026-11-20 10:00:00', 'postgres'),
(2, NULL, 'confirmada', '2026-11-20 10:05:00', 'postgres'),
(3, NULL, 'confirmada', '2026-11-20 10:10:00', 'postgres'),
(6, NULL, 'confirmada', '2026-11-20 11:00:00', 'postgres'),
(11, NULL, 'lista_espera', '2026-11-20 11:30:00', 'postgres'),
(12, NULL, 'confirmada', '2026-11-20 12:00:00', 'postgres'),
(17, NULL, 'confirmada', '2026-11-20 13:00:00', 'postgres'),
(22, NULL, 'lista_espera', '2026-11-20 14:00:00', 'postgres'),
(26, NULL, 'cancelada', '2026-11-20 15:00:00', 'postgres'),
(30, NULL, 'confirmada', '2026-11-20 16:00:00', 'postgres');


\encoding UTF8
-- 1. fn_valida_inscricao	
-- Regra: impede inscrição em evento cancelado ou encerrado e em evento cujo horário conflite com outro já confirmado do mesmo participante.
-- Mecanismo: RAISE EXCEPTION com mensagem clara.
-- Como verificar: inscrever o mesmo participante em dois eventos no mesmo horário.
CREATE OR REPLACE FUNCTION fn_validar_inscricao()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_status_evento status_evento;
    v_data_inicio TIMESTAMP;
    v_data_fim TIMESTAMP;
    v_vagas INTEGER;
    v_capacidade_local INTEGER;
BEGIN
    -- 1. Permitir o cancelamento da inscrição
    IF NEW.status = 'cancelada' THEN
        RETURN NEW;
    END IF;

    -- 2. Recuperar e bloquear os dados do evento
    SELECT
        e.status,
        e.data_inicio,
        e.data_fim,
        e.vagas,
        l.capacidade
    INTO
        v_status_evento,
        v_data_inicio,
        v_data_fim,
        v_vagas,
        v_capacidade_local
    FROM evento e
    INNER JOIN local l
        ON l.id = e.local_id
    WHERE e.id = NEW.evento_id
    FOR UPDATE OF e;

    -- 3. Verificar se o evento existe
    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Evento % não encontrado.',
            NEW.evento_id;
    END IF;

    -- 4. Validar o status do evento
    IF v_status_evento <> 'aberto' THEN
        RAISE EXCEPTION
            'Não é possível realizar inscrição no evento %, pois ele está %.',
            NEW.evento_id,
            v_status_evento;
    END IF;

    -- 5. Validar a capacidade do local
    IF v_capacidade_local IS NULL THEN
        RAISE EXCEPTION
            'O evento % está associado a um local inexistente ou sem capacidade definida.',
            NEW.evento_id;
    END IF;

    IF v_vagas > v_capacidade_local THEN
        RAISE EXCEPTION
            'O evento possui % vagas, mas o local comporta apenas % pessoas.',
            v_vagas,
            v_capacidade_local;
    END IF;

    -- 6. Bloquear o participante durante a validação
    PERFORM 1
    FROM participante p
    WHERE p.id = NEW.participante_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Participante % não encontrado.',
            NEW.participante_id;
    END IF;

    -- 7. Verificar conflitos de horário
    IF NEW.status = 'confirmada' AND EXISTS (
        SELECT 1
        FROM inscricao i
        INNER JOIN evento e
            ON e.id = i.evento_id
        WHERE i.participante_id = NEW.participante_id
          AND i.id IS DISTINCT FROM NEW.id
          AND i.status = 'confirmada'
          AND e.id <> NEW.evento_id
          AND e.data_inicio < v_data_fim
          AND e.data_fim > v_data_inicio
    ) THEN
        RAISE EXCEPTION
            'Participante % já possui inscrição confirmada em evento com horário conflitante.',
            NEW.participante_id;
    END IF;

    RETURN NEW;
END;
$$;


-- 2. fn_auditoria_inscricao
-- Regra: toda criação ou mudança de status em inscricao gera uma linha em log_inscricao.
-- Como verificar: cancelar uma inscrição e consultar log_inscricao.
CREATE OR REPLACE FUNCTION fn_auditoria_inscricao() 
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- 1. Verificar qual operação disparou a TRIGGER
    IF TG_OP = 'INSERT' THEN
        -- Registrar a Criação da Inscrição
        INSERT INTO log_inscricao(
            inscricao_id,
            status_anterior,
            status_novo
        )
        VALUES (
            NEW.id,
            NULL,
            NEW.status
        );
    ELSIF TG_OP = 'UPDATE' THEN
        -- 2. Verificar se o Status realmente mudou
        IF OLD.status is DISTINCT FROM NEW.status THEN
            -- registrar a alteração
            INSERT INTO log_inscricao(
            inscricao_id,
            status_anterior,
            status_novo
        )
        VALUES (
            NEW.id,
            OLD.status,
            NEW.status
        );
        END IF;
    END IF;
    -- 3; Finalizar a Função
    RETURN NULL;    
END;
$$;

-- 3. fn_calcular_valor_inscricao
-- Objetivo: calcular o preço de uma inscrição aplicando desconto conforme o tipo do participante.
CREATE OR REPLACE FUNCTION fn_calcular_valor_inscricao(p_participante INTEGER, p_evento INTEGER) RETURNS NUMERIC(10, 2)
LANGUAGE plpgsql
AS $$
DECLARE
    var_tipo_part tipo_participante;
    var_valor_base NUMERIC(10, 2);
    var_status_evento status_evento;

    var_desconto NUMERIC(4, 2);
    var_valor_inscricao NUMERIC(10, 2);
BEGIN
    -- Recuperar o tipo do participante
    SELECT
        p.tipo
    INTO
        var_tipo_part
    FROM participante p
    WHERE p.id = p_participante;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Participante % Não Foi Encontrado', p_participante;
    END IF;

    -- Recuperar o valor_base do Evento
    SELECT
        e.status,
        e.valor_base
    INTO
        var_status_evento,
        var_valor_base
    FROM evento e
    WHERE e.id = p_evento;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Evento % Não Foi Encontrado', p_evento;
    END IF; 

    IF var_status_evento = 'cancelado' THEN
        RAISE EXCEPTION 'Evento % Está Cancelado', p_evento;
    ELSIF var_status_evento = 'encerrado' THEN
        RAISE EXCEPTION 'Evento % Está Encerrado', p_evento;
    ELSE
        RAISE NOTICE 'Evento % Está Aberto', p_evento;
    END IF;

    -- Aplicar Desconto
    IF var_tipo_part = 'estudante' THEN
        var_desconto := 0.50;
    ELSIF var_tipo_part = 'professor' THEN
        var_desconto := 0.30;
    ELSE 
        var_desconto := 0.00;
    END IF;

    -- Retornar Valor Final
    var_valor_inscricao := ROUND(var_valor_base * (1 - var_desconto), 2);
    RETURN var_valor_inscricao;
END;
$$;



-- 3. fn_relatorio_ocupacao()
CREATE OR REPLACE FUNCTION fn_relatorio_ocupacao()
RETURNS TABLE (
    evento_id INTEGER,
    titulo VARCHAR(100),
    vagas INTEGER,
    confirmados BIGINT,
    lista_espera BIGINT,
    percentual_ocupacao NUMERIC,
    arrecadacao NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN

    RETURN QUERY

    SELECT
        e.id,
        e.titulo,
        e.vagas,
        -- 1. Contando inscrições confirmadas
        COUNT(i.id) FILTER (WHERE i.status = 'confirmada') AS confirmados,

        -- 2. Contando inscrições na lista de espera
        COUNT(i.id) FILTER (WHERE i.status = 'lista_espera') AS lista_espera,

        -- 3. Calculando percentual de ocupação
        ROUND((COUNT(i.id) FILTER (WHERE i.status = 'confirmada'))::NUMERIC * 100 / e.vagas, 2) AS percentual_ocupacao,

        -- 4. Calculando arrecadação
        COALESCE(SUM(i.valor_pago) FILTER (WHERE i.status = 'confirmada'),0::NUMERIC) AS arrecadacao
    FROM evento e
    LEFT JOIN inscricao i
        ON i.evento_id = e.id
    GROUP BY
        e.id,
        e.titulo,
        e.vagas
    ORDER BY e.id;
END;
$$;

\encoding UTF8


-- 1. sp_realizar_inscricao
-- Calcula o valor com fn_calcular_valor_inscricao.
-- Se há vaga, grava como confirmada; caso contrário, como lista_espera.
CREATE OR REPLACE PROCEDURE sp_realizar_inscricao(
    p_participante INTEGER,
    p_evento INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    var_vagas INTEGER;
    var_confirmadas BIGINT;
    var_valor NUMERIC(10, 2);
    var_status status_inscricao;
    var_status_evento status_evento;
    var_capacidade_local INTEGER;
BEGIN
    -- 1. Recuperar e bloquear os dados do evento
    SELECT
        e.vagas,
        e.status,
        l.capacidade
    INTO
        var_vagas,
        var_status_evento,
        var_capacidade_local
    FROM evento e
    INNER JOIN local l ON l.id = e.local_id
    WHERE e.id = p_evento
    FOR UPDATE OF e;

    -- 2. Verificar se o evento existe
    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Evento % não encontrado.',
            p_evento;
    END IF;

    -- 3. Verificar se o evento está aberto
    IF var_status_evento <> 'aberto' THEN
        RAISE EXCEPTION
            'Não é possível realizar inscrições no evento %, pois ele está %.',
            p_evento,
            var_status_evento;
    END IF;

    -- 4. Verificar a capacidade do local
    IF var_vagas > var_capacidade_local THEN
        RAISE EXCEPTION
            'O evento possui % vagas, mas o local comporta apenas % pessoas.',
            var_vagas,
            var_capacidade_local;
    END IF;

    -- 5. Verificar se o participante existe
    PERFORM 1
    FROM participante p
    WHERE p.id = p_participante;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Participante % não encontrado.',
            p_participante;
    END IF;

    -- 6. Verificar se o participante já possui inscrição ativa
    PERFORM 1
    FROM inscricao i
    WHERE i.participante_id = p_participante
      AND i.evento_id = p_evento
      AND i.status <> 'cancelada';

    IF FOUND THEN
        RAISE EXCEPTION
            'Participante % já está inscrito no evento %.',
            p_participante,
            p_evento;
    END IF;

    -- 7. Contar as inscrições confirmadas
    SELECT COUNT(*)
    INTO var_confirmadas
    FROM inscricao i
    WHERE i.evento_id = p_evento
      AND i.status = 'confirmada';

    -- 8. Definir o status da inscrição
    IF var_confirmadas < var_vagas THEN
        var_status := 'confirmada';
    ELSE
        var_status := 'lista_espera';
    END IF;

    -- 9. Calcular o valor da inscrição
    var_valor := fn_calcular_valor_inscricao(
        p_participante,
        p_evento
    );

    -- 10. Inserir a inscrição
    -- Inscrições em lista de espera ainda não possuem valor pago.
    INSERT INTO inscricao (
        participante_id,
        evento_id,
        status,
        valor_pago
    )
    VALUES (
        p_participante,
        p_evento,
        var_status,
        CASE
            WHEN var_status = 'confirmada' THEN var_valor
            ELSE 0.00
        END
    );

END;
$$;


-- 2. sp_cancelar_inscricao

CREATE OR REPLACE PROCEDURE sp_cancelar_inscricao(
    p_inscricao INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    var_evento INTEGER;
    var_evento_atual INTEGER;
    var_status_atual status_inscricao;
    var_status_evento status_evento;
    var_prox_inscricao INTEGER;
    var_participante INTEGER;
BEGIN
    -- 1. Identificar o evento da inscrição
    SELECT i.evento_id
    INTO var_evento
    FROM inscricao i
    WHERE i.id = p_inscricao;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Inscrição % não encontrada.',
            p_inscricao;
    END IF;

    -- 2. Bloquear o evento durante o cancelamento
    SELECT e.status
    INTO var_status_evento
    FROM evento e
    WHERE e.id = var_evento
    FOR UPDATE;

    -- 3. Bloquear e recuperar a inscrição
    SELECT
        i.evento_id,
        i.status
    INTO
        var_evento_atual,
        var_status_atual
    FROM inscricao i
    WHERE i.id = p_inscricao
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Inscrição % não encontrada.',
            p_inscricao;
    END IF;

    -- Verificar se a inscrição continua associada ao evento
    IF var_evento_atual <> var_evento THEN
        RAISE EXCEPTION
            'A inscrição foi alterada durante a operação. Tente novamente.';
    END IF;

    -- 4. Impedir cancelamento duplicado
    IF var_status_atual = 'cancelada' THEN
        RAISE EXCEPTION
            'A inscrição % já está cancelada.',
            p_inscricao;
    END IF;

    -- 5. Cancelar a inscrição
    UPDATE inscricao
    SET status = 'cancelada'
    WHERE id = p_inscricao;

    -- 6. Só promover alguém se havia uma vaga confirmada
    -- e o evento continua aberto
    IF var_status_atual = 'confirmada'
       AND var_status_evento = 'aberto' THEN

        -- 7. Percorrer a lista de espera por ordem de chegada
        FOR var_prox_inscricao, var_participante IN
            SELECT
                i.id,
                i.participante_id
            FROM inscricao i
            WHERE i.evento_id = var_evento
              AND i.status = 'lista_espera'
            ORDER BY
                i.data_inscricao ASC,
                i.id ASC
            FOR UPDATE
        LOOP
            BEGIN
                -- 8. Promover e recalcular o valor
                UPDATE inscricao
                SET
                    status = 'confirmada',
                    valor_pago = fn_calcular_valor_inscricao(
                        var_participante,
                        var_evento
                    )
                WHERE id = var_prox_inscricao;

                RAISE NOTICE
                    'Inscrição % promovida para confirmada.',
                    var_prox_inscricao;

                -- Uma promoção bem-sucedida encerra a procedure
                RETURN;

            EXCEPTION
                WHEN raise_exception THEN
                    -- Se houver conflito, tentar o próximo candidato
                    RAISE NOTICE
                        'Inscrição % não pôde ser promovida: %',
                        var_prox_inscricao,
                        SQLERRM;
            END;
        END LOOP;

        RAISE NOTICE
            'Não há participantes elegíveis na lista de espera.';
    END IF;
END;
$$;

\encoding UTF8
-- 1. trg_valida_inscricao
DROP TRIGGER IF EXISTS trg_valida_inscricao ON inscricao;
CREATE TRIGGER trg_valida_inscricao
BEFORE INSERT OR UPDATE OF evento_id, participante_id, status
ON inscricao
FOR EACH ROW
EXECUTE FUNCTION fn_validar_inscricao();

-- 2. trg_auditoria_inscricao
CREATE TRIGGER trg_auditoria_inscricao
AFTER INSERT OR UPDATE
ON inscricao
FOR EACH ROW
EXECUTE FUNCTION fn_auditoria_inscricao();


