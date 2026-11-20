enum ContractType {
  hpp('HPP', 'Pracovní poměr', 'Standardní pracovní poměr na plný či zkrácený úvazek'),
  dpp('DPP', 'Do 300 hod/rok', 'Dohoda o provedení práce s limitem 300 hodin v roce'),
  dpc('DPČ', '20 hod/týden', 'Dohoda o pracovní činnosti s limitem v průměru 20 hod týdně');

  final String label;
  final String subtitle;
  final String description;
  const ContractType(this.label, this.subtitle, this.description);
}

class Contract {
  final String id;
  final String companyName;
  final String jobTitle;
  final ContractType contractType;
  final double hourlyWage;
  final double monthlyGrossWage;
  final DateTime startDate;
  final DateTime? endDate;
  final int probationPeriodMonths;
  final String workLocation;
  final double weeklyHours;
  final bool hasNonCompete;
  final double? nonCompeteCompensationPercent;
  final String notes;
  final int evaluationScore; // 0 to 100 %
  final int verifiedItemsCount;
  final int totalItemsCount;
  final bool isArchived;
  final Map<String, String> checkedClauses;
  final bool hasTaxDeclaration; // Sleva na poplatníka (prohlášení k dani / růžovka)
  final int taxReliefChildrenCount; // Počet dětí pro daňové zvýhodnění (§ 35c ZDP)
  final bool isStudent; // Status studenta do 26 let
  final bool hasDisability; // Sleva na invaliditu

  const Contract({
    required this.id,
    required this.companyName,
    required this.jobTitle,
    required this.contractType,
    this.hourlyWage = 0,
    this.monthlyGrossWage = 0,
    required this.startDate,
    this.endDate,
    this.probationPeriodMonths = 3,
    this.workLocation = '',
    this.weeklyHours = 40,
    this.hasNonCompete = false,
    this.nonCompeteCompensationPercent,
    this.notes = '',
    this.evaluationScore = 85,
    this.verifiedItemsCount = 7,
    this.totalItemsCount = 10,
    this.isArchived = false,
    this.checkedClauses = const {},
    this.hasTaxDeclaration = false,
    this.taxReliefChildrenCount = 0,
    this.isStudent = false,
    this.hasDisability = false,
  });

  /// Is contract for indefinite period
  bool get isIndefinite => endDate == null;

  /// Days remaining until contract ends (or null if indefinite)
  int? get daysUntilEnd {
    if (endDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
    return end.difference(today).inDays;
  }

  /// Days remaining in probation period (null if no probation or already ended)
  int? get daysRemainingInProbation {
    if (probationPeriodMonths <= 0) return null;
    final probationEnd = DateTime(
      startDate.year,
      startDate.month + probationPeriodMonths,
      startDate.day,
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = probationEnd.difference(today).inDays;
    return diff >= 0 ? diff : null;
  }

  Contract copyWith({
    String? id,
    String? companyName,
    String? jobTitle,
    ContractType? contractType,
    double? hourlyWage,
    double? monthlyGrossWage,
    DateTime? startDate,
    DateTime? endDate,
    int? probationPeriodMonths,
    String? workLocation,
    double? weeklyHours,
    bool? hasNonCompete,
    double? nonCompeteCompensationPercent,
    String? notes,
    int? evaluationScore,
    int? verifiedItemsCount,
    int? totalItemsCount,
    bool? isArchived,
    Map<String, String>? checkedClauses,
    bool? hasTaxDeclaration,
    int? taxReliefChildrenCount,
    bool? isStudent,
    bool? hasDisability,
  }) {
    return Contract(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      jobTitle: jobTitle ?? this.jobTitle,
      contractType: contractType ?? this.contractType,
      hourlyWage: hourlyWage ?? this.hourlyWage,
      monthlyGrossWage: monthlyGrossWage ?? this.monthlyGrossWage,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      probationPeriodMonths: probationPeriodMonths ?? this.probationPeriodMonths,
      workLocation: workLocation ?? this.workLocation,
      weeklyHours: weeklyHours ?? this.weeklyHours,
      hasNonCompete: hasNonCompete ?? this.hasNonCompete,
      nonCompeteCompensationPercent:
          nonCompeteCompensationPercent ?? this.nonCompeteCompensationPercent,
      notes: notes ?? this.notes,
      evaluationScore: evaluationScore ?? this.evaluationScore,
      verifiedItemsCount: verifiedItemsCount ?? this.verifiedItemsCount,
      totalItemsCount: totalItemsCount ?? this.totalItemsCount,
      isArchived: isArchived ?? this.isArchived,
      checkedClauses: checkedClauses ?? this.checkedClauses,
      hasTaxDeclaration: hasTaxDeclaration ?? this.hasTaxDeclaration,
      taxReliefChildrenCount: taxReliefChildrenCount ?? this.taxReliefChildrenCount,
      isStudent: isStudent ?? this.isStudent,
      hasDisability: hasDisability ?? this.hasDisability,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyName': companyName,
      'jobTitle': jobTitle,
      'contractType': contractType.name,
      'hourlyWage': hourlyWage,
      'monthlyGrossWage': monthlyGrossWage,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'probationPeriodMonths': probationPeriodMonths,
      'workLocation': workLocation,
      'weeklyHours': weeklyHours,
      'hasNonCompete': hasNonCompete,
      'nonCompeteCompensationPercent': nonCompeteCompensationPercent,
      'notes': notes,
      'evaluationScore': evaluationScore,
      'verifiedItemsCount': verifiedItemsCount,
      'totalItemsCount': totalItemsCount,
      'isArchived': isArchived,
      'checkedClauses': checkedClauses,
      'hasTaxDeclaration': hasTaxDeclaration,
      'taxReliefChildrenCount': taxReliefChildrenCount,
      'isStudent': isStudent,
      'hasDisability': hasDisability,
    };
  }

  factory Contract.fromJson(Map<String, dynamic> json) {
    return Contract(
      id: json['id'] as String,
      companyName: json['companyName'] as String,
      jobTitle: json['jobTitle'] as String,
      contractType: ContractType.values.byName(
        json['contractType'] as String? ?? 'dpp',
      ),
      hourlyWage: (json['hourlyWage'] as num?)?.toDouble() ?? 0,
      monthlyGrossWage: (json['monthlyGrossWage'] as num?)?.toDouble() ?? 0,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      probationPeriodMonths: json['probationPeriodMonths'] as int? ?? 3,
      workLocation: json['workLocation'] as String? ?? '',
      weeklyHours: (json['weeklyHours'] as num?)?.toDouble() ?? 40,
      hasNonCompete: json['hasNonCompete'] as bool? ?? false,
      nonCompeteCompensationPercent:
          (json['nonCompeteCompensationPercent'] as num?)?.toDouble(),
      notes: json['notes'] as String? ?? '',
      evaluationScore: json['evaluationScore'] as int? ?? 85,
      verifiedItemsCount: json['verifiedItemsCount'] as int? ?? 7,
      totalItemsCount: json['totalItemsCount'] as int? ?? 10,
      isArchived: json['isArchived'] as bool? ?? false,
      checkedClauses: Map<String, String>.from(
        json['checkedClauses'] as Map? ?? {},
      ),
      hasTaxDeclaration: json['hasTaxDeclaration'] as bool? ?? false,
      taxReliefChildrenCount: json['taxReliefChildrenCount'] as int? ?? 0,
      isStudent: json['isStudent'] as bool? ?? false,
      hasDisability: json['hasDisability'] as bool? ?? false,
    );
  }
}
