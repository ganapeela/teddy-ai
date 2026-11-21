import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/market_snapshot.dart';
import '../models/teddy_signal.dart';

class GeminiService {
  final Dio _dio = Dio();

  static const String teddySystemPrompt = """
You are "Teddy" — a 20+ year veteran institutional Indian F&O (NSE/BSE: Nifty, BankNifty, Sensex) derivatives trader.
YOUR PHILOSOPHY:
1. CAPITAL PRESERVATION FIRST.
2. Strict Risk-to-Reward: Never initiate any option buying trade with less than 1:2 R:R.
3. No Hallucinations: Base your analysis STRICTLY on the provided quantitative snapshot.
4. If market is choppy, stuck inside VWAP/EMA range, or conflicting OI buildup vs price action, return "NO_TRADE".
5. Trap Awareness: Never buy CE if Call writers are aggressively building OI at resistance (Bull Trap). Never buy PE if Put writers are absorbing at support (Bear Trap).

YOU MUST RESPOND ONLY WITH A VALID JSON OBJECT MATCHING THIS SCHEMA:
{
  "decision": "BUY_CE | BUY_PE | NO_TRADE",
  "confidence_score": <0-100>,
  "setup_type": "<string>",
  "instrument": "<string, e.g. NIFTY 24500 CE>",
  "spot_trigger": <number or null>,
  "option_entry_zone": [<low>, <high>] or null,
  "stop_loss_option": <number or null>,
  "stop_loss_spot": <number or null>,
  "targets_option": [<t1>, <t2>, <t3>] or null,
  "risk_reward": "<e.g. 1:2.4>",
  "why_this_trade": ["<point 1>", "<point 2>", "<point 3>"],
  "how_to_execute": "<string>",
  "invalidation_warning": "<string>"
}
""";

  Future<TeddySignal?> analyzeOnDevice(MarketSnapshot snapshot, String apiKey) async {
    if (apiKey.trim().isEmpty) return null;

    final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey';

    final promptData = {
      "instrument": snapshot.instrument,
      "spot_price": snapshot.spotPrice,
      "price_change_pct": snapshot.priceChangePct,
      "technicals": {
        "vwap": snapshot.technicals.vwap,
        "ema_9": snapshot.technicals.ema9,
        "ema_20": snapshot.technicals.ema20,
        "pdh": snapshot.technicals.pdh,
        "pdl": snapshot.technicals.pdl,
        "orh": snapshot.technicals.orh,
        "orl": snapshot.technicals.orl,
        "rsi_14": snapshot.technicals.rsi14,
        "atr_14": snapshot.technicals.atr14,
        "bos_detected": snapshot.technicals.bosDetected,
        "bos_direction": snapshot.technicals.bosDirection
      },
      "option_analytics": {
        "atm_strike": snapshot.optionAnalytics.atmStrike,
        "max_call_oi": snapshot.optionAnalytics.maxCallOiStrike,
        "max_put_oi": snapshot.optionAnalytics.maxPutOiStrike,
        "pcr": snapshot.optionAnalytics.pcr,
        "pcr_trend": snapshot.optionAnalytics.pcrTrend,
        "india_vix": snapshot.optionAnalytics.indiaVix
      },
      "trap_context": {
        "session_phase": snapshot.trapContext.sessionPhase,
        "bull_trap": snapshot.trapContext.bullTrapAlert,
        "bear_trap": snapshot.trapContext.bearTrapAlert
      }
    };

    final body = {
      "contents": [
        {
          "role": "user",
          "parts": [
            {
              "text": "$teddySystemPrompt\n\nMARKET SNAPSHOT DATA:\n${jsonEncode(promptData)}\n\nAnalyze this snapshot and output strict JSON only."
            }
          ]
        }
      ]
    };

    try {
      final response = await _dio.post(
        url,
        data: body,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final candidates = response.data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) return null;

      final text = candidates[0]['content']['parts'][0]['text'] as String;
      String cleanJson = text.trim();
      if (cleanJson.startsWith('```')) {
        cleanJson = cleanJson.split('\n').sublist(1).join('\n');
      }
      if (cleanJson.endsWith('```')) {
        cleanJson = cleanJson.substring(0, cleanJson.lastIndexOf('```'));
      }
      cleanJson = cleanJson.trim();

      final data = jsonDecode(cleanJson) as Map<String, dynamic>;
      return TeddySignal.fromJson(data);
    } catch (e) {
      print('On-device Gemini API error: $e');
      return null;
    }
  }
}
