# Introdução ao Flask

## Versão do Python

Recomendamos o uso da versão mais recente do Python. O Flask suporta Python 3.9 e mais recente

## Dependências

Essas distribuições serão instaladas automaticamente ao instalar o Flask.

- **Werkzeug** implementa o WSGI, a interface Python padrão entre aplicações e servidores.

- **Jinja** é um idioma de modelo que renderiza as páginas do seu aplicativo serve.

- **MarkupSafe** vem com Jinja. Ele escapa da entrada não confiável ao renderizar templates para evitar ataques de injeção.

- Sua perigosa assina com segurança dados para garantir sua integridade. Isto é usado para proteger o cookie de sessão da Flask.

- **Click** é uma estrutura para escrever aplicativos de linha de comando. Proporciona o flaskcomando e permite adicionar comandos de gerenciamento personalizados.

- O **Blinker** fornece suporte para Sinais.


## Ambientes virtuais

Use um ambiente virtual para gerenciar as dependências do seu projeto, tanto em desenvolvimento e na produção.

> Qual Problema Resolve um Ambiente Virtual?

- Quanto mais Python projetar você têm, o mais provável é que você precisa trabalhar com diferentes versões de Bibliotecas Python, ou mesmo Python em si. 

- Versões mais recentes de bibliotecas para uma projeto pode quebrar compatibilidade em outro projeto

- Ambientes virtuais são grupos independentes de bibliotecas Python, um para cada projeto. 

- Os pacotes instalados para um projeto não afetarão outros projetos ou pacotes do sistema operacional

### Criando um Ambiente

```bash
$ mkdir myproject
$ cd myproject
$ python3 -m venv .venv
```


### Ativando o Ambiente

```bash
$ . .venv/bin/activate
```

## Instalando o Flask

```bash
$ pip install Flask
```


## Instalando o psycopg

> **Psycopg** é um software livre que funciona como um adaptador de banco de dados PostgreSQL mais popular e avançado para a linguagem Python

Se você usa Python e PostgreSQL e gostaria de suportar a manutenção do adaptador mais avançado entre os dois sistemas, por favor considere tornando-se um patrocinador. 

O patrocínio ajuda a garantir a manutenção contínua do Psycopg 2, Psycopg 3 e projetos relacionados. 

```bash
pip install "psycopg[binary]"
```

## Executando o Código

```bash
flask --app hello run
```

> ``hello`` é o nome do nosso Arquivo 

---

# Objetos principais em Psycopg 3

O uso básico do Psycopg é comum a todos os adaptadores de banco de dados que implementam o protocolo DB-API.

Outros adaptadores de banco de dados, como o builtin sqlite3ou psycopg2, têm aproximadamente o mesmo padrão de interaç

```python
# Note: the module name is psycopg, not psycopg3
import psycopg

# Connect to an existing database
with psycopg.connect("dbname=test user=postgres") as conn:

    # Open a cursor to perform database operations
    with conn.cursor() as cur:

        # Execute a command: this creates a new table
        cur.execute("""
            CREATE TABLE test (
                id serial PRIMARY KEY,
                num integer,
                data text)
            """)

        # Pass data to fill a query placeholders and let Psycopg perform
        # the correct conversion (no SQL injections!)
        cur.execute(
            "INSERT INTO test (num, data) VALUES (%s, %s)",
            (100, "abc'def"))

        # Query the database and obtain data as Python objects.
        cur.execute("SELECT * FROM test")
        print(cur.fetchone())
        # will print (1, 100, "abc'def")

        # You can use `cur.executemany()` to perform an operation in batch
        cur.executemany(
            "INSERT INTO test (num) values (%s)",
            [(33,), (66,), (99,)])

        # You can use `cur.fetchmany()`, `cur.fetchall()` to return a list
        # of several records, or even iterate on the cursor
        cur.execute("SELECT id, num FROM test order by num")
        for record in cur:
            print(record)

        # Make the changes to the database persistent
        conn.commit()
```

> No exemplo, você pode ver alguns dos principais objetos e métodos e como eles Relacionar-se entre si:

- A função connect()cria uma nova sessão de banco de dados e retorna um novo Connectioninstância. AsyncConnection.connect()cria uma asyncioconexão em vez disso.

- O Connectionclasse encapsula uma sessão de banco de dados. Permite:

    * criar novos Cursorinstâncias usando o cursor()método para executar comandos e consultas de banco de dados, encerrar transações usando os métodos commit()ou rollback().

    * A classe Cursorpermite a interação com o banco de dados:

    * enviar comandos para o banco de dados usando métodos como execute()e executemany(),

    * recuperar dados do banco de dados, iterando no cursor ou usando métodos como tais fetchone(), fetchmany(), fetchall().

    > **Usando esses objetos como gerenciadores de contexto (ou seja, usando with) vai certificar-se para fechá-los e liberar seus recursos no final do bloco (observe que isso é diferente do psycopg2).**

