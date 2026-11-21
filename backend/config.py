"""
Teddy AI - Indian F&O Options Analyzer
Configuration & Constants
"""
import os
from pydantic import BaseModel
from dotenv import load_dotenv

load_dotenv()

class InstrumentConfig(BaseModel):
    name: str
    symbol: str
    strike_step: int
    lot_size: int
    exchange: str

SUPPORTED_INSTRUMENTS = {
    "NIFTY 50": InstrumentConfig(
        name="NIFTY 50",
        symbol="NIFTY",
        strike_step=50,
        lot_size=75,
        exchange="NSE"
    ),
    "BANKNIFTY": InstrumentConfig(
        name="BANKNIFTY",
        symbol="BANKNIFTY",
        strike_step=100,
        lot_size=30,
        exchange="NSE"
    ),
    "SENSEX": InstrumentConfig(
        name="SENSEX",
        symbol="SENSEX",
        strike_step=100,
        lot_size=20,
        exchange="BSE"
    ),
}

# Environment variables
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./teddy_ai.db")
PORT = int(os.getenv("PORT", "8000"))
HOST = os.getenv("HOST", "0.0.0.0")

# Broker settings
BROKER_NAME = os.getenv("BROKER_NAME", "MOCK") # MOCK | DHAN | ZERODHA | UPSTOX
DHAN_CLIENT_ID = os.getenv("DHAN_CLIENT_ID", "")
DHAN_ACCESS_TOKEN = os.getenv("DHAN_ACCESS_TOKEN", "")
