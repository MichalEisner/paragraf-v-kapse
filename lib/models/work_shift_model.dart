class WorkShift {
  final String id;
  final String contractId;
  final DateTime date;
  final double hours;
  final String description;
  final double hourlyRate;

  const WorkShift({
    required this.id,
    required this.contractId,
    required this.date,
    required this.hours,
    required this.description,
    required this.hourlyRate,
  });

  double get wage => hours * hourlyRate;

  WorkShift copyWith({
    String? id,
    String? contractId,
    DateTime? date,
    double? hours,
    String? description,
    double? hourlyRate,
  }) {
    return WorkShift(
      id: id ?? this.id,
      contractId: contractId ?? this.contractId,
      date: date ?? this.date,
      hours: hours ?? this.hours,
      description: description ?? this.description,
      hourlyRate: hourlyRate ?? this.hourlyRate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contractId': contractId,
      'date': date.toIso8601String(),
      'hours': hours,
      'description': description,
      'hourlyRate': hourlyRate,
    };
  }

  factory WorkShift.fromJson(Map<String, dynamic> json) {
    return WorkShift(
      id: json['id'] as String,
      contractId: json['contractId'] as String,
      date: DateTime.parse(json['date'] as String),
      hours: (json['hours'] as num).toDouble(),
      description: json['description'] as String? ?? '',
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble() ?? 250,
    );
  }
}
