Prova ifbet testes · SQL
-- =====================================================================
--  Testes das Questões 1, 2 e 3 da prova
--  Pré-requisitos: ifbet_resolucao.sql, ifbet_dados_exemplo.sql e
--  prova_ifbet_resolucao.sql já carregados.
--
--  Tudo roda dentro de BEGIN ... ROLLBACK, então os dados de teste
--  não ficam gravados no banco.
--
--  Jogos usados (dados de exemplo):
--    jogo 1 e 2 = em aberto (sem placar)
--    jogo 5     = encerrado: BRASIL 1 x 0 SAO PAULO DE RG
-- =====================================================================
 
\set VERBOSITY terse
BEGIN;
 
-- Apostas de teste (placar previsto em gols_casa x gols_visitante)
INSERT INTO aposta (id_usuario, id_jogo, valor, odd, gols_casa, gols_visitante) VALUES
    -- jogo 5 (encerrado, 1 x 0)
    (1, 5, 50, 2.0, 1, 0),   -- usuário 1: acerto EXATO
    (1, 5, 30, 2.0, 2, 0),   -- usuário 1: acerto de RESULTADO (casa vence)
    (2, 5, 20, 2.0, 0, 0),   -- usuário 2: previu empate  -> sem acerto
    (2, 5, 20, 2.0, 0, 1),   -- usuário 2: previu visitante -> sem acerto
    (3, 5, 10, 2.0, 2, 1),   -- usuário 3: acerto de RESULTADO
    -- jogos em aberto
    (1, 1, 100, 2.0, 2, 1),
    (1, 1,  50, 2.0, 1, 1),
    (2, 1,  25, 2.0, 0, 1),
    (1, 2,  10, 2.0, 1, 0);
 
-- '=== QUESTÃO 1: jogo 5 (encerrado) ==='
-- 'Esperado: usuário 1 -> 1 exato, 1 resultado, 2 apostas'
-- '          usuário 2 -> 0, 0, 2   |   usuário 3 -> 0, 1, 1'
SELECT * FROM relatorio_acertos_jogo(5);
 
-- '=== QUESTÃO 1: jogo 1 (em aberto) e jogo 9999 (inexistente) -> 0 linhas ==='
SELECT * FROM relatorio_acertos_jogo(1);
SELECT * FROM relatorio_acertos_jogo(9999);
 
-- '=== QUESTÃO 3: auditoria de pendentes ==='
-- 'Esperado: jogo 1 -> 3 apostas, total 175,00, 2 usuários'
-- '          jogo 2 -> 1 aposta,  total 10,00,  1 usuário  (jogo 5 não aparece)'
-- '(o símbolo da moeda do tipo MONEY depende do lc_monetary do servidor)'
SELECT * FROM auditoria_apostas_pendentes();
 
-- '=== QUESTÃO 2: cancelamento (usuário 1, jogo 1) ==='
SELECT id, saldo FROM usuario WHERE id = 1;
CALL cancelar_apostas_usuario_jogo(1, 1);        -- cancela 2 apostas (R$ 150,00)
SELECT id, saldo FROM usuario WHERE id = 1;      -- saldo + 150
SELECT id_jogo, id_usuario, valor FROM aposta WHERE id_usuario = 1 AND id_jogo = 1;  -- 0 linhas
 
-- '=== QUESTÃO 2: sem apostas correspondentes (NOTICE) ==='
CALL cancelar_apostas_usuario_jogo(1, 1);
 
-- '=== QUESTÃO 2: casos de erro (esperados) ==='
DO $$ BEGIN CALL cancelar_apostas_usuario_jogo(9999, 1);
EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'Erro esperado: %', SQLERRM; END $$;
 
DO $$ BEGIN CALL cancelar_apostas_usuario_jogo(1, 9999);
EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'Erro esperado: %', SQLERRM; END $$;
 
DO $$ BEGIN CALL cancelar_apostas_usuario_jogo(1, 5);
EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'Erro esperado: %', SQLERRM; END $$;
 
-- '=== QUESTÃO 3 de novo: o jogo 1 perdeu as apostas do usuário 1 ==='
-- 'Esperado: jogo 1 -> 1 aposta, R$ 25,00, 1 usuário; jogo 2 -> 1 aposta, R$ 10,00'
SELECT * FROM auditoria_apostas_pendentes();
 
ROLLBACK;
 
