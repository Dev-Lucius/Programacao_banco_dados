DROP DATABASE IF EXISTS ifbet;

CREATE DATABASE ifbet;

\c ifbet;

-- Instalando a Extensão do plpgsql
CREATE EXTENSION IF NOT EXISTS plpgsql;

CREATE TABLE usuario (
    id serial primary key,
    nome character varying(200) not null,
    email character varying(200) unique not null,
    senha character varying(200) not null,
    saldo money default 0::money
);

INSERT INTO usuario (nome, email, senha, saldo) VALUES
('IGOR', 'igor.pereira@riogrande.ifrs.edu.br', md5('123'), 1000),
('ROGERIO', 'rogerio.rogerio@riogrande.ifrs.edu.br', md5('123'), 1000),
('MARCELO', 'marcelo.silva@riogrande.ifrs.edu.br', md5('123'), 1500),
('FERNANDA', 'fernanda.souza@riogrande.ifrs.edu.br', md5('123'), 800),
('GABRIEL', 'gabriel.costa@riogrande.ifrs.edu.br', md5('123'), 1200),
('MATHEUS', 'matheus.oliveira@riogrande.ifrs.edu.br', md5('123'), 500);

CREATE TABLE equipe (
    id serial primary key,
    nome text,
    local text
);
INSERT INTO equipe (nome, local) VALUES
('SAO PAULO DE RG', 'ALDO DAPUZZO'),
('RIOGRANDENSE', 'COLOSSO DO TREVO'),
('BRASIL DE PELOTAS', 'BENTO FREITAS'),
('NORTENSE', 'NÃO SEI'),
('PELOTAS', 'BOCA DO LOBO'),
('RIO GRANDE', 'ARTUR LAWSON'),
('SÃO JOSÉ', 'ESTÁDIO PASSO D''AREIA'),
('JUVENTUDE', 'ALFREDO JACONI'),
('GRÊMIO', 'ARENA DO GRÊMIO'),
('INTERNACIONAL', 'BEIRA-RIO'),
('PELOTAS FC', 'BOCA DO LOBO'),
('FARROUPILHA', 'ESTÁDIO ALDO DAPUZZO');

CREATE TABLE jogo (
    id serial primary key,
    data_hora timestamp default current_timestamp,
    equipe_casa_id integer references equipe (id),
    equipe_visitante_id integer references equipe(id),
    gols_da_casa integer,
    gols_do_visitante integer
);
INSERT INTO jogo (equipe_casa_id, equipe_visitante_id) VALUES
(1, 6, now() + interval '1 day'),
(2, 3, now() + interval '2 days'),
(4, 5, now() + interval '3 days');

-- jogo já encerrado (tem placar): NÃO deve aparecer em liste_jogos()
INSERT INTO jogo (equipe_casa_id, equipe_visitante_id, data_hora, gols_da_casa, gols_do_visitante) VALUES
(5, 2, now() - interval '2 days', 2, 1),
-- Amanhã
(1, 6, now() + interval '1 day'),

-- Em 2 dias
(2, 3, now() + interval '2 days'),

-- Em 3 dias
(4, 5, now() + interval '3 days'),

-- Em 4 dias
(7, 8, now() + interval '4 days'),

-- Em 5 dias
(9, 10, now() + interval '5 days'),

-- Em 6 dias
(11, 12, now() + interval '6 days');


CREATE TABLE aposta (
    id serial primary key,
    usuario_id integer references usuario (id),
    valor money,
    jogo_id integer references jogo (id),
    gols_da_casa integer,
    gols_do_visitante integer,
    odd real check (odd > 0 and odd <= 1) 
);

INSERT INTO aposta (usuario_id, valor, jogo_id, gols_da_casa, gols_do_visitante, odd) VALUES
(2, 100, 1, 10, 0, 0.5);

UPDATE usuario SET saldo = CAST((saldo::numeric - 100::numeric) as money) WHERE id = 2;