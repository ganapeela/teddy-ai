"""
Teddy AI - Pydantic Data Models
"""
from typing import List, Optional, Tuple, Dict, Any
from pydantic import BaseModel, Field

class Candle(BaseModel):
    timestamp: str # ISO or HH:MM
    open: float
    high: float
    low: float
    close: float
    volume: float

class OptionChainStrike(BaseModel):
    strike: float
    ce_ltp: float
    ce_oi: int
    ce_change_oi: int
    ce_iv: float
    ce_delta: float
    ce_theta: float
    ce_vega: float
    pe_ltp: float
    pe_oi: int
    pe_change_oi: int
    pe_iv: float
    pe_delta: float
    pe_theta: float
    pe_vega: float

class MarketTechnicals(BaseModel):
    spot_price: float
    vwap: float
    ema_9: float
    ema_20: float
    pdh: float
    pdl: float
    orh: float
    orl: float
    swing_high: float
    swing_low: float
    atr_14: float
    rsi_14: float
    bos_detected: bool = False
    bos_direction: Optional[str] = None # BULLISH | BEARISH
    choch_detected: bool = False
    order_block: Optional[Dict[str, Any]] = None # {"type": "BULLISH"|"BEARISH", "top": float, "bottom": float}
    fvg: Optional[Dict[str, Any]] = None # {"type": "BULLISH"|"BEARISH", "top": float, "bottom": float}

class OptionAnalytics(BaseModel):
    atm_strike: float
    max_call_oi_strike: float # Resistance
    max_put_oi_strike: float  # Support
    total_call_oi: int
    total_put_oi: int
    total_call_oi_change: int
    total_put_oi_change: int
    pcr: float
    pcr_trend: str # RISING | FALLING | FLAT
    india_vix: float
    atm_iv: float
    dte_days: float
    dte_label: str

class TrapContext(BaseModel):
    session_phase: str # "Opening Volatility" | "Morning Trend" | "Midday Chop" | "Closing Move"
    bull_trap_alert: bool = False
    bear_trap_alert: bool = False
    trap_notes: Optional[str] = None

class MarketSnapshot(BaseModel):
    instrument: str
    timestamp: str
    spot_price: float
    price_change: float
    price_change_pct: float
    technicals: MarketTechnicals
    option_analytics: OptionAnalytics
    trap_context: TrapContext
    recent_candles: List[Candle] = []
    option_chain: List[OptionChainStrike] = []

class TeddySignal(BaseModel):
    id: Optional[int] = None
    timestamp: str
    instrument: str
    decision: str # "BUY_CE" | "BUY_PE" | "NO_TRADE"
    confidence_score: int # 0 - 100
    setup_type: str
    recommended_strike: Optional[str] = None # e.g. "NIFTY 24500 CE"
    spot_trigger: Optional[float] = None
    option_entry_zone: Optional[List[float]] = None # [low, high]
    stop_loss_option: Optional[float] = None
    stop_loss_spot: Optional[float] = None
    targets_option: Optional[List[float]] = None # [t1, t2, t3]
    risk_reward: str
    why_this_trade: List[str] = []
    how_to_execute: str
    invalidation_warning: str
    raw_reasoning: Optional[str] = None
