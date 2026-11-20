import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum TicketStatus {
  submitted,  // Nově předáno
  inProgress, // V řešení administrátorem
  resolved,   // Vyřešeno
  closed,     // Uzavřeno
}

class TicketMessage {
  final String id;
  final String sender; // 'user' | 'admin' | 'system'
  final String senderName;
  final String text;
  final DateTime timestamp;

  const TicketMessage({
    required this.id,
    required this.sender,
    required this.senderName,
    required this.text,
    required this.timestamp,
  });

  bool get isFromAdmin => sender == 'admin';
  bool get isFromUser => sender == 'user';
  bool get isSystem => sender == 'system';

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender': sender,
        'senderName': senderName,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
      };

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      id: json['id'] as String,
      sender: json['sender'] as String? ?? 'user',
      senderName: json['senderName'] as String? ?? 'Uživatel',
      text: json['text'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class FeedbackTicket {
  final String id;
  final String title;
  final String category;
  final String description;
  final DateTime createdAt;
  final TicketStatus status;
  final List<TicketMessage> messages;
  final String? userEmail;
  final bool includeDiagnostics;
  final String? adminNote;

  const FeedbackTicket({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.createdAt,
    this.status = TicketStatus.submitted,
    this.messages = const [],
    this.userEmail,
    this.includeDiagnostics = true,
    this.adminNote,
  });

  String get statusLabel {
    switch (status) {
      case TicketStatus.submitted:
        return 'Předáno';
      case TicketStatus.inProgress:
        return 'V řešení';
      case TicketStatus.resolved:
        return 'Vyřešeno';
      case TicketStatus.closed:
        return 'Uzavřeno';
    }
  }

  Color get statusColor {
    switch (status) {
      case TicketStatus.submitted:
        return AppColors.primary;
      case TicketStatus.inProgress:
        return AppColors.warning;
      case TicketStatus.resolved:
        return AppColors.secondary;
      case TicketStatus.closed:
        return AppColors.outline;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case TicketStatus.submitted:
        return Icons.outbox;
      case TicketStatus.inProgress:
        return Icons.hourglass_top;
      case TicketStatus.resolved:
        return Icons.check_circle;
      case TicketStatus.closed:
        return Icons.archive;
    }
  }

  FeedbackTicket copyWith({
    String? id,
    String? title,
    String? category,
    String? description,
    DateTime? createdAt,
    TicketStatus? status,
    List<TicketMessage>? messages,
    String? userEmail,
    bool? includeDiagnostics,
    String? adminNote,
  }) {
    return FeedbackTicket(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      messages: messages ?? this.messages,
      userEmail: userEmail ?? this.userEmail,
      includeDiagnostics: includeDiagnostics ?? this.includeDiagnostics,
      adminNote: adminNote ?? this.adminNote,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
        'messages': messages.map((m) => m.toJson()).toList(),
        'userEmail': userEmail,
        'includeDiagnostics': includeDiagnostics,
        'adminNote': adminNote,
      };

  factory FeedbackTicket.fromJson(Map<String, dynamic> json) {
    TicketStatus parsedStatus;
    try {
      parsedStatus = TicketStatus.values.byName(json['status'] as String);
    } catch (_) {
      parsedStatus = TicketStatus.submitted;
    }

    final rawMessages = json['messages'] as List<dynamic>? ?? [];
    final messages = rawMessages
        .map((m) => TicketMessage.fromJson(m as Map<String, dynamic>))
        .toList();

    return FeedbackTicket(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Podnět',
      category: json['category'] as String? ?? 'Chyba v aplikaci',
      description: json['description'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      status: parsedStatus,
      messages: messages,
      userEmail: json['userEmail'] as String?,
      includeDiagnostics: json['includeDiagnostics'] as bool? ?? true,
      adminNote: json['adminNote'] as String?,
    );
  }
}
