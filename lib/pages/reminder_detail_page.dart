import 'package:catalog_app_mobile/models/recurrence_rule.dart';
import 'package:catalog_app_mobile/models/reminder.dart';
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

      Navigator.pop(context, _currentReminder);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Изменения сохранены'),
          backgroundColor: Colors.green,
        ),
      );
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
    final DateTime? date = await showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          color: CupertinoColors.white,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.dateAndTime,
            initialDateTime: _currentReminder.reminderDate,
            onDateTimeChanged: (DateTime newDate) {
              setState(() {
                _currentReminder.reminderDate = newDate;
              });
            },
          ),
        );
      },
    );
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
      setState(() {
        // создаем новое или обновляем
        _currentReminder.recurrenceRule = RecurrenceRule(
          frequency: selected,
          intervalValue: 1, // значение по умолчанию
        );
        _currentReminder.reminderDate = null; // убираем дату
        _hasChanges = true;
      });
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

    if (rule.intervalValue > 1) {
      return 'Каждые ${rule.intervalValue} ${_getIntervalWord(rule)}';
    }
    return '';
  }

  String _getIntervalWord(RecurrenceRule rule) {
    switch (rule.frequency) {
      case Frequency.daily:
        return 'дня';
      case Frequency.weekly:
        return 'недели';
      case Frequency.monthly:
        return 'месяца';
      case Frequency.yearly:
        return 'года';
    }
  }
}