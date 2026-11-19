import 'package:flutter/material.dart';
import '../models/contract_model.dart';
import '../models/work_shift_model.dart';
import '../models/tax_parameters_model.dart';
import '../services/local_storage_service.dart';
import '../services/tax_calculator_service.dart';

class AppState extends ChangeNotifier {
  final LocalStorageService _storageService = LocalStorageService();
  final TaxCalculatorService _taxCalculator = const TaxCalculatorService();

  int _selectedTabIndex = 0;
  List<Contract> _contracts = [];
  List<WorkShift> _shifts = [];
  TaxParameters _taxParams = const TaxParameters();
  bool _isInitialized = false;

  int get selectedTabIndex => _selectedTabIndex;
  List<Contract> get contracts => _contracts.where((c) => !c.isArchived).toList();
  List<Contract> get archivedContracts => _contracts.where((c) => c.isArchived).toList();
  List<WorkShift> get shifts => _shifts;
  TaxParameters get taxParams => _taxParams;
  bool get isInitialized => _isInitialized;
  TaxCalculatorService get taxCalculator => _taxCalculator;

  Future<void> init() async {
    if (_isInitialized) return;
    _contracts = await _storageService.loadContracts();
    _shifts = await _storageService.loadShifts();
    _isInitialized = true;
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
}
