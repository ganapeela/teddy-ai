import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/market_snapshot.dart';

class TickerStrip extends StatelessWidget {
  final MarketSnapshot snapshot;

  const TickerStrip({Key? key, required this.snapshot}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isPositive = snapshot.priceChange >= 0;
    final color = isPositive ? AppColors.green : AppColors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Spot LTP + Change
          Row(
            children: [
              Text(
                '₹${snapshot.spotPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${isPositive ? '+' : ''}${snapshot.priceChangePct.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          // India VIX
          _buildMetricPill(
            label: 'VIX',
            value: snapshot.optionAnalytics.indiaVix.toStringAsFixed(1),
            valueColor: AppColors.amber,
          ),

          // PCR
          _buildMetricPill(
            label: 'PCR',
            value: '${snapshot.optionAnalytics.pcr.toStringAsFixed(2)} (${snapshot.optionAnalytics.pcrTrend[0]})',
            valueColor: snapshot.optionAnalytics.pcr >= 1.0 ? AppColors.green : AppColors.red,
          ),

          // Session Phase
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule,
                  size: 11,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  _abbreviatePhase(snapshot.trapContext.sessionPhase),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  String _abbreviatePhase(String phase) {
    if (phase.contains('Opening')) return 'Opening';
    if (phase.contains('Morning')) return 'Morn Trend';
    if (phase.contains('Midday')) return 'Midday Chop';
    if (phase.contains('Closing')) return 'Closing Move';
    return 'Replay';
  }
}
