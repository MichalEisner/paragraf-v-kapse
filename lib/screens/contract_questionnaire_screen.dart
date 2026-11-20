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

class ProblemAlert {
  final bool isCritical;
  final String title;
  final String whatItMeans;
  final String? videoOrDetailTitle;

  const ProblemAlert({
    required this.isCritical,
    required this.title,
    required this.whatItMeans,
    this.videoOrDetailTitle,
  });
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
  final TextEditingController _customHoursController = TextEditingController();

  late DateTime _selectedStartDate;
  int _probationMonths = 3;
  bool _isIndefinite = true;
  DateTime? _selectedEndDate;
  double _weeklyHours = 40;
  bool _isCustomHours = false;
  String _selectedWorkloadPreset = '40 hod/týden';
  bool _isPayrollPanelExpanded = false;
  bool _hasTaxDeclaration = false;
  int _taxChildrenCount = 0;
  bool _isStudent = false;
  bool _hasDisability = false;

  // Selections (null = not yet selected by user)
  int? _roleStatus; // 0: yes, 1: vague, 2: missing
  int? _locationStatus; // 0: yes, 1: missing, 2: too broad (warning)
  int? _startDateStatus; // 0: yes, 1: vague, 2: missing
  int? _probationStatus; // 0: normal, 1: longer, 2: none
  int? _nonCompeteStatus; // 0: valid, 1: warn (missing compensation), 2: none
  int? _scheduleStatus; // 0: verified, 1: vague, 2: unverified

  // Expanded help flags
  final Set<String> _expandedHelp = {};

