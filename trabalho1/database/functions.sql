-- Função 1 - obter_saldo(usuario_id)
-- devolve o saldo do usuário. Devolve numeric (e não money) — assim o Python recebe um Decimal. Se o usuário não existe, devolve NULL.
CREATE OR REPLACE FUNCTION obter_saldo(var_usuario_id INTEGER) RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    saldo_total numeric(10, 2) := 0;
BEGIN
    SELECT u.saldo::NUMERIC
    INTO saldo_total
    FROM usuario u
    WHERE u.id = var_usuario_id;

    RETURN saldo_total;
END;
$$;

-- Função 2 - liste_jogos()
-- devolve os jogos disponíveis para apostar. 
-- RETURNS TABLE faz a função se comportar como uma tabela: 
-- use SELECT * FROM liste_jogos(). (Um SELECT liste_jogos() devolveria cada linha como uma única coluna composta — armadilha comum.)
CREATE OR REPLACE FUNCTION liste_jogos() 
RETURNS TABLE(
    var_jogo_id INTEGER,
    var_data_hora_jogo TIMESTAMP,
    var_equipe_casa TEXT,
    var_equipe_visitante TEXT,
    var_gols_da_casa INTEGER,
    var_gols_do_visitante INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        j.id,
        j.data_hora,
        ec.nome,
        ev.nome,
        j.gols_da_casa,
        j.gols_do_visitante
    FROM jogo j
    LEFT JOIN equipe ec
        ON ec.id = j.equipe_casa_id
    LEFT JOIN equipe ev
        ON ev.id = j.equipe_visitante_id;
END;
$$;

-- Função 3 - total_jogos()
-- Retorna a quantidade de jogos cadastrados (estatística do rodapé).
CREATE OR REPLACE FUNCTION total_jogos() RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE 
    qtde_total_jogos INTEGER := 0;
BEGIN
    SELECT
        COUNT(id) as total_jogos
    FROM jogo
    INTO qtde_total_jogos;

    RETURN qtde_total_jogos;
END;
$$;

-- Função 4 - media_valor_apostas()
-- valor médio das apostas (estatística do rodapé).
-- AVG() não aceita money diretamente; por isso o ::numeric. O COALESCE devolve 0 quando ainda não há apostas (senão viria NULL)
CREATE OR REPLACE FUNCTION media_valor_apostas() RETURNS MONEY
LANGUAGE plpgsql
AS $$
DECLARE
    somatorio_valores_apostados MONEY := 0::MONEY;
    media_valores_apostados MONEY := 0::MONEY;
BEGIN
    SELECT SUM(valor) FROM aposta INTO somatorio_valores_apostados WHERE id IS NOT NULL;
    media_valores_apostados := AVG(somatorio_valores_apostados::NUMERIC);
    RETURN media_valores_apostados;
END;
$$;

-- Função 5 - propor_aposta(usuario_id, jogo_id, valor)
-- Pontos Importantes:
/*
    - SELECT … FOR UPDATE trava a linha do usuário até o fim da transação. Sem isso, duas apostas simultâneas poderiam ler o mesmo saldo e gastá-lo duas vezes

    - INSERT + UPDATE no mesmo corpo de função = uma única transação: se algo falhar, nada é gravado.
    
    - O parâmetro p_valor é numeric (não money): assim o Python passa um Decimal sem conversões
*/
CREATE OR REPLACE FUNCTION propor_aposta(
    p_usuario_id INTEGER,
    p_jogo_id INTEGER,
    p_valor NUMERIC,
    p_gols_da_casa INTEGER,
    p_gols_do_visitante INTEGER,
    p_odd REAL
)
RETURNS TABLE(
    var_aposta_id INTEGER,
    var_usuario_id INTEGER,
    var_jogo_id INTEGER,
    var_valor NUMERIC,
    var_gols_da_casa INTEGER,
    var_gols_do_visitante INTEGER,
    var_odd REAL,
    var_saldo_restante NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_saldo NUMERIC;
    v_aposta_id INTEGER;
BEGIN

    -- 1. Bloqueia o usuário para evitar
    -- duas apostas consumindo o mesmo saldo
    SELECT u.saldo::NUMERIC
    INTO v_saldo
    FROM usuario u
    WHERE u.id = p_usuario_id
    FOR UPDATE;

    -- 2. Verifica se o usuário existe
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Usuário % não encontrado', p_usuario_id;
    END IF;

    -- 3. Valida o valor da aposta
    IF p_valor <= 0 THEN
        RAISE EXCEPTION 'O valor da aposta deve ser maior que zero';
    END IF;

    -- 4. Valida os gols
    IF p_gols_da_casa < 0 OR p_gols_do_visitante < 0 THEN
        RAISE EXCEPTION 'A quantidade de gols não pode ser negativa';
    END IF;

    -- 5. Valida a odd
    IF p_odd <= 0 OR p_odd > 1 THEN
        RAISE EXCEPTION 'A odd deve ser maior que 0 e menor ou igual a 1';
    END IF;

    -- 6. Verifica se o jogo existe
    IF NOT EXISTS (
        SELECT 1
        FROM jogo
        WHERE id = p_jogo_id
    ) THEN
        RAISE EXCEPTION 'Jogo % não encontrado', p_jogo_id;
    END IF;

    -- 7. Verifica se o usuário possui saldo suficiente
    IF v_saldo < p_valor THEN
        RAISE EXCEPTION
            'Saldo insuficiente. Saldo disponível: %, valor da aposta: %',
            v_saldo,
            p_valor;
    END IF;

    -- 8. Registra a aposta
    INSERT INTO aposta (
        usuario_id,
        valor,
        jogo_id,
        gols_da_casa,
        gols_do_visitante,
        odd
    )
    VALUES (
        p_usuario_id,
        p_valor::MONEY,
        p_jogo_id,
        p_gols_da_casa,
        p_gols_do_visitante,
        p_odd
    )
    RETURNING id INTO v_aposta_id;

    -- 9. Desconta o valor do saldo
    UPDATE usuario
    SET saldo = saldo::NUMERIC - p_valor::NUMERIC
    WHERE id = p_usuario_id;

    -- 10. Retorna os dados da aposta
    RETURN QUERY
    SELECT
        v_aposta_id,
        p_usuario_id,
        p_jogo_id,
        p_valor,
        p_gols_da_casa,
        p_gols_do_visitante,
        p_odd,
        v_saldo::NUMERIC - p_valor::NUMERIC;
END;
$$;

-- Função 6 - apostas_usuario(usuario_id) 
-- lista as apostas do usuário (id, jogo, valor, odd)
CREATE OR REPLACE FUNCTION apostas_usuario(var_usuario_id INTEGER)
RETURNS TABLE(
    var_user_id INTEGER,
    var_usuario_nome VARCHAR(200),
    var_usuario_saldo MONEY,
    var_aposta_id INTEGER,
    var_aposta_odd REAL,
    var_aposta_valor MONEY,
    var_aposta_gols_casa INTEGER,
    var_aposta_gols_visitante INTEGER,
    var_jogo_id INTEGER,
    var_jogo_data_hora TIMESTAMP,
    var_equipe_casa_nome TEXT,
    var_equipe_visitante_nome TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        u.id,
        u.nome,
        u.saldo,
        a.id,
        a.odd,
        a.valor,
        a.gols_da_casa,
        a.gols_do_visitante,
        j.id,
        j.data_hora,
        ec.nome,
        ev.nome
    FROM usuario u
    LEFT JOIN aposta a
        ON a.usuario_id = u.id
    LEFT JOIN jogo j
        ON j.id = a.jogo_id
    LEFT JOIN equipe ec
        ON ec.id = j.equipe_casa_id
    LEFT JOIN equipe ev
        ON ev.id = j.equipe_visitante_id
    WHERE u.id = var_usuario_id;

END;
$$;

-- Função 7 - lucro_potencial(aposta_id) 
-- lucro projetado de uma aposta. NULLIF(odd, 0) transforma um eventual zero em NULL, evitando erro de divisão por zero mesmo em bases antigas.
CREATE OR REPLACE FUNCTION lucro_potencial(var_aposta_id INTEGER) 
RETURNS TABLE(
    var_aposta_valor MONEY,
    var_aposta_odd REAL,
    var_lucro_esperado MONEY
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        valor,
        odd,
        valor * (1 + odd) AS lucro_esperado
    FROM aposta
    WHERE aposta.id = var_aposta_id;
END;
$$;