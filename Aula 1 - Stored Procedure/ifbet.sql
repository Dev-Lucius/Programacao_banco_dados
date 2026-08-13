DROP DATABASE IF EXISTS ifbet;

CREATE DATABASE ifbet;

\c ifbet;

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


--DROP FUNCTION propor_aposta;

CREATE FUNCTION propor_aposta(var_usuario_id integer, var_jogo_id integer, var_valor money) RETURNS BOOLEAN AS
$$
DECLARE
    param_saldo money;
    
    nome_equipe_casa text;
    nome_equipe_visitante text; 
    
    param_equipe_casa_id integer := 0;
    param_equipe_visitante_id integer := 0;
    
    param_odd real := CAST(RANDOM() AS NUMERIC(3,2));
    
    gols_casa integer := CAST(RANDOM()*10 AS NUMERIC(1,0));
    gols_visitante integer := CAST(RANDOM()*10 AS NUMERIC(1,0));    
    
BEGIN
    SELECT equipe_casa_id, equipe_visitante_id FROM jogo WHERE id = var_jogo_id INTO param_equipe_casa_id, param_equipe_visitante_id;
    
    SELECT nome FROM equipe WHERE id = param_equipe_casa_id INTO nome_equipe_casa;
    
    SELECT nome FROM equipe WHERE id = param_equipe_visitante_id INTO nome_equipe_visitante;
            
    SELECT saldo::money FROM usuario where id = var_usuario_id INTO param_saldo;        
            
    IF (var_valor::numeric <= param_saldo::numeric) THEN
    
        RAISE NOTICE '% (%) vs % (%): Aposta: %, ODD:%', nome_equipe_casa, gols_casa, nome_equipe_visitante, gols_visitante, var_valor, param_odd;        
           
         INSERT INTO aposta (usuario_id, valor, jogo_id, gols_da_casa, gols_do_visitante, odd) VALUES
    (var_usuario_id, var_valor, var_jogo_id, gols_casa, gols_visitante, param_odd);
    
        UPDATE usuario SET saldo = cast((saldo::numeric - var_valor::numeric) as money) where id = var_usuario_id;
    
        RETURN TRUE;
    
    ELSE
        RAISE NOTICE 'saldo insuficiente';    
    END IF;    
    
    RETURN FALSE;
    
 END;
$$ LANGUAGE 'plpgsql';



