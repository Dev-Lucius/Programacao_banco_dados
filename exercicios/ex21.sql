-- Crie uma procedure depositar(usuario_id, valor) que aumente o saldo.
CREATE OR REPLACE PROCEDURE depositar(    
    p_usuario_id integer,    
    p_valor money
)
LANGUAGE plpgsql
AS $$
BEGIN    
    
    /*       
        UPDATE com operador de adição (+=) no PostgreSQL:       
        Não existe += em SQL, então fazemos saldo = saldo + p_valor.       
        O WHERE garante que apenas o usuário correto seja afetado.    
    */    
    
    UPDATE usuario    
    SET saldo = saldo + p_valor    
    WHERE id = p_usuario_id;    
    
    /*       
        FOUND é uma variável booleana automática do PL/pgSQL.       
        Ela indica se o último comando SQL afetou alguma linha.       
        Se nenhuma linha foi atualizada, o usuário não existe.    
    */    
    IF NOT FOUND THEN        
        RAISE EXCEPTION 'Usuário % não encontrado', p_usuario_id;    
    END IF;    
    
    /*       
        COMMIT é permitido dentro de PROCEDURE (não em FUNCTION).       
        Ele torna a alteração permanente imediatamente.       
        Se omitirmos, o commit ocorrerá apenas quando quem chamou a procedure       
        fizer COMMIT (se a procedure for chamada dentro de uma transação).    
    */    
    COMMIT;    
    
    RAISE NOTICE 'Depósito de % realizado para o usuário %', p_valor, p_usuario_id;
END;
$$;
