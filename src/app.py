import streamlit as st
import pandas as pd
from sqlalchemy import create_engine
from config import DATABASE_URI, DB_SCHEMA
from db_utils import get_db_schema, execute_sql
from prompt_utils import load_prompt_template, build_prompt
from euri_api import call_euri_llm

st.title("Natural Language to SQL Query App")

nl_query = st.text_input("Enter your question (NL to SQL):")

df = pd.DataFrame()  # Initialize df for scope

if st.button("Run Query") and nl_query:
    engine = create_engine(DATABASE_URI)
    schema_txt = get_db_schema(engine, DB_SCHEMA)
    template = load_prompt_template("prompt_template.txt")
    prompt = build_prompt(template, schema_txt, nl_query)
    
    sql_query = call_euri_llm(prompt)
    st.code(sql_query, language="sql")
    
    if "DROP TABLE IF EXISTS" in sql_query and "view" in sql_query.lower():
        sql_query = sql_query.replace("DROP TABLE IF EXISTS", "DROP VIEW IF EXISTS")
    
    if "<" in sql_query and ">" in sql_query:
        st.error("The generated SQL contains a placeholder. Please provide the required value or rephrase your question.")
    else:
        try:
            df = execute_sql(engine, sql_query)
            if not df.empty:
                st.dataframe(df.head(50))
            else:
                st.info("No data returned.")
        except Exception as e:
            st.error(f"Error: {e}")

# Visualization options have been removed.