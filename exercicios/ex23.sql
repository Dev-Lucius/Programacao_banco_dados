-- Crie uma procedure transferir(origem, destino, valor).
CREATE OR REPLACE PROCEDURE transferir(
    p_origem integer,
    p_destino integer,
    p_valor money
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_saldo_origem money;
BEGIN
    /*
       Validação 1: origem e destino não podem ser o mesmo.
       Essa verificação evita bugs lógicos (transferir para si mesmo).
    */
    IF p_origem = p_destino THEN
        RAISE EXCEPTION 'Origem e destino não podem ser o mesmo usuário';
    END IF;

    /*
       Validação 2: verificar saldo do remetente.
       Usamos SELECT FOR UPDATE para bloquear a linha durante a transação,
       evitando race conditions (outra sessão alterando o saldo ao mesmo tempo).
    */
    SELECT saldo INTO v_saldo_origem
    FROM usuario
    WHERE id = p_origem
    FOR UPDATE;  -- trava a linha até o COMMIT/ROLLBACK

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Usuário origem % não encontrado', p_origem;
    END IF;

    IF v_saldo_origem < p_valor THEN
        RAISE EXCEPTION 'Saldo insuficiente para transferência. Saldo: %', v_saldo_origem;
    END IF;

    /*
       Execução: debitar origem e creditar destino.
       Como estamos dentro de uma única transação, as duas operações
       são atômicas: ou ambas acontecem, ou nenhuma (consistência).
    */
    UPDATE usuario SET saldo = saldo - p_valor WHERE id = p_origem;
    UPDATE usuario SET saldo = saldo + p_valor WHERE id = p_destino;

    /*
       Verifica se o destino existe (se não existir, UPDATE não afeta linhas).
    */
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Usuário destino % não encontrado', p_destino;
    END IF;

    COMMIT;

    RAISE NOTICE 'Transferência de % de % para % realizada com sucesso', 
        p_valor, p_origem, p_destino;
END;
$$;
