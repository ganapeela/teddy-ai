# 🧸 Teddy AI — Indian F&O Options Analyzer
### Institutional 20+ Year Veteran Options Trading Monorepo (Android Flutter + Python FastAPI)

Teddy AI is an institutional-grade Indian F&O options analyzer built for **NSE / BSE: Nifty 50, BankNifty, and Sensex**. It pairs a **deterministic, zero-hallucination Quant Engine** with a **Gemini-powered 20+ Year Institutional Trader Reasoning Brain** and a sleek, high-contrast **Material 3 Dark Mode Android Trading Terminal**.

---

## 🏛️ Architecture Overview

```
                                  +------------------------------------+
                                  |    Teddy AI Android App (Flutter)  |
                                  |  - Candlestick Chart + Overlays    |
                                  |  - Teddy Desk (Trade Breakdown)    |
                                  |  - Live Option Chain (OI / Greeks) |
                                  |  - Signal Audit Log & Settings     |
                                  +-----------------+------------------+
                                                    |  REST / WebSockets
                                                    v
+-------------------------------------------------------------------------------------------------------+
|                                     FASTAPI PYTHON BACKEND                                            |
|                                                                                                       |
|  +-------------------------------------+             +---------------------------------------------+  |
|  |     Deterministic Quant Engine      |             |             Teddy AI Brain                  |  |
|  |  • Spot, VWAP, 9/20 EMA             |  Snapshot   |  • Gemini LLM + 20+ Yr Veteran System Prompt |  |
|  |  • PDH/PDL, ORH/ORL, ATR, RSI       |  Structured |  • Strict Capital Preservation Protocol     |  |
|  |  • Smart Money Concepts (BOS/CHoCH) | ----------> |  • Trap Awareness (Bull / Bear Traps)       |  |
|  |  • Order Blocks & Fair Value Gaps   |    JSON     |  • R:R >= 1:2 Hurdle Rate or NO_TRADE       |  |
|  |  • Option Chain Greeks (B-S)        |             |  • Offline Deterministic Veteran Fallback   |  |
|  |  • PCR, Delta OI, Max Call/Put Walls|             +----------------------+----------------------+  |
|  +-------------------------------------+                                    |                         |
|                    ^                                                        v                         |
|                    |                                       +-------------------------------+          |
|  +-----------------+-------------------+                   |    SQLite Signal Audit Log    |          |
|  |      Data Feed Adapter Pattern      |                   |    Past Calls, Levels & Audit |          |
|  |  • 24/7 Market Replay / Mock Engine |                   +-------------------------------+          |
|  |  • Live Broker Adapter (DhanHQ)     |                                                              |
|  +-------------------------------------+                                                              |
+-------------------------------------------------------------------------------------------------------+
```

---

## 📁 Monorepo Structure

```
Teddy/
├── backend/
│   ├── .env.example              # Environment variables template (Gemini API, Broker keys)
│   ├── requirements.txt          # Python dependencies (FastAPI, Uvicorn, Pandas, NumPy, etc.)
│   ├── config.py                 # Instruments config (Nifty 50, BankNifty, Sensex), strike steps
│   ├── models.py                 # Pydantic schemas (MarketSnapshot, TeddySignal, Candle, etc.)
│   ├── quant_engine.py           # Deterministic Math: VWAP, EMA, ATR, RSI, SMC, BS Greeks, Traps
│   ├── teddy_brain.py            # 20+ Year Veteran LLM Engine + Deterministic Institutional Fallback
│   ├── data_feed.py              # 24/7 Market Replay Generator + Live Broker Adapter (DhanHQ)
│   ├── database.py               # SQLite Signal Audit Log database
│   ├── main.py                   # FastAPI app, REST routes, WebSockets broadcast
│   └── test_quant.py             # Full pipeline verification test suite
│
├── android_app/
│   ├── pubspec.yaml              # Flutter dependencies (Riverpod, Dio, WebSocket, Notifications)
│   ├── android/
│   │   ├── app/
│   │   │   ├── build.gradle      # Android SDK 34, compile options
│   │   │   └── src/main/AndroidManifest.xml # INTERNET, POST_NOTIFICATIONS permissions
│   └── lib/
│       ├── main.dart             # App entrypoint, Dark theme, notification setup
│       ├── core/
│       │   ├── constants/        # Terminal color palette (Obsidian, Cyan, Emerald, Crimson, Amber)
│       │   ├── models/           # Candle, OptionChain, MarketSnapshot, TeddySignal models
│       │   ├── network/          # Dio ApiService & WebSocketChannel live streaming
│       │   ├── services/         # NotificationService & built-in Offline Demo fallback
│       │   └── providers/        # Riverpod: MarketNotifier, TeddySignalNotifier, SettingsNotifier
│       └── ui/
│           ├── navigation/       # MainScreen with Top App Bar + Ticker Strip + Bottom Nav Bar
│           ├── screens/
│           │   ├── chart_screen.dart            # Candlestick chart + Overlays + Sticky verdict
│           │   ├── teddy_desk_screen.dart       # Confidence ring, execution cards, institutional breakdown
│           │   ├── option_chain_screen.dart     # ATM ± 5 table, horizontal OI bars, IV, Delta
│           │   └── history_settings_screen.dart # Signal Audit Log + Server IP & Alert settings
│           └── widgets/
│               ├── interactive_candle_chart.dart # CustomPainter canvas with pinch-zoom & crosshair
│               ├── confidence_meter.dart        # Circular progress confidence meter
│               ├── ticker_strip.dart            # Spot LTP, VIX, PCR, Session Phase strip
│               └── copyable_badge.dart          # Tap-to-copy institutional trade level badges
└── README.md
```

