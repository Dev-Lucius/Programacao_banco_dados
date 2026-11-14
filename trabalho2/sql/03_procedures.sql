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
