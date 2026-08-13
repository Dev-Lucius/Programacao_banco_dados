# Lista de Exercícios – Stored Procedures e Functions no PostgreSQL

**Base de dados: IFBET**

## Parte 1 – Functions Básicas

### Exercício 1

Crie uma função `obter_saldo(usuario_id)` que retorne o saldo do usuário.

---

### Exercício 2

Crie uma função `quantidade_apostas(usuario_id)` que retorne o número total de apostas realizadas por um usuário.

---

### Exercício 3

Crie uma função `valor_total_apostado(usuario_id)` que retorne a soma de todas as apostas de um usuário.

---

### Exercício 4

Crie uma função `nome_equipe(equipe_id)` que retorne o nome da equipe.

---

### Exercício 5

Crie uma função `nome_jogo(jogo_id)` que retorne uma string no formato:

```text
SAO PAULO DE RG x RIO GRANDE
```

---

### Exercício 6

Crie uma função `possui_saldo(usuario_id, valor)` que retorne TRUE ou FALSE.

---

### Exercício 7

Crie uma função `total_usuarios()` que retorne a quantidade de usuários cadastrados.

---

### Exercício 8

Crie uma função `total_equipes()` que retorne a quantidade de equipes.

---

### Exercício 9

Crie uma função `total_jogos()` que retorne a quantidade de jogos cadastrados.

---

### Exercício 10

Crie uma função `media_valor_apostas()` que retorne a média dos valores apostados.

---

## Parte 2 – Functions Intermediárias

### Exercício 11

Crie uma função `usuario_mais_rico()` que retorne o nome do usuário com maior saldo.

---

### Exercício 12

Crie uma função `maior_aposta()` que retorne o maior valor apostado.

---

### Exercício 13

Crie uma função `apostas_usuario(usuario_id)` que retorne uma tabela contendo:

* id da aposta
* valor
* odd

---

### Exercício 14

Crie uma função `listar_jogos()` que retorne:

* equipe casa
* equipe visitante
* data

---

### Exercício 15

Crie uma função `lucro_potencial(aposta_id)`:

```text
valor × odd
```

---

### Exercício 16

Crie uma função `tempo_desde_jogo(jogo_id)` que retorne quantos dias passaram desde a realização do jogo.

---

### Exercício 17

Crie uma função `saldo_total_sistema()`.

---

### Exercício 18

Crie uma função `apostas_acima(valor)` que retorne todas as apostas acima de determinado valor.

---

### Exercício 19

Crie uma função `usuarios_sem_apostas()`.

---

### Exercício 20

Crie uma função `ranking_apostadores()` que retorne:

| Usuário | Número de apostas |

---

## Parte 3 – Procedures

### Exercício 21

Crie uma procedure `depositar(usuario_id, valor)` que aumente o saldo.

---

### Exercício 22

Crie uma procedure `sacar(usuario_id, valor)`.

Regras:

* verificar saldo;
* impedir saldo negativo.

---

### Exercício 23

Crie uma procedure `transferir(origem, destino, valor)`.

---

### Exercício 24

Crie uma procedure `cadastrar_equipe(nome, local)`.

---

### Exercício 25

Crie uma procedure `criar_jogo(casa, visitante, data)`.

---

### Exercício 26

Crie uma procedure `cancelar_aposta(aposta_id)`.

Regras:

* devolver o valor ao usuário;
* excluir a aposta.

---

### Exercício 27

Crie uma procedure `zerar_apostas_usuario(usuario_id)`.

---

### Exercício 28

Crie uma procedure `bonus_todos(valor)` que acrescente bônus a todos os usuários.

---

### Exercício 29

Crie uma procedure `simular_apostas(quantidade)` que gere apostas aleatórias utilizando a função `propor_aposta()`.

---

### Exercício 30

Crie uma procedure `encerrar_jogo(jogo_id, gols_casa, gols_visitante)`.

A procedure deverá:

* atualizar o resultado do jogo;
* identificar apostas vencedoras;
* calcular prêmio:

```text
prêmio = valor / odd
```

* creditar o saldo dos vencedores.

---

# Exercícios Desafio

### Desafio 1

Criar uma função que retorne o histórico completo de apostas de um usuário em formato texto:

```text
Jogo: SAO PAULO DE RG x RIO GRANDE
Placar apostado: 2 x 1
Valor: R$ 100,00
```

---

### Desafio 2

Criar uma função que gere estatísticas por equipe:

* número de jogos;
* gols marcados;
* gols sofridos.

---

### Desafio 3

Criar uma procedure que realize um campeonato completo entre todas as equipes, gerando jogos e resultados aleatórios.

---

### Desafio 4

Criar uma função que retorne a tabela de classificação:

| Time | P | V | E | D | GP | GC | SG |

---

### Desafio 5

Criar uma trigger que impeça apostas em jogos já encerrados.

---

## Consultas para testar

```sql
SELECT obter_saldo(1);

SELECT quantidade_apostas(2);

CALL depositar(1, 500);

CALL transferir(1,2,100);

SELECT * FROM ranking_apostadores();

CALL encerrar_jogo(1,2,1);
```
