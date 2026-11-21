class OptionChainStrike {
  final double strike;
  final double ceLtp;
  final int ceOi;
  final int ceChangeOi;
  final double ceIv;
  final double ceDelta;
  final double ceTheta;
  final double ceVega;
  final double peLtp;
  final int peOi;
  final int peChangeOi;
  final double peIv;
  final double peDelta;
  final double peTheta;
  final double peVega;

  const OptionChainStrike({
    required this.strike,
    required this.ceLtp,
    required this.ceOi,
    required this.ceChangeOi,
    required this.ceIv,
    required this.ceDelta,
    required this.ceTheta,
    required this.ceVega,
    required this.peLtp,
    required this.peOi,
    required this.peChangeOi,
    required this.peIv,
    required this.peDelta,
    required this.peTheta,
    required this.peVega,
  });

  factory OptionChainStrike.fromJson(Map<String, dynamic> json) {
    return OptionChainStrike(
      strike: (json['strike'] as num?)?.toDouble() ?? 0.0,
      ceLtp: (json['ce_ltp'] as num?)?.toDouble() ?? 0.0,
      ceOi: (json['ce_oi'] as num?)?.toInt() ?? 0,
      ceChangeOi: (json['ce_change_oi'] as num?)?.toInt() ?? 0,
      ceIv: (json['ce_iv'] as num?)?.toDouble() ?? 0.0,
      ceDelta: (json['ce_delta'] as num?)?.toDouble() ?? 0.0,
      ceTheta: (json['ce_theta'] as num?)?.toDouble() ?? 0.0,
      ceVega: (json['ce_vega'] as num?)?.toDouble() ?? 0.0,
      peLtp: (json['pe_ltp'] as num?)?.toDouble() ?? 0.0,
      peOi: (json['pe_oi'] as num?)?.toInt() ?? 0,
      peChangeOi: (json['pe_change_oi'] as num?)?.toInt() ?? 0,
      peIv: (json['pe_iv'] as num?)?.toDouble() ?? 0.0,
      peDelta: (json['pe_delta'] as num?)?.toDouble() ?? 0.0,
      peTheta: (json['pe_theta'] as num?)?.toDouble() ?? 0.0,
      peVega: (json['pe_vega'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
