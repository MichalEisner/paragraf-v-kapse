import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/contract_model.dart';
import '../models/tax_parameters_model.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/app_logo_action.dart';
import '../widgets/statute_badge.dart';

class CalculatorScreen extends StatefulWidget {
  final AppState appState;

  const CalculatorScreen({super.key, required this.appState});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  ContractType _currentContract = ContractType.dpp;
  bool _isHourly = true;
  final TextEditingController _rateController =
      TextEditingController(text: '250');
  final TextEditingController _hoursController =
      TextEditingController(text: '80');
  double _sliderHours = 80;

  // Slevy na dani parameters from image
  bool _hasDeclaration = true; // na poplatníka (ano / ne)
  int _childrenCount = 3; // počet dětí (výchozí 3 dle obrázku)
  int _ztpChildrenCount = 0; // z toho počet dětí s průkazem ZTP/P (žádné)
  bool _hasDisability12 = false; // invalidní důchod 1. nebo 2. stupně (ne / ano)
  bool _hasDisability3 = false; // invalidní důchod 3. stupně (ne / ano)
  bool _hasZtp = false; // držitel průkazu ZTP/P (ne / ano)
  bool _isStudent = true; // student do 26 let (pouze pro DPP a DPČ)

  final Set<String> _openHelps = {};

