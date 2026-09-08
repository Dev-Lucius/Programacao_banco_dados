import psycopg
from psycopg.rows import dict_row
from config import DatabaseConfig


class DatabaseConnection:
    def __init__(self):
        self.conn = psycopg.connect(
            DatabaseConfig.get_connection_url(),
            row_factory=dict_row
        )

    def execute_query(self, query: str, params: tuple | None = None) -> list:
        try:
            with self.conn.cursor() as cur:
                cur.execute(query, params)
                return cur.fetchall()
        except psycopg.Error as e:
            print(f"Erro na consulta: {e}")
            return []

    def execute_update(self, query: str, params: tuple | None = None) -> bool:
        try:
            with self.conn.cursor() as cur:
                cur.execute(query, params)
            self.conn.commit()
            return True
        except psycopg.Error as e:
            self.conn.rollback()
            print(f"Erro na operação: {e}")
            return False

    def close(self):
        if self.conn and not self.conn.closed:
            self.conn.close()