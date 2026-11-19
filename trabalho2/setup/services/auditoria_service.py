
from ..db import DatabaseConnection


def listar_auditoria():
    """
    Retorna o histórico de alterações nas inscrições.
    """
    db = DatabaseConnection()

    try:
        return db.execute_query(
            """
            SELECT
                l.id,
                l.inscricao_id,
                p.nome AS participante,
                e.titulo AS evento,
                l.status_anterior,
                l.status_novo,
                l.data_hora,
                l.usuario
            FROM log_inscricao l
            JOIN inscricao i ON i.id = l.inscricao_id
            JOIN participante p ON p.id = i.participante_id
            JOIN evento e ON e.id = i.evento_id
            ORDER BY l.data_hora DESC;
            """
        )

    finally:
        db.close()
