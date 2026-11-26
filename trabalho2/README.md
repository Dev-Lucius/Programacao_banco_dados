# Sistema de Gerenciamento de Eventos e Inscrições

Sistema web desenvolvido em **Python, Flask e PostgreSQL** para o gerenciamento de eventos, participantes e inscrições. A aplicação permite administrar vagas, controlar listas de espera, calcular valores de inscrição, registrar alterações e consultar relatórios de ocupação e arrecadação.

O projeto foi desenvolvido como trabalho acadêmico da disciplina de **Programação em Banco de Dados**, com foco na aplicação prática de conceitos de SQL, PL/pgSQL, funções, procedures, triggers, transações, integridade referencial e integração entre uma aplicação web e um banco de dados relacional.

---

## 1. Objetivos do projeto

O principal objetivo é desenvolver um sistema que centralize o gerenciamento de eventos e inscrições, garantindo a integridade dos dados e automatizando operações importantes por meio de rotinas armazenadas no PostgreSQL.

Entre os objetivos específicos estão:

- Gerenciar o cadastro de eventos e participantes.
- Realizar inscrições de participantes em eventos.
- Controlar automaticamente a disponibilidade de vagas.
- Impedir inscrições duplicadas e conflitos de horário.
- Administrar listas de espera e promover participantes automaticamente.
- Calcular valores de inscrição de acordo com o tipo de participante.
- Validar a capacidade física dos locais.
- Registrar alterações nas inscrições por meio de auditoria.
- Apresentar indicadores e relatórios de ocupação e arrecadação.
- Aplicar conceitos de programação diretamente no banco de dados.

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

Permite cadastrar e consultar participantes, classificando-os de acordo com seu tipo.

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
| Encerrado | Evento que não aceita novas inscrições |
| Cancelado | Evento cancelado |

O sistema também valida se a quantidade de vagas configurada para o evento não ultrapassa a capacidade física do local associado.

### Gerenciamento de inscrições

Permite realizar e consultar inscrições vinculadas a participantes e eventos.

O processo de inscrição utiliza a procedure `sp_realizar_inscricao()`, responsável por:

1. Verificar se o evento existe e está aberto.
2. Validar a capacidade do local.
3. Verificar a existência do participante.
4. Impedir inscrições ativas duplicadas.
5. Contabilizar as inscrições confirmadas.
6. Definir se a inscrição será confirmada ou encaminhada para a lista de espera.
7. Calcular o valor da inscrição.
8. Registrar a inscrição no banco de dados.

Estados das inscrições:

| Status | Descrição |
|---|---|
| Confirmada | Inscrição efetivada |
| Lista de espera | Participante aguardando disponibilidade |
| Cancelada | Inscrição cancelada |

Também é possível cancelar inscrições. Quando uma inscrição confirmada é cancelada, a procedure `sp_cancelar_inscricao()` procura o próximo participante elegível na lista de espera e tenta promovê-lo automaticamente.

A promoção respeita a ordem de chegada e considera as validações de inscrição. Quando a promoção é bem-sucedida, o valor da inscrição é recalculado de acordo com o tipo do participante.

### Auditoria

Apresenta o histórico de alterações realizadas nas inscrições.

Os registros são gerados automaticamente por uma trigger PostgreSQL e incluem:

- Identificador da inscrição.
- Status anterior.
- Novo status.
- Data e horário da alteração.
- Usuário responsável, conforme registrado pela rotina de auditoria.

Os dados são armazenados na tabela `log_inscricao`, permitindo acompanhar o histórico das operações.

### Relatórios

Página destinada à análise dos resultados dos eventos.

Apresenta indicadores gerais e informações individualizadas por evento:

- Total de eventos analisados.
- Total de vagas.
- Inscrições confirmadas.
- Inscrições em lista de espera.
- Percentual de ocupação por evento.
- Arrecadação por evento.
- Arrecadação total.

Os dados são obtidos por meio da função `fn_relatorio_ocupacao()`.

