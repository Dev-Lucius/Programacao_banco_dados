-- =====================================================================
--  IFBET – Dados de exemplo (OPCIONAL)
--  Execute somente se o seu banco estiver vazio. Depois de
--  ifbet_resolucao.sql e antes de ifbet_testes.sql.
--
--  psql -U postgres -d ifbet -f ifbet_dados_exemplo.sql
-- =====================================================================

INSERT INTO usuario (nome, email, saldo, ativo) VALUES
    ('Igor',   'igor@exemplo.com',   1000.00, TRUE),    -- id 1
    ('Maria',  'maria@exemplo.com',  1500.00, TRUE),    -- id 2
    ('Joao',   'joao@exemplo.com',     50.00, TRUE),    -- id 3
    ('Ana',    'ana@exemplo.com',     300.00, FALSE),   -- id 4 (inativa, com saldo)
    ('Carlos', 'carlos@exemplo.com',    0.00, TRUE);    -- id 5 (sem saldo)

INSERT INTO equipe (nome, local) VALUES
    ('SAO PAULO DE RG', 'Rio Grande'),   -- id 1
    ('RIO GRANDE',      'Rio Grande'),   -- id 2
    ('PELOTAS',         'Pelotas'),      -- id 3
    ('BRASIL',          'Pelotas');      -- id 4

-- Jogos em aberto (ids 1 a 4)
INSERT INTO jogo (id_casa, id_visitante, data_jogo) VALUES
    (1, 2, now() + interval '1 day'),    -- id 1: SAO PAULO DE RG x RIO GRANDE
    (3, 4, now() + interval '2 days'),   -- id 2: PELOTAS x BRASIL
    (2, 3, now() + interval '3 days'),   -- id 3: RIO GRANDE x PELOTAS
    (1, 4, now() + interval '4 days');   -- id 4: SAO PAULO DE RG x BRASIL

-- Um jogo já encerrado (id 5), para a classificação e a artilharia
INSERT INTO jogo (id_casa, id_visitante, data_jogo, gols_casa, gols_visitante, encerrado) VALUES
    (4, 1, now() - interval '1 day', 1, 0, TRUE);   -- BRASIL 1 x 0 SAO PAULO DE RG

-- Alguns registros no extrato, para o Desafio 2
INSERT INTO transacao (id_usuario, tipo, valor, descricao) VALUES
    (1, 'DEPOSITO', 1000.00, 'Saldo inicial'),
    (2, 'DEPOSITO', 1500.00, 'Saldo inicial'),
    (3, 'DEPOSITO',   50.00, 'Saldo inicial'),
    (4, 'DEPOSITO',  300.00, 'Saldo inicial');
