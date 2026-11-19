import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/contract_model.dart';
import '../models/work_shift_model.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/date_formatter.dart';
import '../widgets/app_logo_action.dart';
import '../widgets/hours_progress_bar.dart';

class ContractDetailScreen extends StatefulWidget {
  final Contract contract;
  final AppState appState;

  const ContractDetailScreen({
    super.key,
    required this.contract,
    required this.appState,
  });

  static Route route(Contract contract, AppState appState) {
    return MaterialPageRoute(
      builder: (_) => ContractDetailScreen(
        contract: contract,
        appState: appState,
      ),
    );
  }

  @override
  State<ContractDetailScreen> createState() => _ContractDetailScreenState();
}

class _ContractDetailScreenState extends State<ContractDetailScreen> {
  final TextEditingController _hoursController = TextEditingController(text: '4.0');
  final TextEditingController _descController = TextEditingController(
    text: 'Testování mobilní aplikace - release 1.2',
  );
  DateTime _selectedDate = DateTime.now();
  bool _isLogFormExpanded = true;

  @override
  void dispose() {
    _hoursController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _addShift() {
    final double? hours = double.tryParse(_hoursController.text.replaceAll(',', '.'));
    if (hours == null || hours <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zadejte prosím platný počet hodin.')),
      );
      return;
    }

    final String desc = _descController.text.trim().isEmpty
        ? 'Pracovní směna'
        : _descController.text.trim();

    final rate = widget.contract.hourlyWage > 0
        ? widget.contract.hourlyWage
        : 250.0;

    final shift = WorkShift(
      id: 'shift_${DateTime.now().millisecondsSinceEpoch}',
      contractId: widget.contract.id,
      date: _selectedDate,
      hours: hours,
      description: desc,
      hourlyRate: rate,
    );

    widget.appState.addShift(shift);

    final wageFmt = NumberFormat.currency(
      locale: 'cs_CZ',
      symbol: 'Kč',
      decimalDigits: 0,
    ).format(shift.wage);

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
              'Zapsáno +${hours.toStringAsFixed(1)} h ($wageFmt)',
              style: AppTypography.bodySm(color: AppColors.inverseOnSurface),
            ),
          ],
        ),
      ),
    );

    setState(() {
      _descController.text = '';
    });
  }

  void _exportAttendance() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primaryContainer,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            const Icon(Icons.download_done, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Generuji docházkový list pro ${widget.contract.companyName}...',
              style: AppTypography.bodySm(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final shifts = widget.appState.getShiftsForContract(widget.contract.id);
        final totalHours = widget.appState.getTotalHoursForContract(widget.contract.id);
        final rate = widget.contract.hourlyWage > 0 ? widget.contract.hourlyWage : 250.0;
        final currentShiftHours = double.tryParse(_hoursController.text.replaceAll(',', '.')) ?? 0;
        final calculatedShiftWage = currentShiftHours * rate;

        final monthShifts = shifts;
        final monthHours = monthShifts.fold<double>(0.0, (sum, s) => sum + s.hours);
        final monthGross = monthHours * rate;
        final currencyFmt = NumberFormat.currency(locale: 'cs_CZ', symbol: 'Kč', decimalDigits: 0);

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
                  'Detail Smlouvy',
                  style: AppTypography.headlineSm(color: AppColors.onSurface),
                ),
                Text(
                  '${widget.contract.companyName} • ${widget.contract.contractType.label}',
                  style: AppTypography.labelLaw(color: AppColors.onSurfaceVariant),
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
                // Employer Summary Hero Card
                Card(
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
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    widget.contract.contractType.label,
                                    style: AppTypography.labelLaw(color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryContainer,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: AppColors.secondary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Aktivní',
                                        style: AppTypography.labelBadge(color: AppColors.onSecondaryContainer),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Sjednaná mzda',
                                    style: AppTypography.labelBadge(color: AppColors.outline),
                                  ),
                                  Text(
                                    widget.contract.contractType == ContractType.hpp
                                        ? '${currencyFmt.format(widget.contract.monthlyGrossWage)}/měs'
                                        : '${rate.toInt()} Kč/h',
                                    style: AppTypography.headlineSm(color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.contract.companyName,
                          style: AppTypography.headlineSm(color: AppColors.onSurface),
                        ),
                        Text(
                          widget.contract.jobTitle,
                          style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 18, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Místo výkonu', style: AppTypography.labelLaw(color: AppColors.outline)),
                                          Text(
                                            widget.contract.workLocation.isNotEmpty
                                                ? widget.contract.workLocation
                                                : 'Dle smlouvy',
                                            style: AppTypography.bodySm(color: AppColors.onSurface),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
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
                                child: Row(
                                  children: [
                                    const Icon(Icons.event, size: 18, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Konec / lhůta', style: AppTypography.labelLaw(color: AppColors.outline)),
                                          Text(
                                            widget.contract.daysUntilEnd != null
                                                ? 'Zbývá ${widget.contract.daysUntilEnd} dní'
                                                : 'Neurčitá',
                                            style: AppTypography.bodySm(color: AppColors.onSurface),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Legal Hour Tracker (DPP Limit 300 hrs)
                if (widget.contract.contractType == ContractType.dpp) ...[
                  Card(
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
                                  const Icon(Icons.speed, size: 20, color: AppColors.secondary),
                                  const SizedBox(width: 6),
                                  Text('Limit 300 hodin', style: AppTypography.headlineSm(color: AppColors.onSurface)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryFixed,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text('§ 75 ZP', style: AppTypography.labelLaw(color: AppColors.primary)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          HoursProgressBar(currentHours: totalHours, maxHours: 300.0),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info, size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Dle § 75 ZP nesmí rozsah práce na DPP překročit 300 hodin v kalendářním roce u jednoho zaměstnavatele.',
                                    style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Monthly Financial Status
                Card(
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
                                const Icon(Icons.calendar_month, size: 20, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text('Tento měsíc', style: AppTypography.headlineSm(color: AppColors.onSurface)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: monthGross <= 10500 ? AppColors.secondaryContainer : AppColors.errorContainer,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                monthGross <= 10500 ? 'Bez odvodů SP/ZP' : 'Odvody aktivní',
                                style: AppTypography.labelBadge(
                                  color: monthGross <= 10500 ? AppColors.onSecondaryContainer : AppColors.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Odpracováno', style: AppTypography.labelLaw(color: AppColors.outline)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${monthHours.toStringAsFixed(monthHours.truncateToDouble() == monthHours ? 0 : 1)} h',
                                      style: AppTypography.displayMd(color: AppColors.onSurface),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Čistá výplata (cca)', style: AppTypography.labelLaw(color: AppColors.onPrimaryContainer)),
                                    const SizedBox(height: 4),
                                    Text(
                                      currencyFmt.format(monthGross),
                                      style: AppTypography.displayMd(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Hrubá odměna:', style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)),
                            Text(currencyFmt.format(monthGross), style: AppTypography.labelButton(color: AppColors.onSurface)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Sociální & Zdravotní pojištění:', style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)),
                            Text(
                              monthGross <= 10500 ? '0 Kč (do 10 500 Kč)' : 'Odvádí se 11,6 %',
                              style: AppTypography.labelLaw(color: monthGross <= 10500 ? AppColors.secondary : AppColors.error),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Rapid Hour Entry Form
                Card(
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
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryFixed,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.edit_calendar, size: 18, color: AppColors.primary),
                                ),
                                const SizedBox(width: 8),
                                Text('Nový záznam práce', style: AppTypography.headlineSm(color: AppColors.onSurface)),
                              ],
                            ),
                            IconButton(
                              icon: Icon(_isLogFormExpanded ? Icons.expand_less : Icons.expand_more),
                              onPressed: () => setState(() => _isLogFormExpanded = !_isLogFormExpanded),
                            ),
                          ],
                        ),
                        if (_isLogFormExpanded) ...[
                          const SizedBox(height: 12),
                          Text('Datum směny', style: AppTypography.labelLaw(color: AppColors.outline)),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2024),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setState(() => _selectedDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 18, color: AppColors.outline),
                                  const SizedBox(width: 8),
                                  Text(
                                    CzechDateFormatter.formatFull(_selectedDate),
                                    style: AppTypography.bodyMd(color: AppColors.onSurface),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Délka směny (hodiny)', style: AppTypography.labelLaw(color: AppColors.outline)),
                              Text(
                                '= ${currencyFmt.format(calculatedShiftWage)}',
                                style: AppTypography.labelLaw(color: AppColors.secondary).copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _hoursController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (_) => setState(() {}),
                                  style: AppTypography.headlineSm(color: AppColors.onSurface),
                                  decoration: const InputDecoration(
                                    suffixText: 'hod',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Wrap(
                                spacing: 4,
                                children: [4.0, 6.0, 8.0].map((h) {
                                  return ActionChip(
                                    label: Text('${h.toInt()}h'),
                                    onPressed: () {
                                      setState(() {
                                        _hoursController.text = h.toStringAsFixed(1);
                                      });
                                    },
                                    backgroundColor: AppColors.surfaceContainerHigh,
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('Popis práce / Poznámka', style: AppTypography.labelLaw(color: AppColors.outline)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _descController,
                            style: AppTypography.bodyMd(color: AppColors.onSurface),
                            decoration: const InputDecoration(
                              hintText: 'např. Testování release kandidáta 1.2',
                              prefixIcon: Icon(Icons.notes, size: 18, color: AppColors.outline),
                            ),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            onPressed: _addShift,
                            icon: const Icon(Icons.add_circle, size: 18),
                            label: const Text('Uložit hodiny do deníku'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Shifts List
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Poslední záznamy', style: AppTypography.headlineSm(color: AppColors.onSurface)),
                                Text('Evidence směn', style: AppTypography.labelLaw(color: AppColors.outline)),
                              ],
                            ),
                            OutlinedButton.icon(
                              onPressed: _exportAttendance,
                              icon: const Icon(Icons.download, size: 16),
                              label: const Text('Export'),
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (shifts.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Text(
                                'Zatím žádné zapsané směny.',
                                style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: shifts.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final shift = shifts[index];
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(10),
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
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: AppColors.secondary,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              CzechDateFormatter.formatShort(shift.date),
                                              style: AppTypography.bodyMd(color: AppColors.onSurface).copyWith(fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(width: 6),
                                            Text('• ${shift.hours.toStringAsFixed(1)} hod', style: AppTypography.labelLaw(color: AppColors.outline)),
                                          ],
                                        ),
                                        Text(
                                          currencyFmt.format(shift.wage),
                                          style: AppTypography.labelButton(color: AppColors.primary),
                                        ),
                                      ],
                                    ),
                                    if (shift.description.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 14),
                                        child: Text(
                                          shift.description,
                                          style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Archive button
                OutlinedButton.icon(
                  onPressed: () {
                    widget.appState.toggleArchiveContract(widget.contract.id);
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.archive, size: 18, color: AppColors.error),
                  label: Text(
                    widget.contract.isArchived ? 'Obnovit z archivu' : 'Ukončit nebo archivovat dohodu',
                    style: const TextStyle(color: AppColors.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.errorContainer),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
