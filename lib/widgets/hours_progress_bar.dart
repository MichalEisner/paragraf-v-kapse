import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class HoursProgressBar extends StatelessWidget {
  final double currentHours;
  final double maxHours;
  final String label;

  const HoursProgressBar({
    super.key,
    required this.currentHours,
    this.maxHours = 300.0,
    this.label = 'Zákonný limit DPP (§ 75 ZP)',
  });

  @override
  Widget build(BuildContext context) {
    final double percentage = ((currentHours / maxHours) * 100).clamp(0.0, 100.0);
    final double remaining = (maxHours - currentHours).clamp(0.0, maxHours);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.timelapse,
                    size: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: AppTypography.labelLaw(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Text(
                '${currentHours.toStringAsFixed(currentHours.truncateToDouble() == currentHours ? 0 : 1)} / ${maxHours.toInt()} hod',
                style: AppTypography.labelLaw(
                  color: AppColors.primary,
                ).copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percentage / 100.0,
              minHeight: 8,
              backgroundColor: AppColors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage > 90
                    ? AppColors.error
                    : (percentage > 75 ? AppColors.warning : AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Čerpáno ${percentage.toStringAsFixed(0)} %',
                style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
              ),
              Text(
                'Zbývá ${remaining.toStringAsFixed(remaining.truncateToDouble() == remaining ? 0 : 1)} hodin',
                style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
