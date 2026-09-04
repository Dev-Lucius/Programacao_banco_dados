-- Crie uma procedure zerar_apostas_usuario(usuario_id).
CREATE OR REPLACE PROCEDURE zerar_apostas_usuario(
    p_usuario_id integer
)
LANGUAGE plpgsql
AS $$
DECLARE
    registro RECORD;
    v_total_devolvido money := 0::money;
BEGIN
    /*
       Estratégia: iterar sobre cada aposta ativa do usuário.
       Usamos FOR ... IN para criar um cursor implícito.
       Para cada aposta, devolvemos o valor e marcamos como cancelada.
    */
    FOR registro IN
        SELECT id, valor
        FROM aposta
        WHERE usuario_id = p_usuario_id
          AND status = 'ativa'
    LOOP
        /*
           Devolve o valor individual de cada aposta.
           Fazemos UPDATE acumulativo no saldo do usuário.
        */
        UPDATE usuario
        SET saldo = saldo + registro.valor
        WHERE id = p_usuario_id;

        /*
           Em vez de DELETE, usamos UPDATE para manter o histórico
           (boa prática em sistemas reais).
        */
        UPDATE aposta
        SET status = 'cancelada'
        WHERE id = registro.id;

        v_total_devolvido := v_total_devolvido + registro.valor;
    END LOOP;

    COMMIT;

    RAISE NOTICE 'Apostas do usuário % zeradas. Total devolvido: %', 
        p_usuario_id, v_total_devolvido;
END;
$$;
