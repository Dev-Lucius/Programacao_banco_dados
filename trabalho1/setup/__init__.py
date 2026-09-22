from decimal import Decimal, InvalidOperation
import psycopg
from flask import Flask, render_template
from .config import AppConfig
from .routes import register_routes


def formatar_brl(valor) -> str:
    """
    Formata valores monetários para o padrão brasileiro.

    Exemplos:
        900       -> R$ 900,00
        975.50    -> R$ 975,50
        R$ 900,00 -> R$ 900,00
    """

    if valor is None:
        return "—"

    texto = str(valor).strip()

    # PostgreSQL pode retornar o tipo MONEY
    # já formatado como "R$ 900,00".
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


def create_app() -> Flask:
    """
    Cria e configura a aplicação Flask.
    """

    AppConfig.validate()

    app = Flask(__name__)

    app.config.from_object(AppConfig)

    app.jinja_env.filters["brl"] = formatar_brl

    register_routes(app)

    @app.errorhandler(psycopg.Error)
    def erro_banco(e):
        app.logger.exception("Erro de banco de dados")

        return (
            render_template(
                "erro.html",
                mensagem="Erro ao acessar o banco de dados."
            ),
            500
        )

    return app