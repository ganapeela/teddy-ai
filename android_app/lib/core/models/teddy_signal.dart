class TeddySignal {
  final int? id;
  final String timestamp;
  final String instrument;
  final String decision; // "BUY_CE" | "BUY_PE" | "NO_TRADE"
  final int confidenceScore; // 0 - 100
  final String setupType;
  final String? recommendedStrike;
  final double? spotTrigger;
  final List<double>? optionEntryZone;
  final double? stopLossOption;
  final double? stopLossSpot;
  final List<double>? targetsOption;
  final String riskReward;
  final List<String> whyThisTrade;
  final String howToExecute;
  final String invalidationWarning;
  final String? rawReasoning;

  const TeddySignal({
    this.id,
    required this.timestamp,
    required this.instrument,
    required this.decision,
    required this.confidenceScore,
    required this.setupType,
    this.recommendedStrike,
    this.spotTrigger,
    this.optionEntryZone,
    this.stopLossOption,
    this.stopLossSpot,
    this.targetsOption,
    required this.riskReward,
    required this.whyThisTrade,
    required this.howToExecute,
    required this.invalidationWarning,
    this.rawReasoning,
  });

  factory TeddySignal.fromJson(Map<String, dynamic> json) {
    List<double>? entryZone;
    if (json['option_entry_zone'] != null) {
      entryZone = (json['option_entry_zone'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList();
    }

    List<double>? targets;
    if (json['targets_option'] != null) {
      targets = (json['targets_option'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList();
    }

    List<String> why = [];
    if (json['why_this_trade'] != null) {
      why = (json['why_this_trade'] as List<dynamic>)
          .map((e) => e.toString())
          .toList();
    }

    return TeddySignal(
      id: json['id'] as int?,
      timestamp: json['timestamp'] as String? ?? '',
      instrument: json['instrument'] as String? ?? 'NIFTY 50',
      decision: json['decision'] as String? ?? 'NO_TRADE',
      confidenceScore: (json['confidence_score'] as num?)?.toInt() ?? 0,
      setupType: json['setup_type'] as String? ?? 'Standard Setup',
      recommendedStrike: json['recommended_strike'] as String?,
      spotTrigger: (json['spot_trigger'] as num?)?.toDouble(),
      optionEntryZone: entryZone,
      stopLossOption: (json['stop_loss_option'] as num?)?.toDouble(),
      stopLossSpot: (json['stop_loss_spot'] as num?)?.toDouble(),
      targetsOption: targets,
      riskReward: json['risk_reward'] as String? ?? '1:2.0',
      whyThisTrade: why,
      howToExecute: json['how_to_execute'] as String? ?? '',
      invalidationWarning: json['invalidation_warning'] as String? ?? '',
      rawReasoning: json['raw_reasoning'] as String?,
    );
  }
}
