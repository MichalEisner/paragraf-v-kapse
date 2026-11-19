import 'dart:math';
import '../models/contract_model.dart';
import '../models/tax_parameters_model.dart';

class TaxCalculatorService {
  const TaxCalculatorService();

  TaxCalculationResult calculate({
    required ContractType contractType,
    required double rate,
    required double hours,
    required bool isHourly,
    required bool hasTaxDeclaration,
    required bool isStudent,
    required int childrenCount,
    int ztpChildrenCount = 0,
    bool hasDisability12 = false,
    bool hasDisability3 = false,
    bool hasZtp = false,
    TaxParameters params = const TaxParameters(),
  }) {
    final double grossWage = isHourly
        ? (rate * hours).roundToDouble()
        : rate.roundToDouble();

    bool paysInsurance = false;
    double social = 0.0;
    double health = 0.0;

    switch (contractType) {
      case ContractType.dpp:
        if (grossWage > params.dppThreshold) {
          paysInsurance = true;
          social = (grossWage * params.socialInsuranceRate).roundToDouble();
          health = (grossWage * params.healthInsuranceRate).roundToDouble();
        }
        break;
      case ContractType.dpc:
        if (grossWage >= params.dpcThreshold) {
          paysInsurance = true;
          social = (grossWage * params.socialInsuranceRate).roundToDouble();
          health = (grossWage * params.healthInsuranceRate).roundToDouble();
        }
        break;
      case ContractType.hpp:
        paysInsurance = true;
        social = (grossWage * params.socialInsuranceRate).roundToDouble();
        health = (grossWage * params.healthInsuranceRate).roundToDouble();
        break;
    }

    final double taxBase = grossWage;
    final double taxBeforeRelief = (taxBase * params.taxRate).roundToDouble();

    double appliedTaxRelief = 0.0;
    double appliedChildRelief = 0.0;
    double taxBonus = 0.0;
    double taxFinal = 0.0;

    if (hasTaxDeclaration) {
      // Slevy na poplatníka (§ 35ba ZDP - max do výše daně)
      double totalPersonalRelief = params.basicTaxRelief;
      if (hasDisability12) {
        totalPersonalRelief += params.disability12Relief;
      }
      if (hasDisability3) {
        totalPersonalRelief += params.disability3Relief;
      }
      if (hasZtp) {
        totalPersonalRelief += params.ztpRelief;
      }

      appliedTaxRelief = min(taxBeforeRelief, totalPersonalRelief);
      final double taxAfterPersonal = max(0.0, taxBeforeRelief - appliedTaxRelief);

      // Daňové zvýhodnění na vyživované děti (§ 35c ZDP)
      if (childrenCount > 0) {
        final int validZtp = min(childrenCount, max(0, ztpChildrenCount));
        for (int i = 1; i <= childrenCount; i++) {
          double childRate = 0.0;
          if (i == 1) {
            childRate = params.child1Relief;
          } else if (i == 2) {
            childRate = params.child2Relief;
          } else {
            childRate = params.child3PlusRelief;
          }
          // Dítě s průkazem ZTP/P má dvojnásobnou slevu
          if (i <= validZtp) {
            childRate *= 2;
          }
          appliedChildRelief += childRate;
        }
      }

      if (appliedChildRelief > taxAfterPersonal) {
        taxBonus = (appliedChildRelief - taxAfterPersonal).roundToDouble();
        taxFinal = 0.0;
      } else {
        taxFinal = (taxAfterPersonal - appliedChildRelief).roundToDouble();
      }
    } else {
      // Bez podepsaného prohlášení
      if (contractType == ContractType.dpp && grossWage <= params.dppThreshold) {
        // Srážková daň 15 %
        taxFinal = (grossWage * params.taxRate).roundToDouble();
      } else {
        // Zálohová daň 15 % bez uplatnění slev
        taxFinal = taxBeforeRelief;
      }
    }

    final double netWage = max(0.0, grossWage - social - health - taxFinal + taxBonus);
    final double netHourly = hours > 0
        ? (netWage / hours).roundToDouble()
        : (isHourly ? rate : (netWage / 160).roundToDouble());

    // Generate notice content
    String noticeTitle = '';
    String noticeDesc = '';
    String noticeType = 'info';

    if (!paysInsurance &&
        (contractType == ContractType.dpp || contractType == ContractType.dpc)) {
      noticeType = 'safe';
      noticeTitle = 'Výborně! Žádné odvody na pojištění';
      noticeDesc =
          'Váš měsíční výdělek je pod zákonným limitem pro povinné odvody sociálního a zdravotního pojištění u ${contractType.label}. Z výdělku se vám nestrhává 11,6 % pojistného a zaměstnavatel za vás neplatí 33,8 %.';
    } else if (contractType == ContractType.hpp) {
      noticeType = 'info';
      noticeTitle = 'Pracovní poměr s plnou ochranou';
      noticeDesc =
          'Při HPP máte plnou sociální ochranu, garantovaný nárok na placenou dovolenou, nemocenskou i příplatky za víkendy a svátky.';
    } else {
      noticeType = 'warning';
      noticeTitle = 'Pozor: Překročen měsíční limit u ${contractType.label}';
      noticeDesc =
          'Při překročení zákonného limitu u ${contractType.label} vám zaměstnavatel ze zákona strhává 11,6 % (sociální + zdravotní pojištění). Stáváte se plně pojištěným účastníkem.';
    }

    return TaxCalculationResult(
      grossWage: grossWage,
      socialInsurance: social,
      healthInsurance: health,
      taxBeforeRelief: taxBeforeRelief,
      appliedTaxRelief: appliedTaxRelief,
      appliedChildRelief: appliedChildRelief,
      taxBonus: taxBonus,
      taxFinal: taxFinal,
      netWage: netWage,
      netHourly: netHourly,
      paysInsurance: paysInsurance,
      noticeTitle: noticeTitle,
      noticeDesc: noticeDesc,
      noticeType: noticeType,
    );
  }
}
