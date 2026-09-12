import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:antigravity_usage_indicator/core/services/logging_service.dart';
import 'package:antigravity_usage_indicator/core/services/startup_service.dart';
import 'package:antigravity_usage_indicator/core/services/tray_service.dart';
import 'package:antigravity_usage_indicator/core/services/window_service.dart';
import 'package:antigravity_usage_indicator/features/settings/data/settings_repository.dart';
import 'package:antigravity_usage_indicator/features/settings/domain/app_settings.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  throw UnimplementedError('settingsRepositoryProvider must be initialized in main()');
});

final settingsNotifierProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return SettingsNotifier(repo);
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SettingsRepository _repository;

  SettingsNotifier(this._repository) : super(_repository.loadSettings());

  Future<void> _update(AppSettings newSettings) async {
    state = newSettings;
    await _repository.saveSettings(newSettings);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _update(state.copyWith(themeMode: mode));
  }

  Future<void> setDisplayMode(DisplayMode mode) async {
    if (state.displayMode == mode) return;
    await _update(state.copyWith(displayMode: mode));
    await WindowService.instance.setDisplayMode(mode);
  }

  Future<void> setAlwaysOnTop(bool isAlwaysOnTop) async {
    await _update(state.copyWith(alwaysOnTop: isAlwaysOnTop));
    await WindowService.instance.setAlwaysOnTop(isAlwaysOnTop);
    await TrayService.instance.updateState(isAlwaysOnTop: isAlwaysOnTop);
  }

  Future<void> setLaunchAtStartup(bool enable) async {
    final success = await StartupService.instance.setEnabled(enable);
    if (success) {
      await _update(state.copyWith(launchAtStartup: enable));
      await TrayService.instance.updateState(startWithWindows: enable);
    }
  }

  Future<void> setShowOnStartup(bool show) async {
    await _update(state.copyWith(showOnStartup: show));
  }

  Future<void> setRememberPosition(bool remember) async {
    await _update(state.copyWith(rememberPosition: remember));
  }

  Future<void> updateWindowPosition(double x, double y) async {
    await _update(state.copyWith(lastWindowX: x, lastWindowY: y));
  }

  Future<void> resetWindowPosition() async {
    await _update(state.copyWith(lastWindowX: null, lastWindowY: null));
  }

  Future<void> setWidgetOpacity(double opacity) async {
    await _update(state.copyWith(widgetOpacity: opacity));
  }

  Future<void> setAutoCollapseSeconds(int seconds) async {
    await _update(state.copyWith(autoCollapseSeconds: seconds));
  }

  Future<void> setShowModelName(bool show) async {
    await _update(state.copyWith(showModelName: show));
  }

  Future<void> setShowPercentage(bool show) async {
    await _update(state.copyWith(showPercentage: show));
  }

  Future<void> setShowResetTimer(bool show) async {
    await _update(state.copyWith(showResetTimer: show));
  }

  Future<void> setStaleThresholdMinutes(int minutes) async {
    await _update(state.copyWith(staleThresholdMinutes: minutes));
  }

  Future<void> setQuotaFilePath(String? path) async {
    await _update(state.copyWith(quotaFilePath: path));
  }

  Future<void> setEdgeSnapping(bool enabled) async {
    await _update(state.copyWith(edgeSnappingEnabled: enabled));
  }

  Future<void> setDemoMode(bool isDemo) async {
    await _update(state.copyWith(isDemoMode: isDemo));
  }

  Future<void> setCompletedOnboarding(bool completed) async {
    await _update(state.copyWith(hasCompletedOnboarding: completed));
  }

  Future<void> setDebugLogging(bool enabled) async {
    LoggingService.instance.setDebugLogging(enabled);
    await _update(state.copyWith(enableDebugLogging: enabled));
  }

  Future<void> setPrimaryMetric(String metric) async {
    await _update(state.copyWith(primaryMetric: metric));
  }

  Future<void> setAutoSyncIntervalMinutes(int minutes) async {
    await _update(state.copyWith(autoSyncIntervalMinutes: minutes));
  }

  Future<void> resetToDefaults() async {
    await _repository.resetSettings();
    state = const AppSettings();
    await WindowService.instance.setAlwaysOnTop(state.alwaysOnTop);
    await WindowService.instance.setDisplayMode(state.displayMode);
    if (Platform.isWindows) {
      await StartupService.instance.setEnabled(state.launchAtStartup);
    }
  }
}
