import 'package:flutter_test/flutter_test.dart';
import 'package:paragraf_do_kapsy/models/contract_model.dart';
import 'package:paragraf_do_kapsy/services/notification_scheduler_service.dart';

void main() {
  group('NotificationSchedulerService', () {
    test('generateAlarmId produces unique deterministic IDs for different contracts and types', () {
      final id1Type1 = NotificationSchedulerService.generateAlarmId('contract_1', NotificationSchedulerService.typeContractEnd30Days);
      final id1Type2 = NotificationSchedulerService.generateAlarmId('contract_1', NotificationSchedulerService.typeContractEnd7Days);
      final id2Type1 = NotificationSchedulerService.generateAlarmId('contract_2', NotificationSchedulerService.typeContractEnd30Days);

      expect(id1Type1, isPositive);
      expect(id1Type2, isPositive);
      expect(id2Type1, isPositive);

      expect(id1Type1, isNot(equals(id1Type2)));
      expect(id1Type1, isNot(equals(id2Type1)));

      // Determinism
      final id1Type1Repeat = NotificationSchedulerService.generateAlarmId('contract_1', NotificationSchedulerService.typeContractEnd30Days);
      expect(id1Type1, equals(id1Type1Repeat));
    });

    test('getProbationEndDate calculates correct end date from probationPeriodMonths', () {
      final contract = Contract(
        id: 'test_1',
        jobTitle: 'Analytik',
        companyName: 'Firma s.r.o.',
        contractType: ContractType.hpp,
        startDate: DateTime(2026, 1, 1),
        probationPeriodMonths: 3,
      );

      final probationEnd = NotificationSchedulerService.getProbationEndDate(contract);
      expect(probationEnd, isNotNull);
      // 3 months from Jan 1 = April 1, minus 1 day = March 31
      expect(probationEnd!.year, 2026);
      expect(probationEnd.month, 3);
      expect(probationEnd.day, 31);
    });

    test('getProbationEndDate returns null if no probation period set', () {
      final contract = Contract(
        id: 'test_3',
        jobTitle: 'Brigádník',
        companyName: 'Sklad s.r.o.',
        contractType: ContractType.dpp,
        startDate: DateTime(2026, 6, 1),
        probationPeriodMonths: 0,
      );

      final probationEnd = NotificationSchedulerService.getProbationEndDate(contract);
      expect(probationEnd, isNull);
    });
  });
}
