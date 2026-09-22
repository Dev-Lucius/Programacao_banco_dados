from flask import Blueprint, abort, render_template, request
from ..services import aposta_service, usuario_service

bilhetes_bp = Blueprint("bilhetes", __name__)


@bilhetes_bp.get("/meus-bilhetes")
def meus_bilhetes():
    """
    Exibe o histórico de apostas do usuário.

    O usuário é identificado pelo parâmetro:
        /meus-bilhetes?usuario_id=N
    """

    usuario_id = request.args.get(
        "usuario_id",
        type=int
    )

    if usuario_id is None:
        abort(
            400,
            "Informe ?usuario_id=<numero> na URL."
        )

    usuario = usuario_service.buscar_usuario(usuario_id)

    if usuario is None:
        abort(
            404,
            "Usuário não encontrado."
        )

    bilhetes = aposta_service.listar_bilhetes(usuario_id)

    return render_template(
        "bilhetes.html",
        usuario=usuario,
        bilhetes=bilhetes
    )