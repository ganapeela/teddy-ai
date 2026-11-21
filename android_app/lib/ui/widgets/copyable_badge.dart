import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';

class CopyableBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final String? subtitle;
  final IconData? icon;

  const CopyableBadge({
    Key? key,
    required this.label,
    required this.value,
    this.valueColor,
    this.subtitle,
    this.icon,
  }) : super(key: key);

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied $label: $value to clipboard'),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _copyToClipboard(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        label,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      color: valueColor ?? AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.copy_rounded,
              size: 15,
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }
}
