import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:antigravity_usage_indicator/app/app.dart';
import 'package:antigravity_usage_indicator/core/constants/app_constants.dart';
import 'package:antigravity_usage_indicator/core/services/logging_service.dart';
import 'package:antigravity_usage_indicator/core/services/startup_service.dart';
import 'package:antigravity_usage_indicator/core/services/tray_service.dart';
import 'package:antigravity_usage_indicator/core/services/window_service.dart';
import 'package:antigravity_usage_indicator/features/quota/presentation/providers/quota_state_provider.dart';
import 'package:antigravity_usage_indicator/features/settings/data/settings_repository.dart';
import 'package:antigravity_usage_indicator/features/settings/presentation/providers/settings_provider.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize logging
  await LoggingService.instance.init();
  LoggingService.instance.info('Starting ${AppConstants.appName} v${AppConstants.appVersion}');

  // 2. Load persisted settings
  final settingsRepo = await SettingsRepository.create();
  final initialSettings = settingsRepo.loadSettings();

  // 3. Initialize desktop services
  if (Platform.isWindows) {
    await WindowService.instance.init();
    await StartupService.instance.init();
    await TrayService.instance.init(
      isAlwaysOnTop: initialSettings.alwaysOnTop,
      startWithWindows: initialSettings.launchAtStartup,
    );
  }

  // 4. Create ProviderContainer for pre-UI orchestration
  final container = ProviderContainer(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(settingsRepo),
    ],
  );

  // 5. Connect TrayService callbacks to Riverpod notifiers
  if (Platform.isWindows) {
    TrayService.instance.onRefreshRequested = () {
      container.read(quotaStateProvider.notifier).refresh(triggerSync: true);
    };

    TrayService.instance.onModeChanged = (mode) {
      container.read(settingsNotifierProvider.notifier).setDisplayMode(mode);
    };

    TrayService.instance.onAlwaysOnTopChanged = (value) {
      container.read(settingsNotifierProvider.notifier).setAlwaysOnTop(value);
    };

    TrayService.instance.onStartWithWindowsChanged = (value) {
      container.read(settingsNotifierProvider.notifier).setLaunchAtStartup(value);
    };

    TrayService.instance.onPositionReset = (x, y) {
      container.read(settingsNotifierProvider.notifier).updateWindowPosition(x, y);
    };

    // 6. Restore window position and display mode
    if (initialSettings.rememberPosition &&
        initialSettings.lastWindowX != null &&
        initialSettings.lastWindowY != null) {
      await WindowService.instance.restorePosition(
        initialSettings.lastWindowX,
        initialSettings.lastWindowY,
        mode: initialSettings.displayMode,
      );
    } else {
      await WindowService.instance.setDisplayMode(initialSettings.displayMode, animate: false);
      await WindowService.instance.positionTopCenter();
    }

    // 7. Show window unless user requested start minimized
    if (initialSettings.showOnStartup) {
      await WindowService.instance.show();
    }

    // 8. Automatically sync and keep %LOCALAPPDATA%\AntigravityUsageIndicator\quota.json updated
    container.read(quotaStateProvider.notifier).startAutoSync(
      interval: Duration(minutes: initialSettings.autoSyncIntervalMinutes),
    );
    container.read(quotaStateProvider.notifier).selectPreferredMetric(initialSettings.primaryMetric);
    container.read(quotaStateProvider.notifier).refresh(triggerSync: true);
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AntigravityApp(),
    ),
  );
}
