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

BEGIN
    -- 1. Recuperando os dados do evento
    SELECT
        e.status,
        e.data_inicio,
        e.data_fim
    INTO
        v_status_evento,
        v_data_inicio,
        v_data_fim
    FROM evento e
    WHERE e.id = NEW.evento_id;

    -- Verificando se o evento existe
    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Evento % não encontrado.',
            NEW.evento_id;
    END IF;

    -- 2. Validando o status do evento
    IF v_status_evento IN ('encerrado', 'cancelado') THEN
        RAISE EXCEPTION
            'Não é possível realizar inscrição em eventos encerrados ou cancelados.';
    END IF;

    -- 3. Verificando conflitos de horário
    IF EXISTS (
        SELECT 1
        FROM inscricao i
        INNER JOIN evento e
            ON e.id = i.evento_id
        WHERE
            i.participante_id = NEW.participante_id
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
    RETURN NULL    
END;
$$;
