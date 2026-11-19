import 'package:flutter/material.dart';
import '../services/law_data_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/app_logo_action.dart';
import '../widgets/statute_badge.dart';
import 'clause_detail_screen.dart';

class ExplanationsScreen extends StatefulWidget {
  const ExplanationsScreen({super.key});

  @override
  State<ExplanationsScreen> createState() => _ExplanationsScreenState();
}

class _ExplanationsScreenState extends State<ExplanationsScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'Vše';

  final List<String> _categories = [
    'Vše',
    'Povinné náležitosti',
    'Doplňková ujednání',
    'Dohody',
  ];

  @override
  Widget build(BuildContext context) {
    final allExplanations = LawDataService.explanations;
    final filtered = allExplanations.where((e) {
      final matchesQuery = e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.statuteRef.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.practicalMeaning.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'Vše' || e.category == _selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.menu_book, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paragraf v kapse',
                  style: AppTypography.headlineSm(color: AppColors.primary),
                ),
                Text(
                  'Právní vysvětlivky & Videa',
                  style: AppTypography.labelBadge(color: AppColors.onSurfaceVariant),
                ),
              ],
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
            // Search input
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Hledat v zákoníku práce...',
                prefixIcon: const Icon(Icons.search, color: AppColors.outline),
                fillColor: AppColors.surfaceContainerLowest,
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),

            // Category filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                      selectedColor: AppColors.primaryContainer,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Educational intro
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.smart_display, size: 24, color: AppColors.tertiaryContainer),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edukační kanál Paragraf v kapse',
                          style: AppTypography.labelButton(color: AppColors.primary),
                        ),
                        Text(
                          'Krátká úderná videa a textové vysvětlivky bez právnického žargonu.',
                          style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Explanations cards list
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Žádná vysvětlivka neodpovídá zadání.',
                    style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                  ),
                ),
              )
            else
              ...filtered.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          ClauseDetailScreen.route(item),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    StatuteBadge(text: item.shortStatute),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceContainerHigh,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        item.category,
                                        style: AppTypography.labelBadge(color: AppColors.onSurfaceVariant),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.timer, size: 14, color: AppColors.tertiaryContainer),
                                    const SizedBox(width: 4),
                                    Text(
                                      item.videoDuration,
                                      style: AppTypography.labelBadge(color: AppColors.tertiaryContainer),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.title,
                              style: AppTypography.headlineSm(color: AppColors.onSurface),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.practicalMeaning,
                              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.play_circle_fill, size: 16, color: AppColors.tertiaryContainer),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Video výklad k dispozici',
                                      style: AppTypography.labelBadge(color: AppColors.tertiaryContainer),
                                    ),
                                  ],
                                ),
                                const Icon(Icons.chevron_right, size: 18, color: AppColors.primary),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
