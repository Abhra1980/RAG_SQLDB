import os
from dotenv import load_dotenv

load_dotenv()

DATABASE_URI = os.getenv("DATABASE_URI", "postgresql+psycopg2://user:pass@localhost:5432/yourdb")
EURI_API_URL = os.getenv("EURI_API_URL", "https://api.euron.one/api/v1/euri/chat/completions")
EURI_API_KEY = os.getenv("EURI_API_KEY", None)
DB_SCHEMA = os.getenv("DB_SCHEMA", None)