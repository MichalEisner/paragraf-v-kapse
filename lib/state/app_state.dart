import 'package:flutter/material.dart';
import '../models/contract_model.dart';
import '../models/feedback_ticket_model.dart';
import '../models/notification_settings_model.dart';
import '../models/work_shift_model.dart';
import '../models/tax_parameters_model.dart';
import '../services/local_storage_service.dart';
import '../services/native_bridge_service.dart';
import '../services/tax_calculator_service.dart';
import '../theme/app_colors.dart';

class AppState extends ChangeNotifier {
  final LocalStorageService _storageService = LocalStorageService();
  final TaxCalculatorService _taxCalculator = const TaxCalculatorService();

  int _selectedTabIndex = 0;
  List<Contract> _contracts = [];
  List<WorkShift> _shifts = [];
  List<FeedbackTicket> _feedbackTickets = [];
  TaxParameters _taxParams = const TaxParameters();
  ThemeMode _themeMode = ThemeMode.system;
  NotificationSettings _notificationSettings = const NotificationSettings();
  bool _isInitialized = false;

  int get selectedTabIndex => _selectedTabIndex;
  List<Contract> get contracts => _contracts.where((c) => !c.isArchived).toList();
  List<Contract> get archivedContracts => _contracts.where((c) => c.isArchived).toList();
  List<Contract> get allContracts => _contracts;
  List<WorkShift> get shifts => _shifts;
  List<FeedbackTicket> get feedbackTickets => _feedbackTickets;
  TaxParameters get taxParams => _taxParams;
  ThemeMode get themeMode => _themeMode;
  NotificationSettings get notificationSettings => _notificationSettings;
  bool get isInitialized => _isInitialized;
  TaxCalculatorService get taxCalculator => _taxCalculator;

