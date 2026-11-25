-- ============================================================
-- 1. CATEGORIAS
-- ============================================================

INSERT INTO categoria (nome) VALUES
('Tecnologia'),
('Programação'),
('Ciência'),
('Empreendedorismo'),
('Educação'),
('Segurança da Informação'),
('Inteligência Artificial'),
('Desenvolvimento Web');


-- ============================================================
-- 2. LOCAIS
-- ============================================================

INSERT INTO local (nome, capacidade) VALUES
('Auditório Central', 200),
('Laboratório de Informática 1', 40),
('Laboratório de Informática 2', 30),
('Sala de Conferências', 100),
('Sala Multimídia', 50),
('Espaço Maker', 25);


-- ============================================================
-- 3. EVENTOS
-- ============================================================

INSERT INTO evento (
    titulo,
    categoria_id,
    local_id,
    data_inicio,
    data_fim,
    vagas,
    valor_base,
    status
) VALUES
(
    'Semana de Tecnologia 2026',
    1,
    1,
    '2026-12-10 08:00:00',
    '2026-12-10 18:00:00',
    150,
    0.00,
    'aberto'
),
(
    'Introdução à Programação com Python',
    2,
    2,
    '2026-12-12 09:00:00',
    '2026-12-12 12:00:00',
    40,
    25.00,
    'aberto'
),
(
    'Inteligência Artificial na Atualidade',
    7,
    4,
    '2026-12-15 14:00:00',
    '2026-12-15 17:00:00',
    80,
    50.00,
    'aberto'
),
(
    'Hackathon de Desenvolvimento Web',
    8,
    3,
    '2026-12-18 08:00:00',
    '2026-12-19 18:00:00',
    30,
    35.00,
    'aberto'
),
(
    'Segurança Digital para Iniciantes',
    6,
    5,
    '2026-12-20 14:00:00',
    '2026-12-20 16:00:00',
    50,
    20.00,
    'aberto'
),
(
    'Workshop de Banco de Dados',
    2,
    2,
    '2026-12-22 08:00:00',
    '2026-12-22 12:00:00',
    40,
    30.00,
    'aberto'
),
(
    'Feira de Inovação e Empreendedorismo',
    4,
    1,
    '2026-12-26 10:00:00',
    '2026-12-26 18:00:00',
    180,
    10.00,
    'aberto'
),
(
    'Ciência e Tecnologia no Cotidiano',
    3,
    4,
    '2026-12-28 09:00:00',
    '2026-12-28 11:00:00',
    70,
    15.00,
    'aberto'
),
(
    'Git e GitHub na Prática',
    2,
    6,
    '2026-12-30 14:00:00',
    '2026-12-30 17:00:00',
    25,
    0.00,
    'aberto'
),
(
    'Palestra: O Futuro da Computação',
    1,
    1,
    '2027-01-10 19:00:00',
    '2027-01-10 21:00:00',
    150,
    45.00,
    'aberto'
);


-- ============================================================
-- 4. PARTICIPANTES
-- ============================================================

INSERT INTO participante (nome, email, tipo) VALUES
('Lucas Oliveira', 'lucas.oliveira@email.com', 'estudante'),
('Ana Souza', 'ana.souza@email.com', 'estudante'),
('Pedro Henrique', 'pedro.henrique@email.com', 'estudante'),
('Mariana Costa', 'mariana.costa@email.com', 'estudante'),
('Gabriel Almeida', 'gabriel.almeida@email.com', 'estudante'),
('Julia Martins', 'julia.martins@email.com', 'estudante'),
('Rafael Ferreira', 'rafael.ferreira@email.com', 'estudante'),
('Beatriz Santos', 'beatriz.santos@email.com', 'estudante'),
('Carlos Eduardo', 'carlos.eduardo@email.com', 'estudante'),
('Camila Rodrigues', 'camila.rodrigues@email.com', 'estudante'),
('Roberto Mendes', 'roberto.mendes@email.com', 'professor'),
('Fernanda Lima', 'fernanda.lima@email.com', 'professor'),
('Paulo Ricardo', 'paulo.ricardo@email.com', 'professor'),
('Aline Barbosa', 'aline.barbosa@email.com', 'professor'),
('Bruno Carvalho', 'bruno.carvalho@email.com', 'externo'),
('Leticia Gomes', 'leticia.gomes@email.com', 'externo'),
('Thiago Pereira', 'thiago.pereira@email.com', 'externo'),
('Isabela Nunes', 'isabela.nunes@email.com', 'externo'),
('Daniel Rocha', 'daniel.rocha@email.com', 'externo'),
('Eduarda Freitas', 'eduarda.freitas@email.com', 'externo');


