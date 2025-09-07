import logging
from sqlalchemy import create_engine

from logger import setup_logger
from config import DATABASE_URI, DB_SCHEMA
from db_utils import get_db_schema, execute_sql
from prompt_utils import load_prompt_template, build_prompt
from euri_api import call_euri_llm

def main():
    setup_logger()
    try:
        # 1. Create engine
        logging.info("Creating database engine...")
        engine = create_engine(DATABASE_URI)

        # 2. Introspect schema
        schema_txt = get_db_schema(engine, DB_SCHEMA)

        # 3. Get NL query
        nl_query = input("Enter your question (NL to SQL): ").strip()

        # 4. Build prompt
        template = load_prompt_template("prompt_template.txt")
        prompt = build_prompt(template, schema_txt, nl_query)

        logging.info("\n==== Prompt sent to EURI ====\n")
        logging.info(prompt[:2000] + ("\n...\n" if len(prompt) > 2000 else "\n"))

        # 5. Get SQL from LLM
        logging.info("Calling EURI to generate SQL...")
        sql_query = call_euri_llm(prompt)
        logging.info("\n==== Generated SQL ====\n")
        logging.info(sql_query)

        # 6. Execute and display
        logging.info("Running SQL...")
        df = execute_sql(engine, sql_query)
        if df.empty:
            logging.info("Query executed successfully. No data returned.")
            print("No data returned.")
        else:
            logging.info(f"Returned {len(df)} rows × {len(df.columns)} columns.")
            print(df.head(50))  # Show top 50 rows

    except Exception as e:
        logging.error(f"Pipeline failed: {e}")
        print(f"Pipeline failed: {e}")

if __name__ == "__main__":
    main()