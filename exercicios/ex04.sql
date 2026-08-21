-- EXERCÍCIO 3: Função que retorna o valor total apostado por um usuário

-- CRIAÇÃO DA FUNÇÃO
-- 'CREATE OR REPLACE FUNCTION' cria a função ou substitui se já existir.
-- O nome da função é 'valor_total_apostado'.
-- Ela recebe UM parâmetro de entrada: 'var_usuario_id' do tipo integer.
-- 'RETURNS MONEY' indica que o resultado final será um valor monetário.
CREATE OR REPLACE FUNCTION valor_total_apostado(var_usuario_id integer) 
RETURNS MONEY 
LANGUAGE plpgsql  -- Define que usaremos a linguagem procedural PL/pgSQL
AS $$
DECLARE 
    -- DECLARAÇÃO DE VARIÁVEIS
    -- Aqui declaramos uma variável local chamada 'valor_total'.
    -- O tipo 'money' é específico para valores financeiros no PostgreSQL.
    -- ':= 0::money' significa: inicie com zero, convertido para o tipo money.
    -- Isso é uma boa prática: se a consulta retornar NULL (sem apostas),
    -- a função retorna 0 em vez de NULL.
    valor_total money := 0::money;
BEGIN 
    -- CORPO DA FUNÇÃO
    
    -- SELECT ... INTO: executa uma consulta e ARMAZENA o resultado na variável.
    -- 'sum(valor)' é uma função de agregação do SQL: soma todos os valores.
    -- 'FROM aposta' indica a tabela onde buscaremos os dados.
    -- 'WHERE usuario_id = var_usuario_id' filtra apenas as apostas DESSE usuário.
    -- O INTO vem DEPOIS da lista de colunas e ANTES do FROM (sintaxe correta!).
    SELECT sum(valor) 
    INTO valor_total        -- Guarda o resultado na variável declarada acima
    FROM aposta 
    WHERE usuario_id = var_usuario_id;
    
    -- RETORNO
    -- 'RETURN' devolve o valor da variável para quem chamou a função.
    -- Se o usuário não tiver apostas, 'sum()' retorna NULL, mas como
    -- inicializamos 'valor_total' com 0::money, o COALESCE implícito da
    -- inicialização garante que não retornemos NULL... 
    -- Na verdade, aqui vale uma observação: se a consulta retornar NULL,
    -- o INTO atribui NULL à variável, sobrescrevendo o 0 inicial!
    -- Veremos como melhorar isso abaixo.
    RETURN valor_total;
END;
$$;
