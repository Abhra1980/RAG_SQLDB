import requests
from sqlalchemy import create_engine, MetaData, Table, Column, Integer, String, text
from config import EURI_API_KEY, EURI_API_URL, MODEL_NAME
