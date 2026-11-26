
import re
import psycopg

from ..db import DatabaseConnection


TIPOS_VALIDOS = {
    "estudante",
    "professor",
    "externo"
}


def cadastrar_participante(nome, email, tipo):
    """
    Valida os dados e cadastra um participante no PostgreSQL.
    """

    # Normalizar os dados recebidos.
    nome = (nome or "").strip()
    email = (email or "").strip().lower()
    tipo = (tipo or "").strip()

    # Validar campos obrigatórios.
    if not nome or not email or not tipo:
        raise ValueError("Preencha todos os campos obrigatórios.")

    # Validar tamanho dos campos.
    if len(nome) > 200 or len(email) > 200:
        raise ValueError(
            "Nome e e-mail devem possuir no máximo 200 caracteres."
        )

    # Validar formato do e-mail.
    if not re.fullmatch(r"[^@\s]+@[^@\s]+\.[^@\s]+", email):
        raise ValueError("Informe um endereço de e-mail válido.")

    # Validar tipo de participante.
    if tipo not in TIPOS_VALIDOS:
        raise ValueError("Tipo de participante inválido.")

    db = None

    try:
        db = DatabaseConnection()
        db.execute_update(
            """
            INSERT INTO participante (
                nome,
                email,
                tipo
            )
            VALUES (%s, %s, %s::tipo_participante);
            """,
            (nome, email, tipo)
        )

        return True

    except psycopg.errors.UniqueViolation as erro:
        raise ValueError(
            "Já existe um participante cadastrado com esse e-mail."
        ) from erro

    finally:
        if db is not None:
            db.close()

