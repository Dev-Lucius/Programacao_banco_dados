
# Lista de Revisão – Stored Procedures e Functions no PostgreSQL

**Base de dados: IFBET**

> Lista complementar à lista anterior. Os exercícios começam com questões simples e avançam gradualmente até problemas que combinam vários recursos de PL/pgSQL.

---

# Parte 1 – Revisão de Functions Básicas

### Exercício 1 – Saldo formatado

Crie uma função `saldo_formatado(usuario_id)` que retorne o saldo do usuário como texto.

Exemplo:

```text
R$ 1.500,00
```

---

### Exercício 2 – Verificar usuário

Crie uma função `usuario_existe(usuario_id)` que retorne:

```text
TRUE
```

caso o usuário exista e:

```text
FALSE
```

caso contrário.

---

### Exercício 3 – Verificar equipe

Crie uma função `equipe_existe(equipe_id)` que realize a mesma verificação para equipes.

---

### Exercício 4 – Verificar jogo

Crie uma função `jogo_existe(jogo_id)` que retorne `TRUE` ou `FALSE`.

---

### Exercício 5 – Saldo suficiente

Crie uma função:

```text
saldo_suficiente(usuario_id, valor)
```

que retorne `TRUE` quando o usuário possuir saldo suficiente para realizar uma operação.

---

### Exercício 6 – Classificação de saldo

Crie uma função:

```text
classificar_saldo(usuario_id)
```

que retorne:

```text
SEM SALDO
SALDO BAIXO
SALDO MEDIO
SALDO ALTO
```

Utilize `IF / ELSIF / ELSE`.

---

### Exercício 7 – Classificação utilizando CASE

Reescreva o exercício anterior utilizando `CASE` em vez de `IF`.

---

### Exercício 8 – Situação do usuário

Crie uma função:

```text
situacao_usuario(usuario_id)
```

que retorne:

```text
ATIVO
INATIVO
```

---

# Parte 2 – `SELECT INTO`

### Exercício 9 – Nome do usuário

Crie uma função:

```text
nome_usuario(usuario_id)
```

utilizando obrigatoriamente:

```sql
SELECT ... INTO ...
```

---

### Exercício 10 – E-mail do usuário

Crie:

```text
email_usuario(usuario_id)
```

utilizando `SELECT INTO`.

---

### Exercício 11 – Dados da equipe

Crie:

```text
dados_equipe(equipe_id)
```

que retorne o nome e o local da equipe em uma única string.

Exemplo:

```text
SAO PAULO DE RG - Rio Grande
```

---

### Exercício 12 – Dados do jogo

Crie:

```text
dados_jogo(jogo_id)
```

que retorne:

```text
SAO PAULO DE RG x RIO GRANDE
```

utilizando `SELECT INTO`.

---

# Parte 3 – Agregações dentro de Functions

### Exercício 13 – Total apostado

Crie uma função:

```text
total_apostado(usuario_id)
```

que utilize `SUM()`.

---

### Exercício 14 – Maior aposta do usuário

Crie:

```text
maior_aposta_usuario(usuario_id)
```

utilizando `MAX()`.

---

### Exercício 15 – Menor aposta do usuário

Crie:

```text
menor_aposta_usuario(usuario_id)
```

utilizando `MIN()`.

---

### Exercício 16 – Média das apostas

Crie:

```text
media_apostas_usuario(usuario_id)
```

utilizando `AVG()`.

---

### Exercício 17 – Quantidade de apostas

Crie:

```text
quantidade_apostas_usuario(usuario_id)
```

utilizando `COUNT()`.

---

### Exercício 18 – Estatísticas completas

Crie uma função que receba `usuario_id` e retorne:

```text
quantidade
total
media
maior
menor
```

---

# Parte 4 – Functions com retorno de tabela

### Exercício 19 – Apostas do usuário

Crie:

```text
listar_apostas_usuario(usuario_id)
```

retornando:

* ID da aposta;
* valor;
* odd.

Utilize:

```sql
RETURNS TABLE
```

---

### Exercício 20 – Jogos de uma equipe

Crie:

```text
jogos_equipe(equipe_id)
```

Retorne:

* jogo;
* adversário;
* data;
* resultado.

---

### Exercício 21 – Jogos futuros

Crie:

```text
jogos_futuros()
```

