import pandas as pd
import logging
from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine

def get_db_schema(engine: Engine, target_schema: str | None = None):
    """
    Introspect tables & columns from information_schema and return a concise textual schema description.
    """
    logging.info("Introspecting database schema...")
    try:
        with engine.connect() as conn:
            if target_schema is None:
                current_schema = conn.execute(text("SELECT current_schema()")).scalar()
            else:
                current_schema = target_schema

            rows = conn.execute(text("""
                SELECT table_name, column_name, data_type
                FROM information_schema.columns
                WHERE table_schema = :sch
                ORDER BY table_name, ordinal_position
            """), {"sch": current_schema}).fetchall()

        if not rows:
            logging.warning(f"No tables found in schema '{current_schema}'.")
            return f"(No tables found in schema '{current_schema}')"

        from collections import defaultdict
        tables = defaultdict(list)
        for t, c, d in rows:
            tables[t].append((c, d))

        lines = [f"SCHEMA: {current_schema}"]
        for t in sorted(tables.keys()):
            cols = ", ".join([f"{c} {d}" for c, d in tables[t]])
            lines.append(f"TABLE {t}: {cols}")
        logging.info("Schema introspection completed.")
        return "\n".join(lines)
    except Exception as e:
        logging.error(f"Failed to introspect schema: {e}")
        raise

def execute_sql(engine: Engine, sql: str):
    """
    Execute SQL and return a DataFrame (works for SELECT; for DDL/DML returns empty DF).
    """
    logging.info("Executing SQL query...")
    try:
        with engine.begin() as conn:
            result = conn.execute(text(sql))
            if result.returns_rows:
                df = pd.DataFrame(result.fetchall(), columns=result.keys())
            else:
                df = pd.DataFrame()
        logging.info("SQL query executed successfully.")
        return df
    except Exception as e:
        logging.error(f"SQL execution failed: {e}")
        raise