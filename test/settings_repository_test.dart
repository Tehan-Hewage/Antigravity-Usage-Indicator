import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:antigravity_usage_indicator/core/services/window_service.dart';
import 'package:antigravity_usage_indicator/features/settings/data/settings_repository.dart';
import 'package:antigravity_usage_indicator/features/settings/domain/app_settings.dart';

void main() {
  group('AppSettings Domain & Serialization Tests', () {
    test('Default values are correct', () {
      const s = AppSettings();
      expect(s.themeMode, ThemeMode.system);
      expect(s.displayMode, DisplayMode.compact);
      expect(s.alwaysOnTop, isTrue);
      expect(s.launchAtStartup, isFalse);
      expect(s.rememberPosition, isTrue);
      expect(s.widgetOpacity, 0.94);
      expect(s.staleThresholdMinutes, 15);
      expect(s.isDemoMode, isFalse);
    });

    test('JSON serialization roundtrip preserves all values', () {
      const original = AppSettings(
        themeMode: ThemeMode.dark,
        displayMode: DisplayMode.expanded,
        alwaysOnTop: false,
        launchAtStartup: true,
        showOnStartup: true,
        rememberPosition: true,
        lastWindowX: 450.0,
        lastWindowY: 12.0,
        widgetOpacity: 0.85,
        autoCollapseSeconds: 5,
        showModelName: false,
        showPercentage: true,
        showResetTimer: false,
        staleThresholdMinutes: 30,
        quotaFilePath: 'C:\\custom\\quota.json',
        edgeSnappingEnabled: false,
        isDemoMode: true,
        hasCompletedOnboarding: true,
        enableDebugLogging: true,
      );

      final json = original.toJson();
      final restored = AppSettings.fromJson(json);

      expect(restored.themeMode, ThemeMode.dark);
      expect(restored.displayMode, DisplayMode.expanded);
      expect(restored.alwaysOnTop, isFalse);
      expect(restored.launchAtStartup, isTrue);
      expect(restored.lastWindowX, 450.0);
      expect(restored.lastWindowY, 12.0);
      expect(restored.widgetOpacity, 0.85);
      expect(restored.autoCollapseSeconds, 5);
      expect(restored.showModelName, isFalse);
      expect(restored.showResetTimer, isFalse);
      expect(restored.staleThresholdMinutes, 30);
      expect(restored.quotaFilePath, 'C:\\custom\\quota.json');
      expect(restored.edgeSnappingEnabled, isFalse);
      expect(restored.isDemoMode, isTrue);
      expect(restored.hasCompletedOnboarding, isTrue);
      expect(restored.enableDebugLogging, isTrue);
    });
  });

  group('SettingsRepository Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Loads default settings when storage is empty', () async {
      final repo = await SettingsRepository.create();
      final loaded = repo.loadSettings();
      expect(loaded.alwaysOnTop, isTrue);
      expect(loaded.displayMode, DisplayMode.compact);
    });

    test('Saves and restores updated settings', () async {
      final repo = await SettingsRepository.create();
      const updated = AppSettings(
        alwaysOnTop: false,
        displayMode: DisplayMode.minimal,
        widgetOpacity: 0.88,
      );

      final success = await repo.saveSettings(updated);
      expect(success, isTrue);

      final restored = repo.loadSettings();
      expect(restored.alwaysOnTop, isFalse);
      expect(restored.displayMode, DisplayMode.minimal);
      expect(restored.widgetOpacity, 0.88);
    });

    test('Resets settings to empty', () async {
      final repo = await SettingsRepository.create();
      await repo.saveSettings(const AppSettings(widgetOpacity: 0.75));
      await repo.resetSettings();

      final defaults = repo.loadSettings();
      expect(defaults.widgetOpacity, 0.94);
    });
  });
}