que retorne todos os jogos que ainda não foram encerrados.

---

### Exercício 22 – Jogos encerrados

Crie:

```text
jogos_encerrados()
```

retornando todos os jogos já realizados.

---

### Exercício 23 – Apostas acima de determinado valor

Crie:

```text
apostas_acima(valor)
```

utilizando `RETURN QUERY`.

---

### Exercício 24 – Usuários com saldo mínimo

Crie:

```text
usuarios_com_saldo_minimo(valor)
```

utilizando `RETURN QUERY`.

---

# Parte 5 – `RETURN QUERY`

### Exercício 25 – Ranking de apostadores

Crie:

```text
ranking_apostadores()
```

retornando:

| Usuário | Apostas | Total Apostado |
| ------- | ------: | -------------: |

Ordene pelo maior valor total apostado.

Utilize `RETURN QUERY`.

---

### Exercício 26 – Ranking de equipes

Crie:

```text
ranking_equipes()
```

retornando:

| Equipe | Jogos |
| ------ | ----: |

Ordene da equipe com mais jogos para a equipe com menos jogos.

---

### Exercício 27 – Usuários sem apostas

Crie:

```text
usuarios_sem_apostas()
```

utilizando `LEFT JOIN`.

---

### Exercício 28 – Usuários com apostas

Crie:

```text
usuarios_com_apostas()
```

retornando somente usuários que possuem pelo menos uma aposta.

---

# Parte 6 – Loops

### Exercício 29 – Percorrer usuários

Crie uma função que percorra todos os usuários utilizando:

```sql
FOR registro IN
    SELECT ...
LOOP
```

e apresente cada usuário utilizando:

```sql
RAISE NOTICE
```

Formato:

```text
Usuário: Igor | Saldo: R$ 1000,00
```

---

### Exercício 30 – Percorrer apostas

Crie uma função que receba `usuario_id` e percorra todas as suas apostas utilizando `FOR`.

Para cada aposta, apresente:

```text
Aposta: 10
Valor: R$ 100,00
Odd: 2.50
```

---

### Exercício 31 – Percorrer equipes

Crie uma função que percorra todas as equipes e apresente:

```text
Equipe: SAO PAULO DE RG
Local: Rio Grande
```

---

### Exercício 32 – Somatório utilizando LOOP

Crie uma função que receba `usuario_id` e calcule o total apostado utilizando um loop.

**Não utilize `SUM()`.**

---

### Exercício 33 – Contagem utilizando LOOP

Crie uma função que conte as apostas de um usuário utilizando um loop.

**Não utilize `COUNT()`.**

---

# Parte 7 – `WHILE` e `LOOP`

### Exercício 34 – Contador

Crie uma função:

```text
contar_apostas(usuario_id)
```

que percorra as apostas utilizando `WHILE`.

---

### Exercício 35 – Simulação de apostas

Crie uma função:

```text
simular_valores(quantidade)
```

que utilize `WHILE` para gerar determinada quantidade de valores aleatórios.

Utilize:

```sql
random()
```

---

### Exercício 36 – `LOOP` com `EXIT`

Crie uma função que utilize:

```sql
LOOP
...
EXIT WHEN ...
END LOOP;
```

para gerar números de 1 até 10.

Não utilize `FOR` ou `WHILE`.

---

### Exercício 37 – Encontrar aposta

Percorra as apostas de um usuário utilizando `LOOP`.

Interrompa o processamento com:

```sql
EXIT WHEN ...
```

quando encontrar uma aposta superior a R$ 500.

---

# Parte 8 – Procedures

### Exercício 38 – Depósito com validação

Crie uma procedure:

```text
depositar(usuario_id, valor)
```

Regras:

* valor deve ser positivo;
* usuário deve existir;
* adicionar o valor ao saldo.

Utilize `IF`.

---

### Exercício 39 – Saque com validação

Crie:

```text
sacar(usuario_id, valor)
```

Regras:

* usuário deve existir;
* valor deve ser positivo;
* saldo deve ser suficiente;
* saldo não pode ficar negativo.

---

### Exercício 40 – Transferência

Crie:

```text
transferir(origem, destino, valor)
```

A procedure deverá:

1. validar origem;
2. validar destino;
3. verificar saldo;
4. retirar da origem;
5. adicionar ao destino.

