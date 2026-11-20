import 'dart:convert';
import 'dart:io';
import 'dart:math';
import '../models/contract_model.dart';
import '../models/notification_settings_model.dart';
import '../models/work_shift_model.dart';

class BackupPayload {
  final List<Contract> contracts;
  final List<WorkShift> shifts;
  final NotificationSettings notificationSettings;
  final String themeMode;
  final DateTime exportedAt;
  final String version;

  const BackupPayload({
    required this.contracts,
    required this.shifts,
    required this.notificationSettings,
    required this.themeMode,
    required this.exportedAt,
    this.version = '1.0.0',
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'exportedAt': exportedAt.toIso8601String(),
        'themeMode': themeMode,
        'notificationSettings': notificationSettings.toJson(),
        'contracts': contracts.map((c) => c.toJson()).toList(),
        'shifts': shifts.map((s) => s.toJson()).toList(),
      };

  factory BackupPayload.fromJson(Map<String, dynamic> json) {
    final rawContracts = (json['contracts'] as List<dynamic>? ?? []);
    final rawShifts = (json['shifts'] as List<dynamic>? ?? []);
    return BackupPayload(
      version: json['version'] as String? ?? '1.0.0',
      exportedAt: DateTime.tryParse(json['exportedAt'] as String? ?? '') ??
          DateTime.now(),
      themeMode: json['themeMode'] as String? ?? 'system',
      notificationSettings: json['notificationSettings'] != null
          ? NotificationSettings.fromJson(
              json['notificationSettings'] as Map<String, dynamic>)
          : const NotificationSettings(),
      contracts: rawContracts
          .map((c) => Contract.fromJson(c as Map<String, dynamic>))
          .toList(),
      shifts: rawShifts
          .map((s) => WorkShift.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class BackupCryptoService {
  const BackupCryptoService();

  static const String fileHeader = 'PARAGRAF_BACKUP_SECURE_V1';

  /// Generates a random cryptographic salt
  List<int> _generateSalt(int length) {
    final rng = Random.secure();
    return List<int>.generate(length, (_) => rng.nextInt(256));
  }

  /// Custom 256-bit password-based key derivation function
  List<int> _deriveKey(String password, List<int> salt, int iterations) {
    final passBytes = utf8.encode(password);
    var state = List<int>.filled(32, 0);

    // Initial mix with salt and password
    for (var i = 0; i < 32; i++) {
      final s = salt[i % salt.length];
      final p = passBytes[i % passBytes.length];
      state[i] = ((s * 31 + p * 17 + i * 13) ^ 0x5A) & 0xFF;
    }

    // Iterative mixing rounds
    for (var round = 0; round < iterations; round++) {
      var acc = round & 0xFF;
      for (var i = 0; i < 32; i++) {
        final prev = state[(i + 31) % 32];
        final next = state[(i + 1) % 32];
        final p = passBytes[(round + i) % passBytes.length];
        acc = (acc + prev * 7 + state[i] * 19 + next * 11 + p + round) & 0xFFFFFFFF;
        state[i] = ((acc ^ (acc >> 8) ^ (acc >> 16) ^ (acc >> 24)) & 0xFF);
      }
    }
    return state;
  }

  /// Calculates a verification token from password and salt
  String _computeChecksum(List<int> key, List<int> salt) {
    var h1 = 0x811c9dc5;
    var h2 = 0x9e3779b9;
    for (var i = 0; i < key.length; i++) {
      h1 = ((h1 ^ key[i]) * 16777619) & 0xFFFFFFFF;
      h2 = ((h2 ^ salt[i % salt.length]) * 2166136261) & 0xFFFFFFFF;
    }
    return '${h1.toRadixString(16).padLeft(8, '0')}${h2.toRadixString(16).padLeft(8, '0')}';
  }

  /// Stream cipher to encrypt / decrypt payload bytes using derived key
  List<int> _crypt(List<int> data, List<int> key, List<int> salt) {
    final output = List<int>.filled(data.length, 0);
    var keyIndex = 0;
    var roundAcc = salt.fold<int>(0, (sum, b) => sum + b);

    for (var i = 0; i < data.length; i++) {
      roundAcc = (roundAcc * 37 + key[keyIndex] + salt[i % salt.length] + i) & 0xFFFFFFFF;
      final mask = (roundAcc ^ (roundAcc >> 8) ^ (roundAcc >> 16) ^ (roundAcc >> 24)) & 0xFF;
      output[i] = (data[i] ^ mask) & 0xFF;

      keyIndex = (keyIndex + 1) % key.length;
    }
    return output;
  }

  /// Encrypts entire backup payload with a password and returns formatted backup string
  String createEncryptedBackupString({
    required BackupPayload payload,
    required String password,
  }) {
    if (password.trim().isEmpty) {
      throw ArgumentError('Heslo pro šifrování zálohy nesmí být prázdné.');
    }

    final salt = _generateSalt(16);
    final key = _deriveKey(password, salt, 2048);
    final checksum = _computeChecksum(key, salt);

    final rawJson = jsonEncode(payload.toJson());
    final rawBytes = utf8.encode(rawJson);
    final encryptedBytes = _crypt(rawBytes, key, salt);

    final envelope = {
      'header': fileHeader,
      'createdAt': DateTime.now().toIso8601String(),
      'salt': base64Encode(salt),
      'checksum': checksum,
      'payload': base64Encode(encryptedBytes),
    };

    return jsonEncode(envelope);
  }

  /// Decrypts a backup string and returns the restored BackupPayload
  BackupPayload restoreFromEncryptedBackupString({
    required String backupString,
    required String password,
  }) {
    if (password.trim().isEmpty) {
      throw ArgumentError('Zadejte prosím heslo pro dešifrování zálohy.');
    }

    Map<String, dynamic> envelope;
    try {
      envelope = jsonDecode(backupString.trim()) as Map<String, dynamic>;
    } catch (_) {
      throw const FormatException('Záložní data nemají platný formát JSON.');
    }

    if (envelope['header'] != fileHeader) {
      throw const FormatException('Neplatný formát záložního souboru Paragraf v kapse.');
    }

    final salt = base64Decode(envelope['salt'] as String);
    final storedChecksum = envelope['checksum'] as String;
    final encryptedBytes = base64Decode(envelope['payload'] as String);

    final key = _deriveKey(password, salt, 2048);
    final computedChecksum = _computeChecksum(key, salt);

    if (storedChecksum != computedChecksum) {
      throw const FormatException('Zadané heslo není správné nebo je záložní soubor poškozen.');
    }

    final decryptedBytes = _crypt(encryptedBytes, key, salt);
    final decryptedJson = utf8.decode(decryptedBytes);
    final rawPayload = jsonDecode(decryptedJson) as Map<String, dynamic>;

    return BackupPayload.fromJson(rawPayload);
  }

  /// Saves backup string to local file
  Future<File> saveBackupFile({
    required String backupString,
    required String fileName,
  }) async {
    Directory targetDir;
    try {
      final androidDownload = Directory('/storage/emulated/0/Download');
      if (await androidDownload.exists()) {
        targetDir = androidDownload;
      } else {
        targetDir = Directory.current;
      }
    } catch (_) {
      targetDir = Directory.current;
    }

    final safeName = fileName
        .replaceAll(' ', '_')
        .replaceAll('/', '_')
        .replaceAll('\\', '_');
    final file = File('${targetDir.path}/$safeName');
    return await file.writeAsString(backupString, flush: true);
  }
}
