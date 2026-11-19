from flask import Blueprint, render_template
from ..services import relatorio_service


relatorios_bp = Blueprint("relatorios", __name__)


@relatorios_bp.get("/relatorios")
def listar_relatorios():

    relatorio = relatorio_service.obter_relatorio_ocupacao()

    return render_template(
        "relatorios.html",
        relatorio=relatorio
    )