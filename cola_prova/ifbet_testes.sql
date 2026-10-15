-- =====================================================================
--  IFBET – Desafio 9: Validação completa (script de testes psql)
--
--  Pré-requisitos: ifbet_resolucao.sql carregado e dados de exemplo
--  (ifbet_dados_exemplo.sql) ou uma base equivalente: usuários 1 e 2
--  com saldo suficiente e o jogo 1 ainda não encerrado.
--
--  Execução: psql -U postgres -d ifbet -f ifbet_testes.sql
--  Não envolva este script em BEGIN/COMMIT: processar_apostas() usa
--  COMMIT internamente e só pode ser chamada fora de uma transação.
-- =====================================================================

\set VERBOSITY terse
\pset null '(nulo)'

\echo
\echo '=== 1. CONSULTAS INICIAIS ==================================='
SELECT obter_saldo(1)         AS saldo_usuario_1;
SELECT quantidade_apostas(1)  AS apostas_usuario_1;

\echo
\echo '=== 2. OPERAÇÕES FINANCEIRAS ================================'
CALL depositar(1, 500);
CALL sacar(1, 100);
CALL transferir(1, 2, 200);

SELECT obter_saldo(1) AS saldo_usuario_1_depois;
SELECT obter_saldo(2) AS saldo_usuario_2_depois;

\echo
\echo '=== 3. APOSTAS =============================================='
CALL criar_aposta(1, 1, 100, 2.50);

\echo
\echo '=== 4. CONSULTAS ============================================'
SELECT *
FROM ranking_apostadores();

SELECT *
FROM historico_apostas(1);

\echo
\echo '=== 5. ENCERRAMENTO DO JOGO 1 (SAO PAULO DE RG 2 x 1 RIO GRANDE) ==='
CALL encerrar_jogo(1, 2, 1);

\echo
\echo '=== 6. PROCESSAMENTO DE APOSTAS PENDENTES ==================='
CALL processar_apostas();

\echo
\echo '=== 7. CLASSIFICAÇÃO ========================================'
SELECT *
FROM classificacao_campeonato();


-- =====================================================================
--  VERIFICAÇÕES EXTRAS (opcionais)
-- =====================================================================

\echo
\echo '=== EXTRA A. Extrato e relatório do usuário 1 ==============='
SELECT * FROM extrato_usuario(1);
SELECT * FROM relatorio_usuario(1);

\echo
\echo '=== EXTRA B. Rankings e artilharia =========================='
SELECT * FROM ranking_financeiro();
SELECT * FROM artilharia();
SELECT * FROM ranking_equipes();

\echo
\echo '=== EXTRA C. Estatísticas da equipe 1 ======================='
SELECT * FROM estatisticas_equipe(1);

\echo
\echo '=== EXTRA D. Tratamento de erros (mensagens esperadas) ======'
CALL depositar_seguro(1, -10);            -- Depósito não realizado.
CALL depositar_seguro(9999, 10);          -- Depósito não realizado.
SELECT atualizar_saldo_seguro(1, -50);    -- FALSE
SELECT nome_usuario_seguro(9999);         -- USUÁRIO NÃO ENCONTRADO
SELECT calcular_odds(100, 0);             -- NULL
CALL transferir_seguro(1, 9999, 50);      -- ERRO: nada é alterado
SELECT obter_saldo(1) AS saldo_inalterado_apos_falha;

\echo
\echo '=== EXTRA E. Cancelar uma aposta em jogo aberto ============='
CALL criar_aposta(2, 2, 80, 1.90, 'E');
SELECT * FROM listar_apostas_usuario(2);
-- Troque o ID abaixo pelo ID exibido na consulta anterior:
-- CALL cancelar_aposta(2);

\echo
\echo '=== EXTRA F. Rotinas em lote e simulações ==================='
CALL limpar_usuarios_inativos();
CALL processar_bonus_lotes();
CALL simular_apostas(10);
CALL gerar_campeonato();
CALL processar_apostas();
