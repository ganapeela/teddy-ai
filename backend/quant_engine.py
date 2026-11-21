"""
Teddy AI - Deterministic Quant Engine
Separates mathematical computations, technical indicators, Smart Money Concepts (SMC),
and Indian Option Chain Greek / OI analytics completely from LLM reasoning.
"""
import math
from datetime import datetime, time
from typing import List, Dict, Any, Tuple
import numpy as np
import pandas as pd
from scipy.stats import norm

from models import (
    Candle, MarketTechnicals, OptionAnalytics,
    TrapContext, OptionChainStrike, MarketSnapshot
)
from config import SUPPORTED_INSTRUMENTS

class QuantEngine:
    def __init__(self, risk_free_rate: float = 0.065): # 6.5% RBI repo rate proxy
        self.r = risk_free_rate

    @staticmethod
    def get_strike_step(instrument: str) -> int:
        return SUPPORTED_INSTRUMENTS.get(instrument, SUPPORTED_INSTRUMENTS["NIFTY 50"]).strike_step

    @staticmethod
    def calculate_atm_strike(spot_price: float, strike_step: int) -> float:
        return round(spot_price / strike_step) * strike_step

    def calculate_black_scholes_greeks(
        self,
        spot: float,
        strike: float,
        time_to_expiry_years: float,
        iv: float,
        is_call: bool = True
    ) -> Dict[str, float]:
        """
        Calculates Black-Scholes Greeks: Delta, Theta (per day), Vega (per 1% IV change)
        """
        if time_to_expiry_years <= 0.0001:
            time_to_expiry_years = 0.0001
        if iv <= 0.01:
            iv = 0.01

        s = spot
        k = strike
        t = time_to_expiry_years
        sigma = iv
        r = self.r

        d1 = (math.log(s / k) + (r + 0.5 * sigma ** 2) * t) / (sigma * math.sqrt(t))
        d2 = d1 - sigma * math.sqrt(t)

        pdf_d1 = norm.pdf(d1)
        cdf_d1 = norm.cdf(d1)
        cdf_d2 = norm.cdf(d2)

        if is_call:
            delta = cdf_d1
            theta = (-(s * pdf_d1 * sigma) / (2 * math.sqrt(t)) - r * k * math.exp(-r * t) * cdf_d2) / 365.0
        else:
            delta = cdf_d1 - 1.0
            theta = (-(s * pdf_d1 * sigma) / (2 * math.sqrt(t)) + r * k * math.exp(-r * t) * norm.cdf(-d2)) / 365.0

        vega = (s * math.sqrt(t) * pdf_d1) / 100.0 # Per 1% IV shift

        return {
            "delta": round(float(delta), 3),
            "theta": round(float(theta), 2),
            "vega": round(float(vega), 2)
        }

    def compute_technicals(self, candles: List[Candle], pdh: float, pdl: float) -> MarketTechnicals:
        """
        Deterministic technical analysis & SMC market structure extraction
        """
        if not candles:
            # Fallback default
            return MarketTechnicals(
                spot_price=0.0, vwap=0.0, ema_9=0.0, ema_20=0.0,
                pdh=pdh, pdl=pdl, orh=0.0, orl=0.0,
                swing_high=0.0, swing_low=0.0, atr_14=0.0, rsi_14=50.0
            )

        df = pd.DataFrame([c.model_dump() for c in candles])
        df['typical_price'] = (df['high'] + df['low'] + df['close']) / 3.0
        df['cum_vp'] = (df['typical_price'] * df['volume']).cumsum()
        df['cum_v'] = df['volume'].cumsum()
        df['vwap'] = df['cum_vp'] / df['cum_v'].replace(0, 1)

        # EMAs
        df['ema_9'] = df['close'].ewm(span=9, adjust=False).mean()
        df['ema_20'] = df['close'].ewm(span=20, adjust=False).mean()

        # ATR 14
        df['prev_close'] = df['close'].shift(1)
        tr1 = df['high'] - df['low']
        tr2 = (df['high'] - df['prev_close']).abs()
        tr3 = (df['low'] - df['prev_close']).abs()
        df['tr'] = pd.concat([tr1, tr2, tr3], axis=1).max(axis=1)
        df['atr_14'] = df['tr'].rolling(window=min(14, len(df)), min_periods=1).mean()

        # RSI 14
        delta = df['close'].diff()
        gain = (delta.where(delta > 0, 0)).rolling(window=min(14, len(df)), min_periods=1).mean()
        loss = (-delta.where(delta < 0, 0)).rolling(window=min(14, len(df)), min_periods=1).mean()
        rs = gain / loss.replace(0, 0.00001)
        df['rsi_14'] = 100 - (100 / (1 + rs))

        # Opening Range: first 15 mins (approx first 3-15 candles depending on timeframe, default first 15 rows)
        or_slice = df.head(min(15, len(df)))
        orh = float(or_slice['high'].max())
        orl = float(or_slice['low'].min())

        # Swing High & Low (last 20 candles)
        lookback = df.tail(min(20, len(df)))
        swing_high = float(lookback['high'].max())
        swing_low = float(lookback['low'].min())

        latest = df.iloc[-1]
        spot_price = float(latest['close'])
        vwap = float(latest['vwap'])
        ema_9 = float(latest['ema_9'])
        ema_20 = float(latest['ema_20'])
        atr_14 = float(latest['atr_14'])
        rsi_14 = float(latest['rsi_14'])

        # --- Smart Money Concepts (SMC) Detection ---
        # 1. BOS (Break of Structure): Current close breaks previous swing high/low
        prev_swing_high = float(df['high'].iloc[:-1].tail(15).max()) if len(df) > 5 else swing_high
        prev_swing_low = float(df['low'].iloc[:-1].tail(15).min()) if len(df) > 5 else swing_low

        bos_detected = False
        bos_dir = None
        if spot_price > prev_swing_high:
            bos_detected = True
            bos_dir = "BULLISH"
        elif spot_price < prev_swing_low:
            bos_detected = True
            bos_dir = "BEARISH"

        # 2. CHoCH (Change of Character): Trend reversal breaking counter-trend swing
        choch_detected = False
        if len(df) >= 10:
            short_trend = df['close'].iloc[-5:].mean() - df['close'].iloc[-10:-5].mean()
            if short_trend < 0 and spot_price > ema_20 and spot_price > vwap:
                choch_detected = True
            elif short_trend > 0 and spot_price < ema_20 and spot_price < vwap:
                choch_detected = True

        # 3. Order Blocks (OB)
        # Bullish OB: last down candle before an up impulse
        order_block = None
        if len(df) >= 4:
            c_prev3 = df.iloc[-3]
            c_prev2 = df.iloc[-2]
            c_curr = df.iloc[-1]
            if c_prev3['close'] < c_prev3['open'] and c_curr['close'] > c_prev3['high']:
                order_block = {
                    "type": "BULLISH",
                    "top": round(float(c_prev3['high']), 2),
                    "bottom": round(float(c_prev3['low']), 2)
                }
            elif c_prev3['close'] > c_prev3['open'] and c_curr['close'] < c_prev3['low']:
                order_block = {
                    "type": "BEARISH",
                    "top": round(float(c_prev3['high']), 2),
                    "bottom": round(float(c_prev3['low']), 2)
                }

        # 4. Fair Value Gap (FVG)
        fvg = None
        if len(df) >= 3:
            c1 = df.iloc[-3]
            c3 = df.iloc[-1]
            if c3['low'] > c1['high']: # Bullish FVG
                fvg = {
                    "type": "BULLISH",
                    "top": round(float(c3['low']), 2),
                    "bottom": round(float(c1['high']), 2)
                }
            elif c3['high'] < c1['low']: # Bearish FVG
                fvg = {
                    "type": "BEARISH",
                    "top": round(float(c1['low']), 2),
                    "bottom": round(float(c3['high']), 2)
                }

        return MarketTechnicals(
            spot_price=round(spot_price, 2),
            vwap=round(vwap, 2),
            ema_9=round(ema_9, 2),
            ema_20=round(ema_20, 2),
            pdh=round(pdh, 2),
            pdl=round(pdl, 2),
            orh=round(orh, 2),
            orl=round(orl, 2),
            swing_high=round(swing_high, 2),
            swing_low=round(swing_low, 2),
            atr_14=round(atr_14, 2),
            rsi_14=round(rsi_14, 2),
            bos_detected=bos_detected,
            bos_direction=bos_dir,
            choch_detected=choch_detected,
            order_block=order_block,
            fvg=fvg
        )

    def compute_option_analytics(
        self,
        chain: List[OptionChainStrike],
        spot_price: float,
        strike_step: int,
        india_vix: float,
        dte_days: float = 2.5
    ) -> OptionAnalytics:
        """
        Processes Indian Option Chain to extract Support/Resistance,
        OI concentration, PCR, and IV dynamics.
        """
        atm_strike = self.calculate_atm_strike(spot_price, strike_step)
        if not chain:
            return OptionAnalytics(
                atm_strike=atm_strike,
                max_call_oi_strike=atm_strike + strike_step,
                max_put_oi_strike=atm_strike - strike_step,
                total_call_oi=0,
                total_put_oi=0,
                total_call_oi_change=0,
                total_put_oi_change=0,
                pcr=1.0,
                pcr_trend="FLAT",
                india_vix=india_vix,
                atm_iv=india_vix,
                dte_days=dte_days,
                dte_label=f"{dte_days:.1f} DTE"
            )

        max_call_oi = -1
        max_call_strike = atm_strike
        max_put_oi = -1
        max_put_strike = atm_strike

        tot_call_oi = 0
        tot_put_oi = 0
        tot_call_oi_chg = 0
        tot_put_oi_chg = 0
        atm_iv = india_vix

        for item in chain:
            tot_call_oi += item.ce_oi
            tot_put_oi += item.pe_oi
            tot_call_oi_chg += item.ce_change_oi
            tot_put_oi_chg += item.pe_change_oi

            if item.ce_oi > max_call_oi:
                max_call_oi = item.ce_oi
                max_call_strike = item.strike

            if item.pe_oi > max_put_oi:
                max_put_oi = item.pe_oi
                max_put_strike = item.strike

            if item.strike == atm_strike:
                atm_iv = (item.ce_iv + item.pe_iv) / 2.0

        pcr = round(tot_put_oi / tot_call_oi, 2) if tot_call_oi > 0 else 1.0

        # PCR Trend determination
        if tot_put_oi_chg > tot_call_oi_chg + 10000:
            pcr_trend = "RISING"
        elif tot_call_oi_chg > tot_put_oi_chg + 10000:
            pcr_trend = "FALLING"
        else:
            pcr_trend = "FLAT"

        return OptionAnalytics(
            atm_strike=atm_strike,
            max_call_oi_strike=max_call_strike,
            max_put_oi_strike=max_put_strike,
            total_call_oi=tot_call_oi,
            total_put_oi=tot_put_oi,
            total_call_oi_change=tot_call_oi_chg,
            total_put_oi_change=tot_put_oi_chg,
            pcr=pcr,
            pcr_trend=pcr_trend,
            india_vix=round(india_vix, 2),
            atm_iv=round(atm_iv, 2),
            dte_days=round(dte_days, 1),
            dte_label=f"{round(dte_days, 1)} DTE"
        )

    def evaluate_traps_and_context(
        self,
        technicals: MarketTechnicals,
        analytics: OptionAnalytics,
        chain: List[OptionChainStrike],
        curr_time: datetime
    ) -> TrapContext:
        """
        Institutional Trap Detector:
        - Bull Trap: Price broke above PDH or ORH, but Call Writers are aggressively ADDING OI
          rather than unwinding/covering shorts!
        - Bear Trap: Price broke below PDL or ORL, but Put Writers are aggressively ADDING OI
          rather than dumping positions!
        """
        # Session Phase Tagging
        t = curr_time.time()
        if time(9, 15) <= t < time(9, 30):
            session_phase = "Opening Volatility"
        elif time(9, 30) <= t < time(11, 30):
            session_phase = "Morning Trend"
        elif time(11, 30) <= t < time(13, 30):
            session_phase = "Midday Chop"
        elif time(13, 30) <= t <= time(15, 15):
            session_phase = "Closing Move"
        else:
            session_phase = "Market Closed (Replay Active)"

        bull_trap = False
        bear_trap = False
        notes = []

        # Find ATM strike item
        atm_item = next((s for s in chain if s.strike == analytics.atm_strike), None)

        # Bull Trap check
        if technicals.spot_price >= technicals.pdh or technicals.spot_price >= technicals.orh:
            # If price broke resistance, Call Writers SHOULD unwind (negative change in OI)
            if atm_item and atm_item.ce_change_oi > 0:
                bull_trap = True
                notes.append("Spot breaking higher but Call Writers aggressively adding OI at ATM (Potential Bull Trap).")
            elif analytics.total_call_oi_change > analytics.total_put_oi_change * 1.5:
                bull_trap = True
                notes.append("Spot at highs but Call OI buildup exceeds Put OI buildup.")

        # Bear Trap check
        if technicals.spot_price <= technicals.pdl or technicals.spot_price <= technicals.orl:
            # If price broke support, Put Writers SHOULD unwind
            if atm_item and atm_item.pe_change_oi > 0:
                bear_trap = True
                notes.append("Spot breaking lower but Put Writers holding ground and adding OI at ATM (Potential Bear Trap).")
            elif analytics.total_put_oi_change > analytics.total_call_oi_change * 1.5:
                bear_trap = True
                notes.append("Spot at lows but Put OI buildup indicates strong institutional absorption.")

        if session_phase == "Midday Chop":
            notes.append("Midday low volatility zone (11:30 - 13:30 IST): High theta decay risk. Exercise caution.")

        return TrapContext(
            session_phase=session_phase,
            bull_trap_alert=bull_trap,
            bear_trap_alert=bear_trap,
            trap_notes=" | ".join(notes) if notes else "Normal auction flow. No immediate writer trap detected."
        )

    def generate_snapshot(
        self,
        instrument: str,
        candles: List[Candle],
        chain: List[OptionChainStrike],
        pdh: float,
        pdl: float,
        india_vix: float,
        prev_close: float,
        curr_time: datetime,
        dte_days: float = 2.5
    ) -> MarketSnapshot:
        technicals = self.compute_technicals(candles, pdh, pdl)
        strike_step = self.get_strike_step(instrument)
        analytics = self.compute_option_analytics(chain, technicals.spot_price, strike_step, india_vix, dte_days)
        trap_ctx = self.evaluate_traps_and_context(technicals, analytics, chain, curr_time)

        price_chg = round(technicals.spot_price - prev_close, 2)
        price_chg_pct = round((price_chg / prev_close) * 100.0, 2) if prev_close > 0 else 0.0

        return MarketSnapshot(
            instrument=instrument,
            timestamp=curr_time.strftime("%Y-%m-%d %H:%M:%S"),
            spot_price=technicals.spot_price,
            price_change=price_chg,
            price_change_pct=price_chg_pct,
            technicals=technicals,
            option_analytics=analytics,
            trap_context=trap_ctx,
            recent_candles=candles[-50:], # Last 50 candles for charting
            option_chain=chain
        )
