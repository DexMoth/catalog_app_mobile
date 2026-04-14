import 'package:catalog_app_mobile/pages/item_list_page.dart';
import 'package:catalog_app_mobile/services/api_service.dart';
import 'package:catalog_app_mobile/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // инициализация уведомлений
  await NotificationService().init();
  // запросить разрешения
  await NotificationService().requestPermissions();

  // иначе приложение падает
  if (!kIsWeb) {
    try {
      final reminders = await ApiService().getReminders();
      await NotificationService().rescheduleAll(reminders);
    } catch (e) {
      print('⚠️ Ошибка при перепланировании уведомлений: $e');
    }
  } else {
    print('ℹ️ Уведомления не поддерживаются на Web');
  }


  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Каталог вещей',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ItemListPage(),
    );
  }
}
