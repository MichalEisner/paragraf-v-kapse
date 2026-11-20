import 'dart:io';
import 'package:flutter/services.dart';

class LocalBackupFileInfo {
  final File file;
  final String name;
  final DateTime modifiedAt;
  final int sizeBytes;

  const LocalBackupFileInfo({
    required this.file,
    required this.name,
    required this.modifiedAt,
    required this.sizeBytes,
  });

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
  }
}

class NativeBridgeService {
  static const MethodChannel _channel = MethodChannel('paragraf/native');

  /// Checks whether device has active internet access (via native ConnectivityManager or DNS lookup)
  static Future<bool> isInternetConnected() async {
    try {
      final res = await _channel.invokeMethod<bool>('isOnline');
      if (res != null) return res;
    } catch (_) {}

    // Fallback: Dart socket DNS lookup
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Checks if system notifications are currently enabled
  static Future<bool> areNotificationsEnabled() async {
    try {
      final res = await _channel.invokeMethod<bool>('areNotificationsEnabled');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Requests Android 13+ (API 33+) POST_NOTIFICATIONS runtime permission from the user
  static Future<bool> requestNotificationPermission() async {
    try {
      final res = await _channel.invokeMethod<bool>('requestNotificationPermission');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the system notification settings for this application
  static Future<void> openNotificationSettings() async {
    try {
      await _channel.invokeMethod<bool>('openNotificationSettings');
    } catch (_) {}
  }

  /// Displays real native Android notification in status bar and drawer
  static Future<bool> showSystemNotification({
    required String title,
    required String body,
  }) async {
    try {
      final res = await _channel.invokeMethod<bool>('showNotification', {
        'title': title,
        'body': body,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens native Android system file picker (ACTION_OPEN_DOCUMENT) and returns file content
  static Future<String?> pickBackupFileContent() async {
    try {
      final content = await _channel.invokeMethod<String>('pickBackupFile');
      return content;
    } catch (_) {
      return null;
    }
  }

  /// Searches Android Downloads directory for any existing .paragraf backup files
  static Future<List<LocalBackupFileInfo>> findLocalBackupFiles() async {
    final results = <LocalBackupFileInfo>[];
    final candidateDirs = <Directory>[
      Directory('/storage/emulated/0/Download'),
      Directory.current,
    ];

    for (final dir in candidateDirs) {
      try {
        if (await dir.exists()) {
          final entities = dir.listSync();
          for (final entity in entities) {
            if (entity is File && entity.path.toLowerCase().endsWith('.paragraf')) {
              try {
                final stat = await entity.stat();
                final name = entity.path.split(RegExp(r'[/\\]')).last;
                results.add(LocalBackupFileInfo(
                  file: entity,
                  name: name,
                  modifiedAt: stat.modified,
                  sizeBytes: stat.size,
                ));
              } catch (_) {}
            }
          }
        }
      } catch (_) {}
    }

    results.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return results;
  }
}
