from flask import Blueprint, abort, render_template, request
from ..services import jogo_service, usuario_service

dashboard_bp = Blueprint("dashboard", __name__)

@dashboard_bp.get("/")
def inicio():
    """
    Página inicial para escolha do usuário.

    O usuário selecionado será utilizado para acessar
    o dashboard através de ?usuario_id=.
    """
    usuarios = usuario_service.listar_usuarios()

    return render_template(
        "login.html",
        usuarios=usuarios
    )


@dashboard_bp.get("/dashboard")
def dashboard():
    """
    Exibe o dashboard de um usuário específico.

    O usuário é identificado pelo parâmetro:
        /dashboard?usuario_id=N
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

    jogos = jogo_service.listar_jogos()
    stats = jogo_service.estatisticas()

    return render_template(
        "dashboard.html",
        usuario=usuario,
        jogos=jogos,
        stats=stats
    )