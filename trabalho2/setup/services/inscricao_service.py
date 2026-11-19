
import psycopg
from ..db import DatabaseConnection


def listar_inscricoes():
    """
    Retorna todas as inscrições cadastradas.
    """
    db = DatabaseConnection()

    try:
        return db.execute_query(
            """
            SELECT
                i.id,
                p.nome AS participante,
                p.email,
                e.titulo AS evento,
                i.data_inscricao,
                i.status,
                i.valor_pago
            FROM inscricao i
            JOIN participante p ON p.id = i.participante_id
            JOIN evento e ON e.id = i.evento_id
            ORDER BY i.data_inscricao DESC;
            """
        )
    finally:
        db.close()


def listar_participantes():
    """
    Retorna os participantes disponíveis para inscrição.
    """
    db = DatabaseConnection()

    try:
        return db.execute_query(
            """
            SELECT id, nome, email
            FROM participante
            ORDER BY nome;
            """
        )
    finally:
        db.close()


def listar_eventos():
    """
    Retorna os eventos que aceitam novas inscrições.
    """
    db = DatabaseConnection()

    try:
        return db.execute_query(
            """
            SELECT
                id,
                titulo,
                data_inicio,
                data_fim,
                vagas,
                valor_base
            FROM evento
            WHERE status = 'aberto'
            ORDER BY data_inicio;
            """
        )
    finally:
        db.close()


def realizar_inscricao(participante_id, evento_id):
    """
    Solicita ao PostgreSQL a realização de uma inscrição.
    """
    try:
        participante_id = int(participante_id)
        evento_id = int(evento_id)

        if participante_id <= 0 or evento_id <= 0:
            raise ValueError

    except (TypeError, ValueError):
        raise ValueError("Selecione um participante e um evento válidos.")

    db = DatabaseConnection()

    try:
        db.execute_update(
            """
            CALL sp_realizar_inscricao(%s, %s);
            """,
            (participante_id, evento_id)
        )

        return True

    except psycopg.errors.RaiseException as erro:
        mensagem = erro.diag.message_primary or "Não foi possível realizar a inscrição."
        raise ValueError(mensagem) from erro

    except psycopg.errors.UniqueViolation as erro:
        raise ValueError(
            "Este participante já possui uma inscrição ativa nesse evento."
        ) from erro

    finally:
        db.close()


def cancelar_inscricao(inscricao_id):
    """
    Solicita ao PostgreSQL o cancelamento de uma inscrição.
    """
    try:
        inscricao_id = int(inscricao_id)

        if inscricao_id <= 0:
            raise ValueError

    except (TypeError, ValueError):
        raise ValueError("Identificador de inscrição inválido.")

    db = DatabaseConnection()

    try:
        inscricao = db.execute_query_one(
            """
            SELECT id, status
            FROM inscricao
            WHERE id = %s;
            """,
            (inscricao_id,)
        )

        if inscricao is None:
            raise ValueError("Inscrição não encontrada.")

        if inscricao["status"] == "cancelada":
            raise ValueError("Esta inscrição já foi cancelada.")

        db.execute_update(
            """
            CALL sp_cancelar_inscricao(%s);
            """,
            (inscricao_id,)
        )

        return True

    except psycopg.errors.RaiseException as erro:
        mensagem = erro.diag.message_primary or "Não foi possível cancelar a inscrição."
        raise ValueError(mensagem) from erro

    finally:
        db.close()