---

### Exercício 41 – Alterar odd

Crie:

```text
alterar_odd(aposta_id, nova_odd)
```

que altere a odd de uma aposta.

Impeça valores menores ou iguais a zero.

---

### Exercício 42 – Alterar saldo

Crie:

```text
alterar_saldo(usuario_id, novo_saldo)
```

que substitua o saldo atual.

Não permita saldo negativo.

---

# Parte 9 – `EXCEPTION`

### Exercício 43 – Usuário inexistente

Crie uma função que utilize:

```sql
SELECT ... INTO ...
```

e trate:

```sql
NO_DATA_FOUND
```

utilizando:

```sql
EXCEPTION
```

---

### Exercício 44 – Divisão por zero

Crie uma função:

```text
calcular_odds(valor, quantidade)
```

que realize uma divisão.

Trate o caso de `quantidade = 0` utilizando `EXCEPTION`.

---

### Exercício 45 – Erro genérico

Crie uma function que execute uma operação de atualização e trate:

```sql
WHEN OTHERS
```

Utilize:

```sql
RAISE NOTICE
```

para apresentar uma mensagem de erro.

---

### Exercício 46 – Depósito seguro

Crie uma function ou procedure para depósito que trate erros utilizando `EXCEPTION`.

Em caso de erro:

```text
Depósito não realizado.
```

---

# Parte 10 – Operações envolvendo várias tabelas

### Exercício 47 – Histórico completo

Crie:

```text
historico_apostas(usuario_id)
```

retornando:

* jogo;
* equipe da casa;
* equipe visitante;
* valor apostado;
* odd;
* data.

Utilize `JOIN` e `RETURN QUERY`.

---

### Exercício 48 – Histórico em texto

Crie:

```text
historico_apostas_texto(usuario_id)
```

que percorra as apostas e construa um texto:

```text
Jogo: SAO PAULO DE RG x RIO GRANDE
Valor: R$ 100,00
Odd: 2.50

Jogo: PELOTAS x BRASIL
Valor: R$ 50,00
Odd: 1.80
```

---

### Exercício 49 – Estatísticas por equipe

Crie:

```text
estatisticas_equipe(equipe_id)
```

retornando:

* quantidade de jogos;
* vitórias;
* empates;
* derrotas;
* gols marcados;
* gols sofridos.

---

### Exercício 50 – Ranking de equipes

Crie:

```text
classificacao_campeonato()
```

retornando:

| Equipe |  P |  J |  V |  E |  D | GP | GC | SG |
| ------ | -: | -: | -: | -: | -: | -: | -: | -: |

Utilize `RETURN QUERY`.

---

# Parte 11 – Transações e Procedures

### Exercício 51 – Transferência segura

Crie uma procedure de transferência que execute:

```text
débito da origem
↓
crédito do destino
↓
registro das operações
```

Utilize tratamento de exceção para impedir que uma transferência parcialmente realizada permaneça no banco.

---

### Exercício 52 – Processamento em lote

Crie uma procedure:

```text
processar_bonus()
```

que percorra todos os usuários e acrescente R$ 10,00 ao saldo.

Utilize `FOR`.

---

### Exercício 53 – Bônus em lotes

Modifique o exercício anterior para executar `COMMIT` a cada 100 usuários processados.

---

### Exercício 54 – Limpeza de usuários

Crie uma procedure:

```text
limpar_usuarios_inativos()
```

que:

1. encontre usuários inativos;
2. zere seus saldos;
3. registre a operação;
4. utilize processamento em lote.

---

# Parte 12 – Exercícios de integração

### Exercício 55 – Criar aposta

Crie uma procedure:

```text
criar_aposta(usuario_id, jogo_id, valor, odd)
```

A procedure deverá:

1. verificar se o usuário existe;
2. verificar se o usuário possui saldo;
3. verificar se o jogo existe;
4. verificar se o jogo ainda não foi encerrado;
5. retirar o valor do saldo;
6. criar a aposta.

---

### Exercício 56 – Cancelar aposta

Crie uma procedure:

```text
cancelar_aposta(aposta_id)
```

que:

1. localize a aposta;
2. descubra o usuário;
3. devolva o valor ao usuário;
4. remova a aposta.

Utilize `SELECT INTO`.

---

