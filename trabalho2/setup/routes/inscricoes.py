from flask import Blueprint


inscricoes_bp = Blueprint(
    "inscricoes",
    __name__
)

@inscricoes_bp.route("/inscricoes", methods=["GET"])
def listar_eventos():

    return "<h1>Módulo de eventos em desenvolvimento</h1>"

# Futuramente:
# GET  /inscricoes/nova
# GET  /inscricoes/valor
# POST /inscricoes
# GET  /participantes/<int:participante_id>/inscricoes
# POST /inscricoes/<int:inscricao_id>/cancelar