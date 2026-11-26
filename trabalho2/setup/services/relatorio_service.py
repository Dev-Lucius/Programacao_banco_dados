
from decimal import Decimal

from ..db import DatabaseConnection


def obter_relatorio_ocupacao():
    """
    Retorna os dados de ocupação dos eventos
    e os indicadores gerais do relatório.
    """

    db = DatabaseConnection()

    try:
        eventos = db.execute_query("""
            SELECT
                evento_id,
                titulo,
                vagas,
                confirmados,
                lista_espera,
                percentual_ocupacao,
                arrecadacao
            FROM fn_relatorio_ocupacao()
            ORDER BY evento_id;
        """)

    finally:
        db.close()

    # Calculando os indicadores gerais
    total_eventos = len(eventos)

    total_vagas = sum(
        evento["vagas"] or 0
        for evento in eventos
    )

    total_confirmados = sum(
        evento["confirmados"] or 0
        for evento in eventos
    )

    total_lista_espera = sum(
        evento["lista_espera"] or 0
        for evento in eventos
    )

    arrecadacao_total = sum(
        (
            evento["arrecadacao"] or Decimal("0.00")
            for evento in eventos
        ),
        Decimal("0.00")
    )

    # Calculando a ocupação geral
    if total_vagas > 0:
        percentual_geral = Decimal(
            str(round(total_confirmados * 100 / total_vagas, 2))
        )
    else:
        percentual_geral = Decimal("0.00")

    return {
        "eventos": eventos,

        "resumo": {
            "total_eventos": total_eventos,
            "total_vagas": total_vagas,
            "total_confirmados": total_confirmados,
            "total_lista_espera": total_lista_espera,
            "percentual_ocupacao": percentual_geral,
            "arrecadacao_total": arrecadacao_total
        }
    }

