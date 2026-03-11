import 'package:catalog_app_mobile/models/recurrence_rule.dart';
import 'package:catalog_app_mobile/models/reminder.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ReminderDetailPage extends StatefulWidget{
  final Reminder reminder;

  const ReminderDetailPage({super.key, required this.reminder});

  @override
  State<ReminderDetailPage> createState() => ReminderDetailPageState();
}

class ReminderDetailPageState extends State<ReminderDetailPage> {
  late Reminder _currentReminder;
  bool _hasChanges = false;

  // Контроллеры для полей ввода
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _currentReminder = widget.reminder;

    _titleController = TextEditingController(text: _currentReminder.title);
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
        title: Text(_currentReminder.title),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        actions: [
          // Кнопка сохранения
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Text(
              'Сохранить',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            onPressed: _saveChanges,
          ),
        ],
      ),
      body: ListView(
        padding:  EdgeInsets.symmetric(horizontal: 10.0),
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

  void _saveChanges() {
    Navigator.pop(context, _currentReminder);
  }

  Widget _buildDateTimeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Время',
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
                        _currentReminder.recurrenceRule!.frequency.frequencyDisplay,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        _getRecurrenceDetails(_currentReminder.recurrenceRule!),
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
        if (_currentReminder.recurrenceRule!.untilDate != null)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              'До: ${_formatDateTime(_currentReminder.recurrenceRule!.untilDate!)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),

        if (_currentReminder.recurrenceRule!.occurrencesCount != null)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              'Количество: ${_currentReminder.recurrenceRule!.occurrencesCount}',
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

  void _selectRecurrence() {
  }

  void _switchToRecurrence() {
    setState(() {
      _currentReminder.reminderDate = null;
      _currentReminder.recurrenceRule = new RecurrenceRule(frequency: Frequency.daily, intervalValue: 1);
    });
  }

  _buildChoiceField() {}

  void _switchToDateTime() {
    setState(() {
      _currentReminder.reminderDate = DateTime.now();
      _currentReminder.recurrenceRule = null;
    });
  }

  String _getRecurrenceDetails(RecurrenceRule rule) {
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