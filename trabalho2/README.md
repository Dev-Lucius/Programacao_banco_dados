# Sistema de Gerenciamento de Eventos e Inscrições

Sistema web desenvolvido em **Python, Flask e PostgreSQL** para o gerenciamento de eventos, participantes e inscrições. O projeto permite acompanhar a ocupação das vagas, administrar listas de espera, registrar alterações e consultar relatórios de desempenho.

O sistema foi desenvolvido como projeto acadêmico da disciplina de **Programação em Banco de Dados**, com foco na aplicação prática de conceitos de SQL, PL/pgSQL, procedures, functions, triggers e integração entre uma aplicação web e um banco de dados relacional.

---

## 1. Objetivos do projeto

O principal objetivo é desenvolver um sistema que centralize o gerenciamento de eventos e inscrições, garantindo a integridade dos dados e automatizando operações importantes por meio de rotinas armazenadas no PostgreSQL.

Entre os objetivos específicos estão:

- Gerenciar o cadastro de eventos e participantes.
- Realizar inscrições de participantes em eventos.
- Controlar automaticamente a disponibilidade de vagas.
- Administrar listas de espera.
- Calcular valores de inscrição de acordo com o tipo de participante.
- Registrar alterações nas inscrições por meio de auditoria.
- Apresentar indicadores e relatórios de ocupação e arrecadação.
- Aplicar conceitos de programação no banco de dados.

---

## 2. Funcionalidades

### Dashboard

Página inicial com uma visão geral das informações do sistema.

- Quantidade total de eventos.
- Quantidade de participantes cadastrados.
- Total de inscrições confirmadas.
- Quantidade de inscrições em lista de espera.
- Listagem dos próximos eventos.
- Atalhos para as principais funcionalidades.

### Gerenciamento de participantes

Permite cadastrar participantes e classificá-los de acordo com seu tipo.

Tipos de participantes:

| Tipo | Descrição |
|---|---|
| Estudante | Participante com desconto de 50% |
| Professor | Participante com desconto de 30% |
| Externo | Participante sem desconto |

O cadastro considera informações como nome, e-mail e tipo de participante.

### Gerenciamento de eventos

Permite cadastrar e consultar os eventos disponíveis.

Cada evento possui informações como:

- Título.
- Categoria.
- Local.
- Data e horário de início.
- Data e horário de encerramento.
- Quantidade de vagas.
- Valor-base.
- Status do evento.

Os eventos podem apresentar os seguintes estados:

| Status | Descrição |
|---|---|
| Aberto | Evento disponível para inscrições |
| Encerrado | Evento sem novas inscrições |
| Cancelado | Evento cancelado |

### Gerenciamento de inscrições

Permite realizar e consultar inscrições vinculadas a participantes e eventos.

O processo de inscrição utiliza uma procedure PostgreSQL responsável por:

1. Validar a disponibilidade do evento.
2. Verificar a existência de vagas.
3. Calcular o valor da inscrição.
4. Confirmar a inscrição quando houver disponibilidade.
5. Inserir o participante na lista de espera quando não houver vagas.

Também é possível cancelar inscrições. Quando uma inscrição confirmada é cancelada, o sistema pode promover automaticamente o primeiro participante da lista de espera.

Estados das inscrições:

| Status | Descrição |
|---|---|
| Confirmada | Inscrição efetivada |
| Lista de espera | Participante aguardando disponibilidade |
| Cancelada | Inscrição cancelada |

### Auditoria

Apresenta o histórico de alterações realizadas nas inscrições.

Os registros são gerados automaticamente por uma trigger PostgreSQL e incluem:

- Identificador da inscrição.
- Participante.
- Evento.
- Status anterior.
- Novo status.
- Data e horário da alteração.
- Usuário responsável, conforme registrado pela rotina de auditoria.

### Relatórios

Página destinada à análise dos resultados dos eventos.

Apresenta indicadores gerais e informações individualizadas por evento:

- Total de eventos analisados.
- Total de vagas.
- Inscrições confirmadas.
- Inscrições em lista de espera.
- Percentual geral de ocupação.
- Arrecadação total.
- Percentual de ocupação por evento.
- Arrecadação individual por evento.

