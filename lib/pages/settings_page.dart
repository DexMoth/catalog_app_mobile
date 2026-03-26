import 'package:flutter/material.dart';
import 'package:catalog_app_mobile/services/notification_service.dart';
import 'package:catalog_app_mobile/services/notification_time_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTime();
  }

  Future<void> _loadTime() async {
    final time = await NotificationTimeService.getNotificationTime();
    setState(() {
      _selectedTime = time;
      _isLoading = false;
    });
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
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

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });

      // сохраняем и обновляем все уведомления
      await NotificationTimeService.setNotificationTime(picked);
      await NotificationService().updateGlobalTime(picked);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Время уведомлений изменено на ${_formatTime(picked)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.access_time, color: Colors.brown),
                title: const Text('Время уведомлений'),
                subtitle: _isLoading
                    ? const Text('Загрузка...')
                    : Text(_formatTime(_selectedTime)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _selectTime,
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              elevation: 2,
              child: ListTile(
                leading: Icon(Icons.info_outline, color: Colors.brown),
                title: Text('О приложении'),
                subtitle: Text('Версия 1.0.0'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}