  @override
  void initState() {
    super.initState();
    _selectedType = widget.existingContract?.contractType ?? ContractType.dpc;
    _selectedStartDate = widget.existingContract?.startDate ?? DateTime.now();
    _startDateController.text = CzechDateFormatter.formatShort(_selectedStartDate);
    _probationMonths = widget.existingContract?.probationPeriodMonths ?? 3;
    _isIndefinite = widget.existingContract?.isIndefinite ?? true;
    _selectedEndDate = widget.existingContract?.endDate ??
        _selectedStartDate.add(const Duration(days: 365));
    _weeklyHours = widget.existingContract?.weeklyHours ??
        (_selectedType == ContractType.hpp ? 40 : (_selectedType == ContractType.dpc ? 20 : 300));
    _customHoursController.text = _weeklyHours.toInt().toString();
    _hasTaxDeclaration = widget.existingContract?.hasTaxDeclaration ?? false;
    _taxChildrenCount = widget.existingContract?.taxReliefChildrenCount ?? 0;
    _isStudent = widget.existingContract?.isStudent ?? false;
    _hasDisability = widget.existingContract?.hasDisability ?? false;

    if (widget.existingContract != null) {
      final c = widget.existingContract!;
      _companyController.text = c.companyName;
      _roleController.text = c.jobTitle == 'Pracovní pozice' ? '' : c.jobTitle;
      _locationController.text = c.workLocation == 'Dle smlouvy' ? '' : c.workLocation;

      final clauses = c.checkedClauses;
      final savedLoc = int.tryParse(clauses['locationStatus'] ?? clauses['location_status'] ?? '');
      final savedRole = int.tryParse(clauses['roleStatus'] ?? clauses['role_status'] ?? '');
      final savedStart = int.tryParse(clauses['startDateStatus'] ?? clauses['start_date_status'] ?? '');
      final savedProb = int.tryParse(clauses['probationStatus'] ?? clauses['probation_status'] ?? '');
      final savedNonComp = int.tryParse(clauses['nonCompeteStatus'] ?? clauses['non_compete_status'] ?? '');
      final savedSched = int.tryParse(clauses['scheduleStatus'] ?? clauses['schedule_status'] ?? '');

      _roleStatus = savedRole ?? (c.jobTitle.isNotEmpty ? 0 : 0);
      _locationStatus = savedLoc ?? 0;
      _startDateStatus = savedStart ?? 0;
      _scheduleStatus = savedSched ?? 0;
      if (savedProb != null) {
        _probationStatus = savedProb;
        _probationController.text = c.probationPeriodMonths == 0
            ? 'Bez zkušební doby'
            : '${c.probationPeriodMonths} měsíce';
      } else if (c.probationPeriodMonths == 0) {
        _probationStatus = 2;
        _probationController.text = 'Bez zkušební doby';
      } else if (c.probationPeriodMonths > 3) {
        _probationStatus = 1;
        _probationController.text = '${c.probationPeriodMonths} měsíce';
      } else {
        _probationStatus = 0;
        _probationController.text = '${c.probationPeriodMonths} měsíce';
      }
      _scheduleController.text = c.contractType == ContractType.dpp
          ? '${c.weeklyHours.toInt()} hod/rok'
          : '${c.weeklyHours.toInt()} hod/týden';
      _selectedWorkloadPreset = _scheduleController.text;
      _wageController.text = c.contractType == ContractType.hpp
          ? (c.monthlyGrossWage > 0 ? c.monthlyGrossWage.toInt().toString() : '')
          : (c.hourlyWage > 0 ? c.hourlyWage.toInt().toString() : '');
      _notesController.text = c.notes;
      if (savedNonComp != null) {
        _nonCompeteStatus = savedNonComp;
      } else {
        _nonCompeteStatus = c.hasNonCompete
            ? ((c.nonCompeteCompensationPercent ?? 0) >= 50 ? 0 : 1)
            : 2;
      }
    } else {
      _probationController.text = '3 měsíce';
      _scheduleController.text = _selectedType == ContractType.dpp
          ? '300 hod/rok'
          : (_selectedType == ContractType.dpc ? '20 hod/týden' : '40 hod/týden');
      _selectedWorkloadPreset = _scheduleController.text;
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
    _customHoursController.dispose();
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

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'VYBERTE DEN NÁSTUPU DO PRÁCE',
      cancelText: 'Zrušit',
      confirmText: 'Potvrdit datum',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedStartDate = picked;
        _startDateController.text = CzechDateFormatter.formatShort(picked);
        if (_startDateStatus == 2) {
          _startDateStatus = 0;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate ?? _selectedStartDate.add(const Duration(days: 365)),
      firstDate: _selectedStartDate,
      lastDate: DateTime(2035),
      helpText: 'DATUM UKONČENÍ SMLOUVY NA DOBU URČITOU',
      cancelText: 'Zrušit',
      confirmText: 'Potvrdit datum',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedEndDate = picked;
      });
    }
  }

  Contract? get _conflictingTaxDeclarationContract {
    if (!_hasTaxDeclaration) return null;
    final currentId = widget.existingContract?.id;
    for (final c in widget.appState.contracts) {
      if (c.id != currentId && !c.isArchived && c.hasTaxDeclaration) {
        return c;
      }
    }
    return null;
  }

  int get _criticalCount {
    int count = 0;
    if (_roleStatus == 2) count++;
    if (_locationStatus == 1) count++;
    if (_startDateStatus == 2) count++;
    if (_nonCompeteStatus == 1) count++;
    return count;
  }

  int get _warningCount {
    int count = 0;
    if (_roleStatus == 1) count++;
    if (_locationStatus == 2) count++;
    if (_startDateStatus == 1) count++;
    if (_probationStatus == 1 || (_probationStatus != 2 && _probationMonths > 3)) count++;
    if (_scheduleStatus == 1 || _scheduleStatus == 2) count++;
    return count;
  }

  int get _score {
    int score = 100;
    if (_roleStatus == 2) {
      score -= 35;
    } else if (_roleStatus == 1) {
      score -= 10;
    }

    if (_locationStatus == 1) {
      score -= 35;
    } else if (_locationStatus == 2) {
      score -= 10;
    }

    if (_startDateStatus == 2) {
      score -= 35;
    } else if (_startDateStatus == 1) {
      score -= 10;
    }

    if (_probationStatus == 1 || (_probationStatus != 2 && _probationMonths > 3)) {
      score -= 10;
    }
    if (_nonCompeteStatus == 1) {
      score -= 20;
    }
    if (_scheduleStatus == 1) {
      score -= 10;
    } else if (_scheduleStatus == 2) {
      score -= 5;
    }
    return score.clamp(10, 100);
  }

  int get _verifiedCount {
    int count = 0;
    if (_roleStatus != null) count++;
    if (_locationStatus != null) count++;
    if (_startDateStatus != null) count++;
    if (_probationStatus != null) count++;
    if (_nonCompeteStatus != null) count++;
    if (_scheduleStatus != null) count++;
    if (_companyController.text.trim().isNotEmpty) count++;
    if (_wageController.text.trim().isNotEmpty) count++;
    return count;
  }

  void _saveContract() {
    _showLegalDisclaimerConfirmationDialog();
  }

  Future<void> _showLegalDisclaimerConfirmationDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.gavel, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Právní upozornění',
                  style: AppTypography.headlineSm(color: AppColors.primary),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.hairlineBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: AppColors.secondary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Aplikace Paragraf v kapse má výhradně informativní a orientační charakter a nenahrazuje odbornou právní radu advokáta ani oficiální kontrolu inspektorátu práce.',
                        style: AppTypography.bodySm(color: AppColors.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Důležitá doporučení před podpisem:',
                style: AppTypography.labelButton(color: AppColors.onSurface),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      'Před podpisem si každou smlouvu i mzdový výměr vždy osobně celou a pozorně přečtěte.',
                      style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      'V případě jakýchkoliv nejasností či podezřelých ujednání trvejte na jejich vyjasnění předem.',
                      style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Zpět k úpravám'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(ctx).pop(true),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Rozumím a chci uložit'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      _executeSaveContract();
    }
  }

  void _executeSaveContract() {
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
      startDate: _selectedStartDate,
      endDate: _isIndefinite ? null : _selectedEndDate,
      probationPeriodMonths: _probationStatus == 2 ? 0 : _probationMonths,
      workLocation: _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : (_locationStatus == 0 ? 'Dle smlouvy' : ''),
      weeklyHours: _weeklyHours,
      hasNonCompete: _nonCompeteStatus == 0 || _nonCompeteStatus == 1,
      nonCompeteCompensationPercent: _nonCompeteStatus == 0 ? 50 : 0,
      notes: _notesController.text.trim(),
      evaluationScore: _score,
      verifiedItemsCount: _verifiedCount,
      totalItemsCount: 10,
      checkedClauses: {
        if (_roleStatus != null) 'roleStatus': _roleStatus.toString(),
        if (_locationStatus != null) 'locationStatus': _locationStatus.toString(),
        if (_startDateStatus != null) 'startDateStatus': _startDateStatus.toString(),
        if (_probationStatus != null) 'probationStatus': _probationStatus.toString(),
        if (_nonCompeteStatus != null) 'nonCompeteStatus': _nonCompeteStatus.toString(),
        if (_scheduleStatus != null) 'scheduleStatus': _scheduleStatus.toString(),
      },
      hasTaxDeclaration: _hasTaxDeclaration,
      taxReliefChildrenCount: _taxChildrenCount,
      isStudent: _isStudent,
      hasDisability: _hasDisability,
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
            Icon(Icons.verified, color: AppColors.secondaryFixed),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Smlouva byla uložena do přehledu se skóre $_score %.',
                style: AppTypography.bodySm(color: AppColors.inverseOnSurface),
              ),
            ),
          ],
        ),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    AppColors.isDark = isDark;
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
                              decoration: BoxDecoration(
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
                    child: Icon(
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
                      decoration: InputDecoration(
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
                        prefixIcon: Icon(
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

            // Payroll & Tax Settings Card (Collapsible)
            _buildPayrollSettingsCard(),
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
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _criticalCount > 0
                            ? AppColors.errorContainer.withValues(alpha: 0.6)
                            : (_warningCount > 0
                                ? AppColors.surfaceContainerLow
                                : AppColors.secondaryContainer.withValues(alpha: 0.35)),
                        borderRadius: BorderRadius.circular(10),
                        border: _criticalCount > 0
                            ? Border.all(color: AppColors.error, width: 1.5)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _criticalCount > 0
                                ? Icons.dangerous
                                : (_warningCount > 0
                                    ? Icons.warning_amber_rounded
                                    : Icons.verified),
                            size: 22,
                            color: _criticalCount > 0
                                ? AppColors.error
                                : (_warningCount > 0
                                    ? AppColors.primary
                                    : AppColors.secondary),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _criticalCount > 0
                                      ? '$_criticalCount ${_criticalCount == 1 ? "kritická chyba" : (_criticalCount < 5 ? "kritické chyby" : "kritických chyb")} – smlouva je neplatná!'
                                      : '$_score % smlouvy zkontrolováno',
                                  style: AppTypography.labelButton(
                                    color: _criticalCount > 0
                                        ? AppColors.error
                                        : AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _criticalCount > 0
                                      ? 'Ve smlouvě chybí zákonem vyžadované náležitosti (§ 34 ZP) nebo obsahuje neplatná ujednání.'
                                      : (_warningCount > 0
                                          ? '$_warningCount ${_warningCount == 1 ? "výstraha vyžaduje" : (_warningCount < 5 ? "výstrahy vyžadují" : "výstrah vyžaduje")} vyjasnění se zaměstnavatelem.'
                                          : 'Všechny klíčové náležitosti jsou v pořádku.'),
                                  style: AppTypography.bodySm(
                                    color: _criticalCount > 0
                                        ? AppColors.onErrorContainer
                                        : AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_criticalCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$_criticalCount NEPLATNOST',
                                style: AppTypography.labelBadge(
                                  color: Colors.white,
                                ),
                              ),
                            )
                          else if (_warningCount > 0)
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
                        decoration: BoxDecoration(
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
              problemAlerts: {
                1: const ProblemAlert(
                  isCritical: false,
                  title: 'Příliš obecné vymezení druhu práce',
                  whatItMeans:
                      'Pokud je druh práce formulován obecně (např. „pomocné administrativní práce“), zaměstnavatel vám může přidělovat jakoukoliv pomocnou činnost, i neodpovídající původní dohodě, bez vašeho dalšího souhlasu.',
                  videoOrDetailTitle: 'Přehrát video: Jak správně vymezit druh práce',
                ),
                2: const ProblemAlert(
                  isCritical: true,
                  title: 'Chybí druh práce (§ 34 ZP)',
                  whatItMeans:
                      'Druh práce je jednou ze tří povinných podstatných náležitostí smlouvy. Bez jeho ujednání je pracovní smlouva od samého počátku absolutně neplatná! Smlouvu nepodepisujte, dokud druh práce zaměstnavatel nedoplní.',
                  videoOrDetailTitle: 'Přehrát video: Povinné náležitosti a neplatnost smlouvy',
                ),
              },
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
              problemAlerts: {
                1: const ProblemAlert(
                  isCritical: true,
                  title: 'Chybí místo výkonu práce (§ 34 ZP)',
                  whatItMeans:
                      'Místo výkonu práce je povinnou zákonnou náležitostí. Bez jeho uvedení je pracovní smlouva absolutně neplatná. Nelze určit pravidelné pracoviště ani vznik nároků na cestovní náhrady.',
                  videoOrDetailTitle: 'Přehrát video: Místo výkonu práce',
                ),
                2: const ProblemAlert(
                  isCritical: false,
                  title: 'Místo výkonu je sjednáno příliš široce',
                  whatItMeans:
                      'Ujednání jako „místem výkonu je celá ČR“ dává firmě právo posílat vás na libovolná místa po celé zemi bez nutnosti vašeho zvláštního souhlasu a bez nároku na zákonné cestovní náhrady.',
                  videoOrDetailTitle: 'Přehrát video: Proč je celá ČR past na zaměstnance',
                ),
              },
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
              customInputWidget: _buildDatePickerWidget(),
              problemAlerts: {
                1: const ProblemAlert(
                  isCritical: false,
                  title: 'Podmíněný či nejasný den nástupu',
                  whatItMeans:
                      'Den nástupu musí být stanoven konkrétním dnem nebo objektivní událostí. Pokud je vázán na nejasnou podmínku, riskujete, že pracovní poměr nevznikne včas a nebudete přihlášeni k odvodům pojištění.',
                  videoOrDetailTitle: 'Přehrát video: Den nástupu do práce',
                ),
                2: const ProblemAlert(
                  isCritical: true,
                  title: 'Chybí den nástupu do práce (§ 34 ZP)',
                  whatItMeans:
                      'Bez sjednaného dne nástupu do práce pracovní poměr vůbec nevznikne. Jde o třetí povinnou podstatnou náležitost, bez které je pracovní smlouva od počátku neplatná.',
                  videoOrDetailTitle: 'Přehrát video: Zákonné náležitosti smlouvy',
                ),
              },
            ),
            const SizedBox(height: 12),

            // Contract Duration Card (Doba určitá vs neurčitá)
            _buildContractDurationCard(),
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
                        decoration: BoxDecoration(
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
                StatuteBadge(
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
              onOptionSelected: (idx) {
                setState(() {
                  _probationStatus = idx;
                  if (idx == 0) {
                    if (_probationMonths > 3 || _probationMonths == 0) _probationMonths = 3;
                    _probationController.text = '$_probationMonths měsíce';
                  } else if (idx == 1) {
                    if (_probationMonths <= 3) _probationMonths = 4;
                    _probationController.text = '$_probationMonths měsíce';
                  } else {
                    _probationMonths = 0;
                    _probationController.text = 'Bez zkušební doby';
                  }
                });
              },
              customInputWidget: _buildProbationMonthsSelector(),
              problemAlerts: {
                1: const ProblemAlert(
                  isCritical: false,
                  title: 'Zkušební doba přesahuje limit 3 měsíců',
                  whatItMeans:
                      'Zákoník práce omezuje zkušební dobu na max. 3 měsíce (až 6 měsíců je povoleno pouze u vedoucích zaměstnanců dle § 35 odst. 1 ZP). Ujednání delší zkušební doby pro řadové zaměstnance je v přesahující části neplatné.',
                  videoOrDetailTitle: 'Přehrát video: Zkušební doba a její limity',
                ),
              },
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
                              const StatuteBadge(text: '§ 310 ZP'),
                            ],
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
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
                                Icon(
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
                                    Icon(
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
              customInputWidget: _buildWorkloadSelector(),
              problemAlerts: {
                1: const ProblemAlert(
                  isCritical: false,
                  title: 'Nejasné rozvržení pracovní doby',
                  whatItMeans:
                      'Pokud smlouva neobsahuje rozvrh směn ani pravidla plánování, zaměstnavatel má ze zákona povinnost seznámit vás s rozvrhem alespoň 2 týdny předem (§ 84 ZP). Nemůže vás nutit do směn ze dne na den bez předchozí dohody.',
                  videoOrDetailTitle: 'Přehrát video: Rozvrhování směn a přesčasy',
                ),
                2: const ProblemAlert(
                  isCritical: false,
                  title: 'Rozvrh směn zatím neověřen',
                  whatItMeans:
                      'Doporučujeme ještě před podpisem vyjasnit, jak budou směny plánovány, jaké jsou přestávky na odpočinek a jak jsou propláceny přesčasy a příplatky.',
                  videoOrDetailTitle: 'Přehrát video: Limity pro dohody a směny',
                ),
              },
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
                              Icon(
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
                        Icon(
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
                    child: Icon(
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
    required int? selectedOption,
    required ValueChanged<int> onOptionSelected,
    String? inputLabel,
    TextEditingController? inputController,
    Widget? customInputWidget,
    Map<int, ProblemAlert>? problemAlerts,
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
                        Icon(
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
                final isSelected = selectedOption != null && selectedOption == idx;
                final alert = problemAlerts?[idx];
                final isCriticalOption = alert?.isCritical ?? false;
                final isWarningOption = alert != null && !alert.isCritical;

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
                                : (isCriticalOption
                                    ? AppColors.errorContainer
                                    : AppColors.surfaceContainerHigh))
                            : AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected
                            ? (isCriticalOption
                                ? Border.all(color: AppColors.error, width: 1.5)
                                : (idx == 0
                                    ? Border.all(color: AppColors.secondary, width: 1.5)
                                    : Border.all(color: AppColors.primary, width: 1.5)))
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            idx == 0
                                ? Icons.check_circle
                                : (isCriticalOption
                                    ? Icons.dangerous
                                    : (isWarningOption ? Icons.warning_amber_rounded : Icons.cancel)),
                            size: 18,
                            color: isSelected
                                ? (idx == 0
                                    ? AppColors.onSecondaryContainer
                                    : (isCriticalOption
                                        ? AppColors.error
                                        : AppColors.primary))
                                : AppColors.outline,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              options[idx],
                              style: AppTypography.labelBadge(
                                color: isSelected
                                    ? (isCriticalOption
                                        ? AppColors.onErrorContainer
                                        : AppColors.onSurface)
                                    : AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.done,
                              size: 16,
                              color: isCriticalOption
                                  ? AppColors.error
                                  : AppColors.primary,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            if (problemAlerts != null && selectedOption != null && problemAlerts.containsKey(selectedOption)) ...[
              const SizedBox(height: 6),
              _buildProblemAlertBox(problemAlerts[selectedOption]!, explanationId),
              const SizedBox(height: 8),
            ],
            if (customInputWidget != null) ...[
              const SizedBox(height: 6),
              customInputWidget,
            ],
            if (inputLabel != null && inputController != null) ...[
              const SizedBox(height: 8),
              TextField(
                controller: inputController,
                style: AppTypography.bodySm(color: AppColors.onSurface),
                decoration: InputDecoration(
                  labelText: inputLabel,
                  prefixIcon: Icon(
                    Icons.edit_note,
                    size: 18,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProblemAlertBox(ProblemAlert alert, String explanationId) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: alert.isCritical
            ? AppColors.errorContainer.withValues(alpha: 0.6)
            : AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        border: alert.isCritical
            ? Border.all(color: AppColors.error.withValues(alpha: 0.7), width: 1.5)
            : Border.all(color: AppColors.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                alert.isCritical ? Icons.dangerous : Icons.warning_amber_rounded,
                size: 20,
                color: alert.isCritical ? AppColors.error : AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alert.isCritical
                      ? 'KRITICKÁ CHYBA: ${alert.title.toUpperCase()}'
                      : 'VAROVÁNÍ: ${alert.title.toUpperCase()}',
                  style: AppTypography.labelBadge(
                    color: alert.isCritical ? AppColors.error : AppColors.primary,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: alert.isCritical ? AppColors.error : AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  alert.isCritical ? 'Neplatnost' : 'Riziko',
                  style: AppTypography.labelBadge(color: Colors.white).copyWith(fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Co to pro vás znamená:',
            style: AppTypography.labelLaw(
              color: alert.isCritical ? AppColors.onErrorContainer : AppColors.onSurface,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            alert.whatItMeans,
            style: AppTypography.bodySm(
              color: alert.isCritical ? AppColors.onErrorContainer : AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                ClauseDetailScreen.routeById(explanationId),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: alert.isCritical ? AppColors.error : AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_circle_fill, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      alert.videoOrDetailTitle ?? 'Přehrát video výklad a rozbor',
                      style: AppTypography.labelBadge(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerWidget() {
    return InkWell(
      onTap: _pickStartDate,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.hairlineBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.calendar_month,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ZVOLENÝ DEN NÁSTUPU (KALENDÁŘ):',
                    style: AppTypography.labelLaw(color: AppColors.outline),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CzechDateFormatter.formatFull(_selectedStartDate),
                    style: AppTypography.headlineSm(color: AppColors.primary),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit_calendar, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    'Vybrat datum',
                    style: AppTypography.labelBadge(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProbationMonthsSelector() {
    final options = [0, 1, 2, 3, 4, 5, 6];
    final effectiveMonths = _probationStatus == 2 ? 0 : _probationMonths;
    final probationEnd = DateTime(
      _selectedStartDate.year,
      _selectedStartDate.month + effectiveMonths,
      _selectedStartDate.day,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DÉLKA ZKUŠEBNÍ DOBY (VÝBĚR MĚSÍCŮ):',
          style: AppTypography.labelLaw(color: AppColors.outline),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: options.map((m) {
            final isSelected = (_probationStatus == 2 && m == 0) ||
                (_probationStatus != 2 && _probationMonths == m);
            String label;
            if (m == 0) {
              label = '0 měs (bez)';
            } else if (m == 3) {
              label = '3 měs (standard)';
            } else if (m == 6) {
              label = '6 měs (vedoucí)';
            } else {
              label = '$m ${m == 1 ? "měsíc" : (m < 5 ? "měsíce" : "měsíců")}';
            }

            return ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  if (m == 0) {
                    _probationStatus = 2;
                    _probationMonths = 0;
                    _probationController.text = 'Bez zkušební doby';
                  } else {
                    _probationMonths = m;
                    if (m > 3) {
                      _probationStatus = 1;
                    } else {
                      _probationStatus = 0;
                    }
                    _probationController.text =
                        '$m ${m == 1 ? "měsíc" : (m < 5 ? "měsíce" : "měsíců")}';
                  }
                });
              },
              selectedColor: m > 3
                  ? AppColors.errorContainer
                  : (m == 0
                      ? AppColors.surfaceContainerHigh
                      : AppColors.secondaryContainer),
              labelStyle: TextStyle(
                color: isSelected
                    ? (m > 3
                        ? AppColors.onErrorContainer
                        : (m == 0
                            ? AppColors.onSurface
                            : AppColors.onSecondaryContainer))
                    : AppColors.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                effectiveMonths > 0
                    ? Icons.event_available
                    : Icons.check_circle_outline,
                size: 16,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  effectiveMonths > 0
                      ? 'Konec zkušební doby: ${CzechDateFormatter.formatFull(probationEnd)}'
                      : 'Bez zkušební doby – poměr nelze zrušit ve zkušební době',
                  style: AppTypography.labelLaw(color: AppColors.onSurface).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkloadSelector() {
    List<Map<String, dynamic>> presets;
    if (_selectedType == ContractType.hpp) {
      presets = [
        {'label': '40 h/týden (Plný)', 'hours': 40.0},
        {'label': '30 h/týden (3/4)', 'hours': 30.0},
        {'label': '20 h/týden (Poloviční)', 'hours': 20.0},
        {'label': '10 h/týden (1/4)', 'hours': 10.0},
        {'label': 'Jiné...', 'hours': -1.0},
      ];
    } else if (_selectedType == ContractType.dpp) {
      presets = [
        {'label': '300 h/rok (Maximum)', 'hours': 300.0},
        {'label': '150 h/rok', 'hours': 150.0},
        {'label': '80 h/rok', 'hours': 80.0},
        {'label': 'Jiné...', 'hours': -1.0},
      ];
    } else {
      presets = [
        {'label': '20 h/týden (Maximum)', 'hours': 20.0},
        {'label': '15 h/týden', 'hours': 15.0},
        {'label': '10 h/týden', 'hours': 10.0},
        {'label': 'Jiné...', 'hours': -1.0},
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ROZSAH ÚVAZKU / PRACOVNÍ DOBY:',
          style: AppTypography.labelLaw(color: AppColors.outline),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: presets.map((p) {
            final String label = p['label'] as String;
            final double h = p['hours'] as double;
            final isJine = h == -1.0;
            final isSelected = isJine
                ? _isCustomHours
                : (!_isCustomHours && _weeklyHours == h);

            return ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  if (isJine) {
                    _isCustomHours = true;
                    _selectedWorkloadPreset = 'Jiné';
                  } else {
                    _isCustomHours = false;
                    _weeklyHours = h;
                    _selectedWorkloadPreset = label;
                    _scheduleController.text = label;
                    _customHoursController.text = h.toInt().toString();
                  }
                });
              },
              selectedColor: AppColors.secondaryContainer,
              labelStyle: TextStyle(
                color: isSelected
                    ? AppColors.onSecondaryContainer
                    : AppColors.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            );
          }).toList(),
        ),
        if (_isCustomHours) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.hairlineBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.tune, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'VLASTNÍ ZADÁNÍ ÚVAZKU & ROZVRHU',
                      style: AppTypography.labelBadge(color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _customHoursController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: AppTypography.bodySm(color: AppColors.onSurface),
                  decoration: InputDecoration(
                    labelText: _selectedType == ContractType.dpp
                        ? 'Počet hodin za kalendářní rok'
                        : 'Počet hodin týdně',
                    suffixText: _selectedType == ContractType.dpp ? 'hod/rok' : 'hod/týden',
                    hintText: 'např. 25',
                  ),
                  onChanged: (val) {
                    final parsed = double.tryParse(val.replaceAll(',', '.'));
                    if (parsed != null && parsed > 0) {
                      setState(() {
                        _weeklyHours = parsed;
                        _scheduleController.text = _selectedType == ContractType.dpp
                            ? '${parsed.toInt()} hod/rok'
                            : '${parsed.toInt()} hod/týden';
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _scheduleController,
                  style: AppTypography.bodySm(color: AppColors.onSurface),
                  decoration: const InputDecoration(
                    labelText: 'Rozvrh směn / poznámka k pracovní době',
                    hintText: 'např. Po-Pá 8:00 - 16:30, pružná pracovní doba...',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _selectedType == ContractType.dpp
                      ? 'Zákonný limit DPP: Maximálně 300 hodin v kalendářním roce u jednoho zaměstnavatele (§ 75 ZP).'
                      : (_selectedType == ContractType.dpc
                          ? 'Zákonný limit DPČ: Maximálně v průměru 20 hodin týdně (polovina stanovené týdenní doby, § 76 ZP).'
                          : 'Standardní týdenní pracovní doba činí 40 hodin týdně (§ 79 ZP). Zkrácený úvazek lze sjednat písemnou dohodou.'),
                  style: AppTypography.labelLaw(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContractDurationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text(
                        'Doba trvání pracovního poměru',
                        style: AppTypography.bodyLg(color: AppColors.onSurface)
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      const StatuteBadge(text: '§ 39 ZP'),
                    ],
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(Icons.help_outline, size: 20, color: AppColors.primary),
                  onPressed: () => _toggleHelp('help_duration'),
                ),
              ],
            ),
            Text(
              'Je smlouva sjednána na dobu neurčitou, nebo na dobu určitou?',
              style: AppTypography.bodySm(color: AppColors.onSurface),
            ),
            if (_expandedHelp.contains('help_duration')) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Pracovní poměr trvá na dobu neurčitou, pokud nebyla výslovně sjednána doba jeho trvání. Doba určitá mezi týmiž stranami nesmí přesáhnout 3 roky a může se opakovat nejvýše 2x (§ 39 ZP).',
                  style: AppTypography.bodySm(color: AppColors.onSurface),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Doba neurčitá')),
                    selected: _isIndefinite,
                    onSelected: (_) {
                      setState(() {
                        _isIndefinite = true;
                      });
                    },
                    selectedColor: AppColors.secondaryContainer,
                    labelStyle: TextStyle(
                      color: _isIndefinite
                          ? AppColors.onSecondaryContainer
                          : AppColors.onSurface,
                      fontWeight: _isIndefinite ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Doba určitá')),
                    selected: !_isIndefinite,
                    onSelected: (_) {
                      setState(() {
                        _isIndefinite = false;
                        _selectedEndDate ??= _selectedStartDate.add(const Duration(days: 365));
                      });
                    },
                    selectedColor: AppColors.primaryFixed,
                    labelStyle: TextStyle(
                      color: !_isIndefinite
                          ? AppColors.onPrimaryFixed
                          : AppColors.onSurface,
                      fontWeight: !_isIndefinite ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (!_isIndefinite) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickEndDate,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.hairlineBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.event_busy,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DATUM UKONČENÍ SMLOUVY (KALENDÁŘ):',
                              style: AppTypography.labelLaw(color: AppColors.outline),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedEndDate != null
                                  ? CzechDateFormatter.formatFull(_selectedEndDate!)
                                  : 'Vyberte datum ukončení',
                              style: AppTypography.headlineSm(color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.edit_calendar, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              'Vybrat',
                              style: AppTypography.labelBadge(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ActionChip(
                    label: const Text('+6 měsíců'),
                    onPressed: () {
                      setState(() {
                        _selectedEndDate = DateTime(
                          _selectedStartDate.year,
                          _selectedStartDate.month + 6,
                          _selectedStartDate.day,
                        );
                      });
                    },
                  ),
                  ActionChip(
                    label: const Text('+1 rok'),
                    onPressed: () {
                      setState(() {
                        _selectedEndDate = DateTime(
                          _selectedStartDate.year + 1,
                          _selectedStartDate.month,
                          _selectedStartDate.day,
                        );
                      });
                    },
                  ),
                  ActionChip(
                    label: const Text('+2 roky'),
                    onPressed: () {
                      setState(() {
                        _selectedEndDate = DateTime(
                          _selectedStartDate.year + 2,
                          _selectedStartDate.month,
                          _selectedStartDate.day,
                        );
                      });
                    },
                  ),
                  ActionChip(
                    label: const Text('+3 roky (limit)'),
                    onPressed: () {
                      setState(() {
                        _selectedEndDate = DateTime(
                          _selectedStartDate.year + 3,
                          _selectedStartDate.month,
                          _selectedStartDate.day,
                        );
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_selectedEndDate != null &&
                  _selectedEndDate!.difference(_selectedStartDate).inDays > 1096)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'POZOR: Doba určitá přesahuje zákonný limit 3 let dle § 39 ZP!',
                          style: AppTypography.labelBadge(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: AppColors.secondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Zákonný limit: Doba určitá nesmí přesáhnout 3 roky a může se opakovat max. 2x.',
                          style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPayrollSettingsCard() {
    final conflictContract = _conflictingTaxDeclarationContract;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _isPayrollPanelExpanded = !_isPayrollPanelExpanded),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Mzdové & daňové nastavení',
                                style: AppTypography.headlineSm(color: AppColors.onSurface)
                                    .copyWith(fontSize: 15),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const StatuteBadge(text: '§ 35ba, § 35c'),
                          ],
                        ),
                        Text(
                          _hasTaxDeclaration
                              ? 'Růžovka uplatněna • ${_taxChildrenCount > 0 ? "$_taxChildrenCount ${_taxChildrenCount == 1 ? 'dítě' : 'děti'}" : "bez dětí"}'
                              : 'Růžové prohlášení neuplatněno (bez slevy)',
                          style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _isPayrollPanelExpanded = !_isPayrollPanelExpanded),
                    icon: Icon(
                      _isPayrollPanelExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    label: Text(
                      _isPayrollPanelExpanded ? 'Skrýt' : 'Upravit',
                      style: AppTypography.labelLaw(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            if (_isPayrollPanelExpanded) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),

              // Switch for Tax Declaration (Růžové prohlášení)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Podepsané prohlášení poplatníka (růžovka)',
                                style: AppTypography.labelButton(color: AppColors.onSurface),
                              ),
                              Text(
                                'Uplatnění základní slevy na poplatníka 2 570 Kč/měsíc (§ 35ba ZDP)',
                                style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _hasTaxDeclaration,
                          activeColor: AppColors.secondary,
                          onChanged: (val) {
                            setState(() {
                              _hasTaxDeclaration = val;
                            });
                          },
                        ),
                      ],
                    ),
                    if (_hasTaxDeclaration && conflictContract != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.error),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.warning, color: AppColors.error, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'POZOR – SOUBĚŽNÉ PROHLÁŠENÍ K DANI',
                                    style: AppTypography.labelBadge(color: AppColors.error),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Prohlášení k dani máte již evidováno u zaměstnavatele "${conflictContract.companyName}". Dle § 38k odst. 6 ZDP smí mít poplatník podepsané prohlášení na stejný kalendářní měsíc pouze u JEDNOHO zaměstnavatele!',
                                    style: AppTypography.bodySm(color: AppColors.onErrorContainer),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Child tax relief (§ 35c ZDP)
              Text(
                'POČET DĚTÍ PRO DAŇOVÉ ZVÝHODNĚNÍ (§ 35c ZDP):',
                style: AppTypography.labelLaw(color: AppColors.outline),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [0, 1, 2, 3, 4].map((count) {
                  final isSelected = _taxChildrenCount == count;
                  return ChoiceChip(
                    label: Text(count == 0 ? 'Bez dětí (0)' : '$count ${count == 1 ? "dítě" : (count < 5 ? "děti" : "dětí")}'),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _taxChildrenCount = count;
                      });
                    },
                    selectedColor: AppColors.secondaryContainer,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.onSecondaryContainer
                          : AppColors.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.family_restroom, size: 16, color: AppColors.secondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _taxChildrenCount == 0
                            ? 'Bez slevy na vyživované děti.'
                            : (_taxChildrenCount == 1
                                ? '1 dítě: sleva 1 267 Kč / měsíc (15 204 Kč / rok)'
                                : (_taxChildrenCount == 2
                                    ? '2 děti: sleva 3 127 Kč / měsíc (1 267 + 1 860 Kč)'
                                    : '$_taxChildrenCount děti: sleva 5 447+ Kč / měsíc (včetně daňového bonusu)')),
                        style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Additional status switches (Student, Disability)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    avatar: Icon(
                      Icons.school,
                      size: 16,
                      color: _isStudent ? AppColors.onSecondaryContainer : AppColors.outline,
                    ),
                    label: const Text('Student do 26 let'),
                    selected: _isStudent,
                    onSelected: (val) => setState(() => _isStudent = val),
                    selectedColor: AppColors.secondaryContainer,
                  ),
                  FilterChip(
                    avatar: Icon(
                      Icons.accessible,
                      size: 16,
                      color: _hasDisability ? AppColors.onSecondaryContainer : AppColors.outline,
                    ),
                    label: const Text('Invalidita / ZTP'),
                    selected: _hasDisability,
                    onSelected: (val) => setState(() => _hasDisability = val),
                    selectedColor: AppColors.secondaryContainer,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
