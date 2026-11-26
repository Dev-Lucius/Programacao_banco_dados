
from flask import Blueprint, current_app, flash, redirect, render_template, request, url_for
from ..services import participante_service

participantes_bp = Blueprint("participantes", __name__)


@participantes_bp.get("/participante/novo")
def novo_participante():
    """
    Apresenta o formulário de cadastro de participantes.
    """

    return render_template("participante_form.html")


@participantes_bp.post("/participante/novo")
def cadastrar_participante():
    """
    Recebe o formulário e solicita ao serviço
    o cadastro do participante no PostgreSQL.
    """

    nome = request.form.get("nome")
    email = request.form.get("email")
    tipo = request.form.get("tipo")

    try:
        participante_service.cadastrar_participante(
            nome=nome,
            email=email,
            tipo=tipo
        )

        flash(
            "Participante cadastrado com sucesso!",
            "sucesso"
        )

    except ValueError as erro:
        flash(
            str(erro),
            "erro"
        )

    except Exception:
        current_app.logger.exception(
            "Erro ao cadastrar participante."
        )

        flash(
            "Não foi possível cadastrar o participante.",
            "erro"
        )

    # Post/Redirect/Get:
    # evita reenviar o formulário ao atualizar a página.
    return redirect(
        url_for("participantes.novo_participante")
    )

