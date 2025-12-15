import 'package:catalog_app_mobile/pages/category_list_page.dart';
import 'package:catalog_app_mobile/pages/login_page.dart';
import 'package:catalog_app_mobile/pages/registration_page.dart';
import 'package:catalog_app_mobile/pages/tag_list_page.dart';
import 'package:flutter/material.dart';

import '../pages/item_list_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

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