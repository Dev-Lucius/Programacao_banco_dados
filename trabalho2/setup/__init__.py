from decimal import Decimal, InvalidOperation
import psycopg
from flask import Flask, render_template

from .config import AppConfig


# ==================================================
# FORMATAÇÃO DE VALORES MONETÁRIOS
# ==================================================

def formatar_brl(valor) -> str:
    """
    Formata valores monetários para o padrão brasileiro.
    """

    if valor is None:
        return "—"

    texto = str(valor).strip()

    if texto.startswith("R$"):
        return texto

    try:
        valor_decimal = Decimal(texto)

    except (InvalidOperation, ValueError, TypeError):
        return "—"

    texto = f"{valor_decimal:,.2f}"

    texto = (
        texto
        .replace(",", "X")
        .replace(".", ",")
        .replace("X", ".")
    )

    return f"R$ {texto}"


# ==================================================
# CRIAÇÃO DA APLICAÇÃO
# ==================================================

def create_app() -> Flask:

    # Validar configurações
    AppConfig.validate()

    # Criar aplicação
    app = Flask(__name__)

    # Carregar configurações
    app.config.from_object(AppConfig)

    # Registrar filtro BRL
    app.jinja_env.filters["brl"] = formatar_brl

    @app.errorhandler(psycopg.Error)
    def erro_banco(error):

        app.logger.exception(
            "Erro ao acessar o banco de dados."
        )

        return (
            render_template(
                "erro.html",
                mensagem="Erro ao acessar o banco de dados."
            ),
            500
        )

    # ----------------------------------------------
    # REGISTRAR BLUEPRINTS
    # ----------------------------------------------
    from .routes import register_routes
    register_routes(app)
    return app

