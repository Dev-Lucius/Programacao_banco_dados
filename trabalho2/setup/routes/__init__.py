from .main import main_bp
from .participantes import participantes_bp
from .eventos import eventos_bp
from .inscricoes import inscricoes_bp
from .auditoria import auditoria_bp
from .relatorios import relatorios_bp

def register_routes(app):
    app.register_blueprint(main_bp)
    app.register_blueprint(participantes_bp)
    app.register_blueprint(eventos_bp)
    app.register_blueprint(inscricoes_bp)
    app.register_blueprint(auditoria_bp)
    app.register_blueprint(relatorios_bp)
