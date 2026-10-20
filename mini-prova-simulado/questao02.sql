-- Questão 2 (1,5 ponto) – Registro de palpite com validações

-- Implemente a procedure.

-- registrar_palpite(
--     var_usuario_id      INTEGER,
--     var_jogo_id         INTEGER,
--     var_valor           NUMERIC,
--     var_odd             NUMERIC,
--     var_gols_casa       INTEGER,
--     var_gols_visitante  INTEGER
-- )

-- A procedure deve registrar uma nova aposta do usuário no jogo informado, debitando o valor apostado do saldo do usuário.
-- Requisitos

--     Verifique se o valor é maior que zero, se a odd é maior que 1 e se os gols previstos são informados e não negativos. Em caso de violação, interrompa com RAISE EXCEPTION e uma mensagem clara.
--     Verifique se o usuário e o jogo existem.
--     Não permita apostar em jogo já encerrado.
--     Não permita a operação se o usuário não tiver saldo suficiente.
--     Cada usuário pode ter no máximo 3 apostas por jogo. Se o limite já foi atingido, a aposta não deve ser registrada.
--     Quando todas as validações passarem, debite o valor do saldo e insira a aposta com o placar previsto.
--     Ao final, informe com RAISE NOTICE o identificador da aposta criada e o novo saldo do usuário.
--     Se qualquer validação falhar, nenhuma alteração deve permanecer no banco.

CREATE OR REPLACE PROCEDURE registrar_palpite(
    var_usuario_id INTEGER,
    var_valor NUMERIC,
    var_jogo_id INTEGER,
    var_gols_casa INTEGER,
    var_gols_visitante INTEGER,
    var_odd REAL
)
LANGUAGE plpgsql
AS $$
BEGIN

    -- 1. Validando a Existência de um Usuário
    PERFORM 1 FROM usuario u WHERE u.id = var_usuario_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Usuário % Não Existe !', var_usuario_id;
    END IF;

    -- 2. Validando a Existência do Jogo
    PERFORM
        j.gols_da_casa,
        j.gols_do_visitante
    FROM jogo j
    WHERE j.id = var_jogo_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Jogo % Não Existe !', var_jogo_id;
    END IF;

    -- 3. Jogo Existe, porém, ele está encerrado
    PERFORM 1
    FROM jogo j
    WHERE j.id = var_jogo_id AND j.data_hora > NOW();

    IF NOT FOUND THEN
        RAISE EXCEPTION 'O jogo % Não aceita mais apostas !', var_jogo_id;
    END IF;

    -- 4. Validando o Saldo do usuário
    PERFORM
        u.id,
        u.saldo
    FROM usuario u
    WHERE u.id = var_usuario_id AND u.saldo::NUMERIC >= var_valor;

    IF NOT FOUND THEN
        RAISE NOTICE 'Usuário % Não Possui Saldo Suficiente para Realizar Essa Aposta !', var_usuario_id;
    END IF;

    -- 5. Validando o Limite de Apostas por Usuário e Jogo
    IF (
        SELECT COUNT(*)
        FROM aposta a
        WHERE a.usuario = var_usuario_id AND a.jogo_id = var_jogo_id 
    ) >= 3 THEN
        RAISE EXCEPTION
            'Usuário % Já Atingiu o Limite de 3 aposta no Jogo %',
            var_usuario_id,
            var_jogo_id;
    END IF;


    -- 6. Validando Parâmetros da Aposta
    IF var_valor IS NULL OR var_valor <= 0 THEN
        RAISE EXCEPTION 'O valor da aposta deve ser maior que zero.';
    END IF;

    IF var_odd IS NULL OR var_odd <= 1 THEN
        RAISE EXCEPTION 'A odd deve ser maior que 1.';
    END IF;

    IF var_gols_casa IS NULL OR var_gols_casa < 0 OR var_gols_visitante IS NULL OR var_gols_visitante < 0 THEN
        RAISE EXCEPTION 'Os gols previstos devem ser informados e não negativos.';
    END IF;

    -- 7. Criando uma Nova Aposta
    INSERT INTO aposta (usuario_id, valor, jogo_id, gols_da_casa, gols_do_visitante, odd) VALUES
    (var_usuario_id, var_valor::MONEY, var_jogo_id, var_gols_casa, var_gols_visitante, var_odd);

    RAISE NOTICE 'Aposta Criada Com Sucesso';
END;
$$;
-- CALL registrar_palpite(2, 500.00, 4, 2, 1, 0.25);
