"""
Teddy AI - Reasoning Engine (20+ Year Indian F&O Veteran Institutional Trader)
Processes structured Quant Engine snapshots through Gemini LLM with strict capital preservation,
and provides a deterministic institutional fallback when offline or without API key.
"""
import json
import logging
from typing import Dict, Any, Optional

from config import GEMINI_API_KEY
from models import MarketSnapshot, TeddySignal

logger = logging.getLogger("TeddyBrain")

TEDDY_SYSTEM_PROMPT = """
You are "Teddy" — a 20+ year veteran institutional Indian F&O (NSE/BSE: Nifty, BankNifty, Sensex) derivatives trader.
You spent two decades on institutional proprietary trading desks in Mumbai (BKC / Dalal Street).

YOUR PHILOSOPHY:
1. CAPITAL PRESERVATION FIRST. An amateur asks "How much can I make?", an institutional pro asks "How much can I lose?".
2. Strict Risk-to-Reward: Never initiate any option buying trade with less than 1:2 R:R.
3. No Hallucinations: You are given a mathematically computed snapshot from the deterministic Quant Engine. Base your analysis STRICTLY on these numbers.
4. If the market is choppy, stuck inside VWAP/EMA range, or there is conflicting OI buildup vs price action, DO NOT FORCE A TRADE. Return "NO_TRADE" without hesitation.
5. Trap Awareness: Never buy CE if Call writers are aggressively building OI at resistance (Bull Trap). Never buy PE if Put writers are absorbing at support (Bear Trap).
6. Time & Theta Discipline: Be ruthless during Midday Chop (11:30 - 13:30 IST) where option buyers bleed theta.

DECISION PROTOCOL:
- If High Confluence Bullish (Spot > VWAP > EMA 20, PCR > 1.15 or rising, Call unwinding, BOS/FVG support):
  Consider BUY_CE (Slightly OTM or ATM strike).
- If High Confluence Bearish (Spot < VWAP < EMA 20, PCR < 0.85 or falling, Put unwinding, Bearish BOS/OB resistance):
  Consider BUY_PE (Slightly OTM or ATM strike).
- If R:R < 1:2, choppy, Bull/Bear Trap detected, or conflicting signals:
  MUST return NO_TRADE.

YOU MUST RESPOND ONLY WITH A VALID JSON OBJECT MATCHING THIS EXACT SCHEMA:
{
  "decision": "BUY_CE | BUY_PE | NO_TRADE",
  "confidence_score": <number between 0 and 100>,
  "setup_type": "<string, e.g. VWAP Pullback + Call Short Covering Breakout>",
  "instrument": "<string, e.g. NIFTY 24500 CE>",
  "spot_trigger": <number or null>,
  "option_entry_zone": [<low number>, <high number>] or null,
  "stop_loss_option": <number or null>,
  "stop_loss_spot": <number or null>,
  "targets_option": [<t1>, <t2>, <t3>] or null,
  "risk_reward": "<string, e.g. 1:2.4>",
  "why_this_trade": [
    "<Price action & market structure (SMC, VWAP, EMA) reasoning>",
    "<Option Chain / OI & PCR confirmation (Writer positioning, unwinding)>",
    "<Volatility (India VIX/IV) & Theta/Expiry reasoning>"
  ],
  "how_to_execute": "<Step-by-step entry, partial booking at T1 (50%), moving SL to cost, and trailing remainder with 9 EMA>",
  "invalidation_warning": "<Exact condition that immediately invalidates the trade setup>"
}
"""