A arrecadação considera os valores registrados nas inscrições confirmadas.

---

## 3. Tecnologias utilizadas

### Backend

- **Python 3.12:** linguagem principal da aplicação.
- **Flask:** framework utilizado para desenvolvimento da aplicação web.
- **Psycopg 3:** integração entre Python e PostgreSQL.
- **Jinja2:** renderização dinâmica das páginas HTML.

### Banco de dados

- **PostgreSQL:** sistema gerenciador de banco de dados relacional.
- **SQL:** definição, consulta e manipulação dos dados.
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
       +--------+--------+
       |        |        |
       v        v        v
   PROCEDURES FUNCTIONS TRIGGERS
       |        |        |
       +--------+--------+
                |
                v
       VALIDAÇÕES E REGRAS
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

As rotas recebem os dados enviados pelo usuário e delegam o processamento aos respectivos services. Os services executam consultas e operações no banco de dados, enquanto o PostgreSQL mantém regras de integridade e operações que precisam ser aplicadas diretamente na camada de persistência.

---

## 5. Banco de dados

O PostgreSQL é responsável pelo armazenamento das informações e pela execução de regras de negócio relacionadas às inscrições.

**Nome do banco de dados:** `sistemas_eventos_inscricoes`

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

### Integridade e restrições

O banco utiliza diferentes mecanismos para preservar a consistência dos dados:

- Chaves primárias e estrangeiras.
- Restrições `CHECK`.
- Tipos enumerados (`ENUM`).
- Índices para otimização de consultas.
- Índice único parcial para impedir inscrições ativas duplicadas.
- Bloqueios de linhas durante operações críticas.
- Transações para garantir a consistência das operações.

Entre os índices utilizados está `uq_inscricao_ativa`, que impede que um mesmo participante possua mais de uma inscrição não cancelada para o mesmo evento.

---

## 6. Rotinas armazenadas no PostgreSQL

Um dos principais objetivos acadêmicos do projeto é utilizar recursos de programação diretamente no banco de dados.

Foram implementadas funções, procedures e triggers para centralizar validações, automatizar operações e preservar a integridade dos dados.

### 6.1. `fn_validar_inscricao()`

**Tipo:** Trigger Function.

Executada por meio da trigger `trg_valida_inscricao`, antes da inserção ou atualização de campos relevantes de uma inscrição.

Responsabilidades:

- Permitir o cancelamento de inscrições sem bloquear a operação por outras validações.
- Verificar se o evento existe.
- Impedir inscrições em eventos encerrados ou cancelados.
- Validar se a quantidade de vagas não ultrapassa a capacidade do local.
- Verificar a existência do participante.
- Impedir conflitos de horário com outras inscrições confirmadas do participante.
- Utilizar bloqueios de linhas durante a validação.

### 6.2. `fn_auditoria_inscricao()`

**Tipo:** Trigger Function.

Executada por meio da trigger `trg_auditoria_inscricao`, após inserções ou atualizações na tabela `inscricao`.

Responsabilidades:

- Registrar a criação de inscrições.
- Registrar alterações de status.
- Armazenar o status anterior e o novo status.
- Registrar data, horário e usuário responsável conforme a implementação.

Os registros são armazenados na tabela `log_inscricao`.

### 6.3. `sp_realizar_inscricao()`

**Tipo:** Stored Procedure.

Responsável pelo processo de realização de uma inscrição.

Etapas principais:

1. Recuperar e bloquear os dados do evento.
2. Verificar se o evento existe e está aberto.
3. Validar a capacidade do local.
4. Verificar a existência do participante.
5. Impedir inscrições ativas duplicadas.
6. Contabilizar as inscrições confirmadas.
7. Definir o status da nova inscrição.
8. Calcular o valor da inscrição.
9. Inserir o registro no banco de dados.

Quando existem vagas disponíveis, a inscrição é confirmada. Caso contrário, o participante é encaminhado para a lista de espera.

