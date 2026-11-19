# **Lista de Exercícios – PostgreSQL: Stored Procedures, Procedures e Triggers**

**Disciplina:** Programação em Banco de Dados\
**Linguagem:** SQL / PL/pgSQL\
**SGBD:** PostgreSQL

## **1. Cenário: Sistema de gerenciamento de biblioteca**

Considere um banco de dados de uma biblioteca que controla leitores, livros, exemplares, empréstimos e devoluções.

A estrutura inicial do banco de dados é apresentada a seguir.

### **1.1. Criação das tabelas**

```
CREATE TABLE leitor (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    ativo BOOLEAN DEFAULT TRUE
);

CREATE TABLE livro (
    id SERIAL PRIMARY KEY,
    titulo VARCHAR(150) NOT NULL,
    autor VARCHAR(100),
    categoria VARCHAR(50),
    quantidade_emprestimos INTEGER DEFAULT 0
);

CREATE TABLE exemplar (
    id SERIAL PRIMARY KEY,
    livro_id INTEGER NOT NULL REFERENCES livro(id),
    codigo VARCHAR(20) UNIQUE NOT NULL,
    status VARCHAR(20) DEFAULT 'disponivel'
        CHECK (status IN ('disponivel', 'emprestado', 'manutencao'))
);

CREATE TABLE emprestimo (
    id SERIAL PRIMARY KEY,
    leitor_id INTEGER NOT NULL REFERENCES leitor(id),
    exemplar_id INTEGER NOT NULL REFERENCES exemplar(id),
    data_emprestimo DATE DEFAULT CURRENT_DATE,
    data_devolucao DATE,
    status VARCHAR(20) DEFAULT 'aberto'
        CHECK (status IN ('aberto', 'devolvido'))
);
```

### **1.2. Tabela de auditoria**

Será utilizada para registrar operações realizadas no banco de dados.

```
CREATE TABLE auditoria (
    id SERIAL PRIMARY KEY,
    tabela VARCHAR(50),
    operacao VARCHAR(20),
    registro_id INTEGER,
    descricao TEXT,
    data_operacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### **1.3. Inserção de dados iniciais**

```
INSERT INTO leitor (nome, email) VALUES
('João Silva', 'joao@email.com'),
('Maria Souza', 'maria@email.com'),
('Pedro Santos', 'pedro@email.com');

INSERT INTO livro (titulo, autor, categoria) VALUES
('Banco de Dados', 'Elmasri', 'Computação'),
('Clean Code', 'Robert Martin', 'Programação'),
('Java Como Programar', 'Deitel', 'Programação');

