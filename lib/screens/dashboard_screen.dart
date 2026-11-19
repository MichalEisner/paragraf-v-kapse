import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/contract_model.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/date_formatter.dart';
import '../widgets/app_logo_action.dart';
import '../widgets/hours_progress_bar.dart';
import 'contract_detail_screen.dart';
import 'contract_questionnaire_screen.dart';

class DashboardScreen extends StatefulWidget {
  final AppState appState;
  final VoidCallback onNavigateToCalculator;
  final VoidCallback onNavigateToExplanations;

  const DashboardScreen({
    super.key,
    required this.appState,
    required this.onNavigateToCalculator,
    required this.onNavigateToExplanations,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final Set<String> _expandedPreviews = {};
  bool _showArchived = false;

  void _togglePreview(String id) {
    setState(() {
      if (_expandedPreviews.contains(id)) {
        _expandedPreviews.remove(id);
      } else {
        _expandedPreviews.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final activeContracts = widget.appState.contracts;
        final archivedContracts = widget.appState.archivedContracts;
        final contracts = _showArchived ? archivedContracts : activeContracts;

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
                  child: const Icon(
                    Icons.balance,
                    size: 22,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paragraf v kapse',
                      style: AppTypography.headlineSm(color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
            actions: const [
              AppLogoAction(),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(context).push(
                ContractQuestionnaireScreen.route(widget.appState),
              );
            },
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: Text(
              'Přidat smlouvu',
              style: AppTypography.labelButton(color: Colors.white),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await widget.appState.init();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome & Privacy Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.secondaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.lock,
                            size: 20,
                            color: AppColors.onSecondaryContainer,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Vítej zpět!',
                                    style: AppTypography.headlineSm(
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '100% Offline',
                                      style: AppTypography.labelBadge(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Vaše data jsou uložena výhradně v tomto telefonu. Žádné cloudové servery, žádná registrace.',
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
                  const SizedBox(height: 14),

                  // Primary Fast Launchers Grid
                  Row(
                    children: [
                      // Action 1: Kontrola smlouvy
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              ContractQuestionnaireScreen.route(widget.appState),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 120,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryContainer.withValues(
                                    alpha: 0.2,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.fact_check,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward,
                                      size: 18,
                                      color: AppColors.onPrimaryContainer,
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Kontrola smlouvy',
                                      style: AppTypography.labelButton(
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Zmapovat obsah',
                                      style: AppTypography.bodySm(
                                        color: AppColors.onPrimaryContainer,
                                      ).copyWith(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Action 2: Kalkulačka mezd
                      Expanded(
                        child: InkWell(
                          onTap: widget.onNavigateToCalculator,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 120,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.hairlineBorder,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceContainerHigh,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.calculate,
                                        size: 20,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceContainerHigh,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        '2026',
                                        style: AppTypography.labelBadge(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Mzdová kalkulačka',
                                      style: AppTypography.labelButton(
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                    Text(
                                      'Čistá mzda a odvody',
                                      style: AppTypography.bodySm(
                                        color: AppColors.onSurfaceVariant,
                                      ).copyWith(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Legislative Alert Chip Banner
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryFixed,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified,
                            size: 18,
                            color: AppColors.onPrimaryFixed,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'ZÁKONÍK PRÁCE 2026',
                                    style: AppTypography.labelLaw(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppColors.secondary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Nové limity pro odvody u DPP aktivní. Databáze offline aktuální.',
                                style: AppTypography.bodySm(
                                  color: AppColors.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Active Contracts Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            _showArchived
                                ? 'Archivované smlouvy'
                                : 'Aktivní smlouvy',
                            style: AppTypography.headlineLg(
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${contracts.length}',
                              style: AppTypography.labelBadge(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() => _showArchived = !_showArchived);
                        },
                        icon: Icon(
                          _showArchived ? Icons.folder_open : Icons.archive,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        label: Text(
                          _showArchived ? 'Aktivní' : 'Archiv',
                          style: AppTypography.labelLaw(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Contracts List
                  if (contracts.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.hairlineBorder),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.description_outlined,
                            size: 40,
                            color: AppColors.outline,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _showArchived
                                ? 'V archivu se nenachází žádné smlouvy.'
                                : 'Zatím nemáte přidanou žádnou smlouvu.',
                            style: AppTypography.bodyMd(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          if (!_showArchived) ...[
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  ContractQuestionnaireScreen.route(
                                    widget.appState,
                                  ),
                                );
                              },
                              child: const Text('Zkontrolovat novou smlouvu'),
                            ),
                          ],
                        ],
                      ),
                    )
                  else
                    ...contracts.map((contract) {
                      return _buildContractCard(contract);
                    }),

                  const SizedBox(height: 16),

                  // Educational Nudge & Tip
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lightbulb,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Víte, na co máte nárok?',
                                style: AppTypography.headlineSm(
                                  color: AppColors.onSurface,
                                ).copyWith(fontSize: 15),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Od roku 2024 mají dohodáři (DPP/DPČ) zákonný nárok na placenou dovolenou i překážky v práci dle § 77 ZP.',
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
        );
      },
    );
  }

  Widget _buildContractCard(Contract contract) {
    final isExpanded = _expandedPreviews.contains(contract.id);
    final totalHours = widget.appState.getTotalHoursForContract(contract.id);
    final currencyFmt = NumberFormat.currency(
      locale: 'cs_CZ',
      symbol: 'Kč',
      decimalDigits: 0,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairlineBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Warning Banner for HPP probation or similar alerts
          if (contract.contractType == ContractType.hpp &&
              contract.daysRemainingInProbation != null &&
              contract.daysRemainingInProbation! > 0)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, size: 18, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hlídejte si konec zkušební doby!',
                          style: AppTypography.labelLaw(
                            color: AppColors.onErrorContainer,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Zkušební doba končí za ${contract.daysRemainingInProbation} dní. Do té doby lze poměr zrušit okamžitě.',
                          style: AppTypography.bodySm(
                            color: AppColors.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: contract.contractType == ContractType.dpp
                                ? AppColors.surfaceContainer
                                : AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            contract.contractType == ContractType.dpp
                                ? Icons.terminal
                                : Icons.code,
                            size: 24,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contract.jobTitle,
                              style: AppTypography.headlineSm(
                                color: AppColors.onSurface,
                              ),
                            ),
                            Text(
                              contract.companyName,
                              style: AppTypography.bodySm(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: contract.contractType == ContractType.dpp
                            ? AppColors.secondaryContainer
                            : AppColors.primaryFixed,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        contract.contractType.label,
                        style: AppTypography.labelBadge(
                          color: contract.contractType == ContractType.dpp
                              ? AppColors.onSecondaryContainer
                              : AppColors.onPrimaryFixed,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Metrics grid
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contract.contractType == ContractType.hpp
                                  ? 'Základní hrubá mzda'
                                  : 'Sazba',
                              style: AppTypography.bodySm(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                contract.contractType == ContractType.hpp
                                    ? currencyFmt.format(contract.monthlyGrossWage)
                                    : '${contract.hourlyWage.toInt()} Kč/hod',
                                style: AppTypography.headlineSm(
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contract.contractType == ContractType.hpp
                                  ? 'Dovolená ročně'
                                  : 'Konec dohody',
                              style: AppTypography.bodySm(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  contract.contractType == ContractType.hpp
                                      ? Icons.beach_access
                                      : Icons.schedule,
                                  size: 16,
                                  color: contract.contractType == ContractType.hpp
                                      ? AppColors.primary
                                      : AppColors.secondary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      contract.contractType == ContractType.hpp
                                          ? '25 dní (5 týdnů)'
                                          : (contract.daysUntilEnd != null
                                              ? '${contract.daysUntilEnd} dní'
                                              : 'Neurčitá'),
                                      style: AppTypography.headlineSm(
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Hours tracker for DPP
                if (contract.contractType == ContractType.dpp) ...[
                  const SizedBox(height: 10),
                  HoursProgressBar(currentHours: totalHours, maxHours: 300),
                ],

                const SizedBox(height: 10),
                const Divider(),

                // Safe check footer row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.verified,
                          size: 16,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Kompletně zmapováno (${contract.evaluationScore} %)',
                          style: AppTypography.labelBadge(
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => _togglePreview(contract.id),
                      child: Row(
                        children: [
                          Text(
                            isExpanded ? 'Zavřít náhled' : 'Náhled smlouvy',
                            style: AppTypography.labelLaw(
                              color: AppColors.primary,
                            ),
                          ),
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Expandable preview drawer
                if (isExpanded) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.1),
                      ),
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
                                  Icons.description,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Parametry ze smlouvy',
                                  style: AppTypography.labelBadge(
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Ověřeno',
                                style: AppTypography.labelLaw(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildParamRow('Druh práce:', contract.jobTitle),
                        _buildParamRow(
                          'Místo výkonu:',
                          contract.workLocation.isNotEmpty
                              ? contract.workLocation
                              : 'Neuvedeno',
                        ),
                        _buildParamRow(
                          'Den nástupu:',
                          CzechDateFormatter.formatShort(contract.startDate),
                        ),
                        _buildParamRow(
                          'Zkušební doba:',
                          '${contract.probationPeriodMonths} měsíce',
                        ),
                        _buildParamRow('Úvazek / rozsah:', contract.contractType.description),
                        if (contract.notes.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHighest
                                  .withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.edit_note,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    contract.notes,
                                    style: AppTypography.bodySm(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    ContractDetailScreen.route(
                                      contract,
                                      widget.appState,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.event_note, size: 16),
                                label: const Text('Detail & Docházka'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  ContractQuestionnaireScreen.route(
                                    widget.appState,
                                    existingContract: contract,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Upravit'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParamRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: AppTypography.bodySm(color: AppColors.onSurface)
                  .copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
