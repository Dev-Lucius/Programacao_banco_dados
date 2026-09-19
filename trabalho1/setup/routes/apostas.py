from flask import Blueprint, abort, flash, redirect, request, url_for
from ..services import aposta_service

apostas_bp = Blueprint("apostas", __name__)


@apostas_bp.post("/apostar")
def apostar():
    """
    Recebe o formulário de uma aposta e solicita
    ao PostgreSQL o registro da aposta.
    """

    usuario_id = request.form.get("usuario_id", type=int)
    jogo_id = request.form.get("jogo_id", type=int)

    if usuario_id is None or jogo_id is None:
        abort(400, "Dados do formulário incompletos.")

    valor = aposta_service.converter_valor(
        request.form.get("valor")
    )

    if valor is None:
        flash(
            "Informe um valor numérico maior que zero.",
            "erro"
        )

        return redirect(
            url_for(
                "dashboard.dashboard",
                usuario_id=usuario_id
            )
        )

    try:
        gols_da_casa = request.form.get(
            "gols_da_casa",
            type=int
        )

        gols_do_visitante = request.form.get(
            "gols_do_visitante",
            type=int
        )

        odd_texto = request.form.get("odd")

        if (
            gols_da_casa is None
            or gols_do_visitante is None
            or odd_texto is None
        ):
            abort(400, "Dados da aposta incompletos.")

        odd = float(odd_texto)

        resultado = aposta_service.propor_aposta(
            usuario_id=usuario_id,
            jogo_id=jogo_id,
            valor=valor,
            gols_da_casa=gols_da_casa,
            gols_do_visitante=gols_do_visitante,
            odd=odd
        )

        if resultado:
            flash(
                "Aposta realizada com sucesso!",
                "sucesso"
            )
        else:
            flash(
                "Não foi possível realizar a aposta.",
                "erro"
            )

    except ValueError:
        flash(
            "A odd informada é inválida.",
            "erro"
        )

    except Exception as erro:
        flash(
            str(erro),
            "erro"
        )

    # Post/Redirect/Get:
    # evita reenviar o formulário ao atualizar a página.
    return redirect(
        url_for(
            "dashboard.dashboard",
            usuario_id=usuario_id
        )
    )