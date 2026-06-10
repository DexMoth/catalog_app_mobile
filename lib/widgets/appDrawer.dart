import 'package:catalog_app_mobile/pages/category_list_page.dart';
import 'package:catalog_app_mobile/pages/login_page.dart';
import 'package:catalog_app_mobile/pages/registration_page.dart';
import 'package:catalog_app_mobile/pages/reminder_list_page.dart';
import 'package:catalog_app_mobile/pages/settings_page.dart';
import 'package:catalog_app_mobile/pages/statistic_page.dart';
import 'package:catalog_app_mobile/pages/tag_list_page.dart';
import 'package:catalog_app_mobile/pages/unauthorized_page.dart';
import 'package:flutter/material.dart';

import '../pages/item_list_page.dart';
import '../services/auth_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthService().logout();
    if (context.mounted) {
      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UnauthorizedPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.brown),
            child: Text(
              'Каталог',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2, color: Colors.brown),
            title: const Text('Все вещи'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ItemListPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.category, color: Colors.brown),
            title: const Text('Категории'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CategoryListPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_offer, color: Colors.brown),
            title: const Text('Теги'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TagListPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.alarm, color: Colors.brown),
            title: const Text('Напоминания'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReminderListPage()),
              );
            },
          ),
          const SizedBox(
            height: 40,
          ),
          ListTile(
            leading: const Icon(Icons.auto_graph, color: Colors.brown),
            title: const Text('Статистика'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StatisticPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.brown),
            title: const Text('Настройки'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.brown),
            title: const Text('Выйти'),
            onTap: () => _logout(context),
          ),
/*          ListTile(
            leading: const Icon(Icons.door_front_door, color: Colors.brown),
            title: const Text('Войти в аккаунт'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.app_registration, color: Colors.brown),
            title: const Text('Регистрация'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RegistrationPage()),
              );
            },
          ),*/
          // ListTile(
          //   leading: const Icon(Icons.door_front_door, color: Colors.brown),
          //   title: const Text('Войти в аккаунт'),
          //   onTap: () {
          //     Navigator.pop(context);
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (context) => LoginPage()),
          //     );
          //   },
          // ),
          // ListTile(
          //   leading: const Icon(Icons.app_registration, color: Colors.brown),
          //   title: const Text('Регистрация'),
          //   onTap: () {
          //     Navigator.pop(context);
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (context) => RegistrationPage()),
          //     );
          //   },
          // ),
        ],
      ),
    );
  }
}