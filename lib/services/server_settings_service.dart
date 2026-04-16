import 'package:shared_preferences/shared_preferences.dart';

class ServerSettingsService {
  static const String _ipKey = 'server_ip';
  static const String _portKey = 'server_port';

  static const String defaultIp = '192.168.1.14';
  static const int defaultPort = 8080;

  /// получить сохранённый IP
  static Future<String> getServerIp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_ipKey) ?? defaultIp;
  }

  /// получить сохранённый порт
  static Future<int> getServerPort() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_portKey) ?? defaultPort;
  }

  /// сохранить IP и порт
  static Future<void> saveServerSettings(String ip, int port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ipKey, ip);
    await prefs.setInt(_portKey, port);
  }

  /// получить полный URL
  static Future<String> getBaseUrl() async {
    final ip = await getServerIp();
    final port = await getServerPort();
    return 'http://$ip:$port/api';
  }
}