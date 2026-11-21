import 'dart:math';
import '../models/candle.dart';
import '../models/market_snapshot.dart';
import '../models/option_chain.dart';
import '../models/teddy_signal.dart';

class MockDataGenerator {
  static MarketSnapshot generateMockSnapshot(String instrument) {
    final double baseSpot = instrument == 'BANKNIFTY'
        ? 52200.0
        : (instrument == 'SENSEX' ? 80350.0 : 24450.0);
    final int step = instrument == 'NIFTY 50' ? 50 : 100;
    final double spot = baseSpot + (Random().nextDouble() * 15.0 - 5.0);
    final double prevClose = baseSpot - 85.0;

    final List<Candle> candles = [];
    double curr = baseSpot - 50.0;
    final now = DateTime.now();

    for (int i = 40; i >= 0; i--) {
      final t = now.subtract(Duration(minutes: i * 5));
      final open = curr;
      final close = open + (Random().nextDouble() * 14.0 - 5.0);
      final high = max(open, close) + Random().nextDouble() * 8.0;
      final low = min(open, close) - Random().nextDouble() * 8.0;
      candles.add(Candle(
        timestamp: '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
        open: double.parse(open.toStringAsFixed(2)),
        high: double.parse(high.toStringAsFixed(2)),
        low: double.parse(low.toStringAsFixed(2)),
        close: double.parse(close.toStringAsFixed(2)),
        volume: (15000 + Random().nextInt(25000)).toDouble(),
      ));
      curr = close;
    }

    final double atmStrike = (spot / step).round() * step.toDouble();
    final List<OptionChainStrike> chain = [];

    for (int offset = -5; offset <= 5; offset++) {
      final strike = atmStrike + (offset * step);
      final ceLtp = max(5.0, (spot - strike) + (spot * 0.007));
      final peLtp = max(5.0, (strike - spot) + (spot * 0.007));
      final baseOi = (140000 / (1 + offset.abs() * 0.5)).round();

      chain.add(OptionChainStrike(
        strike: strike,
        ceLtp: double.parse(ceLtp.toStringAsFixed(1)),
        ceOi: baseOi + 15000,
        ceChangeOi: (baseOi * 0.08).round(),
        ceIv: 13.8 + (offset * 0.2),
        ceDelta: double.parse((0.50 - (offset * 0.08)).clamp(0.05, 0.95).toStringAsFixed(2)),
        ceTheta: -12.5,
        ceVega: 14.2,
        peLtp: double.parse(peLtp.toStringAsFixed(1)),
        peOi: baseOi + 22000,
        peChangeOi: (baseOi * 0.12).round(),
        peIv: 14.2 - (offset * 0.2),
        peDelta: double.parse((-0.50 - (offset * 0.08)).clamp(-0.95, -0.05).toStringAsFixed(2)),
        peTheta: -11.8,
        peVega: 14.0,
      ));
    }

    return MarketSnapshot(
      instrument: instrument,
      timestamp: '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
      spotPrice: double.parse(spot.toStringAsFixed(2)),
      priceChange: double.parse((spot - prevClose).toStringAsFixed(2)),
      priceChangePct: double.parse((((spot - prevClose) / prevClose) * 100).toStringAsFixed(2)),
      technicals: MarketTechnicals(
        spotPrice: spot,
        vwap: spot - 18.0,
        ema9: spot - 6.0,
        ema20: spot - 14.0,
        pdh: baseSpot + 120.0,
        pdl: baseSpot - 90.0,
        orh: baseSpot + 45.0,
        orl: baseSpot - 30.0,
        swingHigh: spot + 22.0,
        swingLow: spot - 35.0,
        atr14: 18.5,
        rsi14: 62.4,
        bosDetected: true,
        bosDirection: 'BULLISH',
        chochDetected: false,
        orderBlock: {'type': 'BULLISH', 'top': spot - 12.0, 'bottom': spot - 25.0},
        fvg: {'type': 'BULLISH', 'top': spot - 8.0, 'bottom': spot - 15.0},
      ),
      optionAnalytics: OptionAnalytics(
        atmStrike: atmStrike,
        maxCallOiStrike: atmStrike + (2 * step),
        maxPutOiStrike: atmStrike - (1 * step),
        totalCallOi: 1420000,
        totalPutOi: 1890000,
        totalCallOiChange: 65000,
        totalPutOiChange: 145000,
        pcr: 1.33,
        pcrTrend: 'RISING',
        indiaVix: 13.8,
        atmIv: 14.0,
        dteDays: 2.5,
        dteLabel: '2.5 DTE',
      ),
      trapContext: const TrapContext(
        sessionPhase: 'Morning Trend',
        bullTrapAlert: false,
        bearTrapAlert: false,
        trapNotes: 'Aggressive Put writer additions at ATM indicating institutional base.',
      ),
      recentCandles: candles,
      optionChain: chain,
    );
  }

  static TeddySignal generateMockSignal(String instrument, MarketSnapshot snapshot) {
    final double spot = snapshot.spotPrice;
    final atm = snapshot.optionAnalytics.atmStrike.toInt();
    final recStrike = '$instrument $atm CE';

    return TeddySignal(
      id: 99,
      timestamp: snapshot.timestamp,
      instrument: instrument,
      decision: 'BUY_CE',
      confidenceScore: 84,
      setupType: 'VWAP Pullback + Put Writer Squeeze Breakout',
      recommendedStrike: recStrike,
      spotTrigger: double.parse((spot + 4.0).toStringAsFixed(1)),
      optionEntryZone: const [145.0, 155.0],
      stopLossOption: 118.0,
      stopLossSpot: double.parse((spot - 32.0).toStringAsFixed(1)),
      targetsOption: const [185.0, 215.0, 260.0],
      riskReward: '1:2.6',
      whyThisTrade: [
        'Spot is holding decisively above rising VWAP and 9/20 EMA stack with confirmed Bullish BOS.',
        'Put writers added +145k contracts at $atm strike while Call writers began covering shorts (PCR expanded to ${snapshot.optionAnalytics.pcr}).',
        'India VIX at ${snapshot.optionAnalytics.indiaVix} supports clean directional momentum with favorable Delta (+0.52).'
      ],
      howToExecute: 'Enter $recStrike between ₹145 - ₹155. Book 50% at T1 (₹185) and move Stop Loss to cost immediately. Trail remaining quantity using 5m 9 EMA towards T2 (₹215) and T3 (₹260).',
      invalidationWarning: 'A 5m candle close below VWAP or sudden spike in ATM Call OI (>60k contracts) immediately invalidates this setup.',
    );
  }
}