INSERT INTO exemplar (livro_id, codigo) VALUES
(1, 'LIV001'),
(1, 'LIV002'),
(2, 'LIV003'),
(3, 'LIV004'),
(3, 'LIV005');
```

# **2. Exercícios sobre TRIGGERS**

Maior foco da lista

### **Exercício 1 – Trigger de auditoria de inserção**

Crie uma trigger que registre automaticamente na tabela `auditoria` toda vez que um novo empréstimo for cadastrado.

A auditoria deverá armazenar:

- Nome da tabela;
- Operação realizada;
- ID do empréstimo inserido;
- Uma descrição informando o leitor e o exemplar envolvidos.

**Requisitos:**

a) Crie uma função PL/pgSQL que receba os dados da operação por meio de `NEW`.

b) Crie uma trigger `AFTER INSERT` na tabela `emprestimo`.

c) Cadastre dois empréstimos e verifique os registros gerados na tabela `auditoria`.

### **Exercício 2 – Trigger de atualização de status do exemplar**

Sempre que um empréstimo for cadastrado, o exemplar correspondente deverá mudar seu status para `emprestado`.

**Requisitos:**

a) Crie uma função de trigger que utilize `NEW.exemplar_id`.

b) Atualize o status do exemplar correspondente.

c) Crie uma trigger `AFTER INSERT` na tabela `emprestimo`.

d) Cadastre um empréstimo e verifique se o exemplar foi atualizado.

### **Exercício 3 – Trigger de validação antes da inserção**

Implemente uma trigger que impeça a realização de um empréstimo quando:

- O leitor estiver inativo;
- O exemplar não estiver disponível;
- O exemplar estiver em manutenção.

**Requisitos:**

a) Crie uma função PL/pgSQL que consulte as tabelas `leitor` e `exemplar`.

b) Utilize `RAISE EXCEPTION` para impedir a operação quando alguma condição não for atendida.

c) Crie uma trigger `BEFORE INSERT` na tabela `emprestimo`.

d) Teste diferentes situações, incluindo empréstimos válidos e inválidos.

### **Exercício 4 – Trigger de devolução de exemplar**

Quando um empréstimo tiver seu status alterado de `aberto` para `devolvido`, o exemplar deverá voltar a ficar disponível.

**Requisitos:**

a) Crie uma função de trigger que identifique a alteração do status.

b) Utilize `OLD` e `NEW` para verificar o estado anterior e o novo estado do empréstimo.

c) Atualize o status do exemplar para `disponivel`.

d) Crie uma trigger `AFTER UPDATE` na tabela `emprestimo`.

e) Teste a devolução de um empréstimo.

### **Exercício 5 – Trigger para atualização da quantidade de empréstimos**

A tabela `livro` possui o atributo `quantidade_emprestimos`.

Crie uma trigger que atualize automaticamente esse atributo sempre que um empréstimo for cadastrado.

**Requisitos:**

a) Identifique o livro associado ao exemplar emprestado.

b) Incremente o atributo `quantidade_emprestimos` do livro correspondente.

c) Crie uma trigger `AFTER INSERT` na tabela `emprestimo`.

d) Cadastre vários empréstimos e confira os resultados.

### **Exercício 6 – Trigger de controle de alterações**

Crie uma trigger para registrar na tabela `auditoria` todas as alterações realizadas na tabela `livro`.

A auditoria deverá registrar:

- ID do livro;
- Operação realizada;
- Título anterior;
- Título novo;
- Data e horário da alteração.

**Requisitos:**

a) Implemente uma função que trate operações de atualização.

b) Utilize `OLD` para acessar os valores anteriores.

c) Utilize `NEW` para acessar os valores atualizados.

d) Crie uma trigger `AFTER UPDATE`.

e) Altere o título e a categoria de um livro e verifique os registros de auditoria.

### **Exercício 7 – Trigger para impedir exclusão de livros emprestados**

Implemente uma trigger que impeça a exclusão de um livro quando existir algum exemplar associado a ele que esteja emprestado.

**Requisitos:**

a) Crie uma função que consulte a tabela `exemplar`.

b) Verifique se existe algum exemplar com status `emprestado` associado ao livro que será excluído.

c) Utilize `RAISE EXCEPTION` para impedir a exclusão.

d) Crie uma trigger `BEFORE DELETE` na tabela `livro`.

e) Teste a exclusão de livros com exemplares disponíveis e emprestados.

### **Exercício 8 – Trigger para controlar o prazo de devolução**

Adicione à tabela `emprestimo` o atributo `data_prevista_devolucao`.

```
ALTER TABLE emprestimo
ADD COLUMN data_prevista_devolucao DATE;
```

Crie uma trigger que defina automaticamente a data prevista de devolução para 15 dias após a data do empréstimo.

**Requisitos:**

a) Crie uma função de trigger que calcule a data prevista.

b) Utilize `NEW.data_emprestimo`.

c) Atribua o resultado a `NEW.data_prevista_devolucao`.

d) Crie uma trigger `BEFORE INSERT`.

e) Cadastre empréstimos e verifique as datas geradas.

### **Exercício 9 – Trigger com FOR EACH ROW e FOR EACH STATEMENT**

Considere a tabela `livro`.

Implemente duas triggers para registrar operações de atualização na tabela de auditoria:

- Uma trigger utilizando `FOR EACH ROW`.
- Outra trigger utilizando `FOR EACH STATEMENT`.

**Requisitos:**

a) Na trigger por linha, registre o ID de cada livro atualizado.

b) Na trigger por comando, registre que uma operação de atualização foi executada na tabela.

c) Execute o seguinte comando:

```
UPDATE livro
SET categoria = 'Tecnologia'
WHERE categoria = 'Programação';
```

d) Observe quantos registros foram gerados por cada trigger.

e) Explique a diferença entre os dois mecanismos, considerando uma operação que atualize vários registros.

### **Exercício 10 – Trigger de exclusão com auditoria**

Crie uma trigger que registre na tabela `auditoria` os dados de um empréstimo antes que ele seja excluído.

A descrição deverá conter o ID do leitor, o ID do exemplar e o status do empréstimo.

**Requisitos:**

a) Utilize `OLD` para recuperar os dados do empréstimo.

b) Crie uma trigger `BEFORE DELETE`.

c) Registre a operação na tabela de auditoria.

d) Exclua um empréstimo e verifique se a auditoria foi registrada.

### **Exercício 11 – Trigger de validação de datas**

Implemente uma trigger que impeça a atualização de um empréstimo quando a data de devolução for anterior à data do empréstimo.

**Requisitos:**

a) Crie uma função de trigger que compare `NEW.data_devolucao` com `NEW.data_emprestimo`.

b) Utilize `RAISE EXCEPTION` caso a data seja inválida.

c) Crie uma trigger `BEFORE UPDATE`.

d) Teste atualizações com datas válidas e inválidas.

### **Exercício 12 – Trigger para impedir múltiplos empréstimos do mesmo exemplar**

Implemente uma trigger que impeça o cadastro de um novo empréstimo para um exemplar que já possua um empréstimo com status `aberto`.

**Requisitos:**

a) Consulte a tabela `emprestimo` antes da inserção.

b) Verifique se já existe um empréstimo aberto para o exemplar informado.

c) Utilize `RAISE EXCEPTION` quando encontrar um empréstimo em aberto.

d) Crie uma trigger `BEFORE INSERT`.

e) Teste a tentativa de cadastrar dois empréstimos simultâneos para o mesmo exemplar.

# **3. Exercícios sobre FUNCTIONS e STORED PROCEDURES**

No PostgreSQL, as funções são criadas com `CREATE FUNCTION` e podem retornar valores ou conjuntos de registros. Já as procedures são criadas com `CREATE PROCEDURE` e executadas por meio de `CALL`.

### **Exercício 13 – Function para consultar empréstimos de um leitor**

Crie uma função chamada `consultar_emprestimos` que receba o ID de um leitor e retorne todos os seus empréstimos.

**Requisitos:**

a) Receba o ID do leitor como parâmetro.

b) Retorne o ID do empréstimo, título do livro, data do empréstimo e status.

c) Utilize `RETURNS TABLE`.

d) Faça a consulta relacionando as tabelas `emprestimo`, `exemplar` e `livro`.

e) Execute a função para diferentes leitores.

### **Exercício 14 – Function para calcular quantidade de empréstimos**

Crie uma função chamada `total_emprestimos_leitor` que receba o ID de um leitor e retorne a quantidade total de empréstimos realizados por ele.

**Requisitos:**

a) Receba o ID do leitor.

b) Utilize `COUNT(*)`.

c) Retorne um valor inteiro.

d) Considere todos os empréstimos, independentemente do status.

e) Execute a função para diferentes leitores.

### **Exercício 15 – Procedure para cadastrar empréstimos**

Crie uma procedure chamada `cadastrar_emprestimo` que receba o ID do leitor e o ID do exemplar.

A procedure deverá realizar o cadastro de um novo empréstimo.

**Requisitos:**

a) Receba os parâmetros necessários.

b) Insira um registro na tabela `emprestimo`.

c) Utilize `CALL` para executar a procedure.

d) Verifique se as triggers implementadas nos exercícios anteriores são executadas automaticamente.

e) Teste o cadastro com exemplares disponíveis e indisponíveis.

### **Exercício 16 – Procedure para registrar devolução**

Crie uma procedure chamada `registrar_devolucao` que receba o ID de um empréstimo.

A procedure deverá atualizar o status do empréstimo para `devolvido` e registrar a data da devolução.

**Requisitos:**

a) Receba o ID do empréstimo.

b) Atualize o status para `devolvido`.

c) Atualize a data de devolução para `CURRENT_DATE`.

d) Verifique se o empréstimo existe e ainda está aberto.

e) Utilize `RAISE EXCEPTION` para situações inválidas.

f) Verifique se a trigger de devolução do exemplar foi executada.

### **Exercício 17 – Function para calcular livros mais emprestados**

Crie uma função chamada `livros_mais_emprestados` que retorne os livros ordenados pela quantidade de empréstimos.

**Requisitos:**

a) Retorne o título do livro e a quantidade de empréstimos.

b) Utilize `ORDER BY`.

c) Apresente primeiro os livros mais emprestados.

d) Limite o resultado aos cinco primeiros livros.

### **Exercício 18 – Procedure para desativar leitores**

Crie uma procedure chamada `desativar_leitor` que receba o ID de um leitor e altere seu atributo `ativo` para `false`.

**Requisitos:**

a) Receba o ID do leitor.

b) Verifique se o leitor existe.

c) Verifique se ele possui empréstimos em aberto.

d) Caso possua empréstimos em aberto, impeça a desativação.

e) Caso contrário, realize a atualização.

# **4. Desafio integrador – Sistema de biblioteca**

Desenvolva uma solução utilizando funções, procedures e triggers para automatizar o processo de empréstimos e devoluções.

A solução deverá contemplar:

1. Cadastro de empréstimos por meio de uma procedure.
2. Validação de disponibilidade dos exemplares por meio de trigger.
3. Atualização automática do status do exemplar.
4. Registro das operações em uma tabela de auditoria.
5. Atualização da quantidade de empréstimos dos livros.
6. Devolução de exemplares por meio de uma procedure.
7. Atualização automática do status do exemplar após a devolução.
8. Consulta dos empréstimos de um leitor por meio de uma function.
9. Consulta dos livros mais emprestados por meio de uma function.
10. Impedimento de exclusões indevidas.

## **5. Quadro de revisão dos principais recursos**

| Recurso              | Finalidade                                             | Exemplo                            |
| -------------------- | ------------------------------------------------------ | ---------------------------------- |
| `CREATE FUNCTION`    | Criar funções que podem retornar valores ou registros. | Consultar empréstimos.             |
| `CREATE PROCEDURE`   | Criar procedimentos executados com `CALL`.             | Registrar devolução.               |
| `CREATE TRIGGER`     | Automatizar ações diante de operações no banco.        | Atualizar status do exemplar.      |
| `NEW`                | Acessar os valores novos de um registro.               | `NEW.exemplar_id`                  |
| `OLD`                | Acessar os valores anteriores de um registro.          | `OLD.status`                       |
| `BEFORE`             | Executar a trigger antes da operação.                  | Validar um empréstimo.             |
| `AFTER`              | Executar a trigger após a operação.                    | Registrar auditoria.               |
| `FOR EACH ROW`       | Executar uma vez para cada registro afetado.           | Auditar cada livro atualizado.     |
| `FOR EACH STATEMENT` | Executar uma vez para cada comando SQL.                | Registrar uma atualização em lote. |
| `RAISE EXCEPTION`    | Interromper a operação gerando um erro.                | Impedir empréstimo inválido.       |
| `RETURN NEW`         | Retornar o registro novo em uma trigger de linha.      | Trigger `BEFORE INSERT`.           |
| `RETURN OLD`         | Retornar o registro antigo em uma trigger de linha.    | Trigger `BEFORE DELETE`.           |

**Atenção:** no PostgreSQL, a função associada a uma trigger é criada com `RETURNS TRIGGER`. Ela não é chamada diretamente com `SELECT`: sua execução ocorre automaticamente quando a trigger é acionada.

**Recomendação para estudo:** dê prioridade aos exercícios 1 a 12. É importante dominar especialmente a diferença entre `BEFORE` e `AFTER`, `OLD` e `NEW`, `FOR EACH ROW` e `FOR EACH STATEMENT`, além de saber quando utilizar `RETURN NEW`, `RETURN OLD` e `RAISE EXCEPTION`.