A procedure utiliza `FOR UPDATE` para bloquear a linha do evento durante o processamento, ajudando a evitar inconsistências em operações concorrentes sobre o mesmo evento.

### 6.4. `sp_cancelar_inscricao()`

**Tipo:** Stored Procedure.

Responsável pelo cancelamento de uma inscrição e pelo gerenciamento da lista de espera.

Etapas principais:

1. Identificar o evento associado à inscrição.
2. Bloquear o evento durante a operação.
3. Recuperar e bloquear a inscrição.
4. Verificar se a inscrição já está cancelada.
5. Atualizar o status para `cancelada`.
6. Verificar se o evento continua aberto.
7. Procurar participantes na lista de espera por ordem de chegada.
8. Tentar promover o próximo participante elegível.
9. Recalcular o valor da inscrição promovida.

Caso um participante não possa ser promovido por alguma validação, a procedure tenta o próximo candidato da lista de espera.

A promoção automática ocorre somente quando uma inscrição confirmada é cancelada e o evento continua aberto.

### 6.5. `fn_calcular_valor_inscricao()`

**Tipo:** Function.

Calcula o valor da inscrição de acordo com o tipo de participante.

| Tipo | Desconto | Valor final |
|---|---:|---:|
| Estudante | 50% | 50% do valor-base |
| Professor | 30% | 70% do valor-base |
| Externo | 0% | 100% do valor-base |

A função é utilizada pelas procedures de inscrição e cancelamento, permitindo calcular o valor inicial e atualizar o valor quando um participante é promovido da lista de espera.

### 6.6. `fn_relatorio_ocupacao()`

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

A função utiliza agregações SQL para consolidar as informações e é consumida pelo módulo de relatórios da aplicação.

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

Caso exista um arquivo `requirements.txt`, execute:

```bash
pip install -r requirements.txt
```

As principais dependências utilizadas são:

```bash
pip install Flask "psycopg[binary]" python-dotenv
```

### 7.4. Configurar o PostgreSQL

Crie o banco de dados utilizado pela aplicação:

```sql
CREATE DATABASE sistemas_eventos_inscricoes;
```

Configure as credenciais de acesso de acordo com os parâmetros esperados pela aplicação, utilizando o arquivo `setup/config.py` e as variáveis de ambiente, caso estejam configuradas no projeto.

Exemplo de configuração:

```python
class AppConfig:

    DB_HOST = "localhost"
    DB_PORT = 5432
    DB_NAME = "sistemas_eventos_inscricoes"
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
4. Funções auxiliares.
5. Funções associadas às triggers.
6. Procedures.
7. Triggers.
8. Dados iniciais.

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

### Programação em Python

- Modularização.
- Funções.
- Tratamento de exceções.
- Separação de responsabilidades.
- Integração com banco de dados.

### Desenvolvimento Web

- Rotas e métodos HTTP.
- Templates dinâmicos.
- Herança de templates com Jinja2.
- Formulários HTML.
- CSS responsivo.
- JavaScript para interações.

### Banco de Dados

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
- Agregações e relatórios.

---

## 11. Considerações finais

O projeto demonstra a integração entre uma aplicação web e um banco de dados relacional, utilizando o PostgreSQL não apenas como mecanismo de armazenamento, mas também como responsável pela execução de regras de negócio.

A utilização de procedures, functions e triggers permite centralizar operações importantes no banco de dados, contribuindo para a integridade das informações, a automação de processos e a organização da aplicação.

Além disso, a separação entre rotas e services facilita a manutenção do código e permite que a aplicação evolua de maneira modular.

O desenvolvimento também proporcionou a aplicação prática de conceitos de modelagem, programação em PL/pgSQL, integridade referencial, auditoria e controle de concorrência.

---

## 12. Autor

**Desenvolvido como projeto acadêmico da disciplina de Programação em Banco de Dados.**

Lucas Oliveira

- GitHub: [Dev-Lucius](https://github.com/Dev-Lucius)
