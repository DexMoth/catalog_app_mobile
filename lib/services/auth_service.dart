import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../configuration/app_config.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _emailKey = 'email';

  Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<AuthResponse> register(String username, String email, String password) async {
    final base = await AppConfig.baseUrl;
    final url = '$base/auth/register';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      print(' Регистрация - статус: ${response.statusCode}');
      print(' Ответ: ${response.body}');

      final data = json.decode(response.body);

      return AuthResponse(
        success: data['success'] ?? false,
        message: data['message'] ?? '',
        userId: data['userId'],
        username: data['username'],
        email: data['email'],
        token: data['token'],
        requiresVerification: data['token'] == null, // Нет токена → нужно подтверждение
      );
    } catch (e) {
      print('Ошибка: $e');
      return AuthResponse(
        success: false,
        message: 'Ошибка соединения: $e',
        userId: null,
        username: null,
        email: null,
        token: null,
        requiresVerification: false,
      );
    }
  }

  Future<AuthResponse> verifyCode(String email, String code) async {
    final base = await AppConfig.baseUrl;
    final url = '$base/auth/verify';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'code': code,
        }),
      );

      print(' Подтверждение - статус: ${response.statusCode}');
      print(' Ответ: ${response.body}');

      final data = json.decode(response.body);

      if (data['success'] == true && data['token'] != null) {
        await _saveAuthData(data);
      }

      return AuthResponse(
        success: data['success'] ?? false,
        message: data['message'] ?? '',
        userId: data['userId'],
        username: data['username'],
        email: data['email'],
        token: data['token'],
        requiresVerification: false,
      );
    } catch (e) {
      print('Ошибка: $e');
      return AuthResponse(
        success: false,
        message: 'Ошибка соединения: $e',
        userId: null,
        username: null,
        email: null,
        token: null,
        requiresVerification: false,
      );
    }
  }

  Future<AuthResponse> resendCode(String email) async {
    final base = await AppConfig.baseUrl;
    final url = '$base/auth/resend-code';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      print(' Повторная отправка - статус: ${response.statusCode}');
      print(' Ответ: ${response.body}');

      final data = json.decode(response.body);

      return AuthResponse(
        success: data['success'] ?? false,
        message: data['message'] ?? '',
        userId: null,
        username: null,
        email: null,
        token: null,
        requiresVerification: false,
      );
    } catch (e) {
      print(' Ошибка: $e');
      return AuthResponse(
        success: false,
        message: 'Ошибка соединения: $e',
        userId: null,
        username: null,
        email: null,
        token: null,
        requiresVerification: false,
      );
    }
  }

  Future<AuthResponse> login(String email, String password) async {
    final base = await AppConfig.baseUrl;
    final url = '$base/auth/login';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      print(' Вход - статус: ${response.statusCode}');
      print(' Ответ: ${response.body}');

      final data = json.decode(response.body);

      if (data['success'] == true && data['token'] != null) {
        await _saveAuthData(data);
      }

      return AuthResponse(
        success: data['success'] ?? false,
        message: data['message'] ?? '',
        userId: data['userId'],
        username: data['username'],
        email: data['email'],
        token: data['token'],
        requiresVerification: false,
      );
    } catch (e) {
      print(' Ошибка: $e');
      return AuthResponse(
        success: false,
        message: 'Ошибка соединения: $e',
        userId: null,
        username: null,
        email: null,
        token: null,
        requiresVerification: false,
      );
    }
  }

  Future<void> _saveAuthData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    if (data['token'] != null) {
      await prefs.setString(_tokenKey, data['token']);
    }
    if (data['userId'] != null) {
      await prefs.setInt(_userIdKey, data['userId']);
    }
    if (data['username'] != null) {
      await prefs.setString(_usernameKey, data['username']);
    }
    if (data['email'] != null) {
      await prefs.setString(_emailKey, data['email']);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_emailKey);
  }
}

class AuthResponse {
  final bool success;
  final String message;
  final int? userId;
  final String? username;
  final String? email;
  final String? token;
  final bool requiresVerification;

  AuthResponse({
    required this.success,
    required this.message,
    this.userId,
    this.username,
    this.email,
    this.token,
    this.requiresVerification = false,
  });
}