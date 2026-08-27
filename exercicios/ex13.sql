-- Crie uma função apostas_usuario(usuario_id) que retorne uma tabela contendo:
--   *  id da aposta
--   *  valor
--   *  odd
CREATE OR REPLACE FUNCTION apostas_usuario(var_usuario_id INTEGER)
RETURNS TABlE(
    var_id INTEGER, 
    var_valor MONEY, 
    var_odd REAL)
LANGUAGE plpgsql
AS $$
BEGIN
    -- RETURN QUERY --> Devolve um resultado do Select Como uma Tabela!
    RETURN QUERY
    SELECT
        a.id,    -- preenche a coluna aposta_id
        a.valor, -- preenche a coluna aposta_valor
        a.odd    -- preenche a coluna aposta_odd
    FROM aposta a
    WHERE a.usuario_id = var_usuario_id;

    -- Se não encontrar nada
    -- vamos retornar uma tabela vazia
    RETURN;
END;
$$;
