class CzechDateFormatter {
  CzechDateFormatter._();

  static const List<String> _monthsGenitive = [
    'ledna',
    'února',
    'března',
    'dubna',
    'května',
    'června',
    'července',
    'srpna',
    'září',
    'října',
    'listopadu',
    'prosince',
  ];

  /// Returns e.g. "28. října 2025"
  static String formatFull(DateTime date) {
    final monthName = _monthsGenitive[date.month - 1];
    return '${date.day}. $monthName ${date.year}';
  }

  /// Returns e.g. "28. 10. 2025"
  static String formatShort(DateTime date) {
    return '${date.day}. ${date.month}. ${date.year}';
  }

  /// Returns e.g. "28. 10. 2025, 14:30"
  static String formatDateTime(DateTime date) {
    final minuteStr = date.minute.toString().padLeft(2, '0');
    final hourStr = date.hour.toString().padLeft(2, '0');
    return '${date.day}. ${date.month}. ${date.year}, $hourStr:$minuteStr';
  }
}
