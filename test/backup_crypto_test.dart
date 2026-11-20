import 'package:flutter_test/flutter_test.dart';
import 'package:paragraf_do_kapsy/models/contract_model.dart';
import 'package:paragraf_do_kapsy/models/notification_settings_model.dart';
import 'package:paragraf_do_kapsy/models/work_shift_model.dart';
import 'package:paragraf_do_kapsy/services/backup_crypto_service.dart';

void main() {
  group('BackupCryptoService Tests', () {
    const cryptoService = BackupCryptoService();

    final testContracts = [
      Contract(
        id: 'c1',
        companyName: 'Test Firma s.r.o.',
        jobTitle: 'Vyvojar',
        contractType: ContractType.dpp,
        hourlyWage: 300,
        startDate: DateTime(2026, 1, 1),
      ),
    ];

    final testShifts = [
      WorkShift(
        id: 's1',
        contractId: 'c1',
        date: DateTime(2026, 1, 15),
        hours: 8,
        description: 'Implementace modulu',
        hourlyRate: 300,
      ),
    ];

    test('Encrypt and decrypt with correct password succeeds', () {
      final payload = BackupPayload(
        contracts: testContracts,
        shifts: testShifts,
        notificationSettings: const NotificationSettings(),
        themeMode: 'dark',
        exportedAt: DateTime.now(),
      );

      const password = 'mojeBezpecneHeslo123';
      final encrypted = cryptoService.createEncryptedBackupString(
        payload: payload,
        password: password,
      );

      expect(encrypted.contains('PARAGRAF_BACKUP_SECURE_V1'), isTrue);
      expect(encrypted.contains('Test Firma s.r.o.'), isFalse); // Should be encrypted

      final restored = cryptoService.restoreFromEncryptedBackupString(
        backupString: encrypted,
        password: password,
      );

      expect(restored.contracts.length, equals(1));
      expect(restored.contracts.first.companyName, equals('Test Firma s.r.o.'));
      expect(restored.shifts.length, equals(1));
      expect(restored.shifts.first.hours, equals(8.0));
      expect(restored.themeMode, equals('dark'));
    });

    test('Decrypt with wrong password throws FormatException', () {
      final payload = BackupPayload(
        contracts: testContracts,
        shifts: testShifts,
        notificationSettings: const NotificationSettings(),
        themeMode: 'system',
        exportedAt: DateTime.now(),
      );

      final encrypted = cryptoService.createEncryptedBackupString(
        payload: payload,
        password: 'spravneHeslo',
      );

      expect(
        () => cryptoService.restoreFromEncryptedBackupString(
          backupString: encrypted,
          password: 'spatneHeslo',
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
