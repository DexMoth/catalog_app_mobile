import 'package:catalog_app_mobile/models/recurrence_rule.dart';
import 'package:catalog_app_mobile/models/reminder.dart';
import 'package:catalog_app_mobile/pages/reminder_detail_page.dart';
import 'package:catalog_app_mobile/services/api_service.dart';
import 'package:catalog_app_mobile/widgets/appDrawer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ReminderListPage extends StatefulWidget {
  final ApiService? apiService;

  const ReminderListPage({super.key, this.apiService});

  @override
  State<StatefulWidget> createState() => _ReminderListPageState();
}

class _ReminderListPageState extends State<ReminderListPage> {
  final ApiService _apiService = ApiService();
  List<Reminder> _reminders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final reminders = await _apiService.getReminders();
      //print(reminders);
      setState(() {
        _reminders = reminders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Умные напоминания'),
          backgroundColor: Colors.brown,
          foregroundColor: Colors.white,
        ),
        drawer: const AppDrawer(), // боковое меню
        body: _buildBody(),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showAddDialog();
          },
          backgroundColor: Colors.brown,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        )
    );
  }

  _buildBody() {
    if(_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Ошибка: $_error',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadReminders,
              child: const Text('Попробовать снова'),
            ),
          ],
        ),
      );
    }

    if (_reminders.isEmpty) {
      return const Center(
        child: Text('Список пуст. Попробуйте добавить напоминание!'),
      );
    }

    return ListView.builder(
      itemCount: _reminders.length,
      itemBuilder: (context, index) {
        final reminder = _reminders[index];
        return CardReminder(
          reminder: reminder,
          onTap: () => _navigateToDetail(reminder),
          onDelete: () => _showDeleteDialog(reminder),
          onActiveChanged: (newValue) =>
              _toggleActive(reminder, newValue),
        );
      },
    );
  }

  void _showDeleteDialog(Reminder reminder) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Удалить напоминание?"),
          content: Text("""Вы уверены, что хотите удалить напоминание "${reminder.title}"?"""),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                // API
                await _apiService.deleteReminder(reminder.id);
                setState(() {
                  _reminders.removeWhere((t) => t.id == reminder.id);
                });
                Navigator.pop(context);
              },
              child: const Text('Удалить', style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        )
    );
  }

  void _showAddDialog() {

  }

  void _toggleActive(Reminder reminder, bool newValue) async {
    // Сохраняем индекс до изменения
    final index = _reminders.indexWhere((r) => r.id == reminder.id);
    if (index == -1) return;

    final oldValue = _reminders[index].isActive;

    setState(() {
      _reminders[index].isActive = newValue;
    });

    // Отправка на сервер
    try {
      await ApiService().updateReminderActive(reminder.id, newValue);
    } catch (e) {
      // Откат при ошибке
      setState(() {
        _reminders[index].isActive = oldValue;
      });
      _showError('Ошибка: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  _navigateToDetail(Reminder reminder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReminderDetailPage(reminder: reminder),
      ),
    );
  }
}

class CardReminder extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<bool>? onActiveChanged;

  const CardReminder({
    Key? key,
    required this.reminder,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onActiveChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 8.0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child:   InkWell(
        onTap: onTap,
        onLongPress: onEdit,
        child: ListTile(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reminder.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                reminder.recurrenceRule?.frequency.frequencyDisplay ?? 'Без повторения',
                style: const TextStyle(color: Colors.blueGrey),
              )
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoSwitch(
                value: reminder.isActive,
                activeColor: Colors.brown,
                onChanged: onActiveChanged
              )
            ],
          ),
        ),
      ),
    );
  }
}
