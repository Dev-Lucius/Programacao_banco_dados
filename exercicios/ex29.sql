-- Crie uma procedure simular_apostas(quantidade) que gere apostas aleatórias utilizando a função propor_aposta().

/*
   Supondo que propor_aposta() seja uma função que retorna um registro
   com os dados necessários para criar uma aposta (usuário, jogo, valor, odd).
   Exemplo de assinatura:

   CREATE FUNCTION propor_aposta()
   RETURNS TABLE(usuario_id int, jogo_id int, valor money, odd real)
   ...
*/

CREATE OR REPLACE PROCEDURE simular_apostas(
    p_quantidade integer
)
LANGUAGE plpgsql
AS $$
DECLARE
    i integer;
    v_prop RECORD;  -- recebe o retorno da função propor_aposta()
BEGIN
    /*
       LOOP de 1 até p_quantidade.
       A cada iteração, chamamos propor_aposta() e inserimos o resultado.
    */
    FOR i IN 1..p_quantidade LOOP
        /*
           SELECT * INTO armazena a linha retornada pela função.
           Como propor_aposta() retorna TABLE, usamos LIMIT 1 para pegar uma sugestão.
        */
        SELECT * INTO v_prop
        FROM propor_aposta()
        LIMIT 1;

        /*
           Se propor_aposta() não retornar nada (ex: sem jogos disponíveis),
           v_prop ficará NULL em todos os campos. Verificamos com FOUND.
        */
        IF NOT FOUND THEN
            RAISE NOTICE 'Não há condições para gerar mais apostas na iteração %', i;
            EXIT;  -- sai do loop prematuramente
        END IF;

        /*
           Insere a aposta simulada.
           Verificamos se o usuário tem saldo (opcional, mas recomendado).
        */
        INSERT INTO aposta (usuario_id, jogo_id, valor, odd, status)
        VALUES (v_prop.usuario_id, v_prop.jogo_id, v_prop.valor, v_prop.odd, 'ativa');

        /*
           Debita o valor do saldo do usuário.
        */
        UPDATE usuario
        SET saldo = saldo - v_prop.valor
        WHERE id = v_prop.usuario_id;

    END LOOP;

    COMMIT;

    RAISE NOTICE '% apostas simuladas com sucesso', p_quantidade;
END;
$$;
