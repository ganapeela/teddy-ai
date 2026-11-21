import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/teddy_signal_provider.dart';
import '../widgets/confidence_meter.dart';
import '../widgets/copyable_badge.dart';

class TeddyDeskScreen extends ConsumerWidget {
  const TeddyDeskScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signalState = ref.watch(teddySignalProvider);
    final signal = signalState.latestSignal;

    if (signal == null) {
      return const Center(
        child: Text(
          'No trade analysis yet. Tap "Analyze Now" on Chart.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final isBuyCe = signal.decision == 'BUY_CE';
    final isBuyPe = signal.decision == 'BUY_PE';
    final isNoTrade = signal.decision == 'NO_TRADE';

    final verdictColor = isBuyCe
        ? AppColors.green
        : (isBuyPe ? AppColors.red : AppColors.amber);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Institutional Verdict Header Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.surfaceElevated,
                  AppColors.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: verdictColor.withOpacity(0.3), width: 1.5),
            ),
            child: Row(
              children: [
                // Confidence Ring
                ConfidenceMeter(score: signal.confidenceScore, size: 76),
                const SizedBox(width: 16),

                // Verdict Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: verdictColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              signal.decision.replaceAll('_', ' '),
                              style: TextStyle(
                                color: verdictColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              'R:R ${signal.riskReward}',
                              style: const TextStyle(
                                color: AppColors.cyan,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        signal.recommendedStrike ?? signal.instrument,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        signal.setupType,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Trade Execution Levels Grid (Only when BUY_CE or BUY_PE)
          if (!isNoTrade) ...[
            const Text(
              'INSTITUTIONAL EXECUTION LEVELS',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.1,
              children: [
                CopyableBadge(
                  label: 'Recommended Strike',
                  value: signal.recommendedStrike ?? '-',
                  valueColor: verdictColor,
                  icon: Icons.track_changes_rounded,
                ),
                CopyableBadge(
                  label: 'Spot Trigger',
                  value: signal.spotTrigger != null ? '₹${signal.spotTrigger!.toStringAsFixed(1)}' : '-',
                  valueColor: AppColors.cyan,
                  icon: Icons.radar_rounded,
                ),
                CopyableBadge(
                  label: 'Option Entry Zone',
                  value: signal.optionEntryZone != null
                      ? '₹${signal.optionEntryZone![0]} - ₹${signal.optionEntryZone![1]}'
                      : '-',
                  valueColor: AppColors.green,
                  icon: Icons.input_rounded,
                ),
                CopyableBadge(
                  label: 'Option Stop Loss',
                  value: signal.stopLossOption != null ? '₹${signal.stopLossOption}' : '-',
                  valueColor: AppColors.red,
                  icon: Icons.shield_rounded,
                ),
                CopyableBadge(
                  label: 'Spot SL (Invalidation)',
                  value: signal.stopLossSpot != null ? '₹${signal.stopLossSpot!.toStringAsFixed(1)}' : '-',
                  valueColor: AppColors.amber,
                  icon: Icons.location_off_rounded,
                ),
                CopyableBadge(
                  label: 'Targets T1 | T2 | T3',
                  value: signal.targetsOption != null
                      ? '₹${signal.targetsOption![0]} | ₹${signal.targetsOption!.length > 1 ? signal.targetsOption![1] : '-'} | ₹${signal.targetsOption!.length > 2 ? signal.targetsOption![2] : '-'}'
                      : '-',
                  valueColor: AppColors.green,
                  icon: Icons.flag_rounded,
                ),
              ],
            ),
            const SizedBox(height: 18),
          ],

          // Expandable Institutional Sections
          _buildInstitutionalSection(
            title: 'WHY THIS TRADE?',
            icon: Icons.psychology_rounded,
            iconColor: AppColors.cyan,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: signal.whyThisTrade.map((point) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: AppColors.cyan, fontSize: 16, height: 1.2)),
                      Expanded(
                        child: Text(
                          point,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 14),

          _buildInstitutionalSection(
            title: 'HOW TO MANAGE & EXECUTE',
            icon: Icons.military_tech_rounded,
            iconColor: AppColors.green,
            content: Text(
              signal.howToExecute,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Invalidation Warning (Prominent Alert Box)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.red.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.red.withOpacity(0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.gavel_rounded, color: AppColors.red, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'INVALIDATION WARNING (VETERAN RULE)',
                        style: TextStyle(
                          color: AppColors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        signal.invalidationWarning,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInstitutionalSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          content,
        ],
      ),
    );
  }
}
