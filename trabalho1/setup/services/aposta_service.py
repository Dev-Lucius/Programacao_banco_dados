from decimal import Decimal, InvalidOperation

from ..connection import DatabaseConnection


def converter_valor(texto: str | None) -> Decimal | None:
    """
    Converte um valor recebido do formulário para Decimal.

    Aceita:
        10
        10.50
        10,50

    Retorna None caso o valor seja inválido, infinito,
    NaN ou menor ou igual a zero.
    """
    if not texto:
        return None

    try:
        valor = Decimal(texto.strip().replace(",", "."))
    except (InvalidOperation, ValueError):
        return None

    if not valor.is_finite() or valor <= 0:
        return None

    return valor.quantize(Decimal("0.01"))

def propor_aposta(
    usuario_id: int,
    jogo_id: int,
    valor: Decimal,
    gols_da_casa: int,
    gols_do_visitante: int,
    odd: float
) -> dict | None:
    """
    Registra uma aposta através da função
    propor_aposta() do PostgreSQL.
    """

    db = DatabaseConnection()

    try:
        return db.execute_in_transaction(
            """
            SELECT *
            FROM propor_aposta(
                %s::integer,
                %s::integer,
                %s::numeric,
                %s::integer,
                %s::integer,
                %s::real
            )
            """,
            (
                usuario_id,
                jogo_id,
                valor,
                gols_da_casa,
                gols_do_visitante,
                odd
            )
        )

    finally:
        db.close()


def listar_bilhetes(usuario_id: int) -> list[dict]:
    """
    Retorna os bilhetes de um usuário.

    Os dados da aposta são obtidos através da função
    PostgreSQL apostas_usuario().
    """

    db = DatabaseConnection()

    try:
        bilhetes = db.execute_query(
            """
            SELECT *
            FROM apostas_usuario(%s)
            WHERE var_aposta_id IS NOT NULL
            """,
            (usuario_id,)
        )

        for bilhete in bilhetes:
            lucro = db.execute_query_one(
                """
                SELECT *
                FROM lucro_potencial(%s)
                """,
                (bilhete["var_aposta_id"],)
            )

            if lucro:
                bilhete["var_lucro_esperado"] = (
                    lucro["var_lucro_esperado"]
                )
            else:
                bilhete["var_lucro_esperado"] = None

        return bilhetes

    finally:
        db.close()