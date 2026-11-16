-- 1. sp_realizar_inscricao
-- Calcula o valor com fn_calcular_valor_inscricao. 
-- Se há vaga, grava a inscrição como confirmada; se não há, como lista_espera.
CREATE OR REPLACE PROCEDURE sp_realizar_inscricao(p_participante INTEGER, p_evento INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE
    var_vagas INTEGER;
    var_confirmadas BIGINT;
    var_valor NUMERIC(10, 2);
    var_status status_inscricao;
BEGIN
    -- Recupernado a Quantidade de Vagas
    SELECT
        e.vagas
    INTO
        var_vagas
    FROM evento e
    WHERE e.id = p_evento
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Evento % Não Foi Encontrado', p_evento;
    END IF;

    -- Contando as Inscrições Confirmadas
    SELECT
        COUNT(*)
    INTO 
        var_confirmadas
    FROM inscricao i
    WHERE i.status = 'confirmada' AND i.evento_id = p_evento;

    -- Confirmando se o Participante Já está inscrito no Evento
    PERFORM 1
    FROM inscricao i
    WHERE p_participante = i.participante_id AND p_evento = i.evento_id AND i.status <> 'cancelada';

    IF FOUND THEN
        RAISE EXCEPTION 'Participante % Já Está Inscrito No Evento %', p_participante, p_evento;
    END IF;

    -- Calculando o valor da Inscrição
    -- reaproveitando a função fn_calcular_valor_inscricao(integer, integer)
    var_valor := fn_calcular_valor_inscricao(p_participante, p_evento);

    -- Definindo o Status da Inscrição
    IF var_confirmadas < var_vagas THEN
        var_status := 'confirmadas';
    ELSE 
        var_status := 'lista_espera';
    END IF;

    INSERT INTO inscricao(participante_id, evento_id, status, valor_pago) 
    VALUES(p_participante, p_evento, var_status, var_valor);
END;
$$;
CALL sp_realizar_inscricao(27, 1);
-- Raise Exception
-- Participante 27 Já Está Inscrito No Evento % 1

-- 2. sp_cancelar_inscricao
CREATE OR REPLACE PROCEDURE sp_cancelar_inscricao(p_inscricao INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE
    var_evento INTEGER,
    var_status_atual status_inscricao;
    var_prox_inscricao INTEGER;
BEGIN
    -- Recuperar a Inscrição
    SELECT
        i.evento_id,
        i.status
    INTO
        var_evento,
        var_status_atual
    FROM inscricao i
    WHERE i.id = p_inscricao
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Inscrição % Não Encontrada', p_inscricao;
    END IF;

    -- Cancelando a Inscrição
    UPDATE inscricao
    SET status = 'cancelada'
    WHERE id = p_inscricao;

    -- Verificar se Precisamos Promover Alguém
    IF var_status_atual = 'confirmada' THEN
        -- Procurar prox participante
        SELECT
            i.id
        INTO 
            var_prox_inscricao
        FROM inscricao i
        WHERE 
            i.evento_id = var_evento
            AND i.status = 'lista_espera'
        ORDER BY
            i.data_inscricao ASC,
            i.id ASC
        LIMIT 1
        FOR UPDATE;
    END IF;

    -- Promovendo Participante
    IF FOUND THEN
        UPDATE inscricao
        SET status = 'confirmada'
        WHERE id = var_prox_inscricao;
    END IF;
END;
$$;