-- Exercício 33 – Contagem utilizando LOOP

-- Crie uma função que conte as apostas de um usuário utilizando um loop.
-- Não utilize COUNT().

CREATE OR REPLACE FUNCTION contagem_apostas_usuarios(var_usuario_id INTEGER) RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    var_contagem INTEGER := 0;
    registro_contagem_usuarios RECORD;
BEGIN
    -- 1. Verificando se o Usuário Existe
    PERFORM 1 FROM usuario u WHERE u.id = var_usuario_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Usuário % Não Existe', var_usuario_id;
    END IF;

    -- 2. Verificando se o Usuário Tem alguma Aposta
    PERFORM 1 FROM aposta a WHERE a.usuario_id = var_usuario_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Usuário % Nunca Fez Nenhuma Aposta', var_usuario_id;
    END IF;

    FOR registro_contagem_usuarios IN
        SELECT
            u.nome,
            u.saldo,
            a.valor,
            a.odd
        FROM usuario u
        LEFT JOIN aposta a
            ON u.id = a.usuario_id
        WHERE u.id = var_usuario_id AND u.id IS NOT NULL
    LOOP
        RAISE NOTICE
        '
        Usuario: %
        Saldo: %
        Valor: %
        Odd: %
        ', registro_contagem_usuarios.nome, registro_contagem_usuarios.saldo, registro_contagem_usuarios.valor, registro_contagem_usuarios.odd;

        var_contagem = var_contagem + 1;
    END LOOP;
    RETURN var_contagem;
END;
$$;
