import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contract_model.dart';
import '../models/feedback_ticket_model.dart';
import '../models/notification_settings_model.dart';
import '../models/work_shift_model.dart';

class LocalStorageService {
  static const String _contractsKey = 'paragraf_contracts';
  static const String _shiftsKey = 'paragraf_shifts';
  static const String _themeModeKey = 'paragraf_theme_mode';
  static const String _notificationSettingsKey = 'paragraf_notifications';
  static const String _feedbackTicketsKey = 'paragraf_feedback_tickets';

  Future<ThemeMode> loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = prefs.getString(_themeModeKey);
      if (modeStr == 'dark') return ThemeMode.dark;
      if (modeStr == 'light') return ThemeMode.light;
    } catch (_) {}
    return ThemeMode.system;
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = mode == ThemeMode.dark
          ? 'dark'
          : (mode == ThemeMode.light ? 'light' : 'system');
      await prefs.setString(_themeModeKey, val);
    } catch (_) {}
  }

  Future<NotificationSettings> loadNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_notificationSettingsKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final Map<String, dynamic> map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return NotificationSettings.fromJson(map);
      }
    } catch (_) {}
    return const NotificationSettings();
  }

  Future<void> saveNotificationSettings(NotificationSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_notificationSettingsKey, jsonEncode(settings.toJson()));
    } catch (_) {}
  }

  Future<List<Contract>> loadContracts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_contractsKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
        return list
            .map((item) => Contract.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return _initialContracts();
  }

  Future<void> saveContracts(List<Contract> contracts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(contracts.map((c) => c.toJson()).toList());
      await prefs.setString(_contractsKey, jsonStr);
    } catch (_) {}
  }

  Future<List<WorkShift>> loadShifts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_shiftsKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
        return list
            .map((item) => WorkShift.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return _initialShifts();
  }

  Future<void> saveShifts(List<WorkShift> shifts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(shifts.map((s) => s.toJson()).toList());
      await prefs.setString(_shiftsKey, jsonStr);
    } catch (_) {}
  }

  Future<List<FeedbackTicket>> loadFeedbackTickets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_feedbackTicketsKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
        return list
            .map((item) => FeedbackTicket.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> saveFeedbackTickets(List<FeedbackTicket> tickets) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(tickets.map((t) => t.toJson()).toList());
      await prefs.setString(_feedbackTicketsKey, jsonStr);
    } catch (_) {}
  }

  List<Contract> _initialContracts() {
    final now = DateTime.now();
    return [
      Contract(
        id: 'contract_1',
        companyName: 'TechFlow Solutions s.r.o.',
        jobTitle: 'Software Tester',
        contractType: ContractType.dpp,
        hourlyWage: 250,
        monthlyGrossWage: 0,
        startDate: DateTime(now.year, now.month - 1, 1),
        endDate: now.add(const Duration(days: 142)),
        probationPeriodMonths: 3,
        workLocation: 'Praha 4 - Chodov (kancelář + hybrid)',
        weeklyHours: 15,
        hasNonCompete: false,
        notes:
            'Výplata vždy k 15. dni na účet. Vybavení (notebook) zapůjčeno od firmy. V případě překročení 100 hod konzultovat s team leaderem.',
        evaluationScore: 85,
        verifiedItemsCount: 7,
        totalItemsCount: 10,
        checkedClauses: {
          'job_role': 'Software Tester / QA Junior',
          'location': 'Praha 4 - Chodov (kancelář + hybrid)',
          'start_date': '1. 10. 2025',
          'probation': '3 měsíce (zákonné maximum)',
          'schedule': 'DPP (limit max 300 hod/rok)',
          'non_compete': 'Nenalezena ve smlouvě (v souladu)',
        },
      ),
      Contract(
        id: 'contract_2',
        companyName: 'Innovatech a.s.',
        jobTitle: 'Junior Developer',
        contractType: ContractType.hpp,
        hourlyWage: 0,
        monthlyGrossWage: 48500,
        startDate: now.subtract(const Duration(days: 72)),
        endDate: null,
        probationPeriodMonths: 3,
        workLocation: 'Praha 1 - Staré Město',
        weeklyHours: 40,
        hasNonCompete: true,
        nonCompeteCompensationPercent: 50,
        hasTaxDeclaration: true,
        notes: 'Dovolená 25 dní (5 týdnů). Příspěvek na stravování.',
        evaluationScore: 92,
        verifiedItemsCount: 9,
        totalItemsCount: 10,
        checkedClauses: {
          'job_role': 'Junior Flutter & Web Developer',
          'location': 'Praha 1',
          'start_date': '1. 9. 2025',
          'probation': '3 měsíce (zbývá 18 dní!)',
          'vacation': '25 dní (5 týdnů)',
        },
      ),
    ];
  }

  List<WorkShift> _initialShifts() {
    final now = DateTime.now();
    return [
      WorkShift(
        id: 'shift_1',
        contractId: 'contract_1',
        date: DateTime(now.year, now.month, now.day - 1),
        hours: 6.5,
        description: 'Testování regresních scénářů v staging prostředí',
        hourlyRate: 250,
      ),
      WorkShift(
        id: 'shift_2',
        contractId: 'contract_1',
        date: DateTime(now.year, now.month, now.day - 4),
        hours: 8.0,
        description: 'Příprava testovacích dat a bug reporty pro vývojáře',
        hourlyRate: 250,
      ),
      WorkShift(
        id: 'shift_3',
        contractId: 'contract_1',
        date: DateTime(now.year, now.month, now.day - 7),
        hours: 4.5,
        description: 'Spuštění a revize automatických Cypress testů',
        hourlyRate: 250,
      ),
    ];
  }
}
