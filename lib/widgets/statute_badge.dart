import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class StatuteBadge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final EdgeInsetsGeometry padding;

  const StatuteBadge({
    super.key,
    required this.text,
    this.backgroundColor = AppColors.surfaceContainerHigh,
    this.textColor = AppColors.primary,
    this.borderColor = AppColors.outlineVariant,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: borderColor.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        text,
        style: AppTypography.labelLaw(color: textColor),
      ),
    );
  }
}
