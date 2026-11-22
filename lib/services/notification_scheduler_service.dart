import '../models/contract_model.dart';
import '../state/app_state.dart';
import '../utils/date_formatter.dart';
import 'native_bridge_service.dart';

class NotificationSchedulerService {
  static const int typeContractEnd30Days = 1;
  static const int typeContractEnd7Days = 2;
  static const int typeContractEnd1Day = 3;
  static const int typeProbation7Days = 4;
  static const int typeProbation1Day = 5;
  static const int testNotificationId = 88888;

  /// Deterministically creates a positive 32-bit integer ID for an alarm
  static int generateAlarmId(String contractId, int typeOffset) {
    final base = (contractId.hashCode.abs() % 10000) * 10;
    return base + (typeOffset % 10);
  }

  /// Calculates the end date of probation period if applicable
  static DateTime? getProbationEndDate(Contract contract) {
    return contract.probationEndDate;
  }

  /// Schedules all relevant contract and probation reminders using native Android AlarmManager.
  /// Works 100% offline and fires even when the app is completely turned off or phone reboots.
  static Future<void> syncAllReminders(AppState appState) async {
    final settings = appState.notificationSettings;

    // If notifications are disabled globally, cancel all scheduled native alarms
    if (!settings.enabled) {
      await NativeBridgeService.cancelAllBackgroundAlarms();
      return;
    }

    final now = DateTime.now();

    for (final contract in appState.contracts) {
      // 1. Contract End Date Reminders (for fixed-term contracts)
      if (settings.contractEndReminder && contract.endDate != null) {
        final end = contract.endDate!;

        // 30 days before at 09:00 AM
        final date30 = end.subtract(const Duration(days: 30));
        final trigger30 = DateTime(date30.year, date30.month, date30.day, 9, 0);
        if (trigger30.isAfter(now)) {
          await NativeBridgeService.scheduleBackgroundAlarm(
            id: generateAlarmId(contract.id, typeContractEnd30Days),
            scheduledDate: trigger30,
            title: 'Konec smlouvy za 30 dní (${contract.jobTitle})',
            body: 'Smlouva na dobu určitou u \'${contract.companyName}\' vyprší dne ${CzechDateFormatter.formatShort(end)}. Nezapomeňte včas projednat prodloužení.',
            contractId: contract.id,
          );
        }

        // 7 days before at 09:00 AM
        final date7 = end.subtract(const Duration(days: 7));
        final trigger7 = DateTime(date7.year, date7.month, date7.day, 9, 0);
        if (trigger7.isAfter(now)) {
          await NativeBridgeService.scheduleBackgroundAlarm(
            id: generateAlarmId(contract.id, typeContractEnd7Days),
            scheduledDate: trigger7,
            title: 'Konec smlouvy za 7 dní! (${contract.jobTitle})',
            body: 'Smlouva u \'${contract.companyName}\' končí za týden (${CzechDateFormatter.formatShort(end)}). Zkontrolujte si předání agendy a zápočtový list.',
            contractId: contract.id,
          );
        }

        // 1 day before at 09:00 AM
        final date1 = end.subtract(const Duration(days: 1));
        final trigger1 = DateTime(date1.year, date1.month, date1.day, 9, 0);
        if (trigger1.isAfter(now)) {
          await NativeBridgeService.scheduleBackgroundAlarm(
            id: generateAlarmId(contract.id, typeContractEnd1Day),
            scheduledDate: trigger1,
            title: 'Smlouva končí zítra! (${contract.jobTitle})',
            body: 'Zítra (${CzechDateFormatter.formatShort(end)}) je poslední den trvání smlouvy u \'${contract.companyName}\'.',
            contractId: contract.id,
          );
        }
      } else {
        // Cancel contract end reminders for this contract if disabled or open-ended
        await NativeBridgeService.cancelBackgroundAlarm(generateAlarmId(contract.id, typeContractEnd30Days));
        await NativeBridgeService.cancelBackgroundAlarm(generateAlarmId(contract.id, typeContractEnd7Days));
        await NativeBridgeService.cancelBackgroundAlarm(generateAlarmId(contract.id, typeContractEnd1Day));
      }

      // 2. Probation Period Reminders (§ 35 ZP)
      final probationEnd = getProbationEndDate(contract);
      if (settings.probationEndReminder && probationEnd != null) {
        // 7 days before at 09:00 AM
        final pDate7 = probationEnd.subtract(const Duration(days: 7));
        final pTrigger7 = DateTime(pDate7.year, pDate7.month, pDate7.day, 9, 0);
        if (pTrigger7.isAfter(now)) {
          await NativeBridgeService.scheduleBackgroundAlarm(
            id: generateAlarmId(contract.id, typeProbation7Days),
            scheduledDate: pTrigger7,
            title: 'Zkušební doba končí za 7 dní (${contract.jobTitle})',
            body: 'Zkušební doba u \'${contract.companyName}\' končí ${CzechDateFormatter.formatShort(probationEnd)}. Poté nabýváte plnou zákonnou ochranu s 2měsíční výpovědní dobou dle § 51 ZP.',
            contractId: contract.id,
          );
        }

        // 1 day before at 09:00 AM
        final pDate1 = probationEnd.subtract(const Duration(days: 1));
        final pTrigger1 = DateTime(pDate1.year, pDate1.month, pDate1.day, 9, 0);
        if (pTrigger1.isAfter(now)) {
          await NativeBridgeService.scheduleBackgroundAlarm(
            id: generateAlarmId(contract.id, typeProbation1Day),
            scheduledDate: pTrigger1,
            title: 'Zítra končí zkušební doba! (${contract.jobTitle})',
            body: 'Poslední den zkušební doby pro \'${contract.jobTitle}\'. Od zítřka vás chrání standardní zákoník práce.',
            contractId: contract.id,
          );
        }
      } else {
        // Cancel probation reminders for this contract if disabled
        await NativeBridgeService.cancelBackgroundAlarm(generateAlarmId(contract.id, typeProbation7Days));
        await NativeBridgeService.cancelBackgroundAlarm(generateAlarmId(contract.id, typeProbation1Day));
      }

      // 3. DPP 300-hour Limit Verification (§ 75 ZP)
      if (settings.hourLimitReminder && contract.contractType == ContractType.dpp) {
        final totalHours = appState.getTotalHoursForContract(contract.id);
        if (totalHours >= 300) {
          await NativeBridgeService.showSystemNotification(
            title: 'Překročen zákonný limit 300 h! (${contract.jobTitle})',
            body: 'Evidováno ${totalHours.toInt()} h. Práce nad 300 h/rok na DPP je v přímém rozporu se zákoníkem práce (§ 75 ZP).',
          );
        } else if (totalHours >= 285) {
          // 95% critical limit
          await NativeBridgeService.showSystemNotification(
            title: 'Kritické vyčerpání DPP (95 %)! (${contract.jobTitle})',
            body: 'U dohodnuté DPP zbývá pouze ${(300 - totalHours).toInt()} hodin do vyčerpání ročního zákonného stropu 300 h.',
          );
        } else if (totalHours >= 240) {
          // 80% warning limit
          await NativeBridgeService.showSystemNotification(
            title: 'Upozornění na limit DPP (80 %)',
            body: 'U smlouvy \'${contract.jobTitle}\' máte odpracováno ${totalHours.toInt()} z 300 h. Zbývá ${(300 - totalHours).toInt()} h.',
          );
        }
      }
    }
  }

  /// Schedules a test background alarm in [seconds] seconds.
  /// Allows the user to schedule, kill the app immediately, and verify that the notification fires offline.
  static Future<bool> scheduleTestAlarm({int seconds = 10}) async {
    final scheduledDate = DateTime.now().add(Duration(seconds: seconds));
    return await NativeBridgeService.scheduleBackgroundAlarm(
      id: testNotificationId,
      scheduledDate: scheduledDate,
      title: 'Paragraf v kapse: Test na pozadí',
      body: 'Funguje to! Toto oznámení dorazilo i při vypnuté aplikaci pomocí systémového plánovače Androidu.',
    );
  }
}
