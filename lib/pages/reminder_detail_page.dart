import 'package:catalog_app_mobile/models/recurrence_rule.dart';
import 'package:catalog_app_mobile/models/reminder.dart';
import 'package:catalog_app_mobile/services/notification_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';

class ReminderDetailPage extends StatefulWidget{
  final Reminder? reminder;

  const ReminderDetailPage({super.key, required this.reminder});

  @override
  State<ReminderDetailPage> createState() => ReminderDetailPageState();
}

class ReminderDetailPageState extends State<ReminderDetailPage> {
  late Reminder _currentReminder;
  bool _hasChanges = false;
  bool _isCreating = false;
  String? _dateError;

  // Контроллеры для полей ввода
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _isCreating = widget.reminder == null;

    _currentReminder = widget.reminder ?? Reminder.empty();

    _titleController = TextEditingController(text: _currentReminder.title ?? '');
    _descriptionController = TextEditingController(text: _currentReminder.description ?? '');
    _messageController = TextEditingController(text: _currentReminder.message ?? '');
  }

  @override
  // закрытие
  void dispose() {
    // сохраняем изменения
    if (_hasChanges) {
      _saveChanges();
    }
    _titleController.dispose();
    _descriptionController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentReminder.title.isNotEmpty ? _currentReminder.title : 'Новое напоминание'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveChanges,
            tooltip: 'Сохранить',
          ),
        ],
      ),
      body: ListView(
        padding:  const EdgeInsets.all(25.0),
        children: [
          const Text(
            'Название',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: _titleController,
            placeholder: 'Введите название',
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            onChanged: (value) {
              ;
            },
          ),
          const SizedBox(height: 16),

          if (_currentReminder.reminderDate != null)
            _buildDateTimeField()
          else if (_currentReminder.recurrenceRule != null)
            _buildRecurrenceField()
          else
            _buildChoiceField(),

          const Text(
            'Описание',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: _descriptionController,
            placeholder: 'Введите описание',
            maxLines: 3,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            onChanged: (value) {

            },
          ),
          const SizedBox(height: 16),

          const Text(
            'Сообщение',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: _messageController,
            placeholder: 'Введите сообщение',
            maxLines: 2,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            onChanged: (value) {

            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    final newTitle = _titleController.text.trim();
    if (newTitle.isEmpty) {
      _showError('Введите название');
      return;
    }

    // проверка даты
    if (_currentReminder.reminderDate != null && _currentReminder.recurrenceRule == null) {
      if (_isDateInPast(_currentReminder.reminderDate!)) {
        _showSnackBar('Нельзя сохранить напоминание с прошедшей датой и временем');
        return;
      }
    }

    final updated = Reminder(
      id: _isCreating ? 0 : _currentReminder.id,
      title: newTitle,
      description: _descriptionController.text.trim(),
      message: _messageController.text.trim(),
      isActive: _currentReminder.isActive,
      itemId: _currentReminder.itemId,
      createdAt: _currentReminder.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      recurrenceRule: _currentReminder.recurrenceRule,
      reminderDate: _currentReminder.reminderDate,
    );

    try {
      Reminder savedReminder;

      if (_isCreating) {
        savedReminder = await ApiService().createReminder(updated);
      } else {
        savedReminder = await ApiService().updateReminder(updated);
      }

      await NotificationService().scheduleReminder(savedReminder);

      if (mounted) {
        Navigator.pop(context, savedReminder);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Изменения сохранены'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Ошибка сохранения: $e');
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Ошибка'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Widget _buildDateTimeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Дата и время',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _selectDateTime,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: Colors.brown),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentReminder.reminderDate != null
                        ? _formatDateTime(_currentReminder.reminderDate!)
                        : 'Не указано',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const Icon(Icons.edit, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Кнопка "Переключить на повторение"
        CupertinoButton(
          onPressed: _switchToRecurrence,
          child: const Text(
            'Настроить повторение вместо даты',
            style: TextStyle(color: Colors.brown),
          ),
        ),
      ],
    );
  }

  Widget _buildRecurrenceField() {
    final rule = _currentReminder.recurrenceRule;
    if (rule == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Повторение',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _selectRecurrence,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.repeat, color: Colors.brown),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rule.frequency.frequencyDisplay,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        _getRecurrenceDetails(rule),
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.edit, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Детали повторения
        if (rule.untilDate != null)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              'До: ${_formatDateTime(rule.untilDate!)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),

        if (rule.occurrencesCount != null)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              'Количество: ${rule.occurrencesCount}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),

        const SizedBox(height: 16),

        // Кнопка "Переключить на конкретную дату"
        CupertinoButton(
          onPressed: _switchToDateTime,
          child: const Text(
            'Установить конкретную дату',
            style: TextStyle(color: Colors.brown),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDateTime() async {
    final DateTime now = DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _currentReminder.reminderDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.brown,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      // выбираем время 24ч
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_currentReminder.reminderDate ?? now),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Colors.brown,
                onPrimary: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        final DateTime finalDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        // проверяем, не прошедшая ли дата
        if (_isDateInPast(finalDate)) {
          _showSnackBar('Выбранная дата и время уже прошли. Выберите будущую дату.');
          return;
        }

        setState(() {
          _currentReminder.reminderDate = finalDate;
          _currentReminder.recurrenceRule = null; //убираем правило
          _hasChanges = true;
        });
      }
    }
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectRecurrence() async {
    final Frequency? selected = await showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: const Text('Выберите повторение'),
          actions: [
            for (var frequency in Frequency.values)
              CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(context, frequency),
                child: Text(frequency.frequencyDisplay),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
        );
      },
    );

    if (selected != null) {
      // После выбора частоты показываем дополнительные настройки
      _configureRecurrenceDetails(selected);
    }
  }

  void _switchToRecurrence() {
    setState(() {
      _currentReminder.reminderDate = null;
      _currentReminder.recurrenceRule = new RecurrenceRule(frequency: Frequency.daily, intervalValue: 1);
    });
  }

  Widget _buildChoiceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
        'Тип напоминания',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildDateTimeField(),
            _buildRecurrenceField()
          ],
        )
      ],
    );
  }

  void _switchToDateTime() {
    setState(() {
      _currentReminder.reminderDate = DateTime.now();
      _currentReminder.recurrenceRule = null;
    });
  }

  String _getRecurrenceDetails(RecurrenceRule rule) {
    if (rule == null) return '';

    final buffer = StringBuffer();

    if (rule.intervalValue > 1) {
      buffer.write('Каждые ${rule.intervalValue} ${_getIntervalWord(rule)}');
    }

    if (rule.frequency == Frequency.weekly) {
      final days = rule.weekDaysDisplay;
      if (days != 'Каждый день' && days != 'Нет дней') {
        if (buffer.isNotEmpty) buffer.write('\n');
        buffer.write(days);
      }
    }

    if (rule.frequency == Frequency.monthly && rule.monthDayDisplay.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write('\n');
      buffer.write(rule.monthDayDisplay);
    }

    if (rule.frequency == Frequency.yearly && rule.yearDayDisplay.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write('\n');
      buffer.write(rule.yearDayDisplay);
    }

    return buffer.toString();
  }

  String _getIntervalWord(RecurrenceRule rule) {
    switch (rule.frequency) {
      case Frequency.daily:
        return 'дня';
      case Frequency.weekly:
        return 'недели';
      case Frequency.monthly:
        return 'месяца';
      case Frequency.seasonally:
        return 'сезона';
      case Frequency.yearly:
        return 'года';

    }
  }

  Future<void> _configureRecurrenceDetails(Frequency frequency) async {
    switch (frequency) {
      case Frequency.weekly:
        final rule = await _showWeekDaysSelector();
        if (rule != null && mounted) {
          setState(() {
            _currentReminder.recurrenceRule = rule;
            _currentReminder.reminderDate = null;
            _hasChanges = true;
          });
        }
        break;

      case Frequency.monthly:
        final rule = await _showMonthDaySelector();
        if (rule != null && mounted) {
          setState(() {
            _currentReminder.recurrenceRule = rule;
            _currentReminder.reminderDate = null;
            _hasChanges = true;
          });
        }
        break;

      case Frequency.yearly:
        final rule = await _showYearDaySelector();
        if (rule != null && mounted) {
          setState(() {
            _currentReminder.recurrenceRule = rule;
            _currentReminder.reminderDate = null;
            _hasChanges = true;
          });
        }
        break;

      default:
        if (mounted) {
          setState(() {
            _currentReminder.recurrenceRule = RecurrenceRule(
              frequency: frequency,
              intervalValue: 1,
            );
            _currentReminder.reminderDate = null;
            _hasChanges = true;
          });
        }
    }
  }

  Future<RecurrenceRule?> _showWeekDaysSelector() async {
    final existingRule = _currentReminder.recurrenceRule;

    final tempRule = RecurrenceRule(
      id: existingRule?.id,
      frequency: Frequency.weekly,
      intervalValue: existingRule?.intervalValue ?? 1,
      monday: existingRule?.monday ?? false,
      tuesday: existingRule?.tuesday ?? false,
      wednesday: existingRule?.wednesday ?? false,
      thursday: existingRule?.thursday ?? false,
      friday: existingRule?.friday ?? false,
      saturday: existingRule?.saturday ?? false,
      sunday: existingRule?.sunday ?? false,
    );

    return showModalBottomSheet<RecurrenceRule>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Выберите дни недели',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildWeekDayTile('Пн', tempRule.monday, (value) {
                    setState(() => tempRule.monday = value);
                  }),
                  _buildWeekDayTile('Вт', tempRule.tuesday, (value) {
                    setState(() => tempRule.tuesday = value);
                  }),
                  _buildWeekDayTile('Ср', tempRule.wednesday, (value) {
                    setState(() => tempRule.wednesday = value);
                  }),
                  _buildWeekDayTile('Чт', tempRule.thursday, (value) {
                    setState(() => tempRule.thursday = value);
                  }),
                  _buildWeekDayTile('Пт', tempRule.friday, (value) {
                    setState(() => tempRule.friday = value);
                  }),
                  _buildWeekDayTile('Сб', tempRule.saturday, (value) {
                    setState(() => tempRule.saturday = value);
                  }),
                  _buildWeekDayTile('Вс', tempRule.sunday, (value) {
                    setState(() => tempRule.sunday = value);
                  }),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Отмена'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          tempRule.frequency = Frequency.weekly;
                          Navigator.pop(context, tempRule);
                        },
                        child: const Text('Сохранить'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWeekDayTile(String day, bool value, Function(bool) onChanged) {
    return CheckboxListTile(
      title: Text(day),
      value: value,
      onChanged: (newValue) => onChanged(newValue ?? false),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Future<RecurrenceRule?> _showMonthDaySelector() async {
    final existingRule = _currentReminder.recurrenceRule;
    int selectedDay = existingRule?.monthDay ?? 1;

    return showModalBottomSheet<RecurrenceRule>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: 300,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Выберите день месяца',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: CupertinoPicker(
                      itemExtent: 40,
                      onSelectedItemChanged: (index) {
                        setState(() {
                          selectedDay = index + 1;
                        });
                      },
                      children: List.generate(31, (index) {
                        return Center(child: Text('${index + 1}'));
                      }),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Отмена'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final rule = RecurrenceRule(
                            id: existingRule?.id,
                            frequency: Frequency.monthly,
                            monthDay: selectedDay,
                            intervalValue: existingRule?.intervalValue ?? 1,
                            untilType: existingRule?.untilType ?? UntilType.never,
                            untilDate: existingRule?.untilDate,
                            occurrencesCount: existingRule?.occurrencesCount,
                            description: existingRule?.description,
                            createdAt: existingRule?.createdAt,
                            updatedAt: existingRule?.updatedAt,
                          );
                          Navigator.pop(context, rule);
                        },
                        child: const Text('Сохранить'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<RecurrenceRule?> _showYearDaySelector() async {
    final existingRule = _currentReminder.recurrenceRule;
    int selectedMonth = existingRule?.yearMonth ?? 1;
    int selectedDay = existingRule?.yearDay ?? 1;

    return showModalBottomSheet<RecurrenceRule>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: 400,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Выберите дату',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: CupertinoPicker(
                            itemExtent: 40,
                            onSelectedItemChanged: (index) {
                              setState(() {
                                selectedMonth = index + 1;
                              });
                            },
                            children: const [
                              'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
                              'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
                            ].map((month) => Center(child: Text(month))).toList(),
                          ),
                        ),
                        Expanded(
                          child: CupertinoPicker(
                            itemExtent: 40,
                            onSelectedItemChanged: (index) {
                              setState(() {
                                selectedDay = index + 1;
                              });
                            },
                            children: List.generate(31, (index) {
                              return Center(child: Text('${index + 1}'));
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Отмена'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final rule = RecurrenceRule(
                            id: existingRule?.id,
                            frequency: Frequency.yearly,
                            yearMonth: selectedMonth,
                            yearDay: selectedDay,
                            intervalValue: existingRule?.intervalValue ?? 1,
                            untilType: existingRule?.untilType ?? UntilType.never,
                            untilDate: existingRule?.untilDate,
                            occurrencesCount: existingRule?.occurrencesCount,
                            description: existingRule?.description,
                            createdAt: existingRule?.createdAt,
                            updatedAt: existingRule?.updatedAt,
                          );
                          Navigator.pop(context, rule);
                        },
                        child: const Text('Сохранить'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// проверка даты
  bool _isDateInPast(DateTime date) {
    return date.isBefore(DateTime.now());
  }

  void _showSnackBar(String message, {Color backgroundColor = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}