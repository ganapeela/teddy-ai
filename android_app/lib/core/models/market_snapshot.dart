import 'candle.dart';
import 'option_chain.dart';

class MarketTechnicals {
  final double spotPrice;
  final double vwap;
  final double ema9;
  final double ema20;
  final double pdh;
  final double pdl;
  final double orh;
  final double orl;
  final double swingHigh;
  final double swingLow;
  final double atr14;
  final double rsi14;
  final bool bosDetected;
  final String? bosDirection;
  final bool chochDetected;
  final Map<String, dynamic>? orderBlock;
  final Map<String, dynamic>? fvg;

  const MarketTechnicals({
    required this.spotPrice,
    required this.vwap,
    required this.ema9,
    required this.ema20,
    required this.pdh,
    required this.pdl,
    required this.orh,
    required this.orl,
    required this.swingHigh,
    required this.swingLow,
    required this.atr14,
    required this.rsi14,
    this.bosDetected = false,
    this.bosDirection,
    this.chochDetected = false,
    this.orderBlock,
    this.fvg,
  });

  factory MarketTechnicals.fromJson(Map<String, dynamic> json) {
    return MarketTechnicals(
      spotPrice: (json['spot_price'] as num?)?.toDouble() ?? 0.0,
      vwap: (json['vwap'] as num?)?.toDouble() ?? 0.0,
      ema9: (json['ema_9'] as num?)?.toDouble() ?? 0.0,
      ema20: (json['ema_20'] as num?)?.toDouble() ?? 0.0,
      pdh: (json['pdh'] as num?)?.toDouble() ?? 0.0,
      pdl: (json['pdl'] as num?)?.toDouble() ?? 0.0,
      orh: (json['orh'] as num?)?.toDouble() ?? 0.0,
      orl: (json['orl'] as num?)?.toDouble() ?? 0.0,
      swingHigh: (json['swing_high'] as num?)?.toDouble() ?? 0.0,
      swingLow: (json['swing_low'] as num?)?.toDouble() ?? 0.0,
      atr14: (json['atr_14'] as num?)?.toDouble() ?? 0.0,
      rsi14: (json['rsi_14'] as num?)?.toDouble() ?? 50.0,
      bosDetected: json['bos_detected'] as bool? ?? false,
      bosDirection: json['bos_direction'] as String?,
      chochDetected: json['choch_detected'] as bool? ?? false,
      orderBlock: json['order_block'] as Map<String, dynamic>?,
      fvg: json['fvg'] as Map<String, dynamic>?,
    );
  }
}

class OptionAnalytics {
  final double atmStrike;
  final double maxCallOiStrike;
  final double maxPutOiStrike;
  final int totalCallOi;
  final int totalPutOi;
  final int totalCallOiChange;
  final int totalPutOiChange;
  final double pcr;
  final String pcrTrend;
  final double indiaVix;
  final double atmIv;
  final double dteDays;
  final String dteLabel;

  const OptionAnalytics({
    required this.atmStrike,
    required this.maxCallOiStrike,
    required this.maxPutOiStrike,
    required this.totalCallOi,
    required this.totalPutOi,
    required this.totalCallOiChange,
    required this.totalPutOiChange,
    required this.pcr,
    required this.pcrTrend,
    required this.indiaVix,
    required this.atmIv,
    required this.dteDays,
    required this.dteLabel,
  });

  factory OptionAnalytics.fromJson(Map<String, dynamic> json) {
    return OptionAnalytics(
      atmStrike: (json['atm_strike'] as num?)?.toDouble() ?? 0.0,
      maxCallOiStrike: (json['max_call_oi_strike'] as num?)?.toDouble() ?? 0.0,
      maxPutOiStrike: (json['max_put_oi_strike'] as num?)?.toDouble() ?? 0.0,
      totalCallOi: (json['total_call_oi'] as num?)?.toInt() ?? 0,
      totalPutOi: (json['total_put_oi'] as num?)?.toInt() ?? 0,
      totalCallOiChange: (json['total_call_oi_change'] as num?)?.toInt() ?? 0,
      totalPutOiChange: (json['total_put_oi_change'] as num?)?.toInt() ?? 0,
      pcr: (json['pcr'] as num?)?.toDouble() ?? 1.0,
      pcrTrend: json['pcr_trend'] as String? ?? 'FLAT',
      indiaVix: (json['india_vix'] as num?)?.toDouble() ?? 13.5,
      atmIv: (json['atm_iv'] as num?)?.toDouble() ?? 13.5,
      dteDays: (json['dte_days'] as num?)?.toDouble() ?? 2.5,
      dteLabel: json['dte_label'] as String? ?? '2.5 DTE',
    );
  }
}

class TrapContext {
  final String sessionPhase;
  final bool bullTrapAlert;
  final bool bearTrapAlert;
  final String? trapNotes;

  const TrapContext({
    required this.sessionPhase,
    required this.bullTrapAlert,
    required this.bearTrapAlert,
    this.trapNotes,
  });

  factory TrapContext.fromJson(Map<String, dynamic> json) {
    return TrapContext(
      sessionPhase: json['session_phase'] as String? ?? 'Normal Session',
      bullTrapAlert: json['bull_trap_alert'] as bool? ?? false,
      bearTrapAlert: json['bear_trap_alert'] as bool? ?? false,
      trapNotes: json['trap_notes'] as String?,
    );
  }
}

class MarketSnapshot {
  final String instrument;
  final String timestamp;
  final double spotPrice;
  final double priceChange;
  final double priceChangePct;
  final MarketTechnicals technicals;
  final OptionAnalytics optionAnalytics;
  final TrapContext trapContext;
  final List<Candle> recentCandles;
  final List<OptionChainStrike> optionChain;

  const MarketSnapshot({
    required this.instrument,
    required this.timestamp,
    required this.spotPrice,
    required this.priceChange,
    required this.priceChangePct,
    required this.technicals,
    required this.optionAnalytics,
    required this.trapContext,
    required this.recentCandles,
    required this.optionChain,
  });

  factory MarketSnapshot.fromJson(Map<String, dynamic> json) {
    return MarketSnapshot(
      instrument: json['instrument'] as String? ?? 'NIFTY 50',
      timestamp: json['timestamp'] as String? ?? '',
      spotPrice: (json['spot_price'] as num?)?.toDouble() ?? 0.0,
      priceChange: (json['price_change'] as num?)?.toDouble() ?? 0.0,
      priceChangePct: (json['price_change_pct'] as num?)?.toDouble() ?? 0.0,
      technicals: MarketTechnicals.fromJson(json['technicals'] as Map<String, dynamic>? ?? {}),
      optionAnalytics: OptionAnalytics.fromJson(json['option_analytics'] as Map<String, dynamic>? ?? {}),
      trapContext: TrapContext.fromJson(json['trap_context'] as Map<String, dynamic>? ?? {}),
      recentCandles: (json['recent_candles'] as List<dynamic>?)
              ?.map((e) => Candle.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      optionChain: (json['option_chain'] as List<dynamic>?)
              ?.map((e) => OptionChainStrike.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
