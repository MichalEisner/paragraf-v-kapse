import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class ScoreRing extends StatelessWidget {
  final int score; // 0 to 100
  final double size;
  final double strokeWidth;

  const ScoreRing({
    super.key,
    required this.score,
    this.size = 64,
    this.strokeWidth = 5,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = (score.clamp(0, 100)) / 100.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: strokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.surfaceContainer,
            ),
          ),
          CircularProgressIndicator(
            value: progress,
            strokeWidth: strokeWidth,
            strokeCap: StrokeCap.round,
            valueColor: AlwaysStoppedAnimation<Color>(
              score >= 80
                  ? AppColors.secondary
                  : (score >= 50 ? AppColors.warning : AppColors.error),
            ),
          ),
          Text(
            '$score %',
            style: AppTypography.labelLaw(
              color: AppColors.onSurface,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
