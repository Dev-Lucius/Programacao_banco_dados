
from flask import Blueprint, current_app, flash, redirect, render_template, request, url_for
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


@eventos_bp.post("/eventos/novo")
def cadastrar_evento():
    """
    Recebe os dados do formulário e solicita
    o cadastro do evento no PostgreSQL.
    """

    titulo = request.form.get("titulo")
    categoria_id = request.form.get("categoria_id")
    local_id = request.form.get("local_id")
    data_inicio = request.form.get("data_inicio")
    data_fim = request.form.get("data_fim")
    vagas = request.form.get("vagas")
    valor_base = request.form.get("valor_base")

    try:
        evento_service.cadastrar_evento(
            titulo=titulo,
            categoria_id=categoria_id,
            local_id=local_id,
            data_inicio=data_inicio,
            data_fim=data_fim,
            vagas=vagas,
            valor_base=valor_base
        )

        flash("Evento cadastrado com sucesso!", "sucesso")

    except ValueError as erro:
        flash(str(erro), "erro")

    except Exception:
        current_app.logger.exception(
            "Erro ao cadastrar evento."
        )

        flash(
            "Não foi possível cadastrar o evento.",
            "erro"
        )

    # Post/Redirect/Get
    return redirect(
        url_for("eventos.listar_eventos")
    )

