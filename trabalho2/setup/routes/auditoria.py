
from flask import Blueprint, render_template
from ..services import auditoria_service


auditoria_bp = Blueprint("auditoria", __name__)


@auditoria_bp.get("/auditoria")
def listar_auditoria():
    """
    Exibe o histórico de alterações nas inscrições.
    """
    registros = auditoria_service.listar_auditoria()

    return render_template(
        "auditoria.html",
        registros=registros
    )

