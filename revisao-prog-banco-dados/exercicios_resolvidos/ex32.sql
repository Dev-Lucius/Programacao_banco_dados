-- Exercício 32 – Somatório utilizando LOOP

-- Crie uma função que receba usuario_id e calcule o total apostado utilizando um loop.
-- Não utilize SUM().

CREATE OR REPLACE FUNCTION total_apostado_usuario(var_usuario_id INTEGER) RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    var_somatorio NUMERIC := 0;
    registro_apostas_usuario RECORD;
BEGIN
    FOR registro_apostas_usuario IN
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
        ', registro_apostas_usuario.nome, registro_apostas_usuario.saldo, registro_apostas_usuario.valor, registro_apostas_usuario.odd;

        var_somatorio = var_somatorio + registro_apostas_usuario.valor::NUMERIC AS total_apostado;
    END LOOP;

    RETURN var_somatorio;
END;
$$;

-- SELECT * FROM total_apostado_usuario(1);
-- DROP FUNCTION total_apostado_usuario(integer);
-- Total Apostado: R$ 110,00
