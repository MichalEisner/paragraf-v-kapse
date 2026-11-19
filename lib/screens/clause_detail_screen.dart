import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/law_explanation_model.dart';
import '../services/law_data_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/app_logo_action.dart';
import '../widgets/statute_badge.dart';

class ClauseDetailScreen extends StatelessWidget {
  final LawExplanation explanation;

  const ClauseDetailScreen({super.key, required this.explanation});

  static Route route(LawExplanation explanation) {
    return MaterialPageRoute(
      builder: (_) => ClauseDetailScreen(explanation: explanation),
    );
  }

  static Route routeById(String id) {
    final exp = LawDataService.getById(id) ?? LawDataService.explanations.first;
    return MaterialPageRoute(
      builder: (_) => ClauseDetailScreen(explanation: exp),
    );
  }

  Future<void> _openVideo(BuildContext context) async {
    final uri = Uri.parse(explanation.youtubeUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nelze otevřít odkaz na video.')),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nelze otevřít odkaz na video.')),
        );
      }
    }
  }

  void _copySafeClause(BuildContext context) {
    if (explanation.safeClauseSuggestion.isEmpty) return;
    Clipboard.setData(ClipboardData(text: explanation.safeClauseSuggestion));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.inverseSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.secondaryFixed),
            const SizedBox(width: 8),
            Text(
              'Bezpečná formulace zkopírována do schránky',
              style: AppTypography.bodySm(color: AppColors.inverseOnSurface),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PARAGRAF V KAPSE',
              style: AppTypography.labelBadge(color: AppColors.outline),
            ),
            Text(
              'Detail Ustanovení',
              style: AppTypography.headlineSm(color: AppColors.onSurface),
            ),
          ],
        ),
        actions: const [
          AppLogoAction(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badges row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'ANALÝZA RIZIKA',
                    style: AppTypography.labelBadge(color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.offline_pin,
                      size: 14,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Offline dostupné',
                      style: AppTypography.labelLaw(color: AppColors.secondary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Title & Statute
            Text(
              explanation.title,
              style: AppTypography.headlineLg(color: AppColors.onSurface),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.gavel, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    explanation.statuteRef,
                    style: AppTypography.labelLaw(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Video Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.inverseSurface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 160,
                    width: double.infinity,
                    color: const Color(0xFF1E293B),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            Icons.play_circle_fill,
                            size: 64,
                            color: AppColors.tertiaryFixed.withValues(alpha: 0.9),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.tertiaryContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.smart_display,
                                  size: 14,
                                  color: AppColors.onTertiary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'YouTube výklad',
                                  style: AppTypography.labelBadge(
                                    color: AppColors.onTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.timer,
                                  size: 12,
                                  color: AppColors.tertiaryFixedDim,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  explanation.videoDuration,
                                  style: AppTypography.labelBadge(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          explanation.videoTitle,
                          style: AppTypography.headlineSm(
                            color: AppColors.surface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _openVideo(context),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Sledovat na kanálu Paragraf v kapse',
                                style: AppTypography.bodySm(
                                  color: AppColors.primaryFixedDim,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.open_in_new,
                                size: 14,
                                color: AppColors.primaryFixedDim,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Practical explanation
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.psychology_alt,
                          size: 22,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Co to v praxi znamená pro vás?',
                          style: AppTypography.headlineSm(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      explanation.practicalMeaning,
                      style: AppTypography.bodyMd(color: AppColors.onSurface),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lightbulb,
                            size: 18,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Častý trik zaměstnavatelů',
                                  style: AppTypography.labelButton(
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  explanation.employerTrick,
                                  style: AppTypography.bodySm(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Full statute text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '§',
                              style: AppTypography.labelLaw(
                                color: AppColors.onPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ZÁKON Č. 262/2006 SB.',
                            style: AppTypography.labelLaw(
                              color: AppColors.primary,
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const StatuteBadge(text: 'Plné znění'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.only(left: 10),
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    child: Text(
                      '„${explanation.fullStatuteText}“',
                      style: AppTypography.bodyMd(
                        color: AppColors.onSurface,
                      ).copyWith(fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Safe clause suggestion
            if (explanation.safeClauseSuggestion.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: AppColors.secondary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Doporučená bezpečná formulace',
                            style: AppTypography.headlineSm(
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        explanation.safeClauseSuggestion,
                        style: AppTypography.bodySm(color: AppColors.onSurface),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => _copySafeClause(context),
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Zkopírovat bezpečnou formulaci'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Back button & disclaimer
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Zpět'),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info, size: 14, color: AppColors.secondary),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Aplikace má informativní charakter a nenahrazuje právní radu.',
                    style: AppTypography.bodySm(
                      color: AppColors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