### Exercício 57 – Encerrar jogo

Crie:

```text
encerrar_jogo(jogo_id, gols_casa, gols_visitante)
```

A procedure deverá:

1. atualizar o placar;
2. marcar o jogo como encerrado;
3. localizar as apostas;
4. identificar os vencedores;
5. calcular os prêmios;
6. creditar os usuários vencedores.

---

# Parte 13 – Desafios

### Desafio 1 – Função completa de usuário

Crie:

```text
relatorio_usuario(usuario_id)
```

retornando:

```text
Nome:
Saldo:
Quantidade de apostas:
Total apostado:
Maior aposta:
Menor aposta:
Média das apostas:
```

---

### Desafio 2 – Extrato completo

Crie:

```text
extrato_usuario(usuario_id)
```

retornando todas as operações financeiras do usuário:

| Data | Tipo | Valor | Descrição |
| ---- | ---- | ----: | --------- |

---

### Desafio 3 – Ranking financeiro

Crie:

```text
ranking_financeiro()
```

retornando:

| Posição | Usuário | Saldo | Total apostado |
| ------: | ------- | ----: | -------------: |

Utilize `ROW_NUMBER()`.

---

### Desafio 4 – Artilharia

Crie:

```text
artilharia()
```

retornando:

| Equipe | Gols Marcados |
| ------ | ------------: |

Ordene da maior para a menor quantidade de gols.

---

### Desafio 5 – Campeonato

Crie uma procedure:

```text
gerar_campeonato()
```

que:

1. percorra todas as equipes;
2. gere jogos entre elas;
3. não permita que uma equipe jogue contra ela mesma;
4. gere resultados aleatórios;
5. encerre os jogos;
6. atualize a classificação.

---

### Desafio 6 – Simulação de apostas

Crie uma procedure:

```text
simular_apostas(quantidade)
```

que gere apostas aleatórias para usuários e jogos existentes.

A procedure deverá utilizar:

* `FOR` ou `WHILE`;
* `random()`;
* `SELECT INTO`;
* validação de saldo;
* inserção de apostas;
* atualização de saldo.

---

### Desafio 7 – Processamento de apostas

Crie uma procedure:

```text
processar_apostas()
```

que percorra todas as apostas de jogos encerrados e:

1. identifique os vencedores;
2. calcule os prêmios;
3. credite os usuários;
4. registre o pagamento;
5. marque a aposta como processada.

---

# Parte 14 – Desafio final de revisão

### Desafio 8 – Sistema completo IFBET

Implemente um conjunto de subprogramas para disponibilizar as seguintes operações:

```text
obter_saldo()
nome_usuario()
nome_jogo()
quantidade_apostas()
valor_total_apostado()
ranking_apostadores()
historico_apostas()
estatisticas_equipe()
classificacao_campeonato()
```

E as seguintes procedures:

```text
depositar()
sacar()
transferir()
criar_aposta()
cancelar_aposta()
encerrar_jogo()
processar_apostas()
gerar_campeonato()
```

Durante a implementação, utilize os recursos:

```text
FUNCTION
PROCEDURE
IF / ELSE
CASE
SELECT INTO
FOR
WHILE
LOOP
EXIT
RETURNS TABLE
RETURN QUERY
RAISE NOTICE
EXCEPTION
JOIN
GROUP BY
ORDER BY
ROW_NUMBER()
COMMIT
```

### Desafio 9 – Validação completa

Depois de implementar o sistema, crie um **script de testes em `psql`** que execute, em sequência:

```sql
-- consultas
SELECT obter_saldo(1);
SELECT quantidade_apostas(1);

-- operações financeiras
CALL depositar(1, 500);
CALL sacar(1, 100);
CALL transferir(1, 2, 200);

-- apostas
CALL criar_aposta(1, 1, 100, 2.50);

-- consultas
SELECT *
FROM ranking_apostadores();

SELECT *
FROM historico_apostas(1);

-- encerramento
CALL encerrar_jogo(1, 2, 1);

-- processamento
CALL processar_apostas();

-- classificação
SELECT *
FROM classificacao_campeonato();
```
Claro. A ideia aqui é criar uma **segunda lista de revisão**, aproveitando a mesma base **IFBET**, mas cobrindo de forma progressiva os conceitos que aparecem na lista original: `FUNCTION`, `PROCEDURE`, parâmetros, `SELECT INTO`, `IF`, `CASE`, agregações, `RETURNS TABLE`, `RETURN QUERY`, `FOR`, `WHILE`, `LOOP`, `EXCEPTION`, transações e processamento em lote.

