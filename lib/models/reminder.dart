import 'recurrence_rule.dart';

class Reminder {
  int id;
  String title;
  String? description;
  String? message;

  String? itemId;
  RecurrenceRule? recurrenceRule;

  DateTime? reminderDate;
  bool isActive;
  DateTime createdAt;
  DateTime updatedAt;

  Reminder({
    required this.id,
    required this.title,
    this.description,
    this.message,
    this.itemId,
    this.recurrenceRule,
    this.reminderDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Reminder.empty() {
    return Reminder(
        id: 0,
        title: '',
        isActive: true,
        reminderDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now()
    );
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    print('🔍 Парсинг Reminder:');
    json.forEach((key, value) {
      print('  $key: $value (${value.runtimeType})');
    });

    return Reminder(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      message: json['message'] as String?,
      itemId: json['itemId'] as String?,
      recurrenceRule: json['recurrenceRule'] != null
          ? RecurrenceRule.fromJson(json['recurrenceRule'])
          : null,
      reminderDate: json['reminderDate'] != null
          ? DateTime.parse(json['reminderDate'] as String)
          : null,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'message': message,
      'itemId': itemId,
      'recurrenceRule': recurrenceRule?.toJson(),
      'reminderDate': reminderDate?.toIso8601String(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}