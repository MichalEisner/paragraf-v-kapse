import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/contract_model.dart';
import '../models/work_shift_model.dart';
import '../services/attendance_export_service.dart';
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
  bool _showAllShifts = false;

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
            Icon(Icons.check_circle, color: AppColors.secondaryFixed),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Zapsáno +${hours.toStringAsFixed(1)} h ($wageFmt)',
                style: AppTypography.bodySm(color: AppColors.inverseOnSurface),
              ),
            ),
          ],
        ),
      ),
    );

    setState(() {
      _descController.text = '';
    });
  }

  void _editShiftDialog(WorkShift shift) {
    final hoursController = TextEditingController(
      text: shift.hours.toStringAsFixed(shift.hours.truncateToDouble() == shift.hours ? 0 : 1),
    );
    final descController = TextEditingController(text: shift.description);
    DateTime editDate = shift.date;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final parsedHours = double.tryParse(hoursController.text.replaceAll(',', '.')) ?? 0.0;
            final calculatedWage = parsedHours * shift.hourlyRate;
            final currencyFmt = NumberFormat.currency(locale: 'cs_CZ', symbol: 'Kč', decimalDigits: 0);

            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.edit, size: 20, color: AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Upravit záznam směny',
                      style: AppTypography.headlineSm(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Datum směny', style: AppTypography.labelLaw(color: AppColors.outline)),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: editDate,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setDialogState(() => editDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.hairlineBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: AppColors.outline),
                            const SizedBox(width: 8),
                            Text(
                              CzechDateFormatter.formatFull(editDate),
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
                          '= ${currencyFmt.format(calculatedWage)}',
                          style: AppTypography.labelLaw(color: AppColors.secondary).copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: hoursController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setDialogState(() {}),
                      style: AppTypography.headlineSm(color: AppColors.onSurface),
                      decoration: const InputDecoration(
                        suffixText: 'hod',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Popis práce / Poznámka', style: AppTypography.labelLaw(color: AppColors.outline)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: descController,
                      style: AppTypography.bodyMd(color: AppColors.onSurface),
                      decoration: InputDecoration(
                        hintText: 'např. Testování release 1.2',
                        prefixIcon: Icon(Icons.notes, size: 18, color: AppColors.outline),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Zrušit'),
                ),
                FilledButton(
                  onPressed: () {
                    final h = double.tryParse(hoursController.text.replaceAll(',', '.'));
                    if (h == null || h <= 0) return;
                    final updated = shift.copyWith(
                      date: editDate,
                      hours: h,
                      description: descController.text.trim(),
                    );
                    widget.appState.updateShift(updated);
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.inverseSurface,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: AppColors.secondaryFixed),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text('Záznam směny byl úspěšně upraven.'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: const Text('Uložit změny'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteShift(WorkShift shift) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.delete, size: 20, color: AppColors.error),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Smazat záznam směny?',
                  style: AppTypography.headlineSm(color: AppColors.error),
                ),
              ),
            ],
          ),
          content: Text(
            'Opravdu chcete odstranit záznam ze dne ${CzechDateFormatter.formatShort(shift.date)} (${shift.hours.toStringAsFixed(1)} hod • ${shift.wage.toInt()} Kč)?',
            style: AppTypography.bodyMd(color: AppColors.onSurface),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Ponechat'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () {
                widget.appState.deleteShift(shift.id);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.inverseSurface,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    content: Row(
                      children: [
                        Icon(Icons.delete_sweep, color: AppColors.secondaryFixed),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text('Směna byla odstraněna z evidence.'),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: const Text('Smazat záznam'),
            ),
          ],
        );
      },
    );
  }

  void _exportAttendance() {
    final shifts = widget.appState.getShiftsForContract(widget.contract.id);
    final totalHours = shifts.fold<double>(0.0, (sum, s) => sum + s.hours);
    const exportService = AttendanceExportService();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.receipt_long, size: 22, color: AppColors.primary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Export docházky & směn',
                                style: AppTypography.headlineSm(color: AppColors.onSurface),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Přehled odpracovaných směn a hodin',
                                style: AppTypography.labelLaw(color: AppColors.outline),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Summary box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.hairlineBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Zaměstnavatel', style: AppTypography.labelLaw(color: AppColors.outline)),
                          Text(
                            widget.contract.companyName,
                            style: AppTypography.labelButton(color: AppColors.onSurface),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: AppColors.hairlineBorder,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Celkem směn / hodin', style: AppTypography.labelLaw(color: AppColors.outline)),
                        Text(
                          '${shifts.length} směn • ${totalHours.toStringAsFixed(1)} h',
                          style: AppTypography.labelButton(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Option 1: PDF Generation
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.hairlineBorder),
                ),
                tileColor: AppColors.surfaceContainerLow,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.picture_as_pdf, color: AppColors.error, size: 24),
                ),
                title: Text('Vytvořit a uložit PDF docházkový list', style: AppTypography.labelButton(color: AppColors.onSurface)),
                subtitle: Text('Strukturovaný přehled s tabulkou směn a souhrnem', style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)),
                trailing: Icon(Icons.download, color: AppColors.primary),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final pdfBytes = exportService.generatePdfBytes(widget.contract, shifts);
                  final now = DateTime.now();
                  final fileName = 'Dochazka_${widget.contract.companyName}_${now.year}_${now.month}.pdf';
                  try {
                    final file = await exportService.saveFile(fileName: fileName, bytes: pdfBytes);
                    if (!mounted) return;
                    _showExportSuccessDialog(
                      title: 'PDF docházkový list vygenerován!',
                      filePath: file.path,
                      sizeKb: (pdfBytes.length / 1024).toStringAsFixed(1),
                      format: 'PDF',
                      contract: widget.contract,
                      shifts: shifts,
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Chyba při ukládání PDF: $e')),
                    );
                  }
                },
              ),
              const SizedBox(height: 10),
              // Option 2: Form preview
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.hairlineBorder),
                ),
                tileColor: AppColors.surfaceContainerLow,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.visibility, color: AppColors.primary, size: 24),
                ),
                title: Text('Zobrazit náhled přehledu', style: AppTypography.labelButton(color: AppColors.onSurface)),
                subtitle: Text('Prohlédnout přehled směn přímo v aplikaci', style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)),
                trailing: Icon(Icons.chevron_right, color: AppColors.outline),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showAttendancePreviewModal(widget.contract, shifts);
                },
              ),
              const SizedBox(height: 10),
              // Option 3: Copy to clipboard
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.hairlineBorder),
                ),
                tileColor: AppColors.surfaceContainerLow,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.copy, color: AppColors.onSurface, size: 24),
                ),
                title: Text('Zkopírovat přehled do schránky', style: AppTypography.labelButton(color: AppColors.onSurface)),
                subtitle: Text('Pro rychlé odeslání e-mailem nebo do zprávy', style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)),
                trailing: Icon(Icons.content_copy, color: AppColors.outline),
                onTap: () {
                  Navigator.of(ctx).pop();
                  final text = exportService.generateTextSummary(widget.contract, shifts);
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.inverseSurface,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: AppColors.secondaryFixed),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text('Přehled docházky byl zkopírován do schránky.'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showExportSuccessDialog({
    required String title,
    required String filePath,
    required String sizeKb,
    required String format,
    required Contract contract,
    required List<WorkShift> shifts,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, size: 22, color: AppColors.secondary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title, style: AppTypography.headlineSm(color: AppColors.onSurface)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Soubor byl úspěšně vytvořen a uložen do úložiště zařízení:', style: AppTypography.bodySm(color: AppColors.onSurface)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.hairlineBorder),
                ),
                child: Row(
                  children: [
                    Icon(format == 'PDF' ? Icons.picture_as_pdf : Icons.table_chart, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        filePath,
                        style: AppTypography.labelLaw(color: AppColors.primary),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text('Velikost: $sizeKb KB • Přehled docházky a směn', style: AppTypography.labelLaw(color: AppColors.outline)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: filePath));
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cesta k souboru byla zkopírována do schránky.')),
                );
              },
              child: const Text('Kopírovat cestu'),
            ),
            if (format == 'PDF')
              FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _showAttendancePreviewModal(contract, shifts);
                },
                child: const Text('Zobrazit přehled'),
              )
            else
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Hotovo'),
              ),
          ],
        );
      },
    );
  }

  void _showAttendancePreviewModal(Contract contract, List<WorkShift> shifts) {
    final currencyFmt = NumberFormat.currency(locale: 'cs_CZ', symbol: 'Kč', decimalDigits: 0);
    final totalHours = shifts.fold<double>(0.0, (sum, s) => sum + s.hours);
    final totalWage = shifts.fold<double>(0.0, (sum, s) => sum + s.wage);

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: AppColors.surface,
          insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NÁHLED PŘEHLEDU DOCHÁZKY', style: AppTypography.labelLaw(color: Colors.white70)),
                          Text('Odpracované směny a nárok na odměnu', style: AppTypography.headlineSm(color: Colors.white).copyWith(fontSize: 15)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Formal Card Sheet
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.hairlineBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PŘEHLED DOCHÁZKY A ODPRACOVANÝCH HODIN',
                              style: AppTypography.headlineSm(color: AppColors.primary).copyWith(fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Přehled odpracovaných směn a odměny pro kontrolu zaměstnance',
                              style: AppTypography.labelLaw(color: AppColors.outline),
                            ),
                            const Divider(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('ZAMĚSTNAVATEL:', style: AppTypography.labelLaw(color: AppColors.outline)),
                                      Text(contract.companyName, style: AppTypography.labelButton(color: AppColors.onSurface)),
                                      const SizedBox(height: 6),
                                      Text('MÍSTO VÝKONU:', style: AppTypography.labelLaw(color: AppColors.outline)),
                                      Text(contract.workLocation.isNotEmpty ? contract.workLocation : 'Dle smlouvy', style: AppTypography.bodySm(color: AppColors.onSurface)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('PRACOVNÍ POZICE:', style: AppTypography.labelLaw(color: AppColors.outline)),
                                      Text(contract.jobTitle, style: AppTypography.labelButton(color: AppColors.onSurface)),
                                      const SizedBox(height: 6),
                                      Text('TYP PRACOVNÍHO POMĚRU:', style: AppTypography.labelLaw(color: AppColors.outline)),
                                      Text(contract.contractType.label, style: AppTypography.bodySm(color: AppColors.onSurface)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('ROZPIS ODPRACOVANÝCH SMĚN', style: AppTypography.labelLaw(color: AppColors.outline)),
                      const SizedBox(height: 8),
                      if (shifts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: Text('Zatím žádné zapsané směny.')),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.hairlineBorder),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                color: AppColors.surfaceContainerHigh,
                                child: Row(
                                  children: [
                                    const SizedBox(width: 24, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                    const Expanded(flex: 3, child: Text('Datum', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                    const Expanded(flex: 2, child: Text('Hodin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                    const Expanded(flex: 3, child: Text('Částka', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                    const Expanded(flex: 4, child: Text('Činnost', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                  ],
                                ),
                              ),
                              ...shifts.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final s = entry.value;
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: idx.isEven ? AppColors.surface : AppColors.surfaceContainerLow,
                                    border: Border(top: BorderSide(color: AppColors.hairlineBorder, width: 0.5)),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(width: 24, child: Text('${idx + 1}.', style: const TextStyle(fontSize: 11))),
                                      Expanded(flex: 3, child: Text(CzechDateFormatter.formatShort(s.date), style: const TextStyle(fontSize: 11))),
                                      Expanded(flex: 2, child: Text('${s.hours.toStringAsFixed(1)} h', style: const TextStyle(fontSize: 11))),
                                      Expanded(flex: 3, child: Text(currencyFmt.format(s.wage), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                      Expanded(flex: 4, child: Text(s.description.isNotEmpty ? s.description : '-', style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      const SizedBox(height: 14),
                      // Totals banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          runAlignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text('CELKEM ODPRACOVÁNO:', style: AppTypography.labelButton(color: AppColors.onSecondaryContainer)),
                            Text('${totalHours.toStringAsFixed(1)} hod • ${currencyFmt.format(totalWage)}', style: AppTypography.headlineSm(color: AppColors.onSecondaryContainer).copyWith(fontSize: 14)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Signatures
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('..........................................', maxLines: 1, overflow: TextOverflow.clip),
                                const SizedBox(height: 4),
                                Text('Podpis zaměstnance', style: AppTypography.labelLaw(color: AppColors.outline)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('..........................................', maxLines: 1, overflow: TextOverflow.clip),
                                const SizedBox(height: 4),
                                Text('Podpis a razítko zaměstnavatele', style: AppTypography.labelLaw(color: AppColors.outline)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Zavřít náhled'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    AppColors.isDark = isDark;
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
        final isHpp = widget.contract.contractType == ContractType.hpp;
        final monthGross = isHpp
            ? (widget.contract.monthlyGrossWage > 0
                ? widget.contract.monthlyGrossWage
                : (monthHours > 0 ? monthHours * rate : 0.0))
            : (monthHours * rate);
        final currencyFmt = NumberFormat.currency(locale: 'cs_CZ', symbol: 'Kč', decimalDigits: 0);

        final taxResult = widget.appState.taxCalculator.calculate(
          contractType: widget.contract.contractType,
          rate: isHpp ? monthGross : rate,
          hours: isHpp ? 160.0 : monthHours,
          isHourly: !isHpp,
          hasTaxDeclaration: widget.contract.hasTaxDeclaration,
          childrenCount: widget.contract.taxReliefChildrenCount,
          isStudent: widget.contract.isStudent,
          hasDisability12: widget.contract.hasDisability,
          params: widget.appState.taxParams,
        );

        final netWage = monthGross > 0 ? taxResult.netWage : 0.0;

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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
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
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondaryContainer,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
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
                            ),
                            const SizedBox(width: 8),
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
                                    Icon(Icons.location_on, size: 18, color: AppColors.primary),
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
                                    Icon(Icons.event, size: 18, color: AppColors.primary),
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
                if (widget.contract.daysRemainingInProbation != null &&
                    widget.contract.daysRemainingInProbation! <= 7 &&
                    widget.contract.daysRemainingInProbation! >= 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 22, color: AppColors.error),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hlídejte si konec zkušební doby!',
                                style: AppTypography.labelLaw(color: AppColors.onErrorContainer)
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.contract.daysRemainingInProbation == 0
                                    ? 'Zkušební doba končí dnes (§ 35 ZP). Dnes je poslední den, kdy lze pracovní poměr zrušit okamžitě.'
                                    : (widget.contract.daysRemainingInProbation == 1
                                        ? 'Zkušební doba končí zítra (zbývá 1 den). Do té doby lze poměr zrušit okamžitě.'
                                        : 'Zkušební doba končí za ${widget.contract.daysRemainingInProbation} dní (§ 35 ZP). Do té doby lze poměr zrušit okamžitě bez udání důvodu.'),
                                style: AppTypography.bodySm(color: AppColors.onErrorContainer),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                                  Icon(Icons.speed, size: 20, color: AppColors.secondary),
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
                                Icon(Icons.info, size: 16, color: AppColors.primary),
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
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_month, size: 20, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Tento měsíc',
                                      style: AppTypography.headlineSm(color: AppColors.onSurface),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: !taxResult.paysInsurance ? AppColors.secondaryContainer : AppColors.errorContainer,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                !taxResult.paysInsurance ? 'Bez odvodů' : 'Odvody aktivní',
                                style: AppTypography.labelBadge(
                                  color: !taxResult.paysInsurance ? AppColors.onSecondaryContainer : AppColors.onErrorContainer,
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
                                      currencyFmt.format(netWage),
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
                            Expanded(
                              child: Text('Hrubá odměna:', style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)),
                            ),
                            const SizedBox(width: 8),
                            Text(currencyFmt.format(monthGross), style: AppTypography.labelButton(color: AppColors.onSurface)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Sociální & Zdravotní pojištění:',
                                style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              taxResult.paysInsurance
                                  ? '${currencyFmt.format(taxResult.socialInsurance + taxResult.healthInsurance)} (11,6 %)'
                                  : '0 Kč (do limitu)',
                              style: AppTypography.labelLaw(
                                color: !taxResult.paysInsurance ? AppColors.secondary : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Uplatněné slevy na dani:',
                                style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.contract.hasTaxDeclaration
                                  ? (taxResult.appliedTaxRelief + taxResult.appliedChildRelief > 0
                                      ? '- ${currencyFmt.format(taxResult.appliedTaxRelief + taxResult.appliedChildRelief)}'
                                      : 'Růžovka uplatněna')
                                  : 'Neuplatněno (bez slevy)',
                              style: AppTypography.labelLaw(
                                color: widget.contract.hasTaxDeclaration ? AppColors.secondary : AppColors.outline,
                              ),
                            ),
                          ],
                        ),
                        if (taxResult.taxBonus > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Vyplacený daňový bonus:',
                                  style: AppTypography.bodySm(color: AppColors.secondary),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '+ ${currencyFmt.format(taxResult.taxBonus)}',
                                style: AppTypography.labelButton(color: AppColors.secondary),
                              ),
                            ],
                          ),
                        ],
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
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryFixed,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.edit_calendar, size: 18, color: AppColors.primary),
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
                                  Icon(Icons.calendar_today, size: 18, color: AppColors.outline),
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
                            decoration: InputDecoration(
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Poslední záznamy',
                                    style: AppTypography.headlineSm(color: AppColors.onSurface),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Evidence směn',
                                    style: AppTypography.labelLaw(color: AppColors.outline),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
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
                        else ...[
                          () {
                            final displayedShifts = _showAllShifts || shifts.length <= 5
                                ? shifts
                                : shifts.take(5).toList();
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: displayedShifts.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final shift = displayedShifts[index];
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
                                                Flexible(
                                                  child: Text(
                                                    CzechDateFormatter.formatShort(shift.date),
                                                    style: AppTypography.bodyMd(color: AppColors.onSurface).copyWith(fontWeight: FontWeight.bold),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  '• ${shift.hours.toStringAsFixed(shift.hours.truncateToDouble() == shift.hours ? 0 : 1)} hod',
                                                  style: AppTypography.labelLaw(color: AppColors.outline),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            currencyFmt.format(shift.wage),
                                            style: AppTypography.labelButton(color: AppColors.primary),
                                          ),
                                          const SizedBox(width: 4),
                                          IconButton(
                                            icon: Icon(Icons.edit_outlined, size: 18, color: AppColors.outline),
                                            padding: const EdgeInsets.all(4),
                                            constraints: const BoxConstraints(),
                                            splashRadius: 18,
                                            onPressed: () => _editShiftDialog(shift),
                                            tooltip: 'Upravit směnu',
                                          ),
                                          const SizedBox(width: 2),
                                          IconButton(
                                            icon: Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                            padding: const EdgeInsets.all(4),
                                            constraints: const BoxConstraints(),
                                            splashRadius: 18,
                                            onPressed: () => _confirmDeleteShift(shift),
                                            tooltip: 'Smazat směnu',
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
                            );
                          }(),
                          if (shifts.length > 5) ...[
                            const SizedBox(height: 8),
                            Center(
                              child: TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _showAllShifts = !_showAllShifts;
                                  });
                                },
                                icon: Icon(_showAllShifts ? Icons.expand_less : Icons.expand_more, size: 18),
                                label: Text(
                                  _showAllShifts
                                      ? 'Zobrazit méně (pouze 5 posledních směn)'
                                      : 'Zobrazit dalších ${shifts.length - 5} směn (celkem ${shifts.length})',
                                  style: AppTypography.labelButton(color: AppColors.primary),
                                ),
                              ),
                            ),
                          ],
                        ],
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
                  icon: Icon(Icons.archive, size: 18, color: AppColors.error),
                  label: Text(
                    widget.contract.isArchived ? 'Obnovit z archivu' : 'Ukončit nebo archivovat dohodu',
                    style: TextStyle(color: AppColors.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.errorContainer),
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
