-- Crie uma procedure cadastrar_equipe(nome, local).
CREATE OR REPLACE PROCEDURE cadastrar_equipe(
    p_nome text,
    p_local text
)
LANGUAGE plpgsql
AS $$
BEGIN
    /*
       INSERT simples. Como o id é serial (auto-incremento),
       não precisamos informá-lo.
       RETURNING id INTO poderia capturar o ID gerado, mas como
       é uma procedure (não retorna valor), usamos apenas RAISE NOTICE.
    */
    INSERT INTO equipe (nome, local)
    VALUES (p_nome, p_local);

    COMMIT;

    RAISE NOTICE 'Equipe "%" de % cadastrada com sucesso', p_nome, p_local;
END;
$$;
