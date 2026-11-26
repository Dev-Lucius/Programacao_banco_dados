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

