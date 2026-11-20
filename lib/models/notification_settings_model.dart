class NotificationSettings {
  final bool enabled;
  final bool contractEndReminder;
  final bool probationEndReminder;
  final bool hourLimitReminder;

  const NotificationSettings({
    this.enabled = false,
    this.contractEndReminder = true,
    this.probationEndReminder = true,
    this.hourLimitReminder = true,
  });

  NotificationSettings copyWith({
    bool? enabled,
    bool? contractEndReminder,
    bool? probationEndReminder,
    bool? hourLimitReminder,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      contractEndReminder: contractEndReminder ?? this.contractEndReminder,
      probationEndReminder: probationEndReminder ?? this.probationEndReminder,
      hourLimitReminder: hourLimitReminder ?? this.hourLimitReminder,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'contractEndReminder': contractEndReminder,
        'probationEndReminder': probationEndReminder,
        'hourLimitReminder': hourLimitReminder,
      };

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enabled: json['enabled'] as bool? ?? false,
      contractEndReminder: json['contractEndReminder'] as bool? ?? true,
      probationEndReminder: json['probationEndReminder'] as bool? ?? true,
      hourLimitReminder: json['hourLimitReminder'] as bool? ?? true,
    );
  }
}