# Lista de Revisão – Stored Procedures e Functions no PostgreSQL

**Base de dados: IFBET**

> Lista complementar à lista anterior. Os exercícios começam com questões simples e avançam gradualmente até problemas que combinam vários recursos de PL/pgSQL.

---

# Parte 1 – Revisão de Functions Básicas

### Exercício 1 – Saldo formatado

Crie uma função `saldo_formatado(usuario_id)` que retorne o saldo do usuário como texto.

Exemplo:

```text
R$ 1.500,00
```

---

### Exercício 2 – Verificar usuário

Crie uma função `usuario_existe(usuario_id)` que retorne:

```text
TRUE
```

caso o usuário exista e:

```text
FALSE
```

caso contrário.

---

### Exercício 3 – Verificar equipe

Crie uma função `equipe_existe(equipe_id)` que realize a mesma verificação para equipes.

---

### Exercício 4 – Verificar jogo

Crie uma função `jogo_existe(jogo_id)` que retorne `TRUE` ou `FALSE`.

---

### Exercício 5 – Saldo suficiente

Crie uma função:

```text
saldo_suficiente(usuario_id, valor)
```

que retorne `TRUE` quando o usuário possuir saldo suficiente para realizar uma operação.

---

### Exercício 6 – Classificação de saldo

Crie uma função:

```text
classificar_saldo(usuario_id)
```

que retorne:

```text
SEM SALDO
SALDO BAIXO
SALDO MEDIO
SALDO ALTO
```

Utilize `IF / ELSIF / ELSE`.

---

### Exercício 7 – Classificação utilizando CASE

Reescreva o exercício anterior utilizando `CASE` em vez de `IF`.

---

### Exercício 8 – Situação do usuário

Crie uma função:

```text
situacao_usuario(usuario_id)
```

que retorne:

```text
ATIVO
INATIVO
```

---

# Parte 2 – `SELECT INTO`

### Exercício 9 – Nome do usuário

Crie uma função:

```text
nome_usuario(usuario_id)
```

utilizando obrigatoriamente:

```sql
SELECT ... INTO ...
```

---

### Exercício 10 – E-mail do usuário

Crie:

```text
email_usuario(usuario_id)
```

utilizando `SELECT INTO`.

---

### Exercício 11 – Dados da equipe

Crie:

```text
dados_equipe(equipe_id)
```

que retorne o nome e o local da equipe em uma única string.

Exemplo:

```text
SAO PAULO DE RG - Rio Grande
```

---

### Exercício 12 – Dados do jogo

Crie:

```text
dados_jogo(jogo_id)
```

que retorne:

```text
SAO PAULO DE RG x RIO GRANDE
```

utilizando `SELECT INTO`.

---

# Parte 3 – Agregações dentro de Functions

### Exercício 13 – Total apostado

Crie uma função:

```text
total_apostado(usuario_id)
```

que utilize `SUM()`.

---

### Exercício 14 – Maior aposta do usuário

Crie:

```text
maior_aposta_usuario(usuario_id)
```

utilizando `MAX()`.

---

### Exercício 15 – Menor aposta do usuário

Crie:

```text
menor_aposta_usuario(usuario_id)
```

utilizando `MIN()`.

---

### Exercício 16 – Média das apostas

Crie:

```text
media_apostas_usuario(usuario_id)
```

utilizando `AVG()`.

---

### Exercício 17 – Quantidade de apostas

Crie:

```text
quantidade_apostas_usuario(usuario_id)
```

utilizando `COUNT()`.

---

### Exercício 18 – Estatísticas completas

Crie uma função que receba `usuario_id` e retorne:

```text
quantidade
total
media
maior
menor
```

---

# Parte 4 – Functions com retorno de tabela

### Exercício 19 – Apostas do usuário

Crie:

```text
listar_apostas_usuario(usuario_id)
```

retornando:

* ID da aposta;
* valor;
* odd.

Utilize:

```sql
RETURNS TABLE
```

---

### Exercício 20 – Jogos de uma equipe

Crie:

