# Trabalho - Plataforma Web IFBet (Python + Flask + Jinja + Psycopg)

## Instalações  e Configurações Necessárias

### Instalações

```bash
pip install flask python-dotenv psycopg[binary]
```
### Configurando Ambiente Virtual

```bash
# Instalação
mkdir myproject
cd trabalho1
python3 -m venv .venv

# Ativação
# Linux / macOS
. .venv/bin/activate

# Windows (CMD)
.venv\Scripts\activate.bat

# Windows (PowerShell)
.venv\Scripts\Activate.ps1
```
> Tendo Ativado, o prompt do terminal exibirá o nome do ambiente (ex: ```.venv```)

--- 

## Executando a Aplicação

```bash
python3 run.py
``` 

### Configurando o arquivo ```.env```

Este trabalho usa um arquivo ```.env```.

> abreviação de environment, ou ambiente

Sua função é armazenar variáveis de ambiente e informações sensíveis de forma centralizada fora do código-fonte da aplicação.

O Trabalho possui um ```.env-example``` que pode ajudar a configuração

```env
DB_NAME=nome_banco
DB_USER=usuario_banco
DB_PASSWORD=senha_banco
DB_HOST=localhost
DB_PORT=5432

FLASK_SECRET_KEY=chave_flask
```