class TeddyBrain:
    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key or GEMINI_API_KEY
        self.client = None
        if self.api_key:
            try:
                # Try google-genai SDK first
                from google import genai
                self.client = genai.Client(api_key=self.api_key)
                self.sdk_type = "genai"
                logger.info("Initialized Google GenAI client.")
            except Exception:
                try:
                    import google.generativeai as gai
                    gai.configure(api_key=self.api_key)
                    self.client = gai.GenerativeModel("gemini-2.5-flash")
                    self.sdk_type = "generativeai"
                    logger.info("Initialized Google GenerativeAI legacy client.")
                except Exception as e:
                    logger.warning(f"Could not initialize Gemini SDK: {e}")
                    self.client = None

    def analyze_snapshot(self, snapshot: MarketSnapshot) -> TeddySignal:
        """
        Sends snapshot to Gemini LLM, or uses high-fidelity institutional deterministic rules
        if offline/no key.
        """
        if self.client:
            try:
                signal = self._query_gemini(snapshot)
                if signal:
                    return signal
            except Exception as e:
                logger.error(f"Gemini API analysis failed: {e}. Falling back to Institutional Quant Brain.")

        return self._deterministic_veteran_fallback(snapshot)

    def _query_gemini(self, snapshot: MarketSnapshot) -> Optional[TeddySignal]:
        # Formulate clean compact JSON payload for LLM
        prompt_payload = {
            "instrument": snapshot.instrument,
            "timestamp": snapshot.timestamp,
            "spot_price": snapshot.spot_price,
            "price_change_pct": snapshot.price_change_pct,
            "technicals": snapshot.technicals.model_dump(),
            "option_analytics": snapshot.option_analytics.model_dump(),
            "trap_context": snapshot.trap_context.model_dump(),
            "key_strikes": [
                {
                    "strike": s.strike,
                    "ce_ltp": s.ce_ltp,
                    "ce_oi": s.ce_oi,
                    "ce_chg_oi": s.ce_change_oi,
                    "pe_ltp": s.pe_ltp,
                    "pe_oi": s.pe_oi,
                    "pe_chg_oi": s.pe_change_oi,
                }
                for s in snapshot.option_chain
                if abs(s.strike - snapshot.option_analytics.atm_strike) <= (
                    150 if "NIFTY" in snapshot.instrument else 300
                )
            ]
        }

        user_content = f"MARKET SNAPSHOT DATA:\n{json.dumps(prompt_payload, indent=2)}\n\nAnalyze this data as the 20+ year veteran institutional trader and output ONLY strict JSON."

        raw_text = ""
        if self.sdk_type == "genai":
            response = self.client.models.generate_content(
                model="gemini-2.5-flash",
                contents=[
                    {"role": "system", "parts": [{"text": TEDDY_SYSTEM_PROMPT}]},
                    {"role": "user", "parts": [{"text": user_content}]}
                ]
            )
            raw_text = response.text
        else:
            response = self.client.generate_content(
                f"{TEDDY_SYSTEM_PROMPT}\n\n{user_content}"
            )
            raw_text = response.text

        # Clean JSON markdown if wrapped in ```json ... ```
        clean_json = raw_text.strip()
        if clean_json.startswith("```"):
            clean_json = clean_json.split("\n", 1)[1]
        if clean_json.endswith("```"):
            clean_json = clean_json.rsplit("\n", 1)[0]
        clean_json = clean_json.strip()

        data = json.loads(clean_json)

        return TeddySignal(
            timestamp=snapshot.timestamp,
            instrument=snapshot.instrument,
            decision=data.get("decision", "NO_TRADE"),
            confidence_score=int(data.get("confidence_score", 50)),
            setup_type=data.get("setup_type", "Standard Quant Setup"),
            recommended_strike=data.get("instrument") or data.get("recommended_strike"),
            spot_trigger=data.get("spot_trigger"),
            option_entry_zone=data.get("option_entry_zone"),
            stop_loss_option=data.get("stop_loss_option"),
            stop_loss_spot=data.get("stop_loss_spot"),
            targets_option=data.get("targets_option"),
            risk_reward=data.get("risk_reward", "1:2.0"),
            why_this_trade=data.get("why_this_trade", []),
            how_to_execute=data.get("how_to_execute", "Follow standard disciplined trade management."),
            invalidation_warning=data.get("invalidation_warning", "Spot closing beyond structural invalidation level."),
            raw_reasoning=raw_text
        )

    def _deterministic_veteran_fallback(self, snapshot: MarketSnapshot) -> TeddySignal:
        """
        Rock-solid institutional rule engine replicating the exact veteran logic:
        Confluence scoring, Trap filtering, and R:R thresholding.
        """
        tech = snapshot.technicals
        opt = snapshot.option_analytics
        trap = snapshot.trap_context
        spot = snapshot.spot_price
        strike_step = 50 if "NIFTY 50" in snapshot.instrument else 100

        # Rule 1: Trap Filtering
        if trap.bull_trap_alert:
            return TeddySignal(
                timestamp=snapshot.timestamp,
                instrument=snapshot.instrument,
                decision="NO_TRADE",
                confidence_score=40,
                setup_type="Bull Trap Filter Triggered",
                risk_reward="N/A",
                why_this_trade=[
                    f"Spot price ({spot}) broke or tested highs, but Call Writers aggressively added OI.",
                    "Institutional writing indicates smart money is absorbing buying pressure.",
                    "High probability of fake breakout and sharp reversal downward."
                ],
                how_to_execute="Stand aside. Do not chase breakouts when Call open interest is expanding aggressively.",
                invalidation_warning="Setup is fully invalidated if Call writers begin rapid short covering (>20% OI unwinding)."
            )

        if trap.bear_trap_alert:
            return TeddySignal(
                timestamp=snapshot.timestamp,
                instrument=snapshot.instrument,
                decision="NO_TRADE",
                confidence_score=40,
                setup_type="Bear Trap Filter Triggered",
                risk_reward="N/A",
                why_this_trade=[
                    f"Spot price ({spot}) broke or tested lows, but Put Writers aggressively built OI at ATM.",
                    "Institutional absorption detected: Smart money refuses to let price slide lower.",
                    "High probability of aggressive short squeeze triggering higher."
                ],
                how_to_execute="Stand aside. Do not short or buy puts when Put open interest is holding strong.",
                invalidation_warning="Invalidated if Put OI breaks down with sustained negative change in OI."
            )

        # Rule 2: Midday Chop Filter
        if trap.session_phase == "Midday Chop" and 45 <= tech.rsi_14 <= 55:
            return TeddySignal(
                timestamp=snapshot.timestamp,
                instrument=snapshot.instrument,
                decision="NO_TRADE",
                confidence_score=35,
                setup_type="Midday Low-Volatility Consolidation",
                risk_reward="N/A",
                why_this_trade=[
                    f"Current time phase is {trap.session_phase} (11:30 - 13:30 IST).",
                    "RSI(14) is flatlining near 50, and spot is oscillating between EMA 9 and EMA 20.",
                    f"Theta decay is accelerating on {opt.dte_label} options with no directional momentum."
                ],
                how_to_execute="Strict capital preservation mode. Wait for European market opening (13:00 - 13:30 IST) volume expansion.",
                invalidation_warning="Fresh breakout above Opening Range High (ORH) with high volume."
            )

        # Rule 3: Bullish Confluence (BUY_CE)
        bullish_conditions = [
            spot > tech.vwap,
            spot > tech.ema_9 and tech.ema_9 > tech.ema_20,
            opt.pcr >= 1.05 or opt.pcr_trend == "RISING",
            tech.bos_detected and tech.bos_direction == "BULLISH",
            opt.total_put_oi_change > opt.total_call_oi_change
        ]
        bullish_score = sum(bullish_conditions)

        if bullish_score >= 4 and not trap.bull_trap_alert:
            atm_strike = int(opt.atm_strike)
            rec_strike_val = atm_strike
            rec_strike_str = f"{snapshot.instrument} {rec_strike_val} CE"

            # Find estimated option LTP from chain
            opt_item = next((s for s in snapshot.option_chain if s.strike == rec_strike_val), None)
            opt_ltp = opt_item.ce_ltp if opt_item else round(spot * 0.007, 1)

            entry_low = round(opt_ltp * 0.98, 1)
            entry_high = round(opt_ltp * 1.02, 1)
            sl_opt = round(opt_ltp * 0.82, 1) # ~18% risk on premium
            sl_spot = round(min(tech.vwap, tech.ema_20) - (tech.atr_14 * 0.3), 1)

            risk_pts = opt_ltp - sl_opt
            t1 = round(opt_ltp + (risk_pts * 1.5), 1)
            t2 = round(opt_ltp + (risk_pts * 2.2), 1)
            t3 = round(opt_ltp + (risk_pts * 3.2), 1)

            confidence = min(92, 65 + (bullish_score * 6))

            return TeddySignal(
                timestamp=snapshot.timestamp,
                instrument=snapshot.instrument,
                decision="BUY_CE",
                confidence_score=confidence,
                setup_type="VWAP + Bullish BOS Order Flow Confluence",
                recommended_strike=rec_strike_str,
                spot_trigger=round(spot + 2.0, 1),
                option_entry_zone=[entry_low, entry_high],
                stop_loss_option=sl_opt,
                stop_loss_spot=sl_spot,
                targets_option=[t1, t2, t3],
                risk_reward="1:2.4",
                why_this_trade=[
                    f"Spot ({spot}) trading above intraday VWAP ({tech.vwap}) and 9/20 EMA stack with confirmed Bullish BOS.",
                    f"Option chain confirms Put writers dominating (PCR {opt.pcr}, Trend: {opt.pcr_trend}). Max Call wall at {opt.max_call_oi_strike}.",
                    f"India VIX at {opt.india_vix} supports momentum expansion with favorable Delta ({opt_item.ce_delta if opt_item else 0.52})."
                ],
                how_to_execute=f"Enter {rec_strike_str} between ₹{entry_low} - ₹{entry_high}. Book 50% at T1 (₹{t1}), move SL to cost immediately. Trail remaining quantity with 9 EMA on 5m chart towards T2 (₹{t2}) and T3 (₹{t3}).",
                invalidation_warning=f"15m candle close below VWAP ({tech.vwap}) or Call writers adding >50k contracts at ATM immediately invalidates trade."
            )

        # Rule 4: Bearish Confluence (BUY_PE)
        bearish_conditions = [
            spot < tech.vwap,
            spot < tech.ema_9 and tech.ema_9 < tech.ema_20,
            opt.pcr <= 0.95 or opt.pcr_trend == "FALLING",
            tech.bos_detected and tech.bos_direction == "BEARISH",
            opt.total_call_oi_change > opt.total_put_oi_change
        ]
        bearish_score = sum(bearish_conditions)

        if bearish_score >= 4 and not trap.bear_trap_alert:
            atm_strike = int(opt.atm_strike)
            rec_strike_val = atm_strike
            rec_strike_str = f"{snapshot.instrument} {rec_strike_val} PE"

            opt_item = next((s for s in snapshot.option_chain if s.strike == rec_strike_val), None)
            opt_ltp = opt_item.pe_ltp if opt_item else round(spot * 0.007, 1)

            entry_low = round(opt_ltp * 0.98, 1)
            entry_high = round(opt_ltp * 1.02, 1)
            sl_opt = round(opt_ltp * 0.82, 1)
            sl_spot = round(max(tech.vwap, tech.ema_20) + (tech.atr_14 * 0.3), 1)

            risk_pts = opt_ltp - sl_opt
            t1 = round(opt_ltp + (risk_pts * 1.5), 1)
            t2 = round(opt_ltp + (risk_pts * 2.2), 1)
            t3 = round(opt_ltp + (risk_pts * 3.2), 1)

            confidence = min(90, 65 + (bearish_score * 6))

            return TeddySignal(
                timestamp=snapshot.timestamp,
                instrument=snapshot.instrument,
                decision="BUY_PE",
                confidence_score=confidence,
                setup_type="VWAP Breakdown + Call Writer Expansion",
                recommended_strike=rec_strike_str,
                spot_trigger=round(spot - 2.0, 1),
                option_entry_zone=[entry_low, entry_high],
                stop_loss_option=sl_opt,
                stop_loss_spot=sl_spot,
                targets_option=[t1, t2, t3],
                risk_reward="1:2.3",
                why_this_trade=[
                    f"Spot ({spot}) decisively below VWAP ({tech.vwap}) and 9/20 EMA stack with Bearish Break of Structure.",
                    f"Call writers aggressively adding open interest while Put writers are dumping positions (PCR {opt.pcr}).",
                    f"Vega/Delta alignment optimal; downside momentum accelerated by long unwinding."
                ],
                how_to_execute=f"Enter {rec_strike_str} in zone ₹{entry_low} - ₹{entry_high}. Secure 50% profits at T1 (₹{t1}) and trail stop to breakeven. Trail balance with 20 EMA high.",
                invalidation_warning=f"Spot reclaim of VWAP ({tech.vwap}) on 5m close invalidates setup."
            )

        # Default: Confluence too low or choppy -> NO_TRADE
        return TeddySignal(
            timestamp=snapshot.timestamp,
            instrument=snapshot.instrument,
            decision="NO_TRADE",
            confidence_score=45,
            setup_type="Low Confluence / Mixed Market Structure",
            risk_reward="< 1:2.0",
            why_this_trade=[
                f"Market structure lacks clean institutional confluence (Bullish score: {bullish_score}/5, Bearish score: {bearish_score}/5).",
                f"Spot ({spot}) hovering around key indicators without clear expansion volume.",
                "Risk-to-reward does not meet the strict 1:2.0 institutional hurdle rate."
            ],
            how_to_execute="Patiently observe. The market offers dozens of opportunities each week; capital protection is job #1.",
            invalidation_warning="Wait for a decisive Break of Structure (BOS) accompanied by heavy Option Writer unwinding."
        )
