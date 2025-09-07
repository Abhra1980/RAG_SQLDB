import json
import logging
import requests
from config import EURI_API_URL, EURI_API_KEY

def call_euri_llm(prompt: str):
    """
    Call EURI chat completions to transform prompt -> SQL. Expects EURI_API_KEY in env.
    """
    logging.info("Calling EURI API...")
    if not EURI_API_KEY:
        logging.error("EURI_API_KEY is not set.")
        raise RuntimeError("EURI_API_KEY is not set.")

    headers = {
        "Authorization": f"Bearer {EURI_API_KEY}",
        "Content-Type": "application/json",
    }
    payload = {
        "model": "gpt-4.1-nano",
        "messages": [
            {"role": "system", "content": "You convert natural language to strict, runnable SQL for PostgreSQL."},
            {"role": "user", "content": prompt}
        ],
        "temperature": 0.0
    }
    try:
        resp = requests.post(EURI_API_URL, headers=headers, data=json.dumps(payload), timeout=90)
        resp.raise_for_status()
        data = resp.json()
        logging.info("EURI API call successful.")
        return data["choices"][0]["message"]["content"]
    except Exception as e:
        logging.error(f"EURI API call failed: {e}")
        raise