-- ============================================================
-- 5. INSCRIÇÕES
-- ============================================================

INSERT INTO inscricao (
    participante_id,
    evento_id,
    status,
    valor_pago
) VALUES

-- Semana de Tecnologia
(1, 1, 'confirmada', 0.00),
(2, 1, 'confirmada', 0.00),
(3, 1, 'confirmada', 0.00),
(11, 1, 'confirmada', 0.00),
(15, 1, 'confirmada', 0.00),

-- Introdução à Programação com Python
(1, 2, 'confirmada', 25.00),
(4, 2, 'confirmada', 25.00),
(5, 2, 'confirmada', 25.00),
(6, 2, 'confirmada', 25.00),
(11, 2, 'confirmada', 25.00),
(15, 2, 'lista_espera', 0.00),

-- Inteligência Artificial na Atualidade
(2, 3, 'confirmada', 50.00),
(7, 3, 'confirmada', 50.00),
(8, 3, 'confirmada', 50.00),
(12, 3, 'confirmada', 50.00),
(16, 3, 'lista_espera', 0.00),

-- Hackathon de Desenvolvimento Web
(3, 4, 'confirmada', 35.00),
(4, 4, 'confirmada', 35.00),
(5, 4, 'confirmada', 35.00),
(6, 4, 'confirmada', 35.00),
(7, 4, 'confirmada', 35.00),
(8, 4, 'lista_espera', 0.00),

-- Segurança Digital para Iniciantes
(9, 5, 'confirmada', 20.00),
(10, 5, 'confirmada', 20.00),
(13, 5, 'confirmada', 20.00),
(17, 5, 'confirmada', 20.00),
(18, 5, 'cancelada', 0.00),

-- Workshop de Banco de Dados
(1, 6, 'confirmada', 30.00),
(2, 6, 'confirmada', 30.00),
(9, 6, 'confirmada', 30.00),
(11, 6, 'confirmada', 30.00),
(19, 6, 'lista_espera', 0.00),

-- Feira de Inovação e Empreendedorismo
(3, 7, 'confirmada', 10.00),
(10, 7, 'confirmada', 10.00),
(12, 7, 'confirmada', 10.00),
(14, 7, 'confirmada', 10.00),
(20, 7, 'confirmada', 10.00),

-- Ciência e Tecnologia no Cotidiano
(5, 8, 'confirmada', 15.00),
(6, 8, 'confirmada', 15.00),
(13, 8, 'confirmada', 15.00),
(16, 8, 'lista_espera', 0.00),

-- Git e GitHub na Prática
(7, 9, 'confirmada', 0.00),
(8, 9, 'confirmada', 0.00),
(9, 9, 'confirmada', 0.00),
(14, 9, 'confirmada', 0.00),

-- Palestra: O Futuro da Computação
(1, 10, 'confirmada', 45.00),
(10, 10, 'confirmada', 45.00),
(15, 10, 'confirmada', 45.00),
(17, 10, 'lista_espera', 0.00);


-- ============================================================
-- 6. LOG_INSCRICAO
-- ============================================================
-- Exemplos de registros de auditoria.
-- O status_anterior será NULL para novas inscrições.

INSERT INTO log_inscricao (
    inscricao_id,
    status_anterior,
    status_novo,
    data_hora,
    usuario
) VALUES
(1, NULL, 'confirmada', '2026-11-20 10:00:00', 'postgres'),
(2, NULL, 'confirmada', '2026-11-20 10:05:00', 'postgres'),
(3, NULL, 'confirmada', '2026-11-20 10:10:00', 'postgres'),
(6, NULL, 'confirmada', '2026-11-20 11:00:00', 'postgres'),
(11, NULL, 'lista_espera', '2026-11-20 11:30:00', 'postgres'),
(12, NULL, 'confirmada', '2026-11-20 12:00:00', 'postgres'),
(17, NULL, 'confirmada', '2026-11-20 13:00:00', 'postgres'),
(22, NULL, 'lista_espera', '2026-11-20 14:00:00', 'postgres'),
(26, NULL, 'cancelada', '2026-11-20 15:00:00', 'postgres'),
(30, NULL, 'confirmada', '2026-11-20 16:00:00', 'postgres');
