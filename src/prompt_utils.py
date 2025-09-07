import os
import logging

def load_prompt_template(path: str = "prompt_template.txt"):
    """
    Read a prompt template file. If missing, raise an error.
    """
    logging.info(f"Loading prompt template from {path}...")
    try:
        if os.path.exists(path):
            with open(path, "r", encoding="utf-8") as f:
                logging.info("Prompt template loaded successfully.")
                return f.read()
        else:
            logging.error(f"Prompt template file '{path}' not found.")
            raise FileNotFoundError(f"Prompt template file '{path}' not found.")
    except Exception as e:
        logging.error(f"Failed to load prompt template: {e}")
        raise

def build_prompt(template: str, schema: str, question: str) -> str:
    """
    Format the prompt template with schema and question.
    """
    return template.format(schema=schema, question=question)