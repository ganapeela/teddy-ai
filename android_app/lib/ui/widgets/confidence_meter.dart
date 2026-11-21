import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ConfidenceMeter extends StatelessWidget {
  final int score;
  final double size;

  const ConfidenceMeter({
    Key? key,
    required this.score,
    this.size = 72,
  }) : super(key: key);

  Color get _color {
    if (score >= 75) return AppColors.green;
    if (score >= 55) return AppColors.cyan;
    if (score >= 40) return AppColors.amber;
    return AppColors.red;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background track
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: 6,
            color: AppColors.surfaceLight,
          ),
          // Progress track
          CircularProgressIndicator(
            value: (score / 100.0).clamp(0.0, 1.0),
            strokeWidth: 6,
            strokeCap: StrokeCap.round,
            color: _color,
          ),
          // Score text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score%',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: size * 0.24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'CONF',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: size * 0.12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