```text
jogos_equipe(equipe_id)
```

Retorne:

* jogo;
* adversário;
* data;
* resultado.

---

### Exercício 21 – Jogos futuros

Crie:

```text
jogos_futuros()
```

que retorne todos os jogos que ainda não foram encerrados.

---

### Exercício 22 – Jogos encerrados

Crie:

```text
jogos_encerrados()
```

retornando todos os jogos já realizados.

---

### Exercício 23 – Apostas acima de determinado valor

Crie:

```text
apostas_acima(valor)
```

utilizando `RETURN QUERY`.

---

### Exercício 24 – Usuários com saldo mínimo

Crie:

```text
usuarios_com_saldo_minimo(valor)
```

utilizando `RETURN QUERY`.

---

# Parte 5 – `RETURN QUERY`

### Exercício 25 – Ranking de apostadores

Crie:

```text
ranking_apostadores()
```

retornando:

| Usuário | Apostas | Total Apostado |
| ------- | ------: | -------------: |

Ordene pelo maior valor total apostado.

Utilize `RETURN QUERY`.

---

### Exercício 26 – Ranking de equipes

Crie:

```text
ranking_equipes()
```

retornando:

| Equipe | Jogos |
| ------ | ----: |

Ordene da equipe com mais jogos para a equipe com menos jogos.

---

### Exercício 27 – Usuários sem apostas

Crie:

```text
usuarios_sem_apostas()
```

utilizando `LEFT JOIN`.

---

### Exercício 28 – Usuários com apostas

Crie:

```text
usuarios_com_apostas()
```

retornando somente usuários que possuem pelo menos uma aposta.

---

# Parte 6 – Loops

### Exercício 29 – Percorrer usuários

Crie uma função que percorra todos os usuários utilizando:

```sql
FOR registro IN
    SELECT ...
LOOP
```

e apresente cada usuário utilizando:

```sql
RAISE NOTICE
```

Formato:

```text
Usuário: Igor | Saldo: R$ 1000,00
```

---

### Exercício 30 – Percorrer apostas

Crie uma função que receba `usuario_id` e percorra todas as suas apostas utilizando `FOR`.

Para cada aposta, apresente:

```text
Aposta: 10
Valor: R$ 100,00
Odd: 2.50
```

---

### Exercício 31 – Percorrer equipes

Crie uma função que percorra todas as equipes e apresente:

```text
Equipe: SAO PAULO DE RG
Local: Rio Grande
```

---

### Exercício 32 – Somatório utilizando LOOP

Crie uma função que receba `usuario_id` e calcule o total apostado utilizando um loop.

**Não utilize `SUM()`.**

---

### Exercício 33 – Contagem utilizando LOOP

Crie uma função que conte as apostas de um usuário utilizando um loop.

**Não utilize `COUNT()`.**

---

# Parte 7 – `WHILE` e `LOOP`

### Exercício 34 – Contador

Crie uma função:

```text
contar_apostas(usuario_id)
```

que percorra as apostas utilizando `WHILE`.

---

### Exercício 35 – Simulação de apostas

Crie uma função:

```text
simular_valores(quantidade)
```

que utilize `WHILE` para gerar determinada quantidade de valores aleatórios.

Utilize:

```sql
random()
```

---

### Exercício 36 – `LOOP` com `EXIT`

Crie uma função que utilize:

```sql
LOOP
...
EXIT WHEN ...
END LOOP;
```

para gerar números de 1 até 10.

Não utilize `FOR` ou `WHILE`.

---

### Exercício 37 – Encontrar aposta

Percorra as apostas de um usuário utilizando `LOOP`.

Interrompa o processamento com:

```sql
EXIT WHEN ...
```

quando encontrar uma aposta superior a R$ 500.

---

# Parte 8 – Procedures

### Exercício 38 – Depósito com validação

Crie uma procedure:

```text
depositar(usuario_id, valor)
```

Regras:

* valor deve ser positivo;
* usuário deve existir;
* adicionar o valor ao saldo.

Utilize `IF`.

---

### Exercício 39 – Saque com validação

Crie:

```text
sacar(usuario_id, valor)
```

Regras:

* usuário deve existir;
* valor deve ser positivo;
* saldo deve ser suficiente;
* saldo não pode ficar negativo.

---

