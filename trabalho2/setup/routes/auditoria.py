from flask import Blueprint


auditoria_bp = Blueprint(
    "auditoria",
    __name__
)

@auditoria_bp.route("/eventos", methods=["GET"])
def listar_eventos():

    return "<h1>Módulo de eventos em desenvolvimento</h1>"

# Futuramente:
# GET /auditoria