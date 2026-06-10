import 'package:catalog_app_mobile/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'item_list_page.dart';

class VerificationPage extends StatefulWidget {
  final String email;
  const VerificationPage({super.key, required this.email});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final TextEditingController _codeController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isResending = false;

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

  Future<void> _verify() async {
    final code = _codeController.text.trim();

    if (code.length != 6) {
      _showError('Введите 6-значный код');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _authService.verifyCode(widget.email, code);

      if (response.success && mounted) {
        _showSuccess('Email подтверждён!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ItemListPage()),
        );
      } else {
        _showError(response.message);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendCode() async {
    setState(() => _isResending = true);

    try {
      final response = await _authService.resendCode(widget.email);

      if (response.message.contains('отправлен')) {
        _showSuccess('Новый код отправлен на почту');
      } else {
        _showError(response.message);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isResending = false);
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
                  const Text(
                    'Подтверждение email',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Код отправлен на ${widget.email}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Код подтверждения',
                      border: OutlineInputBorder(),
                      hintText: 'Введите 6-значный код',
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, letterSpacing: 8),
                    maxLength: 6,
                  ),
                  const SizedBox(height: 20),
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else
                    ElevatedButton(
                      onPressed: _verify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Подтвердить'),
                    ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _isResending ? null : _resendCode,
                    child: _isResending
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text('Отправить код повторно'),
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