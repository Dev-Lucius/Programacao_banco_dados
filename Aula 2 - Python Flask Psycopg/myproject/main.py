# Importando as ferramentas necessárias do Flask:
# - Flask: Classe principal para criar a aplicação web.
# - redirect: Permite redirecionar o usuário para outra rota.
# - request: Objeto para capturar dados enviados pelo navegador (como dados de formulários).
# - url_for: Gera URLs de forma dinâmica com base no nome das funções das rotas.
# - render_template: Responsável por renderizar os arquivos HTML localizados na pasta 'templates'.
from flask import Flask, redirect, request, url_for, render_template

# Importando a biblioteca psycopg para conectar e manipular o banco de dados PostgreSQL.
import psycopg

# Criando a instância principal da aplicação Flask.
# O argumento __name__ informa ao Flask onde procurar arquivos estáticos e templates.
app = Flask(__name__)

# Definindo a rota "/adicionar". 
# O parâmetro 'methods' define que essa rota aceita dois tipos de requisição HTTP:
# - GET: Quando o usuário apenas acessa a URL para visualizar a página do formulário.
# - POST: Quando o usuário preenche o formulário e envia os dados para o servidor.
@app.route("/adicionar", methods=['GET', 'POST'])
def adicionar():
    # Se a requisição for do tipo GET, exibimos a página com o formulário em branco
    if request.method == 'GET':
        return render_template('tela_adicionar.html')
    
    # Se não for GET (ou seja, é POST), processamos os dados enviados pelo usuário
    else:
        # Capturando os valores digitados nos inputs do formulário através dos atributos 'name'
        nome = request.form['nome']
        email = request.form['email']
        senha = request.form['senha']
        
        # Estabelecendo conexão com o banco de dados PostgreSQL.
        # O gerenciador de contexto 'with' fecha a conexão automaticamente ao terminar o bloco.
        with psycopg.connect(dbname="ifbet", user="postgres", password="postgres", port=5432, host="localhost") as conn:
            # Criando um cursor para enviar comandos SQL para o banco
            with conn.cursor() as cur:
                # Executando o comando SQL de inserção. 
                # Os '%s' são placeholders seguros que evitam falhas de segurança como SQL Injection.
                cur.execute(
                    "INSERT INTO usuario (nome, email, senha) VALUES (%s, %s, %s)", 
                    (nome, email, senha)
                )
                # Confirmando (efetivando) a transação de salvamento no banco de dados
                conn.commit()
                
        # Após salvar com sucesso, redirecionamos o usuário de volta para a função 'inicial' (rota "/")
        return redirect(url_for('inicial'))

# Definindo a rota raiz ("/") que corresponde à página principal da aplicação
@app.route("/")
def inicial():
    # Conectando-se ao banco de dados para buscar os registros existentes
    with psycopg.connect(dbname="ifbet", user="postgres", password="postgres", port=5432, host="localhost") as conn:
        # Abrindo o cursor para executar operações SQL
        with conn.cursor() as cur:
            # Executando a consulta para selecionar todos os usuários cadastrados
            cur.execute("SELECT * FROM usuario")
            
            # cur.fetchall() busca todas as linhas retornadas pela consulta (criando uma lista de tuplas).
            # Esses dados são enviados para o arquivo 'index.html' através da variável 'vetUsuario'.
            return render_template('index.html', vetUsuario=cur.fetchall())

# Bloco padrão para iniciar o servidor de desenvolvimento do Flask em modo de depuração (debug)
if __name__ == '__main__':
    app.run(debug=True)