  @override
  void dispose() {
    _rateController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  void _toggleHelp(String id) {
    setState(() {
      if (_openHelps.contains(id)) {
        _openHelps.remove(id);
      } else {
        _openHelps.add(id);
      }
    });
  }

  void _switchContractType(ContractType type) {
    setState(() {
      _currentContract = type;
      if (type == ContractType.hpp) {
        if (_isHourly) {
          _isHourly = false;
          _rateController.text = '45000';
        }
        _isStudent = false; // Pro HPP student odebrán
      } else {
        if (!_isHourly) {
          _isHourly = true;
          _rateController.text = '250';
        }
      }
    });
  }

  void _switchInputMode(bool hourly) {
    setState(() {
      _isHourly = hourly;
      if (_isHourly) {
        _rateController.text = '250';
      } else {
        _rateController.text = _currentContract == ContractType.hpp ? '48500' : '20000';
      }
    });
  }

  void _syncSlider(double val) {
    setState(() {
      _sliderHours = val;
      _hoursController.text = val.toInt().toString();
    });
  }

  void _showRateModelingDialog({
    required String title,
    required String paramLabel,
    required double currentValue,
    required double defaultValue,
    required ValueChanged<double> onSave,
  }) {
    final controller = TextEditingController(text: currentValue.toInt().toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.tune, color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.headlineSm(color: AppColors.primary),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Zde můžete upravit zákonnou měsíční sazbu pro modelování přesného výpočtu.',
                style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: paramLabel,
                  suffixText: 'Kč / měs',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Zákonná výchozí sazba: ${defaultValue.toInt()} Kč',
                style: AppTypography.labelLaw(color: AppColors.outline),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                onSave(defaultValue);
                Navigator.of(context).pop();
                setState(() {});
              },
              child: const Text('Zákonná výchozí'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Zrušit'),
            ),
            FilledButton(
              onPressed: () {
                final val = double.tryParse(controller.text.replaceAll(' ', '')) ?? defaultValue;
                onSave(val);
                Navigator.of(context).pop();
                setState(() {});
              },
              child: const Text('Uložit'),
            ),
          ],
        );
      },
    );
  }

  void _showChildrenRateModelingDialog() {
    final c1 = TextEditingController(text: widget.appState.taxParams.child1Relief.toInt().toString());
    final c2 = TextEditingController(text: widget.appState.taxParams.child2Relief.toInt().toString());
    final c3 = TextEditingController(text: widget.appState.taxParams.child3PlusRelief.toInt().toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.tune, color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Modelování sazeb pro děti', style: AppTypography.headlineSm(color: AppColors.primary)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: c1,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '1. dítě (Kč / měs)', helperText: 'Zákonná sazba: 1 267 Kč'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: c2,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '2. dítě (Kč / měs)', helperText: 'Zákonná sazba: 1 860 Kč'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: c3,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '3. a další dítě (Kč / měs)', helperText: 'Zákonná sazba: 2 320 Kč'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                widget.appState.updateTaxParams(
                  widget.appState.taxParams.copyWith(
                    child1Relief: 1267.0,
                    child2Relief: 1860.0,
                    child3PlusRelief: 2320.0,
                  ),
                );
                Navigator.of(context).pop();
                setState(() {});
              },
              child: const Text('Zákonná výchozí'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Zrušit'),
            ),
            FilledButton(
              onPressed: () {
                widget.appState.updateTaxParams(
                  widget.appState.taxParams.copyWith(
                    child1Relief: double.tryParse(c1.text.replaceAll(' ', '')) ?? 1267.0,
                    child2Relief: double.tryParse(c2.text.replaceAll(' ', '')) ?? 1860.0,
                    child3PlusRelief: double.tryParse(c3.text.replaceAll(' ', '')) ?? 2320.0,
                  ),
                );
                Navigator.of(context).pop();
                setState(() {});
              },
              child: const Text('Uložit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double rate = double.tryParse(_rateController.text.replaceAll(',', '.')) ?? 0;
    final double hours = double.tryParse(_hoursController.text.replaceAll(',', '.')) ?? 0;

    final result = widget.appState.taxCalculator.calculate(
      contractType: _currentContract,
      rate: rate,
      hours: hours,
      isHourly: _isHourly,
      hasTaxDeclaration: _hasDeclaration,
      isStudent: _currentContract != ContractType.hpp && _isStudent,
      childrenCount: _childrenCount,
      ztpChildrenCount: _ztpChildrenCount,
      hasDisability12: _hasDisability12,
      hasDisability3: _hasDisability3,
      hasZtp: _hasZtp,
      params: widget.appState.taxParams,
    );

    final currencyFmt = NumberFormat.currency(
      locale: 'cs_CZ',
      symbol: 'Kč',
      decimalDigits: 0,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    AppColors.isDark = isDark;

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
              child: const Icon(Icons.balance, size: 20, color: Colors.white),
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
                  'Mzdová Kalkulačka',
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
            // Top Contract Selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: ContractType.values.map((type) {
                  final isSelected = _currentContract == type;
                  return Expanded(
                    child: InkWell(
                      onTap: () => _switchContractType(type),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryContainer : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          type.label,
                          style: AppTypography.labelButton(
                            color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Statutory Threshold Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _currentContract == ContractType.hpp ? Icons.work : Icons.info,
                    size: 20,
                    color: _currentContract == ContractType.hpp ? AppColors.primary : AppColors.secondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentContract == ContractType.dpp
                              ? 'Limit odvodů pro DPP (2025/2026): 10 500 Kč/měs'
                              : (_currentContract == ContractType.dpc
                                  ? 'Rozhodná částka pro DPČ: 4 500 Kč/měs'
                                  : 'Standardní pracovní poměr (HPP)'),
                          style: AppTypography.labelLaw(color: AppColors.primary),
                        ),
                        Text(
                          _currentContract == ContractType.dpp
                              ? 'Nad limit se strhává 11,6 % za pojištění'
                              : (_currentContract == ContractType.dpc
                                  ? 'Do 4 499 Kč bez odvodů, od 4 500 Kč plné pojistné'
                                  : 'Plné odvody pojištění (11,6 %) a nárok na 4+ týdny dovolené'),
                          style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  StatuteBadge(
                    text: _currentContract == ContractType.dpp
                        ? '§ 75 ZP'
                        : (_currentContract == ContractType.dpc ? '§ 76 ZP' : '§ 74 ZP'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Main Input Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Text('Zadání příjmu', style: AppTypography.headlineSm(color: AppColors.onSurface)),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () => _switchInputMode(true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _isHourly ? AppColors.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Hodinová',
                                    style: AppTypography.labelBadge(color: _isHourly ? Colors.white : AppColors.onSurfaceVariant),
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () => _switchInputMode(false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: !_isHourly ? AppColors.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Měsíční paušál',
                                    style: AppTypography.labelBadge(color: !_isHourly ? Colors.white : AppColors.onSurfaceVariant),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isHourly ? 'HODINOVÁ ODMĚNA' : 'HRUBÁ MĚSÍČNÍ MZDA',
                                style: AppTypography.labelBadge(color: AppColors.onSurfaceVariant),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _rateController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) => setState(() {}),
                                style: AppTypography.headlineSm(color: AppColors.onSurface),
                                decoration: InputDecoration(
                                  suffixText: _isHourly ? 'Kč / hod' : 'Kč / měs',
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_isHourly) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'ODPRACOVÁNO',
                                        style: AppTypography.labelBadge(color: AppColors.onSurfaceVariant),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    if (_currentContract == ContractType.dpp)
                                      Flexible(
                                        child: Text(
                                          'Max 300 h/rok',
                                          style: AppTypography.labelLaw(color: AppColors.secondary),
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.end,
                                        ),
                                      )
                                    else if (_currentContract == ContractType.dpc)
                                      Flexible(
                                        child: Text(
                                          'Max 20 h/týden',
                                          style: AppTypography.labelLaw(color: AppColors.secondary),
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.end,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _hoursController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (val) {
                                    final d = double.tryParse(val) ?? 0;
                                    setState(() => _sliderHours = d.clamp(0, 300));
                                  },
                                  style: AppTypography.headlineSm(color: AppColors.onSurface),
                                  decoration: const InputDecoration(
                                    suffixText: 'hod',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (_isHourly) ...[
                      const SizedBox(height: 10),
                      Slider(
                        value: _sliderHours.clamp(0.0, _currentContract == ContractType.dpc ? 80.0 : 160.0),
                        min: 0,
                        max: _currentContract == ContractType.dpc ? 80 : 160,
                        divisions: _currentContract == ContractType.dpc ? 16 : 32,
                        label: '${_sliderHours.toInt()} h',
                        activeColor: AppColors.primaryContainer,
                        onChanged: _syncSlider,
                      ),
                    ],
                    const SizedBox(height: 10),

                    // SECTION: Slevy na dani (Přidání parametrů pro přesnější výpočet)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SLEVY NA DANI',
                          style: AppTypography.labelBadge(color: AppColors.onSurfaceVariant),
                        ),
                        InkWell(
                          onTap: () {
                            widget.appState.updateTaxParams(const TaxParameters());
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Sazby obnoveny na zákonné výchozí hodnoty.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Icon(Icons.refresh, size: 14, color: AppColors.secondary),
                              const SizedBox(width: 4),
                              Text(
                                'Výchozí sazby',
                                style: AppTypography.labelLaw(color: AppColors.secondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 1. na poplatníka
                    _buildReliefRow(
                      reliefKey: 'help_poplatnik',
                      title: 'na poplatníka',
                      statute: '§ 35ba',
                      helpText:
                          'Základní sleva na poplatníka činí 2 570 Kč/měsíc (30 840 Kč ročně). Podmínkou je podepsané prohlášení k dani (růžový formulář). Snižuje vypočtenou daň až na 0 Kč.',
                      control: _buildDropdownBool(
                        value: _hasDeclaration,
                        onChanged: (v) => setState(() => _hasDeclaration = v),
                      ),
                      amountText: '${_hasDeclaration ? widget.appState.taxParams.basicTaxRelief.toInt() : 0} Kč',
                      isPositiveAmount: _hasDeclaration,
                      onModelRate: () => _showRateModelingDialog(
                        title: 'Sleva na poplatníka',
                        paramLabel: 'Základní sleva na poplatníka',
                        currentValue: widget.appState.taxParams.basicTaxRelief,
                        defaultValue: 2570.0,
                        onSave: (val) => widget.appState.updateTaxParams(
                          widget.appState.taxParams.copyWith(basicTaxRelief: val),
                        ),
                      ),
                    ),

                    // 2. počet dětí, na které je uplatňovaná sleva na dani
                    _buildReliefRow(
                      reliefKey: 'help_deti',
                      title: 'počet dětí, na které je uplatňovaná sleva na dani',
                      statute: '§ 35c',
                      helpText:
                          'Daňové zvýhodnění na vyživované dítě: 1. dítě 1 267 Kč/měs, 2. dítě 1 860 Kč/měs, 3. a každé další dítě 2 320 Kč/měs. Pokud je sleva vyšší než daň, vzniká nárok na vyplacení daňového bonusu.',
                      control: _buildDropdownChildren(
                        value: _childrenCount,
                        onChanged: (v) => setState(() {
                          _childrenCount = v;
                          if (_ztpChildrenCount > _childrenCount) {
                            _ztpChildrenCount = _childrenCount;
                          }
                        }),
                      ),
                      amountText: () {
                        if (!_hasDeclaration || _childrenCount == 0) return '0 Kč';
                        double sum = 0;
                        final validZtp = min(_childrenCount, _ztpChildrenCount);
                        for (int i = 1; i <= _childrenCount; i++) {
                          double r = (i == 1)
                              ? widget.appState.taxParams.child1Relief
                              : ((i == 2)
                                  ? widget.appState.taxParams.child2Relief
                                  : widget.appState.taxParams.child3PlusRelief);
                          if (i <= validZtp) r *= 2;
                          sum += r;
                        }
                        return '${sum.toInt()} Kč';
                      }(),
                      isPositiveAmount: _hasDeclaration && _childrenCount > 0,
                      onModelRate: _showChildrenRateModelingDialog,
                    ),

                    // 3. z toho počet dětí s průkazem ZTP/P (zobrazuje se při počtu dětí > 0)
                    if (_childrenCount > 0)
                      _buildReliefRow(
                        reliefKey: 'help_ztp_deti',
                        title: 'z toho počet dětí s průkazem ZTP/P',
                        statute: '§ 35c odst. 7',
                        helpText:
                            'U dítěte, kterému je přiznán nárok na průkaz ZTP/P, se výše daňového zvýhodnění zvyšuje na dvojnásobek (+100 %).',
                        control: _buildDropdownZtpChildren(
                          value: _ztpChildrenCount,
                          maxChildren: _childrenCount,
                          onChanged: (v) => setState(() => _ztpChildrenCount = v),
                        ),
                        amountText: _ztpChildrenCount > 0
                            ? '${_ztpChildrenCount}x ZTP/P (2x sazba)'
                            : 'žádné',
                        isPositiveAmount: _ztpChildrenCount > 0,
                        onModelRate: _showChildrenRateModelingDialog,
                      ),

                    // 4. invalidní důchod 1. nebo 2. stupně
                    _buildReliefRow(
                      reliefKey: 'help_inv12',
                      title: 'invalidní důchod 1. nebo 2. stupně',
                      statute: '§ 35ba',
                      helpText:
                          'Sleva na invaliditu činí 210 Kč/měsíc (2 520 Kč ročně) pro poživatele invalidního důchodu pro invaliditu prvního nebo druhého stupně.',
                      control: _buildDropdownBool(
                        value: _hasDisability12,
                        onChanged: (v) => setState(() => _hasDisability12 = v),
                      ),
                      amountText: '${_hasDeclaration && _hasDisability12 ? widget.appState.taxParams.disability12Relief.toInt() : 0} Kč',
                      isPositiveAmount: _hasDeclaration && _hasDisability12,
                      onModelRate: () => _showRateModelingDialog(
                        title: 'Invalidní důchod 1. a 2. stupně',
                        paramLabel: 'Sleva na invaliditu 1. a 2. st.',
                        currentValue: widget.appState.taxParams.disability12Relief,
                        defaultValue: 210.0,
                        onSave: (val) => widget.appState.updateTaxParams(
                          widget.appState.taxParams.copyWith(disability12Relief: val),
                        ),
                      ),
                    ),

                    // 5. invalidní důchod 3. stupně
                    _buildReliefRow(
                      reliefKey: 'help_inv3',
                      title: 'invalidní důchod 3. stupně',
                      statute: '§ 35ba',
                      helpText:
                          'Sleva na invaliditu činí 420 Kč/měsíc (5 040 Kč ročně) pro poživatele invalidního důchodu pro invaliditu třetího stupně.',
                      control: _buildDropdownBool(
                        value: _hasDisability3,
                        onChanged: (v) => setState(() => _hasDisability3 = v),
                      ),
                      amountText: '${_hasDeclaration && _hasDisability3 ? widget.appState.taxParams.disability3Relief.toInt() : 0} Kč',
                      isPositiveAmount: _hasDeclaration && _hasDisability3,
                      onModelRate: () => _showRateModelingDialog(
                        title: 'Invalidní důchod 3. stupně',
                        paramLabel: 'Sleva na invaliditu 3. st.',
                        currentValue: widget.appState.taxParams.disability3Relief,
                        defaultValue: 420.0,
                        onSave: (val) => widget.appState.updateTaxParams(
                          widget.appState.taxParams.copyWith(disability3Relief: val),
                        ),
                      ),
                    ),

                    // 6. držitel průkazu ZTP/P
                    _buildReliefRow(
                      reliefKey: 'help_ztp_p',
                      title: 'držitel průkazu ZTP/P',
                      statute: '§ 35ba',
                      helpText:
                          'Sleva pro držitele průkazu ZTP/P (zvlášť těžké postižení s průvodcem) činí 1 345 Kč/měsíc (16 140 Kč ročně).',
                      control: _buildDropdownBool(
                        value: _hasZtp,
                        onChanged: (v) => setState(() => _hasZtp = v),
                      ),
                      amountText: '${_hasDeclaration && _hasZtp ? widget.appState.taxParams.ztpRelief.toInt() : 0} Kč',
                      isPositiveAmount: _hasDeclaration && _hasZtp,
                      onModelRate: () => _showRateModelingDialog(
                        title: 'Držitel průkazu ZTP/P',
                        paramLabel: 'Sleva pro držitele ZTP/P',
                        currentValue: widget.appState.taxParams.ztpRelief,
                        defaultValue: 1345.0,
                        onSave: (val) => widget.appState.updateTaxParams(
                          widget.appState.taxParams.copyWith(ztpRelief: val),
                        ),
                      ),
                    ),

                    // 7. Student do 26 let (skryto při HPP, viditelné pro DPP a DPČ)
                    if (_currentContract != ContractType.hpp)
                      _buildReliefRow(
                        reliefKey: 'help_student',
                        title: 'Jsem student do 26 let',
                        statute: '§ 7 ZPoj',
                        helpText:
                            'Za studenty do 26 let hradí zdravotní pojištění stát. U dohod (DPP/DPČ) do limitu nemusíte doplácet pojistné do minimálního vyměřovacího základu.',
                        control: _buildDropdownBool(
                          value: _isStudent,
                          onChanged: (v) => setState(() => _isStudent = v),
                        ),
                        amountText: _isStudent ? 'Státní plátce' : 'Běžný',
                        isPositiveAmount: _isStudent,
                        onModelRate: () => showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: AppColors.surface,
                            title: const Text('Status studenta'),
                            content: const Text(
                              'Podle konsolidačního balíčku byla daňová sleva na studenta zrušena. Status studenta do 26 let vám však stále garantuje, že zdravotní pojištění hradí stát a nemusíte doplácet do minima.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Rozumím'),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Educational Notice Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: result.noticeType == 'safe'
                    ? AppColors.secondaryFixed.withValues(alpha: 0.3)
                    : (result.noticeType == 'warning'
                        ? AppColors.errorContainer.withValues(alpha: 0.5)
                        : AppColors.surfaceContainer),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    result.noticeType == 'safe'
                        ? Icons.verified
                        : (result.noticeType == 'warning' ? Icons.warning : Icons.workspace_premium),
                    size: 20,
                    color: result.noticeType == 'safe'
                        ? AppColors.secondary
                        : (result.noticeType == 'warning' ? AppColors.error : AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.noticeTitle,
                          style: AppTypography.headlineSm(
                            color: result.noticeType == 'safe'
                                ? AppColors.secondary
                                : (result.noticeType == 'warning' ? AppColors.error : AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          result.noticeDesc,
                          style: AppTypography.bodySm(color: AppColors.onSurface),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Highlight Result Hero Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryContainer, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ČISTÝ VÝDĚLEK NA ÚČET',
                        style: AppTypography.labelBadge(color: Colors.white.withValues(alpha: 0.8)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${_currentContract.label} režim',
                          style: AppTypography.labelLaw(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        currencyFmt.format(result.netWage).replaceAll('Kč', '').trim(),
                        style: AppTypography.displayLg(color: Colors.white).copyWith(fontSize: 36),
                      ),
                      const SizedBox(width: 6),
                      Text('Kč', style: AppTypography.headlineLg(color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: Colors.white24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Efektivní čistá sazba:',
                        style: AppTypography.bodySm(color: Colors.white.withValues(alpha: 0.9)),
                      ),
                      Text(
                        '${result.netHourly.toInt()} Kč / hod',
                        style: AppTypography.labelButton(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Detailed Ledger Breakdown
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildLedgerRow(
                      icon: Icons.payments,
                      title: 'Hrubá mzda / odměna',
                      value: currencyFmt.format(result.grossWage),
                      isBold: true,
                    ),
                    const Divider(),
                    _buildLedgerRow(
                      icon: Icons.security,
                      title: 'Sociální pojištění (7,1 %)',
                      subtitle: result.paysInsurance ? 'Zákonný odvod' : 'Bez odvodů (do limitu)',
                      value: currencyFmt.format(result.socialInsurance),
                    ),
                    const Divider(),
                    _buildLedgerRow(
                      icon: Icons.health_and_safety,
                      title: 'Zdravotní pojištění (4,5 %)',
                      subtitle: result.paysInsurance
                          ? 'Zákonný odvod'
                          : (_isStudent ? 'Osvobozeno (student do 26 let)' : 'Bez odvodů do limitu'),
                      value: currencyFmt.format(result.healthInsurance),
                    ),
                    const Divider(),
                    _buildLedgerRow(
                      icon: Icons.receipt_long,
                      title: 'Zálohová daň (15 %)',
                      value: currencyFmt.format(result.taxBeforeRelief),
                    ),
                    if (_hasDeclaration) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 32, top: 4, bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Uplatněná sleva na poplatníka / invaliditu',
                                style: AppTypography.bodySm(color: AppColors.secondary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '- ${currencyFmt.format(result.appliedTaxRelief)}',
                              style: AppTypography.bodySm(color: AppColors.secondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_childrenCount > 0 && _hasDeclaration) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 32, top: 4, bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Sleva na děti ($_childrenCount)',
                                style: AppTypography.bodySm(color: AppColors.secondary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '- ${currencyFmt.format(result.appliedChildRelief)}',
                              style: AppTypography.bodySm(color: AppColors.secondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (result.taxBonus > 0) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 32, top: 4, bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Vyplacený daňový bonus',
                                style: AppTypography.labelButton(color: AppColors.secondary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '+ ${currencyFmt.format(result.taxBonus)}',
                              style: AppTypography.labelButton(color: AppColors.secondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.only(left: 32, top: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text('Výsledná sražená daň', style: AppTypography.labelButton(color: AppColors.onSurface)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            currencyFmt.format(result.taxFinal),
                            style: AppTypography.labelButton(color: AppColors.tertiaryContainer),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLedgerRow({
    required IconData icon,
    required String title,
    String? subtitle,
    required String value,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: isBold
                      ? AppTypography.headlineSm(color: AppColors.onSurface)
                      : AppTypography.bodyMd(color: AppColors.onSurface),
                ),
                if (subtitle != null)
                  Text(subtitle, style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: isBold
                ? AppTypography.headlineSm(color: AppColors.onSurface)
                : AppTypography.labelButton(color: AppColors.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildReliefRow({
    required String reliefKey,
    required String title,
    String? statute,
    required String helpText,
    required Widget control,
    required String amountText,
    required bool isPositiveAmount,
    required VoidCallback onModelRate,
  }) {
    final bool isHelpOpen = _openHelps.contains(reliefKey);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.labelButton(color: AppColors.onSurface),
                      ),
                    ),
                    if (statute != null) ...[
                      const SizedBox(width: 4),
                      StatuteBadge(text: statute),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isHelpOpen ? Icons.help : Icons.help_outline,
                  size: 18,
                  color: AppColors.primary,
                ),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                tooltip: 'Zákonné vysvětlení',
                onPressed: () => _toggleHelp(reliefKey),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.tune, size: 18, color: AppColors.secondary),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                tooltip: 'Modelovat sazbu',
                onPressed: onModelRate,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              control,
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isPositiveAmount ? AppColors.secondary : AppColors.outlineVariant,
                    width: 1,
                  ),
                ),
                child: Text(
                  amountText,
                  style: AppTypography.labelButton(
                    color: isPositiveAmount ? AppColors.primary : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (isHelpOpen) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                helpText,
                style: AppTypography.bodySm(color: AppColors.onSurface),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDropdownBool({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return DropdownButtonHideUnderline(
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButton<bool>(
          value: value,
          isDense: true,
          icon: const Icon(Icons.arrow_drop_down, size: 20),
          items: const [
            DropdownMenuItem(value: true, child: Text('ano')),
            DropdownMenuItem(value: false, child: Text('ne')),
          ],
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ),
    );
  }

  Widget _buildDropdownChildren({
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return DropdownButtonHideUnderline(
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButton<int>(
          value: value,
          isDense: true,
          icon: const Icon(Icons.arrow_drop_down, size: 20),
          items: const [
            DropdownMenuItem(value: 0, child: Text('žádné')),
            DropdownMenuItem(value: 1, child: Text('1 dítě')),
            DropdownMenuItem(value: 2, child: Text('2 děti')),
            DropdownMenuItem(value: 3, child: Text('3 děti')),
            DropdownMenuItem(value: 4, child: Text('4 děti')),
            DropdownMenuItem(value: 5, child: Text('5 dětí')),
          ],
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ),
    );
  }

  Widget _buildDropdownZtpChildren({
    required int value,
    required int maxChildren,
    required ValueChanged<int> onChanged,
  }) {
    return DropdownButtonHideUnderline(
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButton<int>(
          value: value,
          isDense: true,
          icon: const Icon(Icons.arrow_drop_down, size: 20),
          items: [
            const DropdownMenuItem(value: 0, child: Text('žádné')),
            for (int i = 1; i <= maxChildren; i++)
              DropdownMenuItem(
                value: i,
                child: Text('$i ${i == 1 ? 'dítě' : (i < 5 ? 'děti' : 'dětí')}'),
              ),
          ],
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ),
    );
  }
}
