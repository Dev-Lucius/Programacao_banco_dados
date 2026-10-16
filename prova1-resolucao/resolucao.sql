-- =====================================================================
--  Programação em Banco de Dados – Atividade Avaliada 1º Bimestre
--  Resolução das Questões 1, 2 e 3 (IFBET)
--
--  Pré-requisito: o esquema de ifbet_resolucao.sql já carregado
--  (tabelas usuario, equipe, jogo, aposta e as funções de apoio).
--
--  Regras do enunciado aplicadas aqui:
--    * Jogo ENCERRADO  = gols_casa E gols_visitante preenchidos (NOT NULL).
--      (a coluna jogo.encerrado do esquema anterior NÃO é usada na prova)
--    * Os gols guardados em APOSTA são o PALPITE do usuário.
-- =====================================================================


-- ---------------------------------------------------------------------
-- Ajuste de esquema: placar previsto na aposta.
-- O esquema anterior só tinha o palpite C/E/V; a prova trabalha com o
-- placar previsto. Se o seu script de aula já tem essas colunas, ignore.
-- ---------------------------------------------------------------------
ALTER TABLE aposta ADD COLUMN IF NOT EXISTS gols_casa      INT;
ALTER TABLE aposta ADD COLUMN IF NOT EXISTS gols_visitante INT;


-- =====================================================================
-- QUESTÃO 1 (1,5 ponto) – Relatório de acertos por usuário em um jogo
--
--  * Acerto exato     : placar previsto = placar real
--  * Acerto resultado : placar diferente, mas mesmo desfecho
--                       (vitória da casa, empate ou vitória do visitante)
--  * Jogo inexistente ou não encerrado: nenhuma linha.
--
--  SIGN(gols_casa - gols_visitante) vale 1 (casa vence), 0 (empate) ou
--  -1 (visitante vence); comparar o SIGN do palpite com o do placar
--  real compara os desfechos.
-- =====================================================================
CREATE OR REPLACE FUNCTION relatorio_acertos_jogo(var_jogo_id INTEGER)
RETURNS TABLE (
    usuario_id        INTEGER,
    nome_usuario      TEXT,
    acertos_exatos    BIGINT,
    acertos_resultado BIGINT,
    total_apostas     BIGINT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT u.id,
           u.nome::TEXT,
           -- acerto exato
           COUNT(*) FILTER (
               WHERE a.gols_casa      = j.gols_casa
                 AND a.gols_visitante = j.gols_visitante
           ),
           -- acerto do resultado, sem recontar os exatos
           COUNT(*) FILTER (
               WHERE (a.gols_casa <> j.gols_casa OR a.gols_visitante <> j.gols_visitante)
                 AND SIGN(a.gols_casa - a.gols_visitante) = SIGN(j.gols_casa - j.gols_visitante)
           ),
           -- todas as apostas do usuário no jogo
           COUNT(*)
      FROM aposta a
      JOIN jogo    j ON j.id = a.id_jogo
      JOIN usuario u ON u.id = a.id_usuario
     WHERE j.id = var_jogo_id
       AND j.gols_casa      IS NOT NULL      -- jogo encerrado
       AND j.gols_visitante IS NOT NULL
     GROUP BY u.id, u.nome
     ORDER BY u.id;
END;
$$;
-- SELECT * FROM relatorio_acertos_jogo(5);


-- =====================================================================
-- QUESTÃO 2 (1,5 ponto) – Cancelamento em lote das apostas de um
--                         usuário para um jogo
-- =====================================================================
CREATE OR REPLACE PROCEDURE cancelar_apostas_usuario_jogo(
    var_usuario_id INTEGER,
    var_jogo_id    INTEGER
)
LANGUAGE plpgsql AS $$
DECLARE
    var_gols_casa       INTEGER;
    var_gols_visitante  INTEGER;
    registro            RECORD;
    var_canceladas      INTEGER := 0;
    var_total_devolvido NUMERIC := 0;
BEGIN
    -- 1. o usuário existe?
    PERFORM 1 FROM usuario u WHERE u.id = var_usuario_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Usuário % não existe', var_usuario_id;
    END IF;

    -- 2. o jogo existe? (aproveita para ler o placar real)
    SELECT j.gols_casa, j.gols_visitante
      INTO var_gols_casa, var_gols_visitante
      FROM jogo j
     WHERE j.id = var_jogo_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Jogo % não existe', var_jogo_id;
    END IF;

    -- 3. jogo encerrado (placar completo) não permite cancelamento
    IF var_gols_casa IS NOT NULL AND var_gols_visitante IS NOT NULL THEN
        RAISE EXCEPTION 'O jogo % já foi encerrado; não é possível cancelar apostas', var_jogo_id;
    END IF;

    -- 4. para cada aposta: devolver o valor ao saldo e remover a aposta
    FOR registro IN
        SELECT a.id, a.valor
          FROM aposta a
         WHERE a.id_usuario = var_usuario_id
           AND a.id_jogo    = var_jogo_id
         ORDER BY a.id
    LOOP
        UPDATE usuario
           SET saldo = saldo + registro.valor
         WHERE id = var_usuario_id;

        DELETE FROM aposta WHERE id = registro.id;

        -- (opcional) registrar o estorno no extrato do esquema anterior:
        -- INSERT INTO transacao (id_usuario, tipo, valor, descricao)
        -- VALUES (var_usuario_id, 'ESTORNO', registro.valor, 'Cancelamento da aposta ' || registro.id);

        var_canceladas      := var_canceladas + 1;
        var_total_devolvido := var_total_devolvido + registro.valor;
    END LOOP;

    -- 5. mensagens finais
    IF var_canceladas = 0 THEN
        RAISE NOTICE 'O usuário % não possui apostas no jogo %', var_usuario_id, var_jogo_id;
    END IF;

    RAISE NOTICE 'Apostas canceladas: % (valor devolvido: %)', var_canceladas, var_total_devolvido;
END;
$$;
-- CALL cancelar_apostas_usuario_jogo(1, 1);


-- =====================================================================
-- QUESTÃO 3 (2,0 pontos) – Auditoria de apostas pendentes
--
--  * Pendente = resultado real NÃO completamente preenchido
--    (gols_casa IS NULL OU gols_visitante IS NULL).
--  * JOIN (e não LEFT JOIN) garante "pelo menos uma aposta".
--  * COUNT(DISTINCT ...) conta cada usuário uma única vez.
--  * Ordem: mais apostas primeiro; empate -> menor id do jogo.
-- =====================================================================
CREATE OR REPLACE FUNCTION auditoria_apostas_pendentes()
RETURNS TABLE (
    jogo_id             INTEGER,
    quantidade_apostas  BIGINT,
    total_apostado      MONEY,
    quantidade_usuarios BIGINT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT j.id,
           COUNT(a.id),
           SUM(a.valor)::MONEY,
           COUNT(DISTINCT a.id_usuario)
      FROM jogo j
      JOIN aposta a ON a.id_jogo = j.id
     WHERE j.gols_casa IS NULL
        OR j.gols_visitante IS NULL
     GROUP BY j.id
     ORDER BY COUNT(a.id) DESC, j.id ASC;
END;
$$;
-- SELECT * FROM auditoria_apostas_pendentes();