-- Crie uma procedure cancelar_aposta(aposta_id).
-- Regras:
--     devolver o valor ao usuário;
--     excluir a aposta.
CREATE OR REPLACE PROCEDURE cancelar_aposta(
    p_aposta_id integer
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_usuario_id integer;
    v_valor money;
    v_status text;
BEGIN
    /*
       PASSO 1: Ler os dados da aposta ANTES de excluir.
       Se fizermos DELETE primeiro, perdemos a referência do valor e do usuário.
       Usamos SELECT INTO com múltiplas variáveis.
    */
    SELECT usuario_id, valor, status
    INTO v_usuario_id, v_valor, v_status
    FROM aposta
    WHERE id = p_aposta_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Aposta % não encontrada', p_aposta_id;
    END IF;

    /*
       Regra de negócio: não cancelar apostas já encerradas ou canceladas.
       Evita devolver dinheiro de apostas já processadas.
    */
    IF v_status IN ('cancelada', 'vencida', 'perdida') THEN
        RAISE EXCEPTION 'Não é possível cancelar uma aposta com status "%"', v_status;
    END IF;

    /*
       PASSO 2: Devolver o valor ao saldo do usuário.
    */
    UPDATE usuario
    SET saldo = saldo + v_valor
    WHERE id = v_usuario_id;

    /*
       PASSO 3: Excluir a aposta (ou marcar como cancelada).
       O enunciado pede "excluir", então usamos DELETE.
       Se preferir auditoria, poderia ser UPDATE status = 'cancelada'.
    */
    DELETE FROM aposta WHERE id = p_aposta_id;

    COMMIT;

    RAISE NOTICE 'Aposta % cancelada. Valor % devolvido ao usuário %', 
        p_aposta_id, v_valor, v_usuario_id;
END;
$$;
