import 'package:flutter/material.dart';
import '../models/contract_model.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/date_formatter.dart';
import '../widgets/app_logo_action.dart';
import '../widgets/score_ring.dart';
import '../widgets/statute_badge.dart';
import 'clause_detail_screen.dart';

class ContractQuestionnaireScreen extends StatefulWidget {
  final AppState appState;
  final Contract? existingContract;

  const ContractQuestionnaireScreen({
    super.key,
    required this.appState,
    this.existingContract,
  });

  static Route route(AppState appState, {Contract? existingContract}) {
    return MaterialPageRoute(
      builder: (_) => ContractQuestionnaireScreen(
        appState: appState,
        existingContract: existingContract,
      ),
    );
  }

  @override
  State<ContractQuestionnaireScreen> createState() =>
      _ContractQuestionnaireScreenState();
}

class _ContractQuestionnaireScreenState
    extends State<ContractQuestionnaireScreen> {
  late ContractType _selectedType;
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _wageController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _probationController = TextEditingController();
  final TextEditingController _clauseDetailsController = TextEditingController();
  final TextEditingController _scheduleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Selections
  int _roleStatus = 0; // 0: yes, 1: vague, 2: missing
  int _locationStatus = 0; // 0: yes, 1: missing, 2: too broad (warning)
  int _startDateStatus = 0; // 0: yes, 1: vague, 2: missing
  int _probationStatus = 0; // 0: normal, 1: longer, 2: none
  int _nonCompeteStatus = 2; // 0: valid, 1: warn (missing compensation), 2: none
  int _scheduleStatus = 0; // 0: verified, 1: vague, 2: unverified

  // Expanded help flags
  final Set<String> _expandedHelp = {};

  @override
  void initState() {
    super.initState();
    _selectedType = widget.existingContract?.contractType ?? ContractType.dpc;
    if (widget.existingContract != null) {
      final c = widget.existingContract!;
      _companyController.text = c.companyName;
      _roleController.text = c.jobTitle;
      _locationController.text = c.workLocation;
      _startDateController.text = CzechDateFormatter.formatShort(c.startDate);
      _probationController.text = c.probationPeriodMonths > 0
          ? '${c.probationPeriodMonths} měsíce'
          : '';
      _scheduleController.text = '${c.weeklyHours.toInt()} hod/týden';
      _wageController.text = c.contractType == ContractType.hpp
          ? (c.monthlyGrossWage > 0 ? c.monthlyGrossWage.toInt().toString() : '')
          : (c.hourlyWage > 0 ? c.hourlyWage.toInt().toString() : '');
      _notesController.text = c.notes;
      _nonCompeteStatus = c.hasNonCompete
          ? ((c.nonCompeteCompensationPercent ?? 0) >= 50 ? 0 : 1)
          : 2;
    }
  }

  @override
  void dispose() {
    _companyController.dispose();
    _roleController.dispose();
    _wageController.dispose();
    _locationController.dispose();
    _startDateController.dispose();
    _probationController.dispose();
    _clauseDetailsController.dispose();
    _scheduleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _toggleHelp(String id) {
    setState(() {
      if (_expandedHelp.contains(id)) {
        _expandedHelp.remove(id);
      } else {
        _expandedHelp.add(id);
      }
    });
  }

  int get _score {
    int score = 100;
    if (_roleStatus != 0) score -= 15;
    if (_locationStatus == 1) score -= 20;
    if (_locationStatus == 2) score -= 10;
    if (_startDateStatus != 0) score -= 15;
    if (_probationStatus == 1) score -= 10;
    if (_nonCompeteStatus == 1) score -= 15;
    if (_scheduleStatus != 0) score -= 10;
    return score.clamp(20, 100);
  }

  int get _verifiedCount {
    int count = 0;
    if (_roleStatus == 0) count++;
    if (_locationStatus == 0) count++;
    if (_startDateStatus == 0) count++;
    if (_probationStatus == 0) count++;
    if (_nonCompeteStatus != 1) count++;
    if (_scheduleStatus == 0) count++;
    return count + 2; // base checked items
  }

  int get _warningCount {
    int count = 0;
    if (_roleStatus == 1) count++;
    if (_locationStatus == 2) count++;
    if (_probationStatus == 1) count++;
    if (_nonCompeteStatus == 1) count++;
    if (_scheduleStatus == 1) count++;
    return count;
  }

  void _saveContract() {
    final contract = Contract(
      id: widget.existingContract?.id ??
          'contract_${DateTime.now().millisecondsSinceEpoch}',
      companyName: _companyController.text.trim().isEmpty
          ? 'Nový zaměstnavatel'
          : _companyController.text.trim(),
      jobTitle: _roleController.text.trim().isEmpty
          ? 'Pracovní pozice'
          : _roleController.text.trim(),
      contractType: _selectedType,
      hourlyWage: _selectedType == ContractType.hpp
          ? 0
          : (double.tryParse(_wageController.text.replaceAll(' ', '').replaceAll(',', '.')) ?? 0),
      monthlyGrossWage: _selectedType == ContractType.hpp
          ? (double.tryParse(_wageController.text.replaceAll(' ', '').replaceAll(',', '.')) ?? 0)
          : 0,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 180)),
      probationPeriodMonths: _probationStatus == 0 ? 3 : 0,
      workLocation: _locationController.text.trim(),
      weeklyHours: _selectedType == ContractType.dpc ? 20 : 40,
      hasNonCompete: _nonCompeteStatus == 0 || _nonCompeteStatus == 1,
      nonCompeteCompensationPercent: _nonCompeteStatus == 0 ? 50 : 0,
      notes: _notesController.text.trim(),
      evaluationScore: _score,
      verifiedItemsCount: _verifiedCount,
      totalItemsCount: 10,
    );

    if (widget.existingContract != null) {
      widget.appState.updateContract(contract);
    } else {
      widget.appState.addContract(contract);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.inverseSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            const Icon(Icons.verified, color: AppColors.secondaryFixed),
            const SizedBox(width: 8),
            Text(
              'Smlouva byla uložena do přehledu se skóre $_score %.',
              style: AppTypography.bodySm(color: AppColors.inverseOnSurface),
            ),
          ],
        ),
      ),
    );

    Navigator.of(context).pop();
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
              'Kontrola smlouvy',
              style: AppTypography.headlineSm(color: AppColors.primary),
            ),
            Text(
              'Paragraf v kapse',
              style: AppTypography.labelBadge(color: AppColors.onSurfaceVariant),
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
            // Welcome banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.security,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'PRŮVODCE SMLOUVOU',
                              style: AppTypography.labelBadge(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Pojďme smlouvu projít řádek po řádku!',
                          style: AppTypography.headlineSm(
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pomůžeme ti porozumět složitému textu dříve, než ho podepíšeš.',
                          style: AppTypography.bodySm(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.rule,
                      size: 28,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Company Name input
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ZAMĚSTNAVATEL',
                      style: AppTypography.labelLaw(color: AppColors.outline),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _companyController,
                      style: AppTypography.bodyMd(color: AppColors.onSurface),
                      decoration: const InputDecoration(
                        hintText: 'Název společnosti / firmy',
                        prefixIcon: Icon(
                          Icons.business,
                          size: 18,
                          color: AppColors.outline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Contract Type Switcher
            Text(
              'TYP PRACOVNÍHO VZTAHU',
              style: AppTypography.labelLaw(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: ContractType.values.map((type) {
                  final isSelected = _selectedType == type;
                  return Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedType = type),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryContainer
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              type.label,
                              style: AppTypography.labelButton(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.onSurface,
                              ),
                            ),
                            Text(
                              type.subtitle,
                              style: AppTypography.bodySm(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : AppColors.onSurfaceVariant,
                              ).copyWith(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Sjednaná mzda / sazba Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedType == ContractType.hpp
                          ? 'HRUBÁ MĚSÍČNÍ MZDA'
                          : 'HODINOVÁ ODMĚNA (SAZBA)',
                      style: AppTypography.labelLaw(color: AppColors.outline),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _wageController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: AppTypography.bodyMd(color: AppColors.onSurface),
                      decoration: InputDecoration(
                        hintText: _selectedType == ContractType.hpp
                            ? 'např. 45000'
                            : 'např. 250',
                        suffixText: _selectedType == ContractType.hpp ? 'Kč / měs' : 'Kč / hod',
                        prefixIcon: const Icon(
                          Icons.payments,
                          size: 18,
                          color: AppColors.outline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Bento Score Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'STAV OVĚŘENÍ',
                              style: AppTypography.labelBadge(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '$_verifiedCount',
                                  style: AppTypography.displayMd(
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '/ 10 položek ověřeno',
                                  style: AppTypography.bodyMd(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        ScoreRing(score: _score),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: _verifiedCount / 10.0,
                        minHeight: 6,
                        backgroundColor: AppColors.surfaceContainer,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified,
                            size: 18,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$_score % smlouvy zkontrolováno',
                                  style: AppTypography.labelButton(
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  _warningCount > 0
                                      ? '$_warningCount výstraha vyžaduje vyjasnění se zaměstnavatelem.'
                                      : 'Všechny klíčové náležitosti jsou v pořádku.',
                                  style: AppTypography.bodySm(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_warningCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.errorContainer,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$_warningCount varování',
                                style: AppTypography.labelBadge(
                                  color: AppColors.onErrorContainer,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // SECTION 1: Mandatory Legal Requirements (§ 34 ZP)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Povinné náležitosti',
                          style: AppTypography.headlineSm(
                            color: AppColors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const StatuteBadge(text: '§ 34 ZP'),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Bez těchto tří základních bodů je smlouva od samého počátku právně neplatná.',
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),

            // Item 1: Druh práce
            _buildCheckCard(
              title: '1. Druh práce',
              statute: '§ 34 odst. 1 písm. a)',
              question:
                  'Je ve smlouvě srozumitelně uvedeno, jakou pozici budete vykonávat?',
              helpId: 'help_role',
              helpText:
                  'Druh práce by neměl být formulován příliš široce (např. „pomocné práce všeho druhu“), aby vás zaměstnavatel nemohl libovolně převádět na neodpovídající činnosti bez vašeho souhlasu.',
              explanationId: 'druh_prace',
              options: [
                'Ano, přesný název a náplň',
                'Pouze obecně formulováno',
                'Chybí úplně',
              ],
              selectedOption: _roleStatus,
              onOptionSelected: (idx) => setState(() => _roleStatus = idx),
              inputLabel: 'Upřesnění / název pozice:',
              inputController: _roleController,
            ),
            const SizedBox(height: 12),

            // Item 2: Místo výkonu práce
            _buildCheckCard(
              title: '2. Místo výkonu práce',
              statute: '§ 34 odst. 1 písm. b)',
              question:
                  'Našli jste ve smlouvě konkrétně napsané, kde budete pracovat?',
              helpId: 'help_location',
              helpText:
                  'Místo může být jedna adresa, město nebo konkrétní závod. Pokud je místo širší než jedna obec (např. celá ČR), zaměstnavatel vás může posílat kamkoliv bez cestovních náhrad.',
              explanationId: 'misto_vykonu',
              options: [
                'Ano, je tam konkrétní adresa',
                'Ne, chybí to úplně',
                'Je to vymezeno příliš široce (např. celá ČR)',
              ],
              selectedOption: _locationStatus,
              onOptionSelected: (idx) => setState(() => _locationStatus = idx),
              inputLabel: 'Zapište si sjednané místo výkonu práce:',
              inputController: _locationController,
            ),
            const SizedBox(height: 12),

            // Item 3: Den nástupu do práce
            _buildCheckCard(
              title: '3. Den nástupu do práce',
              statute: '§ 34 odst. 1 písm. c)',
              question: 'Máte sjednaný přesný datum zahájení?',
              helpId: 'help_start',
              helpText:
                  'Tímto dnem oficiálně vzniká pracovní poměr a práva i povinnosti z něj plynoucí, i kdyby připadl na víkend či svátek.',
              explanationId: 'den_nastupu',
              options: [
                'Ano, přesné datum',
                'Nejasné či podmíněné datum',
                'Chybí',
              ],
              selectedOption: _startDateStatus,
              onOptionSelected: (idx) => setState(() => _startDateStatus = idx),
              inputLabel: 'Sjednané datum nástupu:',
              inputController: _startDateController,
            ),
            const SizedBox(height: 20),

            // SECTION 2: Supplementary Clauses
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Doplňková ujednání a doložky',
                          style: AppTypography.headlineSm(
                            color: AppColors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const StatuteBadge(
                  text: '§ 35, § 310 ZP',
                  backgroundColor: AppColors.secondaryContainer,
                  textColor: AppColors.onSecondaryContainer,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Zde bývají nejčastější sporná ujednání, sankce a skryté povinnosti.',
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),

            // Item 4: Zkušební doba
            _buildCheckCard(
              title: '4. Zkušební doba',
              statute: '§ 35 ZP',
              question: 'Obsahuje smlouva zkušební dobu a na jak dlouho?',
              helpId: 'help_probation',
              helpText:
                  'Zkušební doba musí být sjednána písemně nejpozději v den nástupu do práce. Dodatečně ji nelze prodlužovat ani sjednat!',
              explanationId: 'zkusebni_doba',
              options: [
                'V normě (max 3 měsíce)',
                'Delší než 3 měsíce (resp. 6 u vedoucích)',
                'Bez zkušební doby',
              ],
              selectedOption: _probationStatus,
              onOptionSelected: (idx) => setState(() => _probationStatus = idx),
              inputLabel: 'Délka zkušební doby:',
              inputController: _probationController,
            ),
            const SizedBox(height: 12),

            // Item 5: Konkurenční doložka (Critical Red Flag alert)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Text(
                                '5. Konkurenční doložka',
                                style: AppTypography.bodyLg(
                                  color: AppColors.onSurface,
                                ).copyWith(fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.errorContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Kritické',
                                  style: AppTypography.labelLaw(
                                    color: AppColors.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.help_outline,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          onPressed: () => _toggleHelp('help_noncompete'),
                        ),
                      ],
                    ),
                    Text(
                      'Omezení po skončení práce vs. povinné odškodnění min. 50 % (§ 310 ZP)',
                      style: AppTypography.bodySm(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // State Buttons
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        ChoiceChip(
                          label: const Text('V souladu'),
                          selected: _nonCompeteStatus == 0,
                          onSelected: (_) => setState(() => _nonCompeteStatus = 0),
                          selectedColor: AppColors.secondaryContainer,
                          labelStyle: TextStyle(
                            color: _nonCompeteStatus == 0
                                ? AppColors.onSecondaryContainer
                                : AppColors.onSurface,
                            fontSize: 12,
                          ),
                        ),
                        ChoiceChip(
                          label: const Text('Chybí peněžité vyrovnání!'),
                          selected: _nonCompeteStatus == 1,
                          onSelected: (_) => setState(() => _nonCompeteStatus = 1),
                          selectedColor: AppColors.tertiaryContainer,
                          labelStyle: TextStyle(
                            color: _nonCompeteStatus == 1
                                ? Colors.white
                                : AppColors.onSurface,
                            fontSize: 12,
                          ),
                        ),
                        ChoiceChip(
                          label: const Text('Není ve smlouvě'),
                          selected: _nonCompeteStatus == 2,
                          onSelected: (_) => setState(() => _nonCompeteStatus = 2),
                          selectedColor: AppColors.surfaceContainerHigh,
                          labelStyle: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Red Flag alert box
                    if (_nonCompeteStatus == 1) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.dangerous,
                                  size: 18,
                                  color: AppColors.tertiaryContainer,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'POZOR NA NEPLATNOU DOLOŽKU',
                                  style: AppTypography.labelBadge(
                                    color: AppColors.tertiaryContainer,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pokud zaměstnavatel požaduje zákaz práce u konkurence po odchodu, musí vám za každý měsíc platit minimálně 50 % průměrného výdělku (§ 310 ZP). Bez toho je ujednání neplatné.',
                              style: AppTypography.bodySm(
                                color: AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  ClauseDetailScreen.routeById(
                                    'konkurencni_dolozka',
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.tertiaryFixed,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.play_circle,
                                      size: 16,
                                      color: AppColors.tertiaryContainer,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Přehrát video: Jak se bránit doložce',
                                      style: AppTypography.labelBadge(
                                        color: AppColors.tertiaryContainer,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    TextField(
                      controller: _clauseDetailsController,
                      style: AppTypography.bodySm(color: AppColors.onSurface),
                      decoration: const InputDecoration(
                        labelText: 'Podrobnosti doložky / výše kompenzace:',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Item 6: Úvazek & rozvržení doby
            _buildCheckCard(
              title: '6. Úvazek & rozvržení doby',
              statute: '§ 81 a násl.',
              question:
                  'Je ve smlouvě sjednán týdenní rozsah hodin a způsob rozvržení směn?',
              helpId: 'help_schedule',
              helpText:
                  'Zaměstnavatel je povinen vypracovat písemný rozvrh týdenní pracovní doby a seznámit s ním zaměstnance nejpozději 2 týdny předem, není-li dohodnuto jinak.',
              explanationId: 'limity_dpp_dpc',
              options: [
                'Ověřeno (jasný rozvrh)',
                'Nejasný rozvrh',
                'Zatím neověřeno',
              ],
              selectedOption: _scheduleStatus,
              onOptionSelected: (idx) => setState(() => _scheduleStatus = idx),
              inputLabel: 'Sjednaný rozsah hodin / směny:',
              inputController: _scheduleController,
            ),
            const SizedBox(height: 16),

            // Custom Notes Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.sticky_note_2,
                                size: 20,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Vlastní poznámky ke smlouvě',
                                  style: AppTypography.headlineSm(
                                    color: AppColors.primary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const StatuteBadge(text: 'Volitelné'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Zde si můžete poznamenat jakékoliv otázky pro budoucího zaměstnavatele, detaily z pohovoru nebo slíbené benefity.',
                      style: AppTypography.bodySm(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      style: AppTypography.bodyMd(color: AppColors.onSurface),
                      decoration: const InputDecoration(
                        hintText:
                            'Zapište si otázky na zaměstnavatele, slíbené benefity nebo detaily ze schůzky...',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.lock,
                          size: 14,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Uloženo výhradně offline v zařízení',
                          style: AppTypography.labelLaw(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Did you know tip card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.lightbulb,
                      size: 22,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VÍTE, ŽE...?',
                          style: AppTypography.labelBadge(
                            color: AppColors.secondary,
                          ),
                        ),
                        Text(
                          'Mzdový výměr nemusí být přímo součástí smlouvy, ale musíte ho dostat písemně nejpozději v den nástupu.',
                          style: AppTypography.bodySm(
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Save CTA Button
            ElevatedButton.icon(
              onPressed: _saveContract,
              icon: const Icon(Icons.save, size: 20),
              label: const Text('Uložit do Mých smluv'),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Aplikace má pouze informativní charakter a nenahrazuje odbornou právní radu.',
                style: AppTypography.labelLaw(
                  color: AppColors.onSurfaceVariant,
                ).copyWith(fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckCard({
    required String title,
    required String statute,
    required String question,
    required String helpId,
    required String helpText,
    required String explanationId,
    required List<String> options,
    required int selectedOption,
    required ValueChanged<int> onOptionSelected,
    required String inputLabel,
    required TextEditingController inputController,
  }) {
    final bool isHelpOpen = _expandedHelp.contains(helpId);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text(
                        title,
                        style: AppTypography.bodyLg(color: AppColors.onSurface)
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      StatuteBadge(text: statute),
                    ],
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    isHelpOpen ? Icons.help : Icons.help_outline,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  onPressed: () => _toggleHelp(helpId),
                ),
              ],
            ),
            Text(
              question,
              style: AppTypography.bodySm(color: AppColors.onSurface),
            ),
            if (isHelpOpen) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'INFORMATIVNÍ VYSVĚTLENÍ',
                          style: AppTypography.labelBadge(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      helpText,
                      style: AppTypography.bodySm(color: AppColors.onSurface),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          ClauseDetailScreen.routeById(explanationId),
                        );
                      },
                      child: Text(
                        'Otevřít podrobný rozbor a video výklad →',
                        style: AppTypography.labelLaw(
                          color: AppColors.primaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Column(
              children: List.generate(options.length, (idx) {
                final isSelected = selectedOption == idx;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    onTap: () => onOptionSelected(idx),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (idx == 0
                                ? AppColors.secondaryContainer
                                : (idx == 1
                                    ? AppColors.surfaceContainerHigh
                                    : AppColors.errorContainer.withValues(alpha: 0.5)))
                            : AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected && idx == 0
                            ? Border.all(color: AppColors.secondary, width: 1.5)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            idx == 0
                                ? Icons.check_circle
                                : (idx == 1 ? Icons.warning : Icons.cancel),
                            size: 18,
                            color: isSelected
                                ? (idx == 0
                                    ? AppColors.onSecondaryContainer
                                    : (idx == 1
                                        ? AppColors.primary
                                        : AppColors.error))
                                : AppColors.outline,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              options[idx],
                              style: AppTypography.labelBadge(
                                color: isSelected
                                    ? AppColors.onSurface
                                    : AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.done,
                              size: 16,
                              color: AppColors.primary,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: inputController,
              style: AppTypography.bodySm(color: AppColors.onSurface),
              decoration: InputDecoration(
                labelText: inputLabel,
                prefixIcon: const Icon(
                  Icons.edit_note,
                  size: 18,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
