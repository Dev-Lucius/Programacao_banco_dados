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

