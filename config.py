import os
from dotdev import load_dotenv
load_dotenv()

EURI_API_KEY = os.getenv("EURI_API_KEY")
EURI_API_URL = "https://api.euron.one/api/v1/euri/chat/completions"
MODEL_NAME = "gpt-5-nano"
DATABASE_URI = os.getenv("DATABASE_URI")