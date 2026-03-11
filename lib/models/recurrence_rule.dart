import 'package:flutter/foundation.dart';

enum Frequency { daily, weekly, monthly, yearly }

extension FrequencyExtension on Frequency {
  String get frequencyDisplay {
    switch (this) {
      case Frequency.daily:
        return 'Ежедневно';
      case Frequency.weekly:
        return 'Еженедельно';
      case Frequency.monthly:
        return 'Ежемесячно';
      case Frequency.yearly:
        return 'Ежегодно';
    }
  }
}

enum UntilType { never, date, count }

class RecurrenceRule {
  final int? id;
  Frequency frequency;
  int intervalValue;
  UntilType untilType;
  DateTime? untilDate;
  int? occurrencesCount;

  // для weekly (дни недели)
  bool monday;
  bool tuesday;
  bool wednesday;
  bool thursday;
  bool friday;
  bool saturday;
  bool sunday;

  // для monthly
  int? monthDay;
  int? monthWeek;
  String? monthWeekday;

  // для yearly
  int? yearMonth;
  int? yearDay;

  // метаданные
  String? description;
  DateTime? createdAt;
  DateTime? updatedAt;

  RecurrenceRule({
    this.id,
    required this.frequency,
    this.intervalValue = 1,
    this.untilType = UntilType.never,
    this.untilDate,
    this.occurrencesCount,
    this.monday = false,
    this.tuesday = false,
    this.wednesday = false,
    this.thursday = false,
    this.friday = false,
    this.saturday = false,
    this.sunday = false,
    this.monthDay,
    this.monthWeek,
    this.monthWeekday,
    this.yearMonth,
    this.yearDay,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  /// создание из JSON (с бэкенда)
  factory RecurrenceRule.fromJson(Map<String, dynamic> json) {
    return RecurrenceRule(
      id: json['id'] as int?,
      frequency: _parseFrequency(json['frequency']),
      intervalValue: json['intervalValue'] ?? 1,
      untilType: _parseUntilType(json['untilType']),
      untilDate: json['untilDate'] != null
          ? DateTime.parse(json['untilDate'])
          : null,
      occurrencesCount: json['occurrencesCount'] as int?,

      monday: json['monday'] ?? false,
      tuesday: json['tuesday'] ?? false,
      wednesday: json['wednesday'] ?? false,
      thursday: json['thursday'] ?? false,
      friday: json['friday'] ?? false,
      saturday: json['saturday'] ?? false,
      sunday: json['sunday'] ?? false,

      monthDay: json['monthDay'] as int?,
      monthWeek: json['monthWeek'] as int?,
      monthWeekday: json['monthWeekday'] as String?,

      yearMonth: json['yearMonth'] as int?,
      yearDay: json['yearDay'] as int?,

      description: json['description'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  /// Преобразование в JSON (для отправки на бэкенд)
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      if (id != null) 'id': id,
      'frequency': frequency.name,
      'intervalValue': intervalValue,
      'untilType': untilType.name,
      if (untilDate != null) 'untilDate': untilDate!.toIso8601String(),
      if (occurrencesCount != null) 'occurrencesCount': occurrencesCount,

      'monday': monday,
      'tuesday': tuesday,
      'wednesday': wednesday,
      'thursday': thursday,
      'friday': friday,
      'saturday': saturday,
      'sunday': sunday,

      if (monthDay != null) 'monthDay': monthDay,
      if (monthWeek != null) 'monthWeek': monthWeek,
      if (monthWeekday != null) 'monthWeekday': monthWeekday,

      if (yearMonth != null) 'yearMonth': yearMonth,
      if (yearDay != null) 'yearDay': yearDay,

      if (description != null) 'description': description,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };

    // Убираем поля со значениями по умолчанию, если нужно
    map.removeWhere((key, value) => value == null);
    return map;
  }

  /// Вспомогательные методы для парсинга enum
  static Frequency _parseFrequency(dynamic value) {
    if (value == null) return Frequency.daily;
    if (value is Frequency) return value;
    return Frequency.values.firstWhere(
          (e) => e.name == value.toString().toLowerCase(),
      orElse: () => Frequency.daily,
    );
  }

  static UntilType _parseUntilType(dynamic value) {
    if (value == null) return UntilType.never;
    if (value is UntilType) return value;
    return UntilType.values.firstWhere(
          (e) => e.name == value.toString().toLowerCase(),
      orElse: () => UntilType.never,
    );
  }

  /// Получить список активных дней недели
  List<int> get activeWeekDays {
    final days = <int>[];
    if (monday) days.add(1);
    if (tuesday) days.add(2);
    if (wednesday) days.add(3);
    if (thursday) days.add(4);
    if (friday) days.add(5);
    if (saturday) days.add(6);
    if (sunday) days.add(7);
    return days;
  }

  /// Проверить, активно ли правило
  bool get isActive {
    return frequency != Frequency.daily ||
        intervalValue > 0 ||
        activeWeekDays.isNotEmpty ||
        monthDay != null ||
        yearMonth != null;
  }

  @override
  String toString() {
    return 'RecurrenceRule(id: $id, frequency: $frequency, interval: $intervalValue)';
  }

  RecurrenceRule copyWith({
    int? id,
    Frequency? frequency,
    int? intervalValue,
    UntilType? untilType,
    DateTime? untilDate,
    int? occurrencesCount,
    bool? monday,
    bool? tuesday,
    bool? wednesday,
    bool? thursday,
    bool? friday,
    bool? saturday,
    bool? sunday,
    int? monthDay,
    int? monthWeek,
    String? monthWeekday,
    int? yearMonth,
    int? yearDay,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecurrenceRule(
      id: id ?? this.id,
      frequency: frequency ?? this.frequency,
      intervalValue: intervalValue ?? this.intervalValue,
      untilType: untilType ?? this.untilType,
      untilDate: untilDate ?? this.untilDate,
      occurrencesCount: occurrencesCount ?? this.occurrencesCount,
      monday: monday ?? this.monday,
      tuesday: tuesday ?? this.tuesday,
      wednesday: wednesday ?? this.wednesday,
      thursday: thursday ?? this.thursday,
      friday: friday ?? this.friday,
      saturday: saturday ?? this.saturday,
      sunday: sunday ?? this.sunday,
      monthDay: monthDay ?? this.monthDay,
      monthWeek: monthWeek ?? this.monthWeek,
      monthWeekday: monthWeekday ?? this.monthWeekday,
      yearMonth: yearMonth ?? this.yearMonth,
      yearDay: yearDay ?? this.yearDay,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}