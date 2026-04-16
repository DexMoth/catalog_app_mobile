import 'package:catalog_app_mobile/services/server_settings_service.dart';

class AppConfig {
  static String? _cachedBaseUrl;

  static Future<String> get baseUrl async {
    if (_cachedBaseUrl != null) return _cachedBaseUrl!;
    _cachedBaseUrl = await ServerSettingsService.getBaseUrl();
    return _cachedBaseUrl!;
  }

  // обновить кэш после изменения настроек
  static void refresh() {
    _cachedBaseUrl = null;
  }
}