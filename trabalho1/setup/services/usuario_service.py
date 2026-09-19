from ..connection import DatabaseConnection


def listar_usuarios() -> list[dict]:
    """
    Retorna todos os usuários cadastrados.
    """
    db = DatabaseConnection()

    try:
        return db.execute_query(
            """
            SELECT
                id,
                nome
            FROM usuario
            ORDER BY id
            """
        )
    finally:
        db.close()


def buscar_usuario(usuario_id: int) -> dict | None:
    """
    Retorna os dados de um usuário e seu saldo.

    O saldo é obtido através da função PostgreSQL
    obter_saldo().
    """
    db = DatabaseConnection()

    try:
        return db.execute_query_one(
            """
            SELECT
                u.id,
                u.nome,
                obter_saldo(u.id) AS saldo
            FROM usuario u
            WHERE u.id = %s
            """,
            (usuario_id,)
        )
    finally:
        db.close()