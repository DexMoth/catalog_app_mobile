import 'package:flutter/material.dart';
import 'package:catalog_app_mobile/services/notification_service.dart';
import 'package:catalog_app_mobile/services/notification_time_service.dart';
import 'package:catalog_app_mobile/services/server_settings_service.dart';
import 'package:catalog_app_mobile/configuration/app_config.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isLoading = true;

  // Поля для настроек сервера
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  bool _isServerSettingsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTime();
    _loadServerSettings();
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _loadTime() async {
    final time = await NotificationTimeService.getNotificationTime();
    setState(() {
      _selectedTime = time;
      _isLoading = false;
    });
  }

  Future<void> _loadServerSettings() async {
    final ip = await ServerSettingsService.getServerIp();
    final port = await ServerSettingsService.getServerPort();
    _ipController.text = ip;
    _portController.text = port.toString();
    setState(() {
      _isServerSettingsLoading = false;
    });
  }

  Future<void> _saveServerSettings() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim());

    if (ip.isEmpty) {
      _showSnackBar('Введите IP-адрес');
      return;
    }

    if (port == null || port <= 0 || port > 65535) {
      _showSnackBar('Введите корректный порт (1-65535)');
      return;
    }

    // Сохраняем настройки
    await ServerSettingsService.saveServerSettings(ip, port);

    // Обновляем кэш в AppConfig
    AppConfig.refresh();

    _showSnackBar('Настройки сохранены. Перезапустите приложение для применения.', isError: false);
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
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

      await NotificationTimeService.setNotificationTime(picked);
      await NotificationService().updateGlobalTime(picked);

      if (mounted) {
        _showSnackBar('Время уведомлений изменено на ${_formatTime(picked)}', isError: false);
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // === НАСТРОЙКИ ПОДКЛЮЧЕНИЯ К СЕРВЕРУ ===
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.settings_ethernet, color: Colors.brown),
                        SizedBox(width: 8),
                        Text(
                          'Подключение к серверу',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _ipController,
                      decoration: const InputDecoration(
                        labelText: 'IP-адрес',
                        hintText: '192.168.1.14',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.dns),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _portController,
                      decoration: const InputDecoration(
                        labelText: 'Порт',
                        hintText: '8080',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.settings_ethernet),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _saveServerSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Сохранить настройки сервера'),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '⚠️ После изменения настроек перезапустите приложение',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // === ВРЕМЯ УВЕДОМЛЕНИЙ ===
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

            // === О ПРИЛОЖЕНИИ ===
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