-- Exercício 8 – Situação do usuário
-- Crie uma função:
-- situacao_usuario(usuario_id)
-- que retorne:
-- ATIVO
-- INATIVO

-- ALterando a Tabela
ALTER TABLE usuario ADD COLUMN status BOOLEAN default TRUE;

CREATE OR REPLACE FUNCTION situacao_usuario(var_usuario_id INTEGER) RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    var_status BOOLEAN;
    situacao TEXT;
BEGIN
    SELECT status
    INTO var_status
    FROM usuario
    WHERE id = var_usuario_id;

    IF NOT FOUND THEN
        RETURN 'USUARIO NAO EXISTE';
    END IF;

    CASE
        WHEN var_status = TRUE THEN
            situacao := 'ATIVO';

        ELSE
            situacao := 'INATIVO';
    END CASE;

    RETURN situacao;
END;
$$;
