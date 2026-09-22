from ..connection import DatabaseConnection


def listar_jogos() -> list[dict]:
    """
    Retorna os jogos disponíveis através da função
    liste_jogos() do PostgreSQL.
    """

    db = DatabaseConnection()

    try:
        return db.execute_query(
            """
            SELECT *
            FROM liste_jogos()
            """
        )

    finally:
        db.close()


def estatisticas() -> dict | None:
    """
    Retorna as estatísticas utilizadas no dashboard.

    As informações são calculadas pelas funções
    total_jogos() e media_valor_apostas() do PostgreSQL.
    """

    db = DatabaseConnection()

    try:
        return db.execute_query_one(
            """
            SELECT
                total_jogos() AS total_jogos,
                media_valor_apostas() AS media_apostas
            """
        )

    finally:
        db.close()
