class TaxParameters {
  final double dppThreshold;
  final double dpcThreshold;
  final double socialInsuranceRate;
  final double healthInsuranceRate;
  final double taxRate;
  final double basicTaxRelief;
  final double child1Relief;
  final double child2Relief;
  final double child3PlusRelief;
  final double disability12Relief;
  final double disability3Relief;
  final double ztpRelief;

  const TaxParameters({
    this.dppThreshold = 10500.0,
    this.dpcThreshold = 4500.0,
    this.socialInsuranceRate = 0.071,
    this.healthInsuranceRate = 0.045,
    this.taxRate = 0.15,
    this.basicTaxRelief = 2570.0,
    this.child1Relief = 1267.0,
    this.child2Relief = 1860.0,
    this.child3PlusRelief = 2320.0,
    this.disability12Relief = 210.0,
    this.disability3Relief = 420.0,
    this.ztpRelief = 1345.0,
  });

  TaxParameters copyWith({
    double? dppThreshold,
    double? dpcThreshold,
    double? socialInsuranceRate,
    double? healthInsuranceRate,
    double? taxRate,
    double? basicTaxRelief,
    double? child1Relief,
    double? child2Relief,
    double? child3PlusRelief,
    double? disability12Relief,
    double? disability3Relief,
    double? ztpRelief,
  }) {
    return TaxParameters(
      dppThreshold: dppThreshold ?? this.dppThreshold,
      dpcThreshold: dpcThreshold ?? this.dpcThreshold,
      socialInsuranceRate: socialInsuranceRate ?? this.socialInsuranceRate,
      healthInsuranceRate: healthInsuranceRate ?? this.healthInsuranceRate,
      taxRate: taxRate ?? this.taxRate,
      basicTaxRelief: basicTaxRelief ?? this.basicTaxRelief,
      child1Relief: child1Relief ?? this.child1Relief,
      child2Relief: child2Relief ?? this.child2Relief,
      child3PlusRelief: child3PlusRelief ?? this.child3PlusRelief,
      disability12Relief: disability12Relief ?? this.disability12Relief,
      disability3Relief: disability3Relief ?? this.disability3Relief,
      ztpRelief: ztpRelief ?? this.ztpRelief,
    );
  }
}

class TaxCalculationResult {
  final double grossWage;
  final double socialInsurance;
  final double healthInsurance;
  final double taxBeforeRelief;
  final double appliedTaxRelief;
  final double appliedChildRelief;
  final double taxBonus;
  final double taxFinal;
  final double netWage;
  final double netHourly;
  final bool paysInsurance;
  final String noticeTitle;
  final String noticeDesc;
  final String noticeType; // 'safe', 'warning', 'info'

  const TaxCalculationResult({
    required this.grossWage,
    required this.socialInsurance,
    required this.healthInsurance,
    required this.taxBeforeRelief,
    required this.appliedTaxRelief,
    required this.appliedChildRelief,
    this.taxBonus = 0.0,
    required this.taxFinal,
    required this.netWage,
    required this.netHourly,
    required this.paysInsurance,
    required this.noticeTitle,
    required this.noticeDesc,
    required this.noticeType,
  });
}
