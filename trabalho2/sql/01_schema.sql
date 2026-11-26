\encoding UTF8
CREATE DATABASE sistemas_eventos_inscricoes;
\c sistemas_eventos_inscricoes
\encoding UTF8

-- Tipos enumerados
CREATE TYPE status_evento     AS ENUM ('aberto', 'encerrado', 'cancelado');
CREATE TYPE tipo_participante AS ENUM ('estudante', 'professor', 'externo');
CREATE TYPE status_inscricao  AS ENUM ('confirmada', 'lista_espera', 'cancelada');

-- Tabelas
CREATE TABLE categoria (
    id   SERIAL PRIMARY KEY,
    nome VARCHAR(200) NOT NULL UNIQUE
);

CREATE TABLE local (
    id         SERIAL PRIMARY KEY,
    nome       VARCHAR(200) NOT NULL,
    capacidade INTEGER NOT NULL CHECK (capacidade > 0)
);

CREATE TABLE evento (
    id           SERIAL PRIMARY KEY,
    titulo       VARCHAR(100) NOT NULL,
    categoria_id INTEGER NOT NULL REFERENCES categoria(id),
    local_id     INTEGER NOT NULL REFERENCES local(id),
    data_inicio  TIMESTAMP NOT NULL,
    data_fim     TIMESTAMP NOT NULL,
    vagas        INTEGER NOT NULL CHECK (vagas > 0),
    valor_base   NUMERIC(10,2) NOT NULL CHECK (valor_base >= 0),
    status       status_evento NOT NULL DEFAULT 'aberto',
    CONSTRAINT ck_evento_datas CHECK (data_fim > data_inicio)
);

CREATE TABLE participante (
    id    SERIAL PRIMARY KEY,
    nome  VARCHAR(200) NOT NULL,
    email VARCHAR(200) NOT NULL UNIQUE,
    tipo  tipo_participante NOT NULL
);

CREATE TABLE inscricao (
    id              SERIAL PRIMARY KEY,
    participante_id INTEGER NOT NULL REFERENCES participante(id) ON DELETE RESTRICT,
    evento_id       INTEGER NOT NULL REFERENCES evento(id)       ON DELETE RESTRICT,
    data_inscricao  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status          status_inscricao NOT NULL,
    valor_pago      NUMERIC(10,2) NOT NULL CHECK (valor_pago >= 0)
);

-- Impede inscrição duplicada ativa, mas permite reinscrever após cancelar
CREATE UNIQUE INDEX uq_inscricao_ativa
    ON inscricao (participante_id, evento_id)
    WHERE status <> 'cancelada';

-- Acelera a contagem de vagas por evento
CREATE INDEX idx_inscricao_evento_status
    ON inscricao (evento_id, status);

CREATE TABLE log_inscricao (
    id              SERIAL PRIMARY KEY,
    inscricao_id    INTEGER NOT NULL REFERENCES inscricao(id) ON DELETE RESTRICT,
    status_anterior status_inscricao,           -- NULL quando é a criação
    status_novo     status_inscricao NOT NULL,
    data_hora       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usuario         VARCHAR(100) NOT NULL DEFAULT current_user
);

CREATE INDEX idx_log_inscricao ON log_inscricao (inscricao_id);


