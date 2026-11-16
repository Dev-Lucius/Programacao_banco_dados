import psycopg
from psycopg.rows import dict_row
from .config import DatabaseConfig

class DatabaseConnection:

    def __init__(self):
        self.conn = psycopg.connect(
            **DatabaseConfig.get_connection_params(),
            row_factory=dict_row
        )

    def execute_query(
        self,
        query: str,
        params: tuple | None = None
    ) -> list[dict]:
        with self.conn.cursor() as cur:
            cur.execute(query, params)
            return cur.fetchall()

    def execute_query_one(
        self,
        query: str,
        params: tuple | None = None
    ) -> dict | None:
        with self.conn.cursor() as cur:
            cur.execute(query, params)
            return cur.fetchone()

    def execute_update(
        self,
        query: str,
        params: tuple | None = None
    ) -> None:
        try:
            with self.conn.cursor() as cur:
                cur.execute(query, params)

            self.conn.commit()

        except psycopg.Error:
            self.conn.rollback()
            raise

    def execute_in_transaction(
        self,
        query: str,
        params: tuple | None = None
    ) -> dict | None:
        try:
            with self.conn.transaction():
                with self.conn.cursor() as cur:
                    cur.execute(query, params)
                    return cur.fetchone()

        except psycopg.Error:
            raise

    def close(self):
        if self.conn and not self.conn.closed:
            self.conn.close()