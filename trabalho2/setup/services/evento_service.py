
from ..db import DatabaseConnection


def listar_eventos():
    """
    Retorna os eventos cadastrados no PostgreSQL.
    """

    db = DatabaseConnection()

    try:
        return db.execute_query(
            """
            SELECT
                e.id,
                e.titulo,
                c.nome AS categoria,
                l.nome AS local,
                e.data_inicio,
                e.data_fim,
                e.vagas,
                e.valor_base,
                e.status
            FROM evento e
            JOIN categoria c ON c.id = e.categoria_id
            JOIN local l ON l.id = e.local_id
            ORDER BY e.data_inicio;
            """
        )

    finally:
        db.close()


def listar_categorias():
    """
    Retorna as categorias disponíveis para eventos.
    """

    db = DatabaseConnection()

    try:
        return db.execute_query(
            """
            SELECT id, nome
            FROM categoria
            ORDER BY nome;
            """
        )

    finally:
        db.close()


def listar_locais():
    """
    Retorna os locais disponíveis para eventos.
    """

    db = DatabaseConnection()

    try:
        return db.execute_query(
            """
            SELECT id, nome, capacidade
            FROM local
            ORDER BY nome;
            """
        )

    finally:
        db.close()


def cadastrar_evento(
    titulo,
    categoria_id,
    local_id,
    data_inicio,
    data_fim,
    vagas,
    valor_base
):
    """
    Cadastra um evento no PostgreSQL.
    """

    db = DatabaseConnection()

    try:
        db.execute_update(
            """
            INSERT INTO evento (
                titulo,
                categoria_id,
                local_id,
                data_inicio,
                data_fim,
                vagas,
                valor_base
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s);
            """,
            (
                titulo,
                categoria_id,
                local_id,
                data_inicio,
                data_fim,
                vagas,
                valor_base
            )
        )

        return True

    finally:
        db.close()