### Exercício 40 – Transferência

Crie:

```text
transferir(origem, destino, valor)
```

A procedure deverá:

1. validar origem;
2. validar destino;
3. verificar saldo;
4. retirar da origem;
5. adicionar ao destino.

---

### Exercício 41 – Alterar odd

Crie:

```text
alterar_odd(aposta_id, nova_odd)
```

que altere a odd de uma aposta.

Impeça valores menores ou iguais a zero.

---

### Exercício 42 – Alterar saldo

Crie:

```text
alterar_saldo(usuario_id, novo_saldo)
```

que substitua o saldo atual.

Não permita saldo negativo.

---

# Parte 9 – `EXCEPTION`

### Exercício 43 – Usuário inexistente

Crie uma função que utilize:

```sql
SELECT ... INTO ...
```

e trate:

```sql
NO_DATA_FOUND
```

utilizando:

```sql
EXCEPTION
```

---

### Exercício 44 – Divisão por zero

Crie uma função:

```text
calcular_odds(valor, quantidade)
```

que realize uma divisão.

Trate o caso de `quantidade = 0` utilizando `EXCEPTION`.

---

### Exercício 45 – Erro genérico

Crie uma function que execute uma operação de atualização e trate:

```sql
WHEN OTHERS
```

Utilize:

```sql
RAISE NOTICE
```

para apresentar uma mensagem de erro.

---

### Exercício 46 – Depósito seguro

Crie uma function ou procedure para depósito que trate erros utilizando `EXCEPTION`.

Em caso de erro:

```text
Depósito não realizado.
```

---

# Parte 10 – Operações envolvendo várias tabelas

### Exercício 47 – Histórico completo

Crie:

```text
historico_apostas(usuario_id)
```

retornando:

* jogo;
* equipe da casa;
* equipe visitante;
* valor apostado;
* odd;
* data.

Utilize `JOIN` e `RETURN QUERY`.

---

### Exercício 48 – Histórico em texto

Crie:

```text
historico_apostas_texto(usuario_id)
```

que percorra as apostas e construa um texto:

```text
Jogo: SAO PAULO DE RG x RIO GRANDE
Valor: R$ 100,00
Odd: 2.50

Jogo: PELOTAS x BRASIL
Valor: R$ 50,00
Odd: 1.80
```

---

### Exercício 49 – Estatísticas por equipe

Crie:

```text
estatisticas_equipe(equipe_id)
```

retornando:

* quantidade de jogos;
* vitórias;
* empates;
* derrotas;
* gols marcados;
* gols sofridos.

---

### Exercício 50 – Ranking de equipes

Crie:

```text
classificacao_campeonato()
```

retornando:

| Equipe |  P |  J |  V |  E |  D | GP | GC | SG |
| ------ | -: | -: | -: | -: | -: | -: | -: | -: |

Utilize `RETURN QUERY`.

---

# Parte 11 – Transações e Procedures

### Exercício 51 – Transferência segura

Crie uma procedure de transferência que execute:

```text
débito da origem
↓
crédito do destino
↓
registro das operações
```

Utilize tratamento de exceção para impedir que uma transferência parcialmente realizada permaneça no banco.

---

### Exercício 52 – Processamento em lote

Crie uma procedure:

```text
processar_bonus()
```

que percorra todos os usuários e acrescente R$ 10,00 ao saldo.

Utilize `FOR`.

---

### Exercício 53 – Bônus em lotes

Modifique o exercício anterior para executar `COMMIT` a cada 100 usuários processados.

---

### Exercício 54 – Limpeza de usuários

Crie uma procedure:

```text
limpar_usuarios_inativos()
```

que:

1. encontre usuários inativos;
2. zere seus saldos;
3. registre a operação;
4. utilize processamento em lote.

---

# Parte 12 – Exercícios de integração

### Exercício 55 – Criar aposta

Crie uma procedure:

```text
criar_aposta(usuario_id, jogo_id, valor, odd)
```

A procedure deverá:

1. verificar se o usuário existe;
2. verificar se o usuário possui saldo;
3. verificar se o jogo existe;
4. verificar se o jogo ainda não foi encerrado;
5. retirar o valor do saldo;
6. criar a aposta.

---

### Exercício 56 – Cancelar aposta

Crie uma procedure:

```text
cancelar_aposta(aposta_id)
```

