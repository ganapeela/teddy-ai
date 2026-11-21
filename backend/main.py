"""
Teddy AI - FastAPI Backend Server
Hosts REST API, WebSockets streaming, Quant Engine, and Teddy AI Brain.
"""
import asyncio
import json
import logging
from datetime import datetime
from typing import Dict, List, Optional
from contextlib import asynccontextmanager

from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Query, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from pydantic import BaseModel
import os

from config import SUPPORTED_INSTRUMENTS, PORT, HOST, BROKER_NAME
from models import MarketSnapshot, TeddySignal, OptionChainStrike
from quant_engine import QuantEngine
from teddy_brain import TeddyBrain
from data_feed import MockReplayDataFeed, LiveBrokerDataFeed, IMarketDataFeed
from database import init_db, log_signal, get_signals

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
logger = logging.getLogger("TeddyServer")

# Global instances
quant_engine = QuantEngine()
teddy_brain = TeddyBrain()
replay_feed = MockReplayDataFeed(quant_engine)
live_feed = LiveBrokerDataFeed(quant_engine)
current_feed_mode = "REPLAY" # "REPLAY" or "LIVE"

def get_active_feed() -> IMarketDataFeed:
    return live_feed if current_feed_mode == "LIVE" else replay_feed

# WebSocket Manager
class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)
        logger.info(f"WebSocket client connected. Total clients: {len(self.active_connections)}")

    def disconnect(self, websocket: WebSocket):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)
            logger.info(f"WebSocket client disconnected. Total clients: {len(self.active_connections)}")

    async def broadcast(self, message: dict):
        for connection in list(self.active_connections):
            try:
                await connection.send_json(message)
            except Exception:
                self.disconnect(connection)

manager = ConnectionManager()

# Background tick loop
async def market_tick_loop():
    logger.info("Starting market tick background worker...")
    while True:
        try:
            feed = get_active_feed()
            if isinstance(feed, MockReplayDataFeed):
                # Simulate live market tick on all instruments
                for inst in SUPPORTED_INSTRUMENTS:
                    feed.tick(inst)

            # Build and broadcast snapshot for active NIFTY 50
            snapshot = build_snapshot("NIFTY 50")
            await manager.broadcast({
                "type": "MARKET_UPDATE",
                "instrument": "NIFTY 50",
                "data": snapshot.model_dump()
            })
        except Exception as e:
            logger.error(f"Error in market tick loop: {e}")
        await asyncio.sleep(2.0)

@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    tick_task = asyncio.create_task(market_tick_loop())
    yield
    tick_task.cancel()

app = FastAPI(
    title="Teddy AI - Indian F&O Options Analyzer",
    description="Deterministic Quant Engine + 20+ Year Veteran Institutional Trader AI Brain",
    version="1.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def build_snapshot(instrument: str) -> MarketSnapshot:
    feed = get_active_feed()
    meta = feed.get_metadata(instrument)
    candles = feed.get_candles(instrument)
    spot = meta["spot_price"]
    chain = feed.get_option_chain(instrument, spot)
    
    return quant_engine.generate_snapshot(
        instrument=instrument,
        candles=candles,
        chain=chain,
        pdh=meta["pdh"],
        pdl=meta["pdl"],
        india_vix=meta["vix"],
        prev_close=meta["prev_close"],
        curr_time=datetime.now(),
        dte_days=2.5
    )

static_dir = os.path.join(os.path.dirname(__file__), "static")
if os.path.exists(static_dir):
    app.mount("/static", StaticFiles(directory=static_dir), name="static")

@app.get("/")
def root():
    index_file = os.path.join(static_dir, "index.html")
    if os.path.exists(index_file):
        return FileResponse(index_file)
    return {
        "app": "Teddy AI - Indian F&O Options Analyzer",
        "status": "online",
        "mode": current_feed_mode,
        "supported_instruments": list(SUPPORTED_INSTRUMENTS.keys())
    }

@app.get("/api/instruments")
def get_instruments():
    return [inst.model_dump() for inst in SUPPORTED_INSTRUMENTS.values()]

@app.get("/api/snapshot", response_model=MarketSnapshot)
def get_snapshot(instrument: str = Query("NIFTY 50")):
    if instrument not in SUPPORTED_INSTRUMENTS:
        instrument = "NIFTY 50"
    return build_snapshot(instrument)

@app.post("/api/analyze", response_model=TeddySignal)
async def analyze_market(instrument: str = Query("NIFTY 50")):
    if instrument not in SUPPORTED_INSTRUMENTS:
        instrument = "NIFTY 50"
    
    snapshot = build_snapshot(instrument)
    signal = teddy_brain.analyze_snapshot(snapshot)
    
    # Log to SQLite
    sig_id = log_signal(signal)
    signal.id = sig_id

    # Broadcast signal via WebSockets to all connected mobile devices
    await manager.broadcast({
        "type": "TEDDY_SIGNAL",
        "instrument": instrument,
        "data": signal.model_dump()
    })

    return signal

@app.get("/api/option-chain", response_model=List[OptionChainStrike])
def get_option_chain(instrument: str = Query("NIFTY 50")):
    if instrument not in SUPPORTED_INSTRUMENTS:
        instrument = "NIFTY 50"
    feed = get_active_feed()
    meta = feed.get_metadata(instrument)
    return feed.get_option_chain(instrument, meta["spot_price"])

@app.get("/api/signals", response_model=List[TeddySignal])
def get_signal_history(instrument: Optional[str] = None, limit: int = 50):
    return get_signals(limit=limit, instrument=instrument)

class ModeRequest(BaseModel):
    mode: str # "REPLAY" or "LIVE"

@app.post("/api/mode")
def set_feed_mode(req: ModeRequest):
    global current_feed_mode
    if req.mode.upper() in ["REPLAY", "LIVE"]:
        current_feed_mode = req.mode.upper()
        return {"status": "success", "mode": current_feed_mode}
    return {"status": "error", "message": "Invalid mode. Choose REPLAY or LIVE."}

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        # Send initial snapshot immediately upon connect
        init_snapshot = build_snapshot("NIFTY 50")
        await websocket.send_json({
            "type": "INITIAL_SNAPSHOT",
            "instrument": "NIFTY 50",
            "data": init_snapshot.model_dump()
        })
        while True:
            # Keep receiving incoming messages or pings
            data = await websocket.receive_text()
            try:
                msg = json.loads(data)
                if msg.get("action") == "SUBSCRIBE":
                    inst = msg.get("instrument", "NIFTY 50")
                    snap = build_snapshot(inst)
                    await websocket.send_json({
                        "type": "MARKET_UPDATE",
                        "instrument": inst,
                        "data": snap.model_dump()
                    })
                elif msg.get("action") == "TRIGGER_ANALYSIS":
                    inst = msg.get("instrument", "NIFTY 50")
                    snap = build_snapshot(inst)
                    sig = teddy_brain.analyze_snapshot(snap)
                    sig_id = log_signal(sig)
                    sig.id = sig_id
                    await manager.broadcast({
                        "type": "TEDDY_SIGNAL",
                        "instrument": inst,
                        "data": sig.model_dump()
                    })
            except Exception:
                pass
    except WebSocketDisconnect:
        manager.disconnect(websocket)
    except Exception as e:
        logger.warning(f"WebSocket error: {e}")
        manager.disconnect(websocket)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host=HOST, port=PORT, reload=True)
