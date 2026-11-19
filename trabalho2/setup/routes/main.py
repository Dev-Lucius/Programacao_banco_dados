from flask import Blueprint, render_template
from ..services import dashboard_service


main_bp = Blueprint("main", __name__)


@main_bp.route("/", methods=["GET"])
def index():

    indicadores = dashboard_service.obter_indicadores()
    proximos_eventos = dashboard_service.listar_proximos_eventos()

    return render_template(
        "home.html",
        total_eventos=indicadores["total_eventos"],
        total_participantes=indicadores["total_participantes"],
        inscricoes_confirmadas=indicadores["inscricoes_confirmadas"],
        lista_espera=indicadores["lista_espera"],
        proximos_eventos=proximos_eventos
    )
