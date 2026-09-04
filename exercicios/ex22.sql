-- Crie uma procedure sacar(usuario_id, valor).
-- Regras:
--     verificar saldo;
--     impedir saldo negativo.
CREATE OR REPLACE PROCEDURE sacar(
    p_usuario_id INTEGER,
    p_valor MONEY
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_valor MONEY;
BEGIN
    -- PASSO 1°: Ler o saldo Atual do Usuário antes de Modificar
    -- SELECT INTO guarda o resultado em uma variável de escopo local
    SELECT saldo INTO v_lado
    FROM usuario
    WHERE id = p_usuario_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Usuário % Não Encontrado', p_usuario_id;
    END IF;

    -- PASSO 2°: Regras de Negócio -> Verificar se há saldo suficiente
    -- OBS -> Comparar money com money é seguro em PSQL
    IF v_saldo < p_valor THEN   
        RAISE EXCEPTION 'Saldo Insuficiente. Saldo: %, Saque Solicitado: %', p_saldo, p_valor;
    END IF;

    -- PASSO 3°: Executar o Saque apenas se passou na validação
    UPDATE usuario
    SET saldo = saldo - p_valor
    WHERE id = p_usuario_id;

    COMMIT;

    RAISE NOTICE 'Saque de % realizado. Novo saldo: %', p_valor, (v_saldo - p_valor);
END;
$$;
