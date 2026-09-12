import 'dart:io';
import 'package:flutter/material.dart';

/// Centralized application constants and configurations.
class AppConstants {
  AppConstants._();

  static const String appName = 'Antigravity Usage Indicator';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';
  static const String executableName = 'AntigravityUsageIndicator.exe';
  static const String disclaimer = 'Unofficial utility for displaying usage information.';

  // Window Sizes (Logical pixels with DPI scaling buffer)
  static const Size minimalSize = Size(130, 52);
  static const Size compactSize = Size(224, 68);
  static const Size expandedSize = Size(340, 310);
  static const Size settingsWindowSize = Size(780, 620);

  // Default Margins
  static const double defaultTopMargin = 12.0;

  // Quota Thresholds
  static const int lowThreshold = 30;
  static const int criticalThreshold = 10;
  static const int exhaustedThreshold = 0;

  // Stale Threshold Options in minutes
  static const List<int> staleThresholdOptions = [5, 15, 30, 60, -1]; // -1 = never

  // Auto-collapse duration options in seconds
  static const List<int> autoCollapseOptions = [0, 3, 5, 10]; // 0 = off

  // Default Opacity
  static const double defaultOpacity = 0.94;
  static const double minOpacity = 0.70;
  static const double maxOpacity = 1.00;

  // Animation Durations
  static const Duration windowResizeDuration = Duration(milliseconds: 220);
  static const Duration progressAnimationDuration = Duration(milliseconds: 350);
  static const Duration fadeAnimationDuration = Duration(milliseconds: 200);

  /// Resolves the default %LOCALAPPDATA%\AntigravityUsageIndicator directory on Windows.
  static Directory get defaultAppDirectory {
    if (Platform.isWindows) {
      final localAppData = Platform.environment['LOCALAPPDATA'];
      if (localAppData != null && localAppData.isNotEmpty) {
        return Directory('$localAppData\\AntigravityUsageIndicator');
      }
    }
    // Fallback to home/current directory
    final home = Platform.environment['USERPROFILE'] ?? Directory.current.path;
    return Directory('$home\\.antigravity_usage_indicator');
  }

  /// Default path to quota.json
  static File get defaultQuotaFile => File('${defaultAppDirectory.path}\\quota.json');

  /// Default path to app.log
  static File get defaultLogFile => File('${defaultAppDirectory.path}\\logs\\app.log');
}