que:

1. localize a aposta;
2. descubra o usuário;
3. devolva o valor ao usuário;
4. remova a aposta.

Utilize `SELECT INTO`.

---

### Exercício 57 – Encerrar jogo

Crie:

```text
encerrar_jogo(jogo_id, gols_casa, gols_visitante)
```

A procedure deverá:

1. atualizar o placar;
2. marcar o jogo como encerrado;
3. localizar as apostas;
4. identificar os vencedores;
5. calcular os prêmios;
6. creditar os usuários vencedores.

---

# Parte 13 – Desafios

### Desafio 1 – Função completa de usuário

Crie:

```text
relatorio_usuario(usuario_id)
```

retornando:

```text
Nome:
Saldo:
Quantidade de apostas:
Total apostado:
Maior aposta:
Menor aposta:
Média das apostas:
```

---

### Desafio 2 – Extrato completo

Crie:

```text
extrato_usuario(usuario_id)
```

retornando todas as operações financeiras do usuário:

| Data | Tipo | Valor | Descrição |
| ---- | ---- | ----: | --------- |

---

### Desafio 3 – Ranking financeiro

Crie:

```text
ranking_financeiro()
```

retornando:

| Posição | Usuário | Saldo | Total apostado |
| ------: | ------- | ----: | -------------: |

Utilize `ROW_NUMBER()`.

---

### Desafio 4 – Artilharia

Crie:

```text
artilharia()
```

retornando:

| Equipe | Gols Marcados |
| ------ | ------------: |

Ordene da maior para a menor quantidade de gols.

---

### Desafio 5 – Campeonato

Crie uma procedure:

```text
gerar_campeonato()
```

que:

1. percorra todas as equipes;
2. gere jogos entre elas;
3. não permita que uma equipe jogue contra ela mesma;
4. gere resultados aleatórios;
5. encerre os jogos;
6. atualize a classificação.

---

### Desafio 6 – Simulação de apostas

Crie uma procedure:

```text
simular_apostas(quantidade)
```

que gere apostas aleatórias para usuários e jogos existentes.

A procedure deverá utilizar:

* `FOR` ou `WHILE`;
* `random()`;
* `SELECT INTO`;
* validação de saldo;
* inserção de apostas;
* atualização de saldo.

---

### Desafio 7 – Processamento de apostas

Crie uma procedure:

```text
processar_apostas()
```

que percorra todas as apostas de jogos encerrados e:

1. identifique os vencedores;
2. calcule os prêmios;
3. credite os usuários;
4. registre o pagamento;
5. marque a aposta como processada.

---

# Parte 14 – Desafio final de revisão

### Desafio 8 – Sistema completo IFBET

Implemente um conjunto de subprogramas para disponibilizar as seguintes operações:

```text
obter_saldo()
nome_usuario()
nome_jogo()
quantidade_apostas()
valor_total_apostado()
ranking_apostadores()
historico_apostas()
estatisticas_equipe()
classificacao_campeonato()
```

E as seguintes procedures:

```text
depositar()
sacar()
transferir()
criar_aposta()
cancelar_aposta()
encerrar_jogo()
processar_apostas()
gerar_campeonato()
```

Durante a implementação, utilize os recursos:

```text
FUNCTION
PROCEDURE
IF / ELSE
CASE
SELECT INTO
FOR
WHILE
LOOP
EXIT
RETURNS TABLE
RETURN QUERY
RAISE NOTICE
EXCEPTION
JOIN
GROUP BY
ORDER BY
ROW_NUMBER()
COMMIT
```

### Desafio 9 – Validação completa

Depois de implementar o sistema, crie um **script de testes em `psql`** que execute, em sequência:

```sql
-- consultas
SELECT obter_saldo(1);
SELECT quantidade_apostas(1);

-- operações financeiras
CALL depositar(1, 500);
CALL sacar(1, 100);
CALL transferir(1, 2, 200);

-- apostas
CALL criar_aposta(1, 1, 100, 2.50);

-- consultas
SELECT *
FROM ranking_apostadores();

SELECT *
FROM historico_apostas(1);

-- encerramento
CALL encerrar_jogo(1, 2, 1);

-- processamento
CALL processar_apostas();

-- classificação
SELECT *
FROM classificacao_campeonato();
```