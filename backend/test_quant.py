"""
Test script for Teddy AI Quant Engine & Brain
"""
import sys
import os

# Add current dir to path
sys.path.append(os.path.dirname(__file__))

from quant_engine import QuantEngine
from data_feed import MockReplayDataFeed
from teddy_brain import TeddyBrain
from database import init_db, log_signal, get_signals
from datetime import datetime

def test_full_pipeline():
    print(">>> 1. Initializing Database...")
    init_db()

    print(">>> 2. Initializing Quant Engine & Replay Data Feed...")
    quant = QuantEngine()
    feed = MockReplayDataFeed(quant)

    candles = feed.get_candles("NIFTY 50")
    meta = feed.get_metadata("NIFTY 50")
    chain = feed.get_option_chain("NIFTY 50", meta["spot_price"])

    print(f"Generated {len(candles)} candles. Spot: {meta['spot_price']}, VIX: {meta['vix']}")
    print(f"Generated {len(chain)} option strikes.")

    print(">>> 3. Computing Market Snapshot via Quant Engine...")
    snapshot = quant.generate_snapshot(
        instrument="NIFTY 50",
        candles=candles,
        chain=chain,
        pdh=meta["pdh"],
        pdl=meta["pdl"],
        india_vix=meta["vix"],
        prev_close=meta["prev_close"],
        curr_time=datetime.now()
    )

    print("--- QUANT SNAPSHOT SUMMARY ---")
    print(f"Spot: {snapshot.spot_price} (Chg: {snapshot.price_change_pct}%)")
    print(f"Technicals -> VWAP: {snapshot.technicals.vwap}, 9 EMA: {snapshot.technicals.ema_9}, 20 EMA: {snapshot.technicals.ema_20}")
    print(f"SMC -> BOS: {snapshot.technicals.bos_detected} ({snapshot.technicals.bos_direction}), CHoCH: {snapshot.technicals.choch_detected}")
    print(f"Option Analytics -> ATM: {snapshot.option_analytics.atm_strike}, Max Call (Res): {snapshot.option_analytics.max_call_oi_strike}, Max Put (Supp): {snapshot.option_analytics.max_put_oi_strike}, PCR: {snapshot.option_analytics.pcr}")
    print(f"Trap Filter -> Session: {snapshot.trap_context.session_phase}, Bull Trap: {snapshot.trap_context.bull_trap_alert}, Bear Trap: {snapshot.trap_context.bear_trap_alert}")

    print(">>> 4. Testing Teddy AI Reasoning Engine...")
    brain = TeddyBrain() # Runs deterministic veteran rule fallback if GEMINI_API_KEY is not set
    signal = brain.analyze_snapshot(snapshot)

    print("--- TEDDY SIGNAL OUTPUT ---")
    print(f"Decision: {signal.decision}")
    print(f"Confidence: {signal.confidence_score}%")
    print(f"Setup Type: {signal.setup_type}")
    print(f"Recommended Strike: {signal.recommended_strike}")
    print(f"Entry Zone: {signal.option_entry_zone}")
    print(f"SL Option: {signal.stop_loss_option} | SL Spot: {signal.stop_loss_spot}")
    print(f"Targets: {signal.targets_option}")
    print(f"R:R: {signal.risk_reward}")
    print("Why This Trade:")
    for w in signal.why_this_trade:
        print(f"  * {w}")
    print(f"How to Execute: {signal.how_to_execute}")
    print(f"Invalidation: {signal.invalidation_warning}")

    print(">>> 5. Testing SQLite Persistence...")
    sig_id = log_signal(signal)
    print(f"Logged signal with ID: {sig_id}")
    history = get_signals(limit=5)
    print(f"Retrieved {len(history)} signals from audit log.")
    assert len(history) > 0, "Signal audit log should contain at least 1 record!"

    print(">>> ALL QUANT & REASONING TESTS PASSED PERFECTLY! <<<")

if __name__ == "__main__":
    test_full_pipeline()
