-- Crie uma procedure bonus_todos(valor) que acrescente bônus a todos os usuários.
CREATE OR REPLACE PROCEDURE bonus_todos(
    p_valor money
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_afetados integer;
BEGIN
    /*
       UPDATE sem WHERE afeta TODAS as linhas da tabela.
       GET DIAGNOSTICS captura informações sobre o último comando SQL executado.
       ROW_COUNT nos diz quantas linhas foram modificadas.
    */
    UPDATE usuario
    SET saldo = saldo + p_valor;

    GET DIAGNOSTICS v_afetados = ROW_COUNT;

    COMMIT;

    RAISE NOTICE 'Bônus de % aplicado a % usuários', p_valor, v_afetados;
END;
$$;
