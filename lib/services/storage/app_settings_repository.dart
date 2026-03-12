import 'package:shared_preferences/shared_preferences.dart';

import '../../models/app_settings.dart';

class AppSettingsRepository {
  static const _settingsKey = 'app_settings';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawSettings = prefs.getString(_settingsKey);
    if (rawSettings == null || rawSettings.isEmpty) {
      return AppSettings.defaults();
    }
    return AppSettings.fromRawJson(rawSettings);
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, settings.toRawJson());
  }
}
