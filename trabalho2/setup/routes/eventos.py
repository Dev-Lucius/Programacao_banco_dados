from flask import Blueprint


eventos_bp = Blueprint(
    "eventos",
    __name__
)

@eventos_bp.route("/eventos", methods=["GET"])
def listar_eventos():
    return "<h1>Módulo de eventos em desenvolvimento</h1>"

# Futuramente:
# GET  /eventos
# GET  /eventos/novo
# POST /eventos