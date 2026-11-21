import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/market_provider.dart';
import '../../core/providers/teddy_signal_provider.dart';
import '../widgets/interactive_candle_chart.dart';

class ChartScreen extends ConsumerWidget {
  const ChartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final market = ref.watch(marketProvider);
    final signalState = ref.watch(teddySignalProvider);
    final signal = signalState.latestSignal;
    final trap = market.snapshot.trapContext;

    return Column(
      children: [
        // Offline / Trap Banner
        if (market.isOfflineDemo)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            color: AppColors.amber.withOpacity(0.15),
            child: Row(
              children: [
                const Icon(Icons.wifi_off_rounded, size: 14, color: AppColors.amber),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Offline Simulation Mode (Backend disconnected). Tap Settings to connect.',
                    style: TextStyle(color: AppColors.amber, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          )
        else if (trap.bullTrapAlert || trap.bearTrapAlert)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            color: AppColors.red.withOpacity(0.18),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 15, color: AppColors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trap.bullTrapAlert
                        ? '⚠️ BULL TRAP ALERT: Spot at highs but Call writers adding heavy OI!'
                        : '⚠️ BEAR TRAP ALERT: Spot at lows but Put writers absorbing pressure!',
                    style: const TextStyle(color: AppColors.red, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

        // Indicator Legend Strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          color: AppColors.surface,
          child: Row(
            children: [
              _buildLegendDot(AppColors.vwapColor, 'VWAP'),
              const SizedBox(width: 12),
              _buildLegendDot(AppColors.ema9Color, '9 EMA'),
              const SizedBox(width: 12),
              _buildLegendDot(AppColors.ema20Color, '20 EMA'),
              const SizedBox(width: 12),
              _buildLegendDot(AppColors.callWallColor, 'Call Wall'),
              const SizedBox(width: 12),
              _buildLegendDot(AppColors.putWallColor, 'Put Wall'),
            ],
          ),
        ),

        // Interactive Candlestick Chart
        Expanded(
          child: Container(
            color: AppColors.background,
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: InteractiveCandleChart(
              candles: market.snapshot.recentCandles,
              snapshot: market.snapshot,
              signal: signal,
            ),
          ),
        ),

        // Sticky Bottom Summary Card
        _buildBottomVerdictCard(context, ref, signal, signalState.isAnalyzing),
      ],
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildBottomVerdictCard(
    BuildContext context,
    WidgetRef ref,
    dynamic signal,
    bool isAnalyzing,
  ) {
    final decision = signal?.decision ?? 'WAIT';
    final isBuyCe = decision == 'BUY_CE';
    final isBuyPe = decision == 'BUY_PE';

    final verdictColor = isBuyCe
        ? AppColors.green
        : (isBuyPe ? AppColors.red : AppColors.textSecondary);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Verdict Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: verdictColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: verdictColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    decision.replaceAll('_', ' '),
                    style: TextStyle(
                      color: verdictColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Recommended Strike or Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        signal?.recommendedStrike ?? (isBuyCe || isBuyPe ? 'Strike calculating...' : 'Disciplined Patience'),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        signal?.setupType ?? 'Awaiting institutional confluence',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // "Analyze Now" Action Button
                ElevatedButton(
                  onPressed: isAnalyzing
                      ? null
                      : () => ref.read(teddySignalProvider.notifier).analyzeNow(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: isAnalyzing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt_rounded, size: 16),
                            SizedBox(width: 4),
                            Text('Analyze Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                ),
              ],
            ),

            if (signal != null && signal.decision != 'NO_TRADE') ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Entry: ₹${signal.optionEntryZone?[0] ?? '-'} - ₹${signal.optionEntryZone?[1] ?? '-'}',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'SL: ₹${signal.stopLossOption ?? '-'}',
                      style: const TextStyle(color: AppColors.red, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'T1: ₹${signal.targetsOption?[0] ?? '-'}',
                      style: const TextStyle(color: AppColors.green, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'R:R ${signal.riskReward}',
                      style: const TextStyle(color: AppColors.cyan, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
