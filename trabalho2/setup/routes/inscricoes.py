
from flask import Blueprint, current_app, flash, redirect, render_template, request, url_for
from ..services import inscricao_service


inscricoes_bp = Blueprint("inscricoes", __name__)


@inscricoes_bp.get("/inscricoes")
def listar_inscricoes():
    """
    Lista todas as inscrições cadastradas.
    """
    inscricoes = inscricao_service.listar_inscricoes()

    return render_template(
        "inscricoes.html",
        inscricoes=inscricoes
    )


@inscricoes_bp.get("/inscricoes/nova")
def nova_inscricao():
    """
    Exibe o formulário para realizar uma inscrição.
    """
    participantes = inscricao_service.listar_participantes()
    eventos = inscricao_service.listar_eventos()

    return render_template(
        "inscricao_form.html",
        participantes=participantes,
        eventos=eventos
    )


@inscricoes_bp.post("/inscricoes/nova")
def criar_inscricao():
    """
    Recebe os dados e solicita a realização da inscrição.
    """
    participante_id = request.form.get("participante_id")
    evento_id = request.form.get("evento_id")

    try:
        inscricao_service.realizar_inscricao(
            participante_id=participante_id,
            evento_id=evento_id
        )

        flash("Inscrição realizada com sucesso!", "sucesso")
        return redirect(url_for("inscricoes.listar_inscricoes"))

    except ValueError as erro:
        flash(str(erro), "erro")

    except Exception:
        current_app.logger.exception("Erro ao realizar inscrição.")
        flash("Não foi possível realizar a inscrição.", "erro")

    return redirect(url_for("inscricoes.nova_inscricao"))


@inscricoes_bp.post("/inscricoes/<int:inscricao_id>/cancelar")
def cancelar_inscricao(inscricao_id):
    """
    Solicita o cancelamento de uma inscrição.
    """
    try:
        inscricao_service.cancelar_inscricao(inscricao_id)

        flash("Inscrição cancelada com sucesso!", "sucesso")

    except ValueError as erro:
        flash(str(erro), "erro")

    except Exception:
        current_app.logger.exception("Erro ao cancelar inscrição.")
        flash("Não foi possível cancelar a inscrição.", "erro")

    return redirect(url_for("inscricoes.listar_inscricoes"))

