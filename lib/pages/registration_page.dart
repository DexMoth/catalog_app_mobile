import 'package:catalog_app_mobile/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'item_list_page.dart';
import 'verification_page.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _register() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (username.isEmpty) {
      _showError('Введите имя пользователя');
      return;
    }
    if (email.isEmpty) {
      _showError('Введите email');
      return;
    }
    if (password.isEmpty) {
      _showError('Введите пароль');
      return;
    }
    if (password != confirm) {
      _showError('Пароли не совпадают');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.register(username, email, password);

      // Если требует подтверждения (нет токена) → страница с кодом
      if (response.requiresVerification && mounted) {
        _showSuccess('Код подтверждения отправлен на почту');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationPage(email: email),
          ),
        );
      }
      // Если успешно и есть токен → сразу на главную
      else if (response.success && response.token != null && mounted) {
        _showSuccess('Регистрация успешна');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ItemListPage()),
        );
      }
      // Иначе ошибка
      else {
        _showError(response.message);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(30),
          child: Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Регистрация', style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 30),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Имя пользователя',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Пароль',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _confirmController,
                    decoration: const InputDecoration(
                      labelText: 'Повторите пароль',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 30),
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else
                    ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        foregroundColor: Colors.white,
                      ),
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