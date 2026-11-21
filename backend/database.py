"""
Teddy AI - SQLite Database Storage & Signal Audit Log
"""
import sqlite3
import json
from typing import List, Optional
from models import TeddySignal

DB_FILE = "teddy_ai.db"

def init_db():
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS signal_audit_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        instrument TEXT NOT NULL,
        decision TEXT NOT NULL,
        confidence_score INTEGER NOT NULL,
        setup_type TEXT NOT NULL,
        recommended_strike TEXT,
        spot_trigger REAL,
        option_entry_low REAL,
        option_entry_high REAL,
        stop_loss_option REAL,
        stop_loss_spot REAL,
        target_1 REAL,
        target_2 REAL,
        target_3 REAL,
        risk_reward TEXT,
        why_this_trade TEXT,
        how_to_execute TEXT,
        invalidation_warning TEXT,
        raw_reasoning TEXT
    )
    """)
    conn.commit()
    conn.close()

def log_signal(sig: TeddySignal) -> int:
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()

    entry_low = sig.option_entry_zone[0] if sig.option_entry_zone and len(sig.option_entry_zone) > 0 else None
    entry_high = sig.option_entry_zone[1] if sig.option_entry_zone and len(sig.option_entry_zone) > 1 else None

    t1 = sig.targets_option[0] if sig.targets_option and len(sig.targets_option) > 0 else None
    t2 = sig.targets_option[1] if sig.targets_option and len(sig.targets_option) > 1 else None
    t3 = sig.targets_option[2] if sig.targets_option and len(sig.targets_option) > 2 else None

    cursor.execute("""
    INSERT INTO signal_audit_log (
        timestamp, instrument, decision, confidence_score, setup_type,
        recommended_strike, spot_trigger, option_entry_low, option_entry_high,
        stop_loss_option, stop_loss_spot, target_1, target_2, target_3,
        risk_reward, why_this_trade, how_to_execute, invalidation_warning, raw_reasoning
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        sig.timestamp,
        sig.instrument,
        sig.decision,
        sig.confidence_score,
        sig.setup_type,
        sig.recommended_strike,
        sig.spot_trigger,
        entry_low,
        entry_high,
        sig.stop_loss_option,
        sig.stop_loss_spot,
        t1,
        t2,
        t3,
        sig.risk_reward,
        json.dumps(sig.why_this_trade),
        sig.how_to_execute,
        sig.invalidation_warning,
        sig.raw_reasoning
    ))

    inserted_id = cursor.lastrowid
    conn.commit()
    conn.close()
    return inserted_id

def get_signals(limit: int = 50, instrument: Optional[str] = None) -> List[TeddySignal]:
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()

    query = "SELECT * FROM signal_audit_log"
    params = []
    if instrument:
        query += " WHERE instrument = ?"
        params.append(instrument)
    query += " ORDER BY id DESC LIMIT ?"
    params.append(limit)

    cursor.execute(query, tuple(params))
    rows = cursor.fetchall()
    conn.close()

    results: List[TeddySignal] = []
    for r in rows:
        why = []
        if r[16]:
            try:
                why = json.loads(r[16])
            except Exception:
                why = [r[16]]

        entry_zone = None
        if r[8] is not None and r[9] is not None:
            entry_zone = [r[8], r[9]]

        targets = None
        if r[12] is not None:
            targets = [t for t in [r[12], r[13], r[14]] if t is not None]

        results.append(TeddySignal(
            id=r[0],
            timestamp=r[1],
            instrument=r[2],
            decision=r[3],
            confidence_score=r[4],
            setup_type=r[5],
            recommended_strike=r[6],
            spot_trigger=r[7],
            option_entry_zone=entry_zone,
            stop_loss_option=r[10],
            stop_loss_spot=r[11],
            targets_option=targets,
            risk_reward=r[15] or "1:2.0",
            why_this_trade=why,
            how_to_execute=r[17] or "",
            invalidation_warning=r[18] or "",
            raw_reasoning=r[19]
        ))

    return results
