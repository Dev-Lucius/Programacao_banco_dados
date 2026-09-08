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
('ROGERIO', 'rogerio.rogerio@riogrande.ifrs.edu.br', md5('123'), 1000);

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
('RIO GRANDE', 'ARTUR LAWSON');

CREATE TABLE jogo (
    id serial primary key,
    data_hora timestamp default current_timestamp,
    equipe_casa_id integer references equipe (id),
    equipe_visitante_id integer references equipe(id),
    gols_da_casa integer,
    gols_do_visitante integer
);
INSERT INTO jogo (equipe_casa_id, equipe_visitante_id) VALUES
(1, 6);


CREATE TABLE aposta (
    id serial primary key,
    usuario_id integer references usuario (id),
    valor money,
    jogo_id integer references jogo (id),
    gols_da_casa integer,
    gols_do_visitante integer,
    odd real check (odd >= 0 and odd <= 1) 
);

INSERT INTO aposta (usuario_id, valor, jogo_id, gols_da_casa, gols_do_visitante, odd) VALUES
(2, 100, 1, 10, 0, 0.5);

UPDATE usuario SET saldo = CAST((saldo::numeric - 100::numeric) as money) WHERE id = 2;