# Introdução ao Flask

## Requisitos

Recomenda-se o uso da versão mais recente do Python. O Flask suporta **Python 3.9 ou superior**.

---

## Dependências do Flask

As seguintes bibliotecas são instaladas automaticamente junto com o Flask:

| Biblioteca | Função |
|---|---|
| **Werkzeug** | Implementa o WSGI, a interface padrão Python entre aplicações e servidores web. |
| **Jinja** | Linguagem de templates para renderizar páginas HTML dinamicamente. |
| **MarkupSafe** | Acompanha o Jinja. Escapa entradas não confiáveis durante a renderização de templates, prevenindo ataques de injeção (XSS). |
| **ItsDangerous** | Assina dados de forma segura para garantir integridade. Utilizado para proteger cookies de sessão do Flask. |
| **Click** | Framework para criar interfaces de linha de comando. Fornece o comando `flask` e permite adicionar comandos personalizados. |
| **Blinker** | Biblioteca opcional que fornece suporte a **Sinais** no Flask. |

---

## Ambientes Virtuais

Um ambiente virtual gerencia as dependências do seu projeto de forma isolada, tanto em desenvolvimento quanto em produção.

### Por que usar um ambiente virtual?

- Quanto mais projetos Python você desenvolve, maior a probabilidade de precisar trabalhar com **versões diferentes** de bibliotecas ou até mesmo do próprio Python.
- Uma versão mais recente de uma biblioteca em um projeto pode **quebrar a compatibilidade** de outro projeto.
- Ambientes virtuais criam **grupos independentes** de bibliotecas Python, um para cada projeto.
- Os pacotes instalados em um projeto **não afetam** outros projetos nem os pacotes do sistema operacional.

### Criando um ambiente virtual

```bash
mkdir myproject
cd myproject
python3 -m venv .venv
```

### Ativando o ambiente virtual

```bash
# Linux / macOS
. .venv/bin/activate

# Windows (CMD)
.venv\Scripts\activate.bat

# Windows (PowerShell)
.venv\Scripts\Activate.ps1
```

> Após ativar, o prompt do terminal exibirá o nome do ambiente (ex: `(.venv)`).

---

## Instalando o Flask

Com o ambiente virtual ativado, execute:

```bash
pip install Flask
```

---

## Instalando o Psycopg (adaptador PostgreSQL para Python)

**Psycopg** é o adaptador de banco de dados PostgreSQL mais popular e avançado para Python.

```bash
pip install "psycopg[binary]"
```

> A opção `[binary]` instala a versão pré-compilada, dispensando a instalação de dependências de compilação no sistema.

---

## Executando a Aplicação

```bash
flask --app nome_do_arquivo run
```

**Exemplo:** se seu arquivo principal se chama `hello.py`:

```bash
flask --app hello run
```

> Por padrão, o servidor roda em `http://127.0.0.1:5000`.

---

# Objetos Principais do Psycopg 3

O padrão de uso do Psycopg é semelhante ao de outros adaptadores DB-API, como o `sqlite3` nativo do Python e o `psycopg2`.

```python
# Importante: o nome do módulo é psycopg, não psycopg3
import psycopg

# Conecta a um banco de dados existente
with psycopg.connect("dbname=test user=postgres") as conn:

    # Abre um cursor para executar operações no banco
    with conn.cursor() as cur:

        # Executa um comando: cria uma nova tabela
        cur.execute("""
            CREATE TABLE test (
                id serial PRIMARY KEY,
                num integer,
                data text
            )
        """)

        # Passa dados para preencher placeholders (%s).
        # O Psycopg converte automaticamente, prevenindo SQL Injection.
        cur.execute(
            "INSERT INTO test (num, data) VALUES (%s, %s)",
            (100, "abc'def")
        )

        # Consulta o banco e obtém os dados como objetos Python
        cur.execute("SELECT * FROM test")
        print(cur.fetchone())
        # Saída: (1, 100, "abc'def")

        # executemany() realiza operações em lote
        cur.executemany(
            "INSERT INTO test (num) VALUES (%s)",
            [(33,), (66,), (99,)]
        )

        # fetchmany() e fetchall() retornam listas de registros.
        # Também é possível iterar diretamente sobre o cursor.
        cur.execute("SELECT id, num FROM test ORDER BY num")
        for record in cur:
            print(record)

        # Torna as alterações permanentes no banco de dados
        conn.commit()
```

### Relação entre os principais objetos

| Objeto / Método | Descrição |
|---|---|
| `psycopg.connect()` | Cria uma nova sessão com o banco de dados e retorna uma instância de `Connection`. Para conexões assíncronas, use `AsyncConnection.connect()`. |
| `Connection` | Encapsula uma sessão de banco de dados. Permite criar cursores com `cursor()`, confirmar transações com `commit()` e desfazê-las com `rollback()`. |
| `Cursor` | Permite interagir com o banco de dados: enviar comandos via `execute()` e `executemany()`, e recuperar dados com `fetchone()`, `fetchmany()`, `fetchall()` ou iterando diretamente sobre o cursor. |

> **Uso de `with` (context manager):** utilizar `with` garante que conexões e cursores sejam **fechados automaticamente** e seus recursos liberados ao final do bloco. Esse comportamento é uma diferença importante em relação ao `psycopg2`.

---

## Resumo dos Métodos do Cursor

| Método | Função |
|---|---|
| `execute(sql, params)` | Executa um único comando SQL com parâmetros opcionais. |
| `executemany(sql, params_list)` | Executa o mesmo comando SQL várias vezes com diferentes parâmetros (operação em lote). |
| `fetchone()` | Retorna a próxima linha do resultado como uma tupla, ou `None` se não houver mais linhas. |
| `fetchmany(size=n)` | Retorna uma lista com até `n` linhas do resultado. |
| `fetchall()` | Retorna uma lista com **todas** as linhas restantes do resultado. |
| `for record in cur` | Itera sobre todas as linhas do resultado de forma eficiente. |

---

## Dicas Importantes

- **Sempre use placeholders (`%s`)** ao passar valores para consultas. O Psycopg trata a conversão e prevenção de SQL Injection automaticamente.
- **Utilize `with`** para gerenciar conexões e cursores. Isso evita vazamento de recursos.
- **Chame `conn.commit()`** para confirmar transações de escrita (`INSERT`, `UPDATE`, `DELETE`). Sem isso, as alterações serão perdidas ao fechar a conexão.
- Em caso de erro durante uma transação, use `conn.rollback()` para desfazer as alterações pendentes.