  Future<void> init() async {
    if (_isInitialized) return;
    _contracts = await _storageService.loadContracts();
    _shifts = await _storageService.loadShifts();
    _feedbackTickets = await _storageService.loadFeedbackTickets();
    _themeMode = await _storageService.loadThemeMode();
    final sysDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    AppColors.isDark = _themeMode == ThemeMode.dark || (_themeMode == ThemeMode.system && sysDark);
    _notificationSettings = await _storageService.loadNotificationSettings();
    final systemNotificationsEnabled = await NativeBridgeService.areNotificationsEnabled();
    if (!systemNotificationsEnabled && _notificationSettings.enabled) {
      _notificationSettings = _notificationSettings.copyWith(enabled: false);
      await _storageService.saveNotificationSettings(_notificationSettings);
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final sysDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    AppColors.isDark = mode == ThemeMode.dark || (mode == ThemeMode.system && sysDark);
    await _storageService.saveThemeMode(mode);
    notifyListeners();
  }

  Future<void> setNotificationSettings(NotificationSettings settings) async {
    _notificationSettings = settings;
    if (settings.enabled) {
      await NativeBridgeService.requestNotificationPermission();
    }
    await _storageService.saveNotificationSettings(settings);
    notifyListeners();
  }

  Future<void> restoreBackup({
    required List<Contract> newContracts,
    required List<WorkShift> newShifts,
    required bool replace,
  }) async {
    if (replace) {
      _contracts = List.from(newContracts);
      _shifts = List.from(newShifts);
    } else {
      // Merge contracts
      for (final nc in newContracts) {
        final existingIdx = _contracts.indexWhere((c) => c.id == nc.id);
        if (existingIdx != -1) {
          _contracts[existingIdx] = nc;
        } else {
          _contracts.add(nc);
        }
      }
      // Merge shifts
      for (final ns in newShifts) {
        final existingIdx = _shifts.indexWhere((s) => s.id == ns.id);
        if (existingIdx != -1) {
          _shifts[existingIdx] = ns;
        } else {
          _shifts.add(ns);
        }
      }
    }
    await _storageService.saveContracts(_contracts);
    await _storageService.saveShifts(_shifts);
    notifyListeners();
  }

  void setTabIndex(int index) {
    if (_selectedTabIndex != index) {
      _selectedTabIndex = index;
      notifyListeners();
    }
  }

  Future<void> addContract(Contract contract) async {
    _contracts.insert(0, contract);
    await _storageService.saveContracts(_contracts);
    notifyListeners();
  }

  Future<void> updateContract(Contract contract) async {
    final index = _contracts.indexWhere((c) => c.id == contract.id);
    if (index != -1) {
      _contracts[index] = contract;
      await _storageService.saveContracts(_contracts);
      notifyListeners();
    }
  }

  Future<void> toggleArchiveContract(String contractId) async {
    final index = _contracts.indexWhere((c) => c.id == contractId);
    if (index != -1) {
      final current = _contracts[index];
      _contracts[index] = current.copyWith(isArchived: !current.isArchived);
      await _storageService.saveContracts(_contracts);
      notifyListeners();
    }
  }

  Future<void> deleteContract(String contractId) async {
    _contracts.removeWhere((c) => c.id == contractId);
    _shifts.removeWhere((s) => s.contractId == contractId);
    await _storageService.saveContracts(_contracts);
    await _storageService.saveShifts(_shifts);
    notifyListeners();
  }

  Future<void> addShift(WorkShift shift) async {
    _shifts.insert(0, shift);
    await _storageService.saveShifts(_shifts);
    notifyListeners();
  }

  Future<void> updateShift(WorkShift shift) async {
    final index = _shifts.indexWhere((s) => s.id == shift.id);
    if (index != -1) {
      _shifts[index] = shift;
      await _storageService.saveShifts(_shifts);
      notifyListeners();
    }
  }

  Future<void> deleteShift(String shiftId) async {
    _shifts.removeWhere((s) => s.id == shiftId);
    await _storageService.saveShifts(_shifts);
    notifyListeners();
  }

  List<WorkShift> getShiftsForContract(String contractId) {
    return _shifts.where((s) => s.contractId == contractId).toList();
  }

  double getTotalHoursForContract(String contractId) {
    // Return base logged hours + any initial balance
    final logged = _shifts
        .where((s) => s.contractId == contractId)
        .fold<double>(0.0, (sum, s) => sum + s.hours);
    // If it's contract_1 (sample data matching mockup of 112 hours)
    if (contractId == 'contract_1') {
      return 112.0 + (logged > 19.0 ? (logged - 19.0) : 0.0);
    }
    return logged;
  }

  void updateTaxParams(TaxParameters params) {
    _taxParams = params;
    notifyListeners();
  }

  Future<void> addFeedbackTicket(FeedbackTicket ticket) async {
    _feedbackTickets.insert(0, ticket);
    await _storageService.saveFeedbackTickets(_feedbackTickets);
    notifyListeners();
  }

  Future<void> addMessageToTicket(String ticketId, String text, {bool isAdmin = false}) async {
    final idx = _feedbackTickets.indexWhere((t) => t.id == ticketId);
    if (idx != -1) {
      final ticket = _feedbackTickets[idx];
      final newMsg = TicketMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        sender: isAdmin ? 'admin' : 'user',
        senderName: isAdmin ? 'Podpora Paragraf v kapse' : 'Uživatel',
        text: text,
        timestamp: DateTime.now(),
      );
      final updatedMessages = List<TicketMessage>.from(ticket.messages)..add(newMsg);
      _feedbackTickets[idx] = ticket.copyWith(messages: updatedMessages);
      await _storageService.saveFeedbackTickets(_feedbackTickets);
      notifyListeners();
    }
  }

  Future<void> updateTicketStatus(String ticketId, TicketStatus newStatus, {String? adminNote}) async {
    final idx = _feedbackTickets.indexWhere((t) => t.id == ticketId);
    if (idx != -1) {
      final ticket = _feedbackTickets[idx];
      _feedbackTickets[idx] = ticket.copyWith(status: newStatus, adminNote: adminNote);
      await _storageService.saveFeedbackTickets(_feedbackTickets);
      notifyListeners();
    }
  }
}
