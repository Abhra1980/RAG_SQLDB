# Natural Language to SQL Query Generator

This project enables users to convert natural language questions into SQL queries, execute them on a connected database, and visualize the results. It leverages a large language model (LLM) API to translate user questions into SQL, introspects the database schema for accurate query generation

## Features

- **Natural Language to SQL**: Converts user questions into SQL queries using the EURI LLM API.
- **Database Schema Introspection**: Automatically reads your database schema for accurate query generation.
- **Modular Design**: Clean separation of configuration, database utilities, prompt handling, API calls, and logging.
- **Logging**: All actions and errors are logged to `pipeline.log`.
- **Easy to Extend**: Add new features or swap out components easily.

## Project Structure

```
SQL_Project/
│
├── src/
│   ├── main.py              # Entry point for the application
│   ├── config.py            # Configuration and environment variable loading
│   ├── db_utils.py          # Database-related utilities
│   ├── prompt_utils.py      # Prompt-related utilities
│   ├── euri_api.py          # Functions for interacting with the EURI API
│   ├── logger.py            # Logging configuration
│
├── prompt_template.txt      # Prompt template file
├── requirements.txt         # Dependencies for the project
├── .env                     # Environment variables (e.g., DATABASE_URI, API keys)
├── pipeline.log             # Log file for the pipeline
└── README.md                # Documentation for the project
```

## Setup

1. **Clone the repository** and navigate to the project directory.

2. **Install dependencies**:
    ```
    pip install -r requirements.txt
    ```

3. **Configure environment variables**:  
   Create a `.env` file in the root directory with the following variables:
    ```
    DATABASE_URI=your_database_uri
    EURI_API_URL=https://api.euron.one/api/v1/euri/chat/completions
    EURI_API_KEY=your_euri_api_key
    DB_SCHEMA=your_schema_name  # Optional
    ```

4. **Edit the prompt template** (optional):  
   Modify `prompt_template.txt` to customize how prompts are sent to the LLM.

## Usage

Run the main application:

```
python src/main.py
```

- Enter your natural language question when prompted.
- The system will generate SQL, execute it, and display the top 50 results.

## Customization

- **Visualization**: You can add a `visualization_utils.py` module to plot results using libraries like Plotly or Matplotlib.
- **Web Interface**: Integrate with Streamlit or Flask for a web-based UI.

## License

This project is for educational and internal use. Please check the terms of the EURI API for commercial use.

---

**Contributions and suggestions are welcome!**
