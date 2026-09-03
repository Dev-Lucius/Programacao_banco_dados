# Importa a classe Flask da biblioteca flask. 
# É ela que nos permite criar o servidor web e gerenciar as rotas.
from flask import Flask

# Cria uma instância (um objeto) da aplicação Flask.
# O parâmetro __name__ serve para o Flask saber onde procurar arquivos, templates e recursos estáticos.
app = Flask(__name__)

# O decorador @app.route diz ao Flask qual URL deve acionar a função logo abaixo.
# O argumento "/" indica que esta é a página principal (raiz) do site.
@app.route("/")
def hello_world():
    # A função retorna uma string simples diretamente para o navegador do usuário.
    return "Hello, World!"

# Este bloco verifica se o arquivo está sendo executado diretamente (e não importado por outro script).
if __name__ == "__main__":
    # Inicia o servidor de desenvolvimento local do Flask.
    # O parâmetro debug=True ativa o modo de depuração, o que faz o servidor reiniciar sozinho 
    # sempre que você salvar alterações no código e mostra erros detalhados no navegador se algo falhar.
    app.run(debug=True)