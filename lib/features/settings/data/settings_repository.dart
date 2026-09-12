import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:antigravity_usage_indicator/core/services/logging_service.dart';
import 'package:antigravity_usage_indicator/features/settings/domain/app_settings.dart';

/// Repository for persisting user settings and window coordinates using SharedPreferences.
class SettingsRepository {
  static const String _settingsKey = 'antigravity_app_settings';
  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  static Future<SettingsRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsRepository(prefs);
  }

  /// Loads persisted settings or returns defaults.
  AppSettings loadSettings() {
    try {
      final raw = _prefs.getString(_settingsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return AppSettings.fromJson(decoded);
        }
      }
    } catch (e, st) {
      LoggingService.instance.error('Error loading settings from SharedPreferences', e, st);
    }
    return const AppSettings();
  }

  /// Saves updated settings.
  Future<bool> saveSettings(AppSettings settings) async {
    try {
      final encoded = jsonEncode(settings.toJson());
      return await _prefs.setString(_settingsKey, encoded);
    } catch (e, st) {
      LoggingService.instance.error('Error saving settings to SharedPreferences', e, st);
      return false;
    }
  }

  /// Clears all stored settings (reset to factory defaults).
  Future<bool> resetSettings() async {
    return await _prefs.remove(_settingsKey);
  }
}
