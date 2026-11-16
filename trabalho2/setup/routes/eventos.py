from flask import Blueprint, render_template
from ..services import evento_service

eventos_bp = Blueprint("eventos", __name__)


@eventos_bp.get("/eventos")
def listar_eventos():
    """
    Apresenta os eventos cadastrados.
    """

    eventos = evento_service.listar_eventos()

    return render_template(
        "eventos.html",
        eventos=eventos
    )


@eventos_bp.get("/eventos/novo")
def novo_evento():
    """
    Apresenta o formulário de cadastro de eventos.
    """

    categorias = evento_service.listar_categorias()
    locais = evento_service.listar_locais()

    return render_template(
        "evento_form.html",
        categorias=categorias,
        locais=locais
    )