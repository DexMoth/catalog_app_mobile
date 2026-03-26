import 'package:catalog_app_mobile/pages/item_list_page.dart';
import 'package:catalog_app_mobile/services/api_service.dart';
import 'package:catalog_app_mobile/services/notification_service.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // инициализация уведомлений
  await NotificationService().init();
  // запросить разрешения
  await NotificationService().requestPermissions();
  await NotificationService().rescheduleAll(await ApiService().getReminders());

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
