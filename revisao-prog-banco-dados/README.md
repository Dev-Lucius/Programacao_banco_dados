## Guia Avançado de Teoria e Otimização de Código: Subprogramas e Recursos em PL/pgSQL

## ⚙️ 1. Programação Procedural: Functions e Stored Procedures
Bancos de dados relacionais puros trabalham com a lógica de conjuntos (álgebra relacional). No entanto, certas regras de negócio exigem estruturas de controle de fluxo de linguagens de programação tradicionais (como loops FOR/WHILE e condicionais IF/ELSE). É aqui que entra o PL/pgSQL (Procedural Language / PostgreSQL Extended).

## O Ciclo de Execução e Compilação

Quando você executa um comando CREATE FUNCTION, o código contido dentro dos delimitadores textuais ($$) não é compilado imediatamente para código de máquina. Ele é apenas armazenado como texto na tabela do catálogo do sistema (pg_proc).

A compilação real e a geração do Plano de Execução ocorrem na primeira vez que a função é invocada (chamada) em uma sessão de usuário. O motor compila as expressões SQL internas e cria pontos de cache para reutilizar esses planos nas chamadas seguintes daquela mesma sessão, reduzindo o tempo de processamento.

## Diferenças Arquiteturais Cruciais entre Functions e Procedures

| Atributo | FUNCTION (Função) | PROCEDURE (Procedimento) |
|---|---|---|
| Forma de Invocação | SELECT funcao(); | CALL procedimento(); |
| Retorno de Dados | Obrigatório (Scalar, Setof ou Table) | Não possui retorno direto |
| Utilização em Expressões SQL | Pode ser usada em cláusulas WHERE/SELECT | Não pode ser usada em SQL |
| Gerenciamento de Transações | Não permite COMMIT/ROLLBACK internos | Permite COMMIT/ROLLBACK |


* Abordagem Transacional: Uma Function roda inteiramente sob o contexto transacional de quem a chamou. Se uma função executa 10 inserções e falha na 11ª, todo o bloco é revertido pela transação externa. Como ela não é dona da própria transação, comandos de controle como COMMIT são proibidos em seu interior.

* Abordagem de Processamento: Uma Procedure abre e gerencia seu próprio contexto transacional. Se você precisar rodar um processo em lote que modifica 1 milhão de linhas, você pode colocar um loop na Procedure que executa um COMMIT a cada 10.000 linhas processadas. Isso limpa o buffer de memória RAM e evita que os bloqueios de linha (Locks) saturem o banco de dados.

## Retorno de Consultas: RETURNS TABLE e RETURN QUERY

Ao criar funções que retornam conjuntos de dados estruturados (linhas e colunas), o PostgreSQL introduz uma otimização fundamental: o RETURN QUERY.
O RETURN QUERY executa a consulta declarada e envia o resultado diretamente para o canal de saída da função de forma assíncrona e em blocos, economizando memória RAM do servidor de banco de dados e acelerando o tempo de resposta do sistema.


## 🔀 2. Gerenciamento de Transações e Bloco de Exceções em Subprogramas

Para compreender o comportamento transacional no PostgreSQL, é fundamental analisar exemplos práticos de como Procedures lidam com commits em lote e como Functions gerenciam a reversão de estados por meio de blocos de tratamento de erro.

## A. Exemplo em PROCEDURE: Commit em Lote (Batch Processing)

Procedures podem abrir e fechar transações no meio da execução. O exemplo abaixo simula uma rotina de manutenção que zera saldos inativos e consolida a operação a cada linha processada, liberando os recursos do servidor imediatamente.

```sql
CREATE OR REPLACE PROCEDURE limpar_saldos_inativos() AS $$DECLARE
    reg_usuario RECORD;BEGIN
    FOR reg_usuario IN SELECT id, nome FROM usuario WHERE saldo > 0::money LOOP
        
        -- Atualiza o registro do usuario atual
        UPDATE usuario SET saldo = 0::money WHERE id = reg_usuario.id;
        RAISE NOTICE 'Saldo do usuario % zerado.', reg_usuario.nome;
        
        -- EXCLUSIVO DE PROCEDURE: Commita a alteracao de cada usuario individualmente.
        -- Isso impede o acumulo de travas (locks) na tabela inteira.
        COMMIT; 
        
    END LOOP;END;
$$ LANGUAGE plpgsql;
```

## B. Exemplo em FUNCTION: Controle Transacional Indireto (EXCEPTION)

Functions não podem executar o comando COMMIT ou ROLLBACK. Contudo, elas gerenciam transações indiretamente usando subtransações internas através do bloco EXCEPTION. Se um erro ocorre dentro do bloco BEGIN ... EXCEPTION, o PostgreSQL reverte automaticamente apenas as escritas daquele bloco específico, agindo como um Savepoint.

```sql
CREATE OR REPLACE FUNCTION simular_deposito_seguro(var_id integer, var_valor money) RETURNS BOOLEAN AS $$BEGIN
    -- Inicio do bloco com monitoramento de erro
    UPDATE usuario SET saldo = saldo + var_valor WHERE id = var_id;
    
    -- Força um erro se o valor for abusivo (apenas para teste de reversao)
    IF var_valor > 1000000::money THEN
        RAISE EXCEPTION 'Valor acima do limite permitido para transferencia direta.';
    END IF;
    
    RETURN TRUE;
EXCEPTION 
    WHEN OTHERS THEN
        -- O PostgreSQL desfaz o UPDATE anterior automaticamente antes de entrar aqui.
        -- O rollback do bloco interno e implicito.
        RAISE NOTICE 'Transacao abortada internamente. Erro interceptado.';
        RETURN FALSE;END;
$$ LANGUAGE plpgsql;
```
