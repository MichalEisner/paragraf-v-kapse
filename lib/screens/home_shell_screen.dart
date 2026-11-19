import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'calculator_screen.dart';
import 'dashboard_screen.dart';
import 'explanations_screen.dart';

class HomeShellScreen extends StatefulWidget {
  final AppState appState;

  const HomeShellScreen({super.key, required this.appState});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final currentTab = widget.appState.selectedTabIndex;

        final screens = [
          DashboardScreen(
            appState: widget.appState,
            onNavigateToCalculator: () => widget.appState.setTabIndex(2),
            onNavigateToExplanations: () => widget.appState.setTabIndex(1),
          ),
          const ExplanationsScreen(),
          CalculatorScreen(appState: widget.appState),
        ];

        return Scaffold(
          body: IndexedStack(
            index: currentTab,
            children: screens,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.95),
              border: const Border(
                top: BorderSide(color: AppColors.hairlineBorder, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 64,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      index: 0,
                      icon: Icons.folder_shared,
                      label: 'Smlouvy',
                      isSelected: currentTab == 0,
                    ),
                    _buildNavItem(
                      index: 1,
                      icon: Icons.menu_book,
                      label: 'Vysvětlivky',
                      isSelected: currentTab == 1,
                    ),
                    _buildNavItem(
                      index: 2,
                      icon: Icons.calculate,
                      label: 'Kalkulačka',
                      isSelected: currentTab == 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => widget.appState.setTabIndex(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? AppColors.primaryContainer
                  : AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: isSelected
                  ? AppTypography.labelBadge(color: AppColors.primaryContainer)
                      .copyWith(fontWeight: FontWeight.bold)
                  : AppTypography.labelBadge(color: AppColors.onSurfaceVariant)
                      .copyWith(fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }
}
