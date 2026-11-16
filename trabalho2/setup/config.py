import os
from dotenv import load_dotenv

load_dotenv()

class DatabaseConfig:

    DB_NAME = os.getenv("DB_NAME")
    DB_USER = os.getenv("DB_USER")
    DB_PASSWORD = os.getenv("DB_PASSWORD")
    DB_HOST = os.getenv("DB_HOST")
    DB_PORT = os.getenv("DB_PORT", "5432")

    @classmethod
    def get_connection_params(cls) -> dict:
        """
        Retorna os parâmetros necessários para conexão
        com o PostgreSQL.
        """

        required = {
            "DB_NAME": cls.DB_NAME,
            "DB_USER": cls.DB_USER,
            "DB_PASSWORD": cls.DB_PASSWORD,
            "DB_HOST": cls.DB_HOST,
            "DB_PORT": cls.DB_PORT,
        }

        missing = [
            name
            for name, value in required.items()
            if not value
        ]

        if missing:
            raise RuntimeError(
                "Variáveis de ambiente ausentes: "
                + ", ".join(missing)
            )

        return {
            "dbname": cls.DB_NAME,
            "user": cls.DB_USER,
            "password": cls.DB_PASSWORD,
            "host": cls.DB_HOST,
            "port": cls.DB_PORT,
        }


class AppConfig:

    SECRET_KEY = os.getenv("FLASK_SECRET_KEY")

    @classmethod
    def validate(cls) -> None:
        """
        Verifica se as configurações obrigatórias da aplicação
        estão presentes.
        """
        if not cls.SECRET_KEY:
            raise RuntimeError(
                "A variável FLASK_SECRET_KEY não foi definida."
            )