Os dados são obtidos por meio da função `fn_relatorio_ocupacao()`.

---

## 3. Tecnologias utilizadas

### Backend

- **Python 3.12:** linguagem principal da aplicação.
- **Flask:** framework utilizado para desenvolvimento da aplicação web.
- **Psycopg 3:** integração entre Python e PostgreSQL.
- **Jinja2:** renderização dinâmica das páginas HTML.

### Banco de dados

- **PostgreSQL:** sistema gerenciador de banco de dados relacional.
- **SQL:** definição e manipulação dos dados.
- **PL/pgSQL:** implementação de funções, procedures e triggers.

### Frontend

- **HTML5:** estrutura das páginas.
- **CSS3:** estilização e responsividade.
- **JavaScript:** interações e funcionalidades no navegador.
- **Font Awesome:** biblioteca de ícones.

---

## 4. Arquitetura do projeto

A aplicação utiliza uma organização modular, separando as responsabilidades entre rotas, serviços, templates, arquivos estáticos e configuração do banco de dados.

```text
trabalho2/
│
├── app.py
│
└── setup/
    │
    ├── __init__.py
    ├── config.py
    ├── db.py
    │
    ├── routes/
    │   ├── __init__.py
    │   ├── main.py
    │   ├── participantes.py
    │   ├── eventos.py
    │   ├── inscricoes.py
    │   ├── auditoria.py
    │   └── relatorios.py
    │
    ├── services/
    │   ├── __init__.py
    │   ├── participante_service.py
    │   ├── evento_service.py
    │   ├── inscricao_service.py
    │   ├── auditoria_service.py
    │   ├── dashboard_service.py
    │   └── relatorio_service.py
    │
    ├── templates/
    │   ├── base.html
    │   ├── home.html
    │   ├── participante_form.html
    │   ├── eventos.html
    │   ├── evento_form.html
    │   ├── inscricoes.html
    │   ├── inscricao_form.html
    │   ├── auditoria.html
    │   ├── relatorios.html
    │   └── erro.html
    │
    └── static/
        ├── css/
        │   ├── style.css
        │   ├── eventos.css
        │   ├── participantes.css
        │   ├── inscricoes.css
        │   ├── auditoria.css
        │   ├── dashboard.css
        │   └── relatorios.css
        │
        └── js/
            ├── main.js
            └── tabelas.js
```

### Responsabilidades dos módulos

| Diretório / arquivo | Responsabilidade |
|---|---|
| `app.py` | Inicialização da aplicação Flask |
| `setup/__init__.py` | Configuração e criação da aplicação |
| `setup/config.py` | Configurações gerais e do banco de dados |
| `setup/db.py` | Conexão e execução de operações no PostgreSQL |
| `routes/` | Definição das rotas e recebimento das requisições |
| `services/` | Regras de negócio e comunicação com o banco |
| `templates/` | Páginas HTML renderizadas pelo Flask |
| `static/css/` | Estilos da aplicação |
| `static/js/` | Interações e funcionalidades JavaScript |

### Fluxo de funcionamento

A aplicação segue um fluxo organizado para separar a interface, o processamento das requisições e a persistência dos dados.

```text
          USUÁRIO
             |
             v
       NAVEGADOR WEB
             |
             v
       ROTAS (FLASK)
             |
             v
          SERVICES
             |
             v
      DATABASE CONNECTION
             |
             v
         POSTGRESQL
             |
             v
   PROCEDURES / FUNCTIONS
       /      |      \
      v       v       v
  TRIGGERS  CONSULTAS  REGRAS
             |
             v
       RESULTADOS
             |
             v
       TEMPLATE HTML
             |
             v
       NAVEGADOR WEB
```

As rotas recebem os dados enviados pelo usuário e delegam o processamento aos respectivos services. Os services executam consultas e operações no banco de dados, enquanto o PostgreSQL mantém as regras que precisam ser aplicadas diretamente na camada de persistência.

---

## 5. Banco de dados

