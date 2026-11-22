import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/feedback_ticket_model.dart';
import 'feedback_history_screen.dart';
import '../services/backup_crypto_service.dart';
import '../services/native_bridge_service.dart';
import '../services/notification_scheduler_service.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/date_formatter.dart';
import '../widgets/app_logo_action.dart';

class SettingsScreen extends StatefulWidget {
  final AppState appState;

  const SettingsScreen({super.key, required this.appState});

  static Route route(AppState appState) {
    return MaterialPageRoute(
      builder: (_) => SettingsScreen(appState: appState),
    );
  }

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BackupCryptoService _cryptoService = const BackupCryptoService();

  // Export Dialog
  void _showExportBackupDialog() {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    var obscure = true;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.shield, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Zabezpečená záloha',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Veškeré smlouvy (${widget.appState.allContracts.length}) a směny (${widget.appState.shifts.length}) budou zašifrovány heslem. Tento soubor můžete přenést na nový telefon.',
                      style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 14),
                    Text('Zadejte heslo k záloze', style: AppTypography.labelLaw(color: AppColors.outline)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: passwordController,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        hintText: 'Minimálně 4 znaky',
                        prefixIcon: const Icon(Icons.lock_outline, size: 18),
                        suffixIcon: IconButton(
                          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 18),
                          onPressed: () => setDialogState(() => obscure = !obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('Potvrďte heslo', style: AppTypography.labelLaw(color: AppColors.outline)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: confirmController,
                      obscureText: obscure,
                      decoration: const InputDecoration(
                        hintText: 'Zopakujte heslo',
                        prefixIcon: Icon(Icons.lock_reset, size: 18),
                      ),
                    ),
                    if (errorMsg != null) ...[
                      const SizedBox(height: 8),
                      Text(errorMsg!, style: TextStyle(color: AppColors.error, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Zrušit'),
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Vytvořit zálohu'),
                  onPressed: () async {
                    final p1 = passwordController.text;
                    final p2 = confirmController.text;
                    if (p1.length < 4) {
                      setDialogState(() => errorMsg = 'Heslo musí mít alespoň 4 znaky.');
                      return;
                    }
                    if (p1 != p2) {
                      setDialogState(() => errorMsg = 'Zadaná hesla se neshodují.');
                      return;
                    }

                    final payload = BackupPayload(
                      contracts: widget.appState.allContracts,
                      shifts: widget.appState.shifts,
                      notificationSettings: widget.appState.notificationSettings,
                      themeMode: widget.appState.themeMode.name,
                      exportedAt: DateTime.now(),
                    );

                    final encryptedString = _cryptoService.createEncryptedBackupString(
                      payload: payload,
                      password: p1,
                    );

                    final now = DateTime.now();
                    final fileName = 'paragraf_zaloha_${now.year}_${now.month}_${now.day}.paragraf';

                    try {
                      final file = await _cryptoService.saveBackupFile(
                        backupString: encryptedString,
                        fileName: fileName,
                      );
                      if (!mounted || !ctx.mounted) return;
                      Navigator.of(ctx).pop();
                      _showBackupCreatedModal(file.path, encryptedString);
                    } catch (e) {
                      setDialogState(() => errorMsg = 'Chyba při ukládání: $e');
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBackupCreatedModal(String filePath, String backupString) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.secondary, size: 24),
              const SizedBox(width: 8),
              const Expanded(child: Text('Záloha vytvořena!')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Zašifrovaný záložní soubor byl úspěšně vygenerován a uložen:',
                style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  filePath,
                  style: AppTypography.bodySm(color: AppColors.primary).copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Tip: Můžete si také zkopírovat celý šifrovaný kód a poslat si ho např. do zprávy pro import na novém zařízení.',
                style: AppTypography.labelLaw(color: AppColors.outline),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: backupString));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Šifrovaný kód zálohy byl zkopírován do schránky.')),
                );
              },
              child: const Text('Kopírovat kód'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hotovo'),
            ),
          ],
        );
      },
    );
  }

  // Import Dialog
  void _showImportBackupDialog() async {
    final localFiles = await NativeBridgeService.findLocalBackupFiles();
    if (!mounted) return;

    final dataController = TextEditingController();
    final passwordController = TextEditingController();
    var obscure = true;
    String? selectedFileName;
    String? errorMsg;
    var showManualInput = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.settings_backup_restore, color: AppColors.secondary, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Obnovit data ze zálohy',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vyberte záložní soubor (.paragraf) ze zařízení a zadejte heslo nastavené při exportu.',
                      style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 14),

                    // Primary Button: Native Android File Picker
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: () async {
                          setDialogState(() => errorMsg = null);
                          final content = await NativeBridgeService.pickBackupFileContent();
                          if (content != null && content.isNotEmpty) {
                            setDialogState(() {
                              dataController.text = content;
                              selectedFileName = 'Vybraný soubor ze zařízení';
                            });
                          }
                        },
                        icon: const Icon(Icons.folder_open, size: 20),
                        label: const Text('Vybrat soubor ze zařízení'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),

                    if (selectedFileName != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: AppColors.secondary, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                selectedFileName!,
                                style: AppTypography.labelButton(color: AppColors.onSurface),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Found local backup files in Downloads
                    if (localFiles.isNotEmpty && selectedFileName == null) ...[
                      const SizedBox(height: 14),
                      Text('NALEZENÉ ZÁLOHY V TELEFONU:', style: AppTypography.labelLaw(color: AppColors.outline)),
                      const SizedBox(height: 6),
                      ...localFiles.take(3).map((f) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () async {
                              try {
                                final text = await f.file.readAsString();
                                setDialogState(() {
                                  dataController.text = text;
                                  selectedFileName = f.name;
                                  errorMsg = null;
                                });
                              } catch (e) {
                                setDialogState(() => errorMsg = 'Chyba při čtení souboru: $e');
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.hairlineBorder),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.description, size: 18, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(f.name, style: AppTypography.labelButton(color: AppColors.onSurface), overflow: TextOverflow.ellipsis),
                                        Text('${f.formattedSize} • ${CzechDateFormatter.formatShort(f.modifiedAt)}', style: AppTypography.labelLaw(color: AppColors.outline)),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.outline),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 14),
                    Text('Heslo k záloze', style: AppTypography.labelLaw(color: AppColors.outline)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: passwordController,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        hintText: 'Zadejte heslo',
                        prefixIcon: const Icon(Icons.lock_outline, size: 18),
                        suffixIcon: IconButton(
                          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 18),
                          onPressed: () => setDialogState(() => obscure = !obscure),
                        ),
                      ),
                    ),

                    // Manual Paste Toggle
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => setDialogState(() => showManualInput = !showManualInput),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Nebo vložit kód zálohy ručně', style: AppTypography.labelLaw(color: AppColors.primary)),
                          Icon(showManualInput ? Icons.expand_less : Icons.expand_more, size: 18, color: AppColors.primary),
                        ],
                      ),
                    ),
                    if (showManualInput) ...[
                      const SizedBox(height: 6),
                      TextField(
                        controller: dataController,
                        maxLines: 3,
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Vložte zašifrovaný text...',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.paste, size: 18),
                            onPressed: () async {
                              final c = await Clipboard.getData(Clipboard.kTextPlain);
                              if (c?.text != null) {
                                setDialogState(() {
                                  dataController.text = c!.text!;
                                  selectedFileName = 'Vloženo ze schránky';
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],

                    if (errorMsg != null) ...[
                      const SizedBox(height: 8),
                      Text(errorMsg!, style: TextStyle(color: AppColors.error, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Zrušit'),
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.lock_open, size: 18),
                  label: const Text('Dešifrovat a načíst'),
                  onPressed: () {
                    final raw = dataController.text.trim();
                    final pass = passwordController.text;
                    if (raw.isEmpty) {
                      setDialogState(() => errorMsg = 'Vyberte soubor nebo vložte data zálohy.');
                      return;
                    }
                    if (pass.isEmpty) {
                      setDialogState(() => errorMsg = 'Zadejte prosím heslo.');
                      return;
                    }

                    try {
                      final payload = _cryptoService.restoreFromEncryptedBackupString(
                        backupString: raw,
                        password: pass,
                      );
                      Navigator.of(ctx).pop();
                      _showConfirmRestoreModal(payload);
                    } catch (e) {
                      setDialogState(() => errorMsg = e.toString().replaceAll('Exception: ', '').replaceAll('FormatException: ', ''));
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showConfirmRestoreModal(BackupPayload payload) {
    var replace = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Potvrdit obnovení dat'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle, size: 18, color: AppColors.secondary),
                            const SizedBox(width: 6),
                            Text('Úspěšně dešifrováno', style: AppTypography.labelButton(color: AppColors.secondary)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('• Počet nalezených smluv: ${payload.contracts.length}', style: AppTypography.bodySm(color: AppColors.onSurface)),
                        Text('• Počet evidovaných směn: ${payload.shifts.length}', style: AppTypography.bodySm(color: AppColors.onSurface)),
                        Text('• Datum vytvoření: ${CzechDateFormatter.formatShort(payload.exportedAt)}', style: AppTypography.bodySm(color: AppColors.onSurface)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Způsob nahrání dat:', style: AppTypography.labelLaw(color: AppColors.outline)),
                  RadioListTile<bool>(
                    value: false,
                    groupValue: replace,
                    title: const Text('Sloučit se stávajícími daty'),
                    subtitle: const Text('Ponechá aktuální data a doplní chybějící.'),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setDialogState(() => replace = val!),
                  ),
                  RadioListTile<bool>(
                    value: true,
                    groupValue: replace,
                    title: const Text('Přepsat všechna data'),
                    subtitle: const Text('Nahradí aktuální smlouvy i směny těmi ze zálohy.'),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setDialogState(() => replace = val!),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Zrušit'),
                ),
                FilledButton(
                  onPressed: () async {
                    await widget.appState.restoreBackup(
                      newContracts: payload.contracts,
                      newShifts: payload.shifts,
                      replace: replace,
                    );
                    if (!mounted || !ctx.mounted) return;
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
                            Expanded(
                              child: Text(
                                'Data byla úspěšně obnovena (${payload.contracts.length} smluv, ${payload.shifts.length} směn).',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: const Text('Obnovit data'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Bug Report Dialog
  Future<void> _showBugReportDialog() async {
    final isOnlineInitial = await NativeBridgeService.isInternetConnected();
    if (!mounted) return;

    if (!isOnlineInitial) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Zařízení je offline',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pro odeslání podnětu nebo nahlášení chyby aplikace je nutné mít aktivní internetové připojení.',
                style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.hairlineBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppColors.outline),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Zkontrolujte připojení k Wi-Fi nebo mobilním datům a zkuste to znovu.',
                        style: AppTypography.labelLaw(color: AppColors.outline),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Zavřít'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                _showBugReportDialog();
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Zkusit znovu'),
            ),
          ],
        ),
      );
      return;
    }

    final titleController = TextEditingController();
    final descController = TextEditingController();
    var category = 'Chyba v aplikaci';
    var includeDiagnostics = true;
    var isCheckingConnection = false;
    var isSubmitting = false;
    var isOnline = true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.tertiaryFixed.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.bug_report, color: AppColors.tertiaryContainer, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Nahlásit chybu / podnět',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isOnline) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.errorContainer,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Zařízení ztratilo připojení k internetu. Odeslání není možné.',
                                style: AppTypography.bodySm(color: AppColors.onErrorContainer),
                              ),
                            ),
                            IconButton(
                              icon: isCheckingConnection
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.refresh, size: 18),
                              onPressed: isCheckingConnection
                                  ? null
                                  : () async {
                                      setDialogState(() => isCheckingConnection = true);
                                      final check = await NativeBridgeService.isInternetConnected();
                                      setDialogState(() {
                                        isOnline = check;
                                        isCheckingConnection = false;
                                      });
                                    },
                            ),
                          ],
                        ),
                      ),
                    ],
                    Text(
                      'Vaše zpětná vazba pomáhá vylepšovat aplikaci pro všechny uživatele.',
                      style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    Text('Kategorie', style: AppTypography.labelLaw(color: AppColors.outline)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: category,
                      items: const [
                        DropdownMenuItem(value: 'Chyba v aplikaci', child: Text('Chyba v aplikaci')),
                        DropdownMenuItem(value: 'Nesprávný výpočet mzdy', child: Text('Nesprávný výpočet mzdy')),
                        DropdownMenuItem(value: 'Návrh na vylepšení', child: Text('Návrh na vylepšení')),
                        DropdownMenuItem(value: 'Jiné', child: Text('Jiné')),
                      ],
                      onChanged: (val) => setDialogState(() => category = val!),
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    ),
                    const SizedBox(height: 10),
                    Text('Předmět / Stručný název', style: AppTypography.labelLaw(color: AppColors.outline)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(hintText: 'např. Chybné zobrazení u DPP'),
                    ),
                    const SizedBox(height: 10),
                    Text('Popis problému', style: AppTypography.labelLaw(color: AppColors.outline)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: const InputDecoration(hintText: 'Popište podrobněji, co se stalo...'),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: includeDiagnostics,
                      onChanged: (val) => setDialogState(() => includeDiagnostics = val!),
                      title: const Text('Připojit diagnostická data', style: TextStyle(fontSize: 13)),
                      subtitle: const Text('Verze aplikace 1.0.0, typ zařízení', style: TextStyle(fontSize: 11)),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Zavřít'),
                ),
                FilledButton.icon(
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send, size: 16),
                  label: const Text('Odeslat'),
                  onPressed: (!isOnline || isSubmitting)
                      ? null
                      : () async {
                          final t = titleController.text.trim();
                          final d = descController.text.trim();
                          if (t.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Vyplňte prosím předmět hlášení.')),
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);
                          final stillOnline = await NativeBridgeService.isInternetConnected();
                          if (!stillOnline) {
                            setDialogState(() {
                              isOnline = false;
                              isSubmitting = false;
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                  content: const Row(
                                    children: [
                                      Icon(Icons.wifi_off, color: Colors.white, size: 18),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text('Zařízení ztratilo připojení k internetu. Podnět nelze odeslat.'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            return;
                          }

                          if (!ctx.mounted) return;
                          Navigator.of(ctx).pop();
                          final reportId = 'POD-${(DateTime.now().millisecondsSinceEpoch % 100000).toString().padLeft(5, '0')}';

                          final newTicket = FeedbackTicket(
                            id: reportId,
                            title: t,
                            category: category,
                            description: d.isNotEmpty ? d : 'Bez doplňujícího popisu.',
                            createdAt: DateTime.now(),
                            status: TicketStatus.submitted,
                            includeDiagnostics: includeDiagnostics,
                            messages: [
                              TicketMessage(
                                id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
                                sender: 'admin',
                                senderName: 'Podpora Paragraf v kapse',
                                text: 'Dobrý den, děkujeme za nahlášení. Váš podnět byl zaevidován pod číslem #$reportId a předán k prověření administrátorovi. O dalším postupu vás budeme informovat zde v historii podnětu.',
                                timestamp: DateTime.now(),
                              ),
                            ],
                          );

                          widget.appState.addFeedbackTicket(newTicket);

                          if (context.mounted) {
                            showDialog(
                              context: context,
                              builder: (c) => AlertDialog(
                                backgroundColor: AppColors.surface,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: AppColors.secondary),
                                    const SizedBox(width: 8),
                                    const Text('Podnět zaevidován'),
                                  ],
                                ),
                                content: Text(
                                  'Děkujeme za váš podnět! Hlášení bylo uloženo s identifikačním kódem #$reportId. Můžete sledovat stav řešení a budoucí zprávy od administrátora v historii podnětů.',
                                  style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(c).pop(),
                                    child: const Text('Zavřít'),
                                  ),
                                  FilledButton.icon(
                                    onPressed: () {
                                      Navigator.of(c).pop();
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => FeedbackDetailScreen(
                                            appState: widget.appState,
                                            ticketId: reportId,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.forum, size: 16),
                                    label: const Text('Zobrazit podnět'),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showTestNotification() async {
    const title = 'Zbývá 7 dní zkušební doby';
    const body = 'U smlouvy Innovatech a.s. brzy skončí 3měsíční zkušební doba dle § 35 ZP.';

    // Check / Request runtime permission first
    final hasPerm = await NativeBridgeService.requestNotificationPermission();

    final sent = await NativeBridgeService.showSystemNotification(
      title: title,
      body: body,
    );

    if (!mounted) return;
    if (!hasPerm && !sent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.errorContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.onErrorContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Oznámení jsou v systému vypnuta. Povolte je v nastavení telefonu.',
                  style: AppTypography.bodySm(color: AppColors.onErrorContainer),
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'Otevřít',
            textColor: AppColors.onErrorContainer,
            onPressed: NativeBridgeService.openNotificationSettings,
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.inverseSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            Icon(Icons.notifications_active, color: AppColors.secondaryFixed),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Upozornění bylo odesláno do horní lišty telefonu!',
                style: AppTypography.bodySm(color: AppColors.inverseOnSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scheduleClosedAppTestNotification() async {
    final hasPerm = await NativeBridgeService.requestNotificationPermission();
    if (!hasPerm) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.errorContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.onErrorContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Povolte prosím oprávnění k oznámením v nastavení.',
                  style: AppTypography.bodySm(color: AppColors.onErrorContainer),
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'Nastavení',
            textColor: AppColors.onErrorContainer,
            onPressed: NativeBridgeService.openNotificationSettings,
          ),
        ),
      );
      return;
    }

    final scheduled = await NotificationSchedulerService.scheduleTestAlarm(seconds: 10);
    if (!mounted) return;

    if (scheduled) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.alarm_on, color: AppColors.secondary, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Test na pozadí připraven',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upozornění je naplánováno v systému Android za 10 sekund.',
                style: AppTypography.bodySm(color: AppColors.onSurface),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline, color: AppColors.secondary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nyní můžete aplikaci ihned zcela zavřít nebo shodit ze seznamu spuštěných aplikací. Systém telefon probudí a notifikaci spolehlivě zobrazí.',
                        style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Rozumím, vyzkouším'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.errorContainer,
          content: Text(
            'Nepodařilo se naplánovat testovací upozornění.',
            style: TextStyle(color: AppColors.onErrorContainer),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    AppColors.isDark = isDark;
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final currentTheme = widget.appState.themeMode;
        final notif = widget.appState.notificationSettings;

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            title: Text(
              'Nastavení aplikace',
              style: AppTypography.headlineSm(color: AppColors.onSurface),
            ),
            actions: const [
              AppLogoAction(),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SECTION 1: Appearance & Theme
                Text('VZHLED A REŽIM ZOBRAZENÍ', style: AppTypography.labelLaw(color: AppColors.outline)),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.palette_outlined, size: 20, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text('Tmavý režim', style: AppTypography.headlineSm(color: AppColors.onSurface)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Vyberte požadovaný barevný profil pro pohodlné používání ve dne i v noci.',
                          style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              avatar: const Icon(Icons.light_mode, size: 16),
                              label: const Text('Světlý'),
                              selected: currentTheme == ThemeMode.light,
                              onSelected: (_) => widget.appState.setThemeMode(ThemeMode.light),
                            ),
                            ChoiceChip(
                              avatar: const Icon(Icons.dark_mode, size: 16),
                              label: const Text('Tmavý'),
                              selected: currentTheme == ThemeMode.dark,
                              onSelected: (_) => widget.appState.setThemeMode(ThemeMode.dark),
                            ),
                            ChoiceChip(
                              avatar: const Icon(Icons.brightness_auto, size: 16),
                              label: const Text('Podle systému'),
                              selected: currentTheme == ThemeMode.system,
                              onSelected: (_) => widget.appState.setThemeMode(ThemeMode.system),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // SECTION 2: Notifications
                Text('UPOZORNĚNÍ A NOTIFIKACE', style: AppTypography.labelLaw(color: AppColors.outline)),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile(
                          value: notif.enabled,
                          onChanged: (val) async {
                            if (val) {
                              final granted = await NativeBridgeService.requestNotificationPermission();
                              if (!granted) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: AppColors.errorContainer,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      content: Row(
                                        children: [
                                          Icon(Icons.warning_amber_rounded, color: AppColors.onErrorContainer),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Pro zapnutí oznámení povolte oprávnění v systému Android.',
                                              style: AppTypography.bodySm(color: AppColors.onErrorContainer),
                                            ),
                                          ),
                                        ],
                                      ),
                                      action: SnackBarAction(
                                        label: 'Nastavení',
                                        textColor: AppColors.onErrorContainer,
                                        onPressed: NativeBridgeService.openNotificationSettings,
                                      ),
                                    ),
                                  );
                                }
                                return;
                              }
                            }
                            widget.appState.setNotificationSettings(notif.copyWith(enabled: val));
                          },
                          contentPadding: EdgeInsets.zero,
                          title: Row(
                            children: [
                              Icon(Icons.notifications_outlined, size: 20, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text('Povolit oznámení', style: AppTypography.headlineSm(color: AppColors.onSurface)),
                            ],
                          ),
                          subtitle: Text(
                            'Včasné upozornění před klíčovými termíny smluv.',
                            style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                          ),
                        ),
                        if (notif.enabled) ...[
                          const Divider(),
                          SwitchListTile(
                            value: notif.contractEndReminder,
                            onChanged: (val) {
                              widget.appState.setNotificationSettings(notif.copyWith(contractEndReminder: val));
                            },
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Konec smlouvy na dobu určitou', style: TextStyle(fontSize: 14)),
                            subtitle: const Text('Upozornit 7 dní a 30 dní před vypršením', style: TextStyle(fontSize: 12)),
                          ),
                          SwitchListTile(
                            value: notif.probationEndReminder,
                            onChanged: (val) {
                              widget.appState.setNotificationSettings(notif.copyWith(probationEndReminder: val));
                            },
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Uplynutí zkušební doby (§ 35 ZP)', style: TextStyle(fontSize: 14)),
                            subtitle: const Text('Upozornit 7 dní před skončením zkušební doby', style: TextStyle(fontSize: 12)),
                          ),
                          SwitchListTile(
                            value: notif.hourLimitReminder,
                            onChanged: (val) {
                              widget.appState.setNotificationSettings(notif.copyWith(hourLimitReminder: val));
                            },
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Limit 300 hodin u DPP (§ 75 ZP)', style: TextStyle(fontSize: 14)),
                            subtitle: const Text('Upozornit při dosažení 80 % a 95 % ročního limitu', style: TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.outlineVariant),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.offline_pin, size: 20, color: AppColors.secondary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '100% offline & spolehlivé i při vypnuté aplikaci',
                                        style: AppTypography.labelLaw(color: AppColors.primary),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Termíny smluv jsou registrovány v systémovém plánovači Android (AlarmManager). Telefon vás upozorní i při zcela zavřené aplikaci nebo po restartu telefonu bez potřeby internetu či externích serverů.',
                                        style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _showTestNotification,
                                icon: const Icon(Icons.notifications_active, size: 16),
                                label: const Text('Okamžitý test'),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: _scheduleClosedAppTestNotification,
                                icon: const Icon(Icons.alarm, size: 16),
                                label: const Text('Test při vypnuté aplikaci (za 10 s)'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // SECTION 3: Backup & Transfer
                Text('ZABEZPEČENÁ ZÁLOHA A PŘENOS DAT', style: AppTypography.labelLaw(color: AppColors.outline)),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.shield_outlined, size: 20, color: AppColors.secondary),
                            const SizedBox(width: 8),
                            Text('Šifrované zálohování', style: AppTypography.headlineSm(color: AppColors.onSurface)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Když si koupíte nový telefon, můžete pomocí šifrovaného souboru chráněného vaším heslem jednoduše převést veškeré smlouvy a evidenci směn.',
                          style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _showExportBackupDialog,
                                icon: const Icon(Icons.download, size: 16),
                                label: const Text('Zálohovat (export)'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _showImportBackupDialog,
                                icon: const Icon(Icons.upload, size: 16),
                                label: const Text('Obnovit (import)'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // SECTION 4: Bug Report & Feedback
                Text('PODPORA A ZPĚTNÁ VAZBA', style: AppTypography.labelLaw(color: AppColors.outline)),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.bug_report_outlined, color: AppColors.primary, size: 22),
                          ),
                          title: Text('Nahlásit chybu aplikace / podnět', style: AppTypography.labelButton(color: AppColors.onSurface)),
                          subtitle: Text('Narazili jste na problém nebo nesprávný výpočet? Napište nám.', style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)),
                          trailing: Icon(Icons.chevron_right, color: AppColors.outline),
                          onTap: _showBugReportDialog,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryContainer.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.forum_outlined, color: AppColors.secondary, size: 22),
                          ),
                          title: Text('Historie podnětů a odpovědi', style: AppTypography.labelButton(color: AppColors.onSurface)),
                          subtitle: Text(
                            widget.appState.feedbackTickets.isEmpty
                                ? 'Zatím nemáte žádné odeslané podněty.'
                                : 'Evidováno ${widget.appState.feedbackTickets.length} ${widget.appState.feedbackTickets.length == 1 ? "podnět" : (widget.appState.feedbackTickets.length < 5 ? "podněty" : "podnětů")} (stav a zprávy podpory)',
                            style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.appState.feedbackTickets.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '${widget.appState.feedbackTickets.length}',
                                    style: AppTypography.labelBadge(color: AppColors.onPrimary),
                                  ),
                                ),
                              const SizedBox(width: 4),
                              Icon(Icons.chevron_right, color: AppColors.outline),
                            ],
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              FeedbackHistoryScreen.route(widget.appState),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // SECTION 5: About App & Privacy
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lock_clock, size: 18, color: AppColors.secondary),
                          const SizedBox(width: 6),
                          Text('100% Offline & Bezpečné', style: AppTypography.labelButton(color: AppColors.secondary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Paragraf v kapse v1.0.0. Aplikace ukládá data výhradně do paměti tohoto telefonu. Aplikace má informativní charakter a nenahrazuje právní radu advokáta.',
                        style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
