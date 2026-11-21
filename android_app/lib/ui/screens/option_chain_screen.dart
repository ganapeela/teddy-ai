import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/option_chain.dart';
import '../../core/providers/market_provider.dart';

class OptionChainScreen extends ConsumerWidget {
  const OptionChainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final market = ref.watch(marketProvider);
    final chain = market.snapshot.optionChain;
    final atmStrike = market.snapshot.optionAnalytics.atmStrike;

    if (chain.isEmpty) {
      return const Center(
        child: Text(
          'Loading Option Chain...',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    // Calculate maximum OI to normalize visual bars
    int maxOi = 1;
    for (final s in chain) {
      if (s.ceOi > maxOi) maxOi = s.ceOi;
      if (s.peOi > maxOi) maxOi = s.peOi;
    }

    return Column(
      children: [
        // Summary Header Strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: AppColors.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CALLS (RESISTANCE)',
                style: const TextStyle(
                  color: AppColors.red,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  'ATM: ${atmStrike.toInt()}',
                  style: const TextStyle(
                    color: AppColors.cyan,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'PUTS (SUPPORT)',
                style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),

        // Table Column Headers
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          color: AppColors.surfaceElevated,
          child: const Row(
            children: [
              Expanded(flex: 3, child: Text('OI / Chg', style: TextStyle(color: AppColors.textSecondary, fontSize: 10))),
              Expanded(flex: 2, child: Text('LTP (IV)', style: TextStyle(color: AppColors.textSecondary, fontSize: 10))),
              Expanded(flex: 2, child: Center(child: Text('STRIKE', style: TextStyle(color: AppColors.textPrimary, fontSize: 10, fontWeight: FontWeight.bold)))),
              Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text('LTP (IV)', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)))),
              Expanded(flex: 3, child: Align(alignment: Alignment.centerRight, child: Text('OI / Chg', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)))),
            ],
          ),
        ),

        // Strikes List
        Expanded(
          child: ListView.separated(
            itemCount: chain.length,
            separatorBuilder: (_, __) => Divider(color: AppColors.border.withOpacity(0.4), height: 1),
            itemBuilder: (context, index) {
              final strike = chain[index];
              final isAtm = (strike.strike - atmStrike).abs() < 1.0;
              return _buildStrikeRow(strike, isAtm, maxOi);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStrikeRow(OptionChainStrike s, bool isAtm, int maxOi) {
    final ceBarWidth = (s.ceOi / maxOi).clamp(0.05, 1.0);
    final peBarWidth = (s.peOi / maxOi).clamp(0.05, 1.0);

    return Container(
      color: isAtm ? AppColors.cyan.withOpacity(0.08) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          // CALL SIDE: OI & Change
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      '${(s.ceOi / 1000).toStringAsFixed(0)}k',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${s.ceChangeOi >= 0 ? '+' : ''}${(s.ceChangeOi / 1000).toStringAsFixed(0)}k',
                      style: TextStyle(
                        color: s.ceChangeOi >= 0 ? AppColors.green : AppColors.red,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                // Horizontal OI Bar
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: ceBarWidth,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.red.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // CALL SIDE: LTP & IV
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '₹${s.ceLtp.toStringAsFixed(1)}',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${s.ceIv.toStringAsFixed(1)}% | Δ${s.ceDelta.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
                ),
              ],
            ),
          ),

          // STRIKE CENTER
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isAtm ? AppColors.cyan : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  s.strike.toInt().toString(),
                  style: TextStyle(
                    color: isAtm ? Colors.black : AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // PUT SIDE: LTP & IV
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '₹${s.peLtp.toStringAsFixed(1)}',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Δ${s.peDelta.toStringAsFixed(2)} | ${s.peIv.toStringAsFixed(1)}%',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
                ),
              ],
            ),
          ),

          // PUT SIDE: OI & Change
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${s.peChangeOi >= 0 ? '+' : ''}${(s.peChangeOi / 1000).toStringAsFixed(0)}k',
                      style: TextStyle(
                        color: s.peChangeOi >= 0 ? AppColors.green : AppColors.red,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${(s.peOi / 1000).toStringAsFixed(0)}k',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                // Horizontal OI Bar
                FractionallySizedBox(
                  alignment: Alignment.centerRight,
                  widthFactor: peBarWidth,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