O PostgreSQL é responsável pelo armazenamento das informações e pela execução de regras de negócio relacionadas às inscrições.

### Principais entidades

| Tabela | Responsabilidade |
|---|---|
| `categoria` | Armazena as categorias dos eventos |
| `local` | Armazena os locais e suas capacidades |
| `evento` | Armazena os eventos cadastrados |
| `participante` | Armazena os participantes |
| `inscricao` | Registra as inscrições |
| `log_inscricao` | Armazena o histórico de alterações das inscrições |

### Relacionamentos

- Uma categoria pode estar associada a vários eventos.
- Um local pode receber vários eventos.
- Um participante pode possuir inscrições em diferentes eventos.
- Um evento pode possuir inscrições de diferentes participantes.
- Uma inscrição pode gerar vários registros de auditoria ao longo de seu histórico.

A tabela `inscricao` possui relacionamentos com `participante` e `evento`, além de uma restrição de unicidade parcial que impede inscrições duplicadas não canceladas para o mesmo participante e evento.

---

## 6. Rotinas armazenadas no PostgreSQL

Um dos principais objetivos acadêmicos do projeto é utilizar recursos de programação diretamente no banco de dados.

Foram desenvolvidas seis rotinas principais.

### 6.1. `trg_valida_inscricao`

**Tipo:** Trigger.

Executada antes da inserção de uma inscrição.

Responsabilidades:

- Impedir inscrições em eventos encerrados.
- Impedir inscrições em eventos cancelados.
- Verificar conflitos com outras inscrições confirmadas, conforme as regras implementadas.

### 6.2. `trg_auditoria_inscricao`

**Tipo:** Trigger.

Executada após inserções ou atualizações na tabela `inscricao`.

Responsabilidades:

- Registrar a criação de inscrições.
- Registrar alterações de status.
- Armazenar o status anterior e o novo status.
- Registrar data, horário e usuário responsável conforme a implementação.

Os registros são armazenados na tabela `log_inscricao`.

### 6.3. `sp_realizar_inscricao`

**Tipo:** Stored Procedure.

Responsável pelo processo de realização de uma inscrição.

Etapas principais:

1. Receber o identificador do participante e do evento.
2. Calcular o valor da inscrição.
3. Verificar a disponibilidade de vagas.
4. Confirmar a inscrição ou encaminhá-la para a lista de espera.

A procedure utiliza controle de concorrência com bloqueio da linha do evento durante o processamento.

### 6.4. `sp_cancelar_inscricao`

**Tipo:** Stored Procedure.

Responsável pelo cancelamento de uma inscrição.

Quando uma inscrição confirmada é cancelada e existe alguém aguardando, a procedure promove o primeiro participante da lista de espera, respeitando a ordem definida na rotina.

### 6.5. `fn_calcular_valor_inscricao`

**Tipo:** Function.

Calcula o valor da inscrição de acordo com o tipo de participante.

| Tipo | Desconto | Valor final |
|---|---:|---:|
| Estudante | 50% | 50% do valor-base |
| Professor | 30% | 70% do valor-base |
| Externo | 0% | 100% do valor-base |

A função é utilizada pela procedure `sp_realizar_inscricao`.

### 6.6. `fn_relatorio_ocupacao`

**Tipo:** Function.

Retorna informações consolidadas sobre a ocupação dos eventos.

Entre os dados retornados estão:

- Identificador do evento.
- Título.
- Quantidade de vagas.
- Total de inscrições confirmadas.
- Total de inscrições em lista de espera.
- Percentual de ocupação.
- Arrecadação.

Essa função é utilizada pelo módulo de relatórios da aplicação.

---

## 7. Instalação e configuração

### Requisitos

Antes de executar o projeto, verifique se possui:

- Python 3.12 ou compatível.
- PostgreSQL instalado e em execução.
- Git.
- Ambiente virtual Python.

### 7.1. Clonar o repositório

```bash
git clone URL_DO_REPOSITORIO
```

Entre na pasta do projeto:

```bash
cd trabalho2
```

### 7.2. Criar o ambiente virtual

