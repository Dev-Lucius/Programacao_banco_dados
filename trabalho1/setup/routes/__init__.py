from flask import Flask

from .apostas import apostas_bp
from .bilhetes import bilhetes_bp
from .dashboard import dashboard_bp


def register_routes(app: Flask) -> None:
    """
    Registra todos os Blueprints da aplicação.
    """

    app.register_blueprint(dashboard_bp)
    app.register_blueprint(apostas_bp)
    app.register_blueprint(bilhetes_bp)