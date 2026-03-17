import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum Frequency { daily, weekly, monthly, seasonally, yearly }

extension FrequencyExtension on Frequency {
  String get frequencyDisplay {
    switch (this) {
      case Frequency.daily:
        return 'Ежедневно';
      case Frequency.weekly:
        return 'Еженедельно';
      case Frequency.monthly:
        return 'Ежемесячно';
      case Frequency.seasonally:
        return 'Сезонно (каждые 3 месяца)';
      case Frequency.yearly:
        return 'Ежегодно';
    }
  }

  IconData get icon {
    switch (this) {
      case Frequency.daily:
        return Icons.calendar_view_day;
      case Frequency.weekly:
        return Icons.calendar_view_week;
      case Frequency.monthly:
        return Icons.calendar_view_month;
      case Frequency.seasonally:
        return Icons.calendar_today_outlined;
      case Frequency.yearly:
        return Icons.calendar_today;
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

  /// Полная строка для отображения правила
  String getDisplayString() {
    final buffer = StringBuffer();

    // частота
    buffer.write(frequency.frequencyDisplay);

    // интервал
    if (intervalValue > 1) {
      buffer.write(' (каждые $intervalValue');
      switch (frequency) {
        case Frequency.daily:
          buffer.write(' дня');
          break;
        case Frequency.weekly:
          buffer.write(' недели');
          break;
        case Frequency.monthly:
          buffer.write(' месяца');
          break;
        case Frequency.seasonally:
          buffer.write(' сезона');
          break;
        case Frequency.yearly:
          buffer.write(' года');
          break;
      }
      buffer.write(')');
    }

    // для weekly
    if (frequency == Frequency.weekly) {
      final days = weekDaysDisplay;
      if (days.isNotEmpty && days != 'Нет дней') {
        buffer.write(' — $days');
      }
    }

    // для monthly
    if (frequency == Frequency.monthly) {
      if (monthDay != null) {
        buffer.write(' — ${monthDay} числа');
      } else if (monthWeek != null && monthWeekday != null) {
        final weeks = ['первый', 'второй', 'третий', 'четвертый', 'последний'];
        final days = {
          'monday': 'понедельник',
          'tuesday': 'вторник',
          'wednesday': 'среда',
          'thursday': 'четверг',
          'friday': 'пятница',
          'saturday': 'суббота',
          'sunday': 'воскресенье',
        };
        buffer.write(' — ${weeks[monthWeek! - 1]} ${days[monthWeekday]}');
      }
    }

    // для yearly
    if (frequency == Frequency.yearly && yearMonth != null && yearDay != null) {
      const months = [
        'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
        'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
      ];
      buffer.write(' — ${yearDay} ${months[yearMonth! - 1]}');
    }

    return buffer.toString();
  }

  /// Получить список названий дней недели
  List<String> get activeWeekDaysNames {
    const weekDays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final active = <String>[];
    if (monday) active.add(weekDays[0]);
    if (tuesday) active.add(weekDays[1]);
    if (wednesday) active.add(weekDays[2]);
    if (thursday) active.add(weekDays[3]);
    if (friday) active.add(weekDays[4]);
    if (saturday) active.add(weekDays[5]);
    if (sunday) active.add(weekDays[6]);
    return active;
  }

  /// Получить строку с днями недели
  String get weekDaysDisplay {
    final days = activeWeekDaysNames;
    if (days.isEmpty) return 'Нет дней';
    if (days.length == 7) return 'Каждый день';
    if (days.length == 5 &&
        monday && tuesday && wednesday && thursday && friday) {
      return 'По будням';
    }
    if (days.length == 2 && saturday && sunday) {
      return 'По выходным';
    }
    return days.join(', ');
  }

  /// Установить дни недели по списку
  void setWeekDays(List<int> days) {
    monday = days.contains(1);
    tuesday = days.contains(2);
    wednesday = days.contains(3);
    thursday = days.contains(4);
    friday = days.contains(5);
    saturday = days.contains(6);
    sunday = days.contains(7);
  }

  /// Для monthly
  String get monthDayDisplay {
    if (monthDay != null) {
      return '$monthDay число';
    }
    if (monthWeek != null && monthWeekday != null) {
      final weeks = ['первый', 'второй', 'третий', 'четвертый', 'последний'];
      final days = {
        'monday': 'понедельник',
        'tuesday': 'вторник',
        'wednesday': 'среду',
        'thursday': 'четверг',
        'friday': 'пятницу',
        'saturday': 'субботу',
        'sunday': 'воскресенье',
      };
      return '${weeks[monthWeek! - 1]} ${days[monthWeekday]}';
    }
    return '';
  }

  /// Для yearly
  String get yearDayDisplay {
    if (yearMonth != null && yearDay != null) {
      const months = [
        'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
        'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
      ];
      return '${yearDay} ${months[yearMonth! - 1]}';
    }
    return '';
  }

  String get fullDescription {
    final buffer = StringBuffer();

    buffer.write(frequency.frequencyDisplay);

    if (intervalValue > 1) {
      buffer.write(' (каждые $intervalValue');
      switch (frequency) {
        case Frequency.daily:
          buffer.write(' дня');
          break;
        case Frequency.weekly:
          buffer.write(' недели');
          break;
        case Frequency.monthly:
          buffer.write(' месяца');
          break;
        case Frequency.seasonally:
          buffer.write(' сезона');
          break;
        case Frequency.yearly:
          buffer.write(' года');
          break;
      }
      buffer.write(')');
    }

    if (frequency == Frequency.weekly) {
      final days = weekDaysDisplay;
      if (days != 'Каждый день' && days != 'Нет дней') {
        buffer.write('\n$days');
      }
    }

    if (frequency == Frequency.monthly && monthDayDisplay.isNotEmpty) {
      buffer.write('\n${monthDayDisplay}');
    }

    if (frequency == Frequency.yearly && yearDayDisplay.isNotEmpty) {
      buffer.write('\n${yearDayDisplay}');
    }

    if (untilType != UntilType.never) {
      if (untilType == UntilType.date && untilDate != null) {
        buffer.write('\nДо: ${_formatDate(untilDate!)}');
      } else if (untilType == UntilType.count && occurrencesCount != null) {
        buffer.write('\nКоличество: $occurrencesCount раз');
      }
    }

    return buffer.toString();
  }
  
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

  String _formatDate(DateTime date) {
    const months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}