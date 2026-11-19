import 'package:flutter_test/flutter_test.dart';
import 'package:paragraf_do_kapsy/models/contract_model.dart';
import 'package:paragraf_do_kapsy/models/tax_parameters_model.dart';
import 'package:paragraf_do_kapsy/services/tax_calculator_service.dart';

void main() {
  const calculator = TaxCalculatorService();
  const params = TaxParameters();

  group('TaxCalculatorService Tests', () {
    test('DPP under 10 500 limit: zero social and health insurance', () {
      final result = calculator.calculate(
        contractType: ContractType.dpp,
        rate: 250,
        hours: 16,
        isHourly: true,
        hasTaxDeclaration: true,
        isStudent: true,
        childrenCount: 0,
        params: params,
      );

      // Gross = 250 * 16 = 4000 Kč
      expect(result.grossWage, 4000.0);
      expect(result.paysInsurance, false);
      expect(result.socialInsurance, 0.0);
      expect(result.healthInsurance, 0.0);
      // Tax = 4000 * 0.15 = 600, relief = 2570 -> taxFinal = 0
      expect(result.taxBeforeRelief, 600.0);
      expect(result.taxFinal, 0.0);
      expect(result.netWage, 4000.0);
      expect(result.netHourly, 250.0);
      expect(result.noticeType, 'safe');
    });

    test('DPP without declaration under limit: 15% withholding tax', () {
      final result = calculator.calculate(
        contractType: ContractType.dpp,
        rate: 200,
        hours: 20,
        isHourly: true,
        hasTaxDeclaration: false,
        isStudent: false,
        childrenCount: 0,
        params: params,
      );

      // Gross = 4000 Kč
      expect(result.grossWage, 4000.0);
      expect(result.socialInsurance, 0.0);
      expect(result.healthInsurance, 0.0);
      // Withholding tax 15% of 4000 = 600 Kč
      expect(result.taxFinal, 600.0);
      expect(result.netWage, 3400.0);
      expect(result.netHourly, 170.0);
    });

    test('DPP above 10 500 limit: mandatory insurance triggered', () {
      final result = calculator.calculate(
        contractType: ContractType.dpp,
        rate: 250,
        hours: 80,
        isHourly: true,
        hasTaxDeclaration: true,
        isStudent: true,
        childrenCount: 0,
        params: params,
      );

      // Gross = 250 * 80 = 20000 Kč
      expect(result.grossWage, 20000.0);
      expect(result.paysInsurance, true);
      // Social = 20000 * 0.071 = 1420 Kč
      expect(result.socialInsurance, 1420.0);
      // Health = 20000 * 0.045 = 900 Kč
      expect(result.healthInsurance, 900.0);
      // Tax = 20000 * 0.15 = 3000, relief = 2570 -> taxFinal = 430 Kč
      expect(result.taxBeforeRelief, 3000.0);
      expect(result.taxFinal, 430.0);
      // Net = 20000 - 1420 - 900 - 430 = 17250 Kč
      expect(result.netWage, 17250.0);
      expect(result.netHourly, (17250 / 80).roundToDouble());
      expect(result.noticeType, 'warning');
    });

    test('DPČ under 4 500 limit: zero insurance', () {
      final result = calculator.calculate(
        contractType: ContractType.dpc,
        rate: 200,
        hours: 20,
        isHourly: true,
        hasTaxDeclaration: true,
        isStudent: true,
        childrenCount: 0,
        params: params,
      );

      // Gross = 4000 Kč (< 4500)
      expect(result.grossWage, 4000.0);
      expect(result.paysInsurance, false);
      expect(result.socialInsurance, 0.0);
      expect(result.healthInsurance, 0.0);
    });

    test('DPČ at or above 4 500 limit: insurance triggered', () {
      final result = calculator.calculate(
        contractType: ContractType.dpc,
        rate: 250,
        hours: 20,
        isHourly: true,
        hasTaxDeclaration: true,
        isStudent: false,
        childrenCount: 0,
        params: params,
      );

      // Gross = 5000 Kč (>= 4500)
      expect(result.grossWage, 5000.0);
      expect(result.paysInsurance, true);
      expect(result.socialInsurance, (5000 * 0.071).roundToDouble());
      expect(result.healthInsurance, (5000 * 0.045).roundToDouble());
    });

    test('HPP standard employment: full protection with child relief', () {
      final result = calculator.calculate(
        contractType: ContractType.hpp,
        rate: 50000,
        hours: 160,
        isHourly: false,
        hasTaxDeclaration: true,
        isStudent: false,
        childrenCount: 2,
        params: params,
      );

      expect(result.grossWage, 50000.0);
      expect(result.paysInsurance, true);
      expect(result.socialInsurance, 3550.0); // 7.1 %
      expect(result.healthInsurance, 2250.0); // 4.5 %
      expect(result.taxBeforeRelief, 7500.0); // 15 %
      // Tax relief: 2570 (basic) + 1267 (child 1) + 1860 (child 2) = 5697 Kč
      expect(result.appliedTaxRelief, 2570.0);
      expect(result.appliedChildRelief, 3127.0);
      expect(result.taxFinal, 7500.0 - 5697.0);
      expect(result.noticeType, 'info');
    });

    test('3 children calculation matches kurzy.cz: 5 447 Kč child relief', () {
      final result = calculator.calculate(
        contractType: ContractType.hpp,
        rate: 60000,
        hours: 160,
        isHourly: false,
        hasTaxDeclaration: true,
        isStudent: false,
        childrenCount: 3,
        params: params,
      );

      // Child relief for 3 children: 1267 + 1860 + 2320 = 5447 Kč
      expect(result.appliedChildRelief, 5447.0);
      expect(result.appliedTaxRelief, 2570.0);
    });

    test('ZTP/P child gets double tax relief (+100 %)', () {
      final result = calculator.calculate(
        contractType: ContractType.hpp,
        rate: 60000,
        hours: 160,
        isHourly: false,
        hasTaxDeclaration: true,
        isStudent: false,
        childrenCount: 2,
        ztpChildrenCount: 1, // 1st child is ZTP/P -> 2 * 1267 = 2534, 2nd child normal -> 1860 => total 4394
        params: params,
      );

      expect(result.appliedChildRelief, 2534.0 + 1860.0);
    });

    test('Disability and ZTP/P personal reliefs apply correctly', () {
      final result = calculator.calculate(
        contractType: ContractType.hpp,
        rate: 50000,
        hours: 160,
        isHourly: false,
        hasTaxDeclaration: true,
        isStudent: false,
        childrenCount: 0,
        hasDisability12: true, // +210
        hasDisability3: false,
        hasZtp: true, // +1345
        params: params,
      );

      // Total personal relief: 2570 (basic) + 210 (inv1/2) + 1345 (ZTP) = 4125 Kč
      expect(result.appliedTaxRelief, 4125.0);
    });

    test('Child relief exceeding tax results in tax bonus paid to employee', () {
      final result = calculator.calculate(
        contractType: ContractType.hpp,
        rate: 20000,
        hours: 160,
        isHourly: false,
        hasTaxDeclaration: true,
        isStudent: false,
        childrenCount: 3, // 5447 Kč
        params: params,
      );

      // Tax before relief: 20000 * 0.15 = 3000 Kč
      // Basic relief: 2570 -> remaining tax = 430 Kč
      // Child relief: 5447 Kč -> tax final = 0, tax bonus = 5447 - 430 = 5017 Kč
      expect(result.appliedTaxRelief, 2570.0);
      expect(result.appliedChildRelief, 5447.0);
      expect(result.taxFinal, 0.0);
      expect(result.taxBonus, 5017.0);
      // Net wage = 20000 - social(1420) - health(900) - 0 + bonus(5017) = 22697 Kč
      expect(result.netWage, 22697.0);
    });
  });
}