---

## ⚡ Quick Start: Python Backend

### 1. Setup Virtual Environment & Install Requirements
```bash
cd backend
python -m venv venv
# On Windows PowerShell:
.\venv\Scripts\Activate.ps1
# On macOS/Linux:
source venv/bin/activate

pip install -r requirements.txt
```

### 2. Configure Environment (Optional for Live Gemini API)
```bash
cp .env.example .env
```
Open `.env` and optionally paste your Gemini API Key:
```ini
GEMINI_API_KEY=your_gemini_api_key_here
```
> **Note:** If `GEMINI_API_KEY` is omitted, Teddy AI automatically runs in **Deterministic Veteran Fallback Mode**, applying the exact same 20+ year institutional risk rules and trap filters!

### 3. Run Pipeline Test Suite
```bash
python test_quant.py
```

### 4. Start the FastAPI Backend Server
```bash
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```
- API Documentation (Swagger UI): `http://localhost:8000/docs`
- Live Snapshot: `http://localhost:8000/api/snapshot?instrument=NIFTY%2050`
- Live WebSocket Stream: `ws://localhost:8000/ws`

---

## 📱 Quick Start: Flutter Android App

### 1. Install Flutter Dependencies
```bash
cd android_app
flutter pub get
```

### 2. Run on Android Emulator or Connected Phone
```bash
# To run on default Android device:
flutter run

# To run specifically with release optimizations:
flutter run --release
```

### 3. Building Release APK
```bash
flutter build apk --release
```
The compiled APK will be created at:
`android_app/build/app/outputs/flutter-apk/app-release.apk`

---

## 🌐 Connecting Android to Backend

Depending on where you run the Flutter app:

| Client Device | Backend Host Setting in App | Description |
|---|---|---|
| **Android Emulator** | `http://10.0.2.2:8000` | Android emulator loopback alias to host machine |
| **Physical Phone (USB/WiFi)** | `http://192.168.1.X:8000` | Your PC's local Wi-Fi IP address |
| **Flutter Web / Desktop** | `http://127.0.0.1:8000` | Direct local machine loopback |
| **Backend Not Running** | *(Automatic)* | App launches smoothly in **Offline Simulation Mode** with realistic live data |

You can switch the server IP directly from the **Settings Tab** inside the app at any time!

---

## 🧠 Institutional Trading Logic

### 1. Deterministic Quant Engine (`quant_engine.py`)
- **Technicals**: Intraday VWAP, 9 & 20 Exponential Moving Averages, Previous Day High/Low (PDH/PDL), Opening Range High/Low (ORH/ORL), ATR(14), RSI(14).
- **Smart Money Concepts (SMC)**: Break of Structure (BOS), Change of Character (CHoCH), Bullish/Bearish Order Blocks (OB), and Fair Value Gaps (FVG).
- **Option Chain Analytics**: ATM Strike rounding (50 for Nifty, 100 for BankNifty/Sensex), Max Call OI (Resistance Wall), Max Put OI (Support Wall), Put-Call Ratio (PCR) & Intraday Slope, ATM Implied Volatility (IV), and Black-Scholes Greeks (Delta, Theta, Vega).
- **Institutional Trap Detector**:
  - *Bull Trap Alert*: Spot breaking above PDH or ORH while Call Writers are aggressively *adding* OI instead of covering.
  - *Bear Trap Alert*: Spot breaking below PDL or ORL while Put Writers are actively *adding* OI instead of dumping.
- **Session Phase Tagging**:
  - `09:15 - 09:30 IST`: Opening Volatility (High Risk)
  - `09:30 - 11:30 IST`: Morning Trend (Prime Momentum Window)
  - `11:30 - 13:30 IST`: Midday Chop (Theta Bleed Trap Zone)
  - `13:30 - 15:15 IST`: Closing Move / Expiry Gamma Expansion

### 2. Teddy AI Brain (`teddy_brain.py`)
- Strictly enforces capital preservation and an institutional **1:2 minimum Risk-to-Reward ratio**.
- If confluence is weak, market is trapped in midday chop, or Bull/Bear traps are active, returns `NO_TRADE` with explicit veteran reasoning.
- Outputs structured execution levels:
  - Recommended Strike (e.g. `NIFTY 24500 CE`)
  - Spot Trigger Level
  - Option Entry Zone `[low, high]`
  - Option Stop Loss & Spot Invalidation Level
  - Targets `[T1, T2, T3]` with partial booking (50% at T1) and 9 EMA trailing logic.
