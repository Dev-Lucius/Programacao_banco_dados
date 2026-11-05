-- Exercício 42 – Alterar saldo

-- Crie:

-- alterar_saldo(usuario_id, novo_saldo)

-- que substitua o saldo atual.

-- Não permita saldo negativo.

CREATE OR REPLACE PROCEDURE alterar_saldo(usuario_id INTEGER, novo_saldo MONEY)
LANGUAGE plpgsql
AS $$
BEGIN

    -- Validando a Existência do Usuário
    PERFORM 1 FROM usuario u WHERE u.id = usuario_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Usuário % Não existe !', usuario_id;
    END IF;

    -- Validando o valor do Saldo que será substituído
    IF novo_saldo::NUMERIC < 0 THEN
        RAISE EXCEPTION 'Valor Inválido para o Saldo!';
    END IF;

    -- Fazendo a Alteração do Saldo
    UPDATE usuario u
    SET saldo = novo_saldo
    WHERE u.id = usuario_id;

    RAISE NOTICE 'Saldo do Usuáriuo % Foi Atualizado para %', usuario_id, novo_saldo;
END;
$$;
