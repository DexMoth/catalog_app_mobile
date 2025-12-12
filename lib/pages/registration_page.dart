import 'package:catalog_app_mobile/pages/item_list_page.dart';
import 'package:flutter/material.dart';

class RegistrationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown,
      body: Center(
        child: Container(
          height: 530,
          child: Card(
            margin: const EdgeInsets.all(30),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 50.0, horizontal: 25.0),
              child: Column(
                children: [
                  const Text(
                      'Регистрация',
                      style: TextStyle(fontSize: 20)
                  ),
                  const SizedBox(height: 40,),
                  const InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Логин',
                        border: OutlineInputBorder(),
                      )
                  ),
                  const SizedBox(height: 30,),
                  const InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Пароль',
                        border: OutlineInputBorder(),
                      )
                  ),
                  const SizedBox(height: 30,),
                  const InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Введите пароль повторно',
                        border: OutlineInputBorder(),
                      )
                  ),
                  const SizedBox(height: 30,),
                  ElevatedButton(
                    onPressed: () => {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                          builder: (context) => const ItemListPage(),
                        ),
                      )
                    },
                    child: const Text('Зарегистрироваться'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}