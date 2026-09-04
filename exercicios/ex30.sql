-- Crie uma procedure encerrar_jogo(jogo_id, gols_casa, gols_visitante).
-- A procedure deverá:
--     - atualizar o resultado do jogo;
--     - identificar apostas vencedoras;
--     - calcular prêmio:
--     > prêmio = valor / odd <
--     - creditar o saldo dos vencedores.

CREATE OR REPLACE PROCEDURE encerrar_jogo(
    p_jogo_id integer,
    p_gols_casa integer,
    p_gols_visitante integer
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_jogo RECORD;
    v_aposta RECORD;
    v_premio money;
    v_equipe_vencedora_id integer;  -- NULL = empate
    v_total_premios money := 0::money;
BEGIN
    /*
       PASSO 1: Ler os dados do jogo e verificar se existe e não está encerrado.
       FOR UPDATE trava a linha para evitar concorrência.
    */
    SELECT * INTO v_jogo
    FROM jogo
    WHERE id = p_jogo_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Jogo % não encontrado', p_jogo_id;
    END IF;

    IF v_jogo.encerrado THEN
        RAISE EXCEPTION 'O jogo % já foi encerrado anteriormente', p_jogo_id;
    END IF;

    /*
       PASSO 2: Atualizar o placar e marcar como encerrado.
    */
    UPDATE jogo
    SET gols_casa = p_gols_casa,
        gols_visitante = p_gols_visitante,
        encerrado = TRUE
    WHERE id = p_jogo_id;

    /*
       PASSO 3: Determinar o vencedor do jogo.
       Se empate, v_equipe_vencedora_id permanece NULL.
    */
    IF p_gols_casa > p_gols_visitante THEN
        v_equipe_vencedora_id := v_jogo.equipe_casa_id;
    ELSIF p_gols_visitante > p_gols_casa THEN
        v_equipe_vencedora_id := v_jogo.equipe_visitante_id;
    END IF;

    /*
       PASSO 4: Iterar sobre as apostas ativas deste jogo.
       Se o usuário acertou o time vencedor (ou empate), calcula o prêmio.
    */
    FOR v_aposta IN
        SELECT a.id, a.usuario_id, a.valor, a.odd, a.equipe_apostada_id
        FROM aposta a
        WHERE a.jogo_id = p_jogo_id
          AND a.status = 'ativa'
    LOOP
        /*
           Regra de vitória:
           - Se houve empate (v_equipe_vencedora_id IS NULL),
             apenas quem apostou em empate ganha (se o sistema permitir).
           - Se houve vencedor, quem apostou na equipe vencedora ganha.

           Simplificação: consideramos que equipe_apostada_id = NULL representa empate,
           ou que o usuário apostou em um dos times.
        */
        IF (
            v_equipe_vencedora_id IS NULL AND v_aposta.equipe_apostada_id IS NULL
        ) OR (
            v_equipe_vencedora_id IS NOT NULL 
            AND v_aposta.equipe_apostada_id = v_equipe_vencedora_id
        ) THEN
            /*
               Cálculo do prêmio: valor / odd
               odd é real (float), então convertemos para numeric para divisão segura.
            */
            v_premio := v_aposta.valor::numeric / v_aposta.odd::numeric;

            /*
               Credita o prêmio no saldo do usuário.
            */
            UPDATE usuario
            SET saldo = saldo + v_premio::money
            WHERE id = v_aposta.usuario_id;

            /*
               Atualiza a aposta como vencida.
            */
            UPDATE aposta
            SET status = 'vencida'
            WHERE id = v_aposta.id;

            v_total_premios := v_total_premios + v_premio::money;

            RAISE NOTICE 'Usuário % venceu! Prêmio: % (odd: %)', 
                v_aposta.usuario_id, v_premio, v_aposta.odd;
        ELSE
            /*
               Apostas perdedoras.
            */
            UPDATE aposta
            SET status = 'perdida'
            WHERE id = v_aposta.id;
        END IF;
    END LOOP;

    COMMIT;

    RAISE NOTICE 'Jogo % encerrado. Placar: % x %. Total em prêmios: %',
        p_jogo_id, p_gols_casa, p_gols_visitante, v_total_premios;
END;
$$;
