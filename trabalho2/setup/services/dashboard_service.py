
from ..db import DatabaseConnection


def obter_indicadores():
    """
    Retorna os principais indicadores do sistema.
    """
    db = DatabaseConnection()

    try:
        return db.execute_query_one("""
            SELECT
                (SELECT COUNT(*) FROM evento)
                    AS total_eventos,

                (SELECT COUNT(*) FROM participante)
                    AS total_participantes,

                (SELECT COUNT(*)
                 FROM inscricao
                 WHERE status = 'confirmada')
                    AS inscricoes_confirmadas,

                (SELECT COUNT(*)
                 FROM inscricao
                 WHERE status = 'lista_espera')
                    AS lista_espera;
        """)
    finally:
        db.close()


def listar_proximos_eventos():
    """
    Retorna os cinco próximos eventos abertos.
    """
    db = DatabaseConnection()

    try:
        return db.execute_query("""
            SELECT
                e.id,
                e.titulo,
                e.data_inicio,
                e.data_fim,
                e.status,
                l.nome AS local
            FROM evento e
            JOIN local l ON l.id = e.local_id
            WHERE e.status = 'aberto'
              AND e.data_inicio >= CURRENT_TIMESTAMP
            ORDER BY e.data_inicio
            LIMIT 5;
        """)
    finally:
        db.close()
