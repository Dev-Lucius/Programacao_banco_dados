-- Exercício 9 – Nome do usuário
-- Crie uma função: nome_usuario(usuario_id)

-- utilizando obrigatoriamente:
-- SELECT ... INTO ...

CREATE OR REPLACE FUNCTION nome_usuario(var_usuario_id INTEGER) RETURNS VARCHAR(200)
LANGUAGE plpgsql
AS $$
DECLARE
    var_nome VARCHAR(200);
BEGIN

    SELECT nome
    INTO var_nome
    FROM usuario
    WHERE id = var_usuario_id;

    RETURN var_nome;
END;
$$;