```bash
python3 -m venv .venv
```

Ative o ambiente virtual:

```bash
source .venv/bin/activate
```

### 7.3. Instalar as dependências

Caso exista um arquivo `requirements.txt`:

```bash
pip install -r requirements.txt
```

As principais dependências utilizadas são:

```bash
pip install Flask "psycopg[binary]"
```

### 7.4. Configurar o PostgreSQL

Crie o banco de dados utilizado pela aplicação:

```sql
CREATE DATABASE trabalho2;
```

Configure as credenciais de acesso no arquivo `setup/config.py`, de acordo com os parâmetros esperados pela aplicação.

Exemplo de configuração:

```python
class AppConfig:

    DB_HOST = "localhost"
    DB_PORT = 5432
    DB_NAME = "trabalho2"
    DB_USER = "postgres"
    DB_PASSWORD = "sua_senha"
```

**Importante:** adapte os nomes dos atributos ao formato utilizado no seu `config.py`. Não compartilhe credenciais reais no repositório.

### 7.5. Criar a estrutura do banco

Execute os scripts SQL do projeto no banco de dados PostgreSQL.

A ordem de criação deve respeitar as dependências:

1. Tipos ENUM.
2. Tabelas.
3. Restrições e índices.
4. Funções.
5. Procedures.
6. Triggers.
7. Dados iniciais.

As tabelas e rotinas devem estar criadas antes da execução da aplicação.

---

## 8. Executando o projeto

Com o ambiente virtual ativado e o banco de dados configurado, execute:

```bash
python3 app.py
```

O servidor de desenvolvimento Flask estará disponível em:

```text
http://127.0.0.1:5000
```

Acesse o endereço no navegador para utilizar o sistema.

---

## 9. Principais rotas

| Método | Rota | Funcionalidade |
|---|---|---|
| GET | `/` | Dashboard |
| GET | `/participante/novo` | Formulário de participante |
| POST | `/participante/novo` | Cadastro de participante |
| GET | `/eventos` | Listagem de eventos |
| GET | `/eventos/novo` | Formulário de evento |
| POST | `/eventos/novo` | Cadastro de evento |
| GET | `/inscricoes` | Listagem de inscrições |
| GET | `/inscricoes/nova` | Formulário de inscrição |
| POST | `/inscricoes/nova` | Realização de inscrição |
| POST | `/inscricoes/<id>/cancelar` | Cancelamento de inscrição |
| GET | `/auditoria` | Histórico de alterações |
| GET | `/relatorios` | Relatórios de ocupação |

---

## 10. Conceitos aplicados

Durante o desenvolvimento do projeto, foram utilizados conceitos importantes de programação e banco de dados.

**Programação em Python**
- Modularização.
- Funções.
- Tratamento de exceções.
- Separação de responsabilidades.
- Integração com banco de dados.

**Desenvolvimento Web**
- Rotas e métodos HTTP.
- Templates dinâmicos.
- Herança de templates com Jinja2.
- Formulários HTML.
- CSS responsivo.
- JavaScript para interações.

**Banco de Dados**
- Modelagem relacional.
- Chaves primárias e estrangeiras.
- Restrições de integridade.
- Índices.
- Tipos ENUM.
- Consultas SQL.
- Funções e procedures.
- Triggers.
- Auditoria.
- Controle de concorrência.
- Transações.

---

## 11. Considerações finais

O projeto demonstra a integração entre uma aplicação web e um banco de dados relacional, utilizando o PostgreSQL não apenas como mecanismo de armazenamento, mas também como responsável pela execução de regras de negócio.

A utilização de procedures, functions e triggers permite centralizar operações importantes no banco de dados, contribuindo para a integridade das informações e para a organização da aplicação.

Além disso, a separação entre rotas e services facilita a manutenção do código e permite que a aplicação evolua de maneira modular.

---

## 12. Autor

**Desenvolvido como projeto acadêmico da disciplina de Programação em Banco de Dados.**

Lucas Oliveira

- GitHub: [Dev-Lucius](https://github.com/Dev-Lucius)
