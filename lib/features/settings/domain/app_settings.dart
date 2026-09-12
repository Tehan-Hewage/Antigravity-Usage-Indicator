import 'package:flutter/material.dart';
import 'package:antigravity_usage_indicator/core/constants/app_constants.dart';
import 'package:antigravity_usage_indicator/core/services/window_service.dart';

/// Immutable model representing all user-configurable settings and desktop states.
class AppSettings {
  final ThemeMode themeMode;
  final DisplayMode displayMode;
  final bool alwaysOnTop;
  final bool launchAtStartup;
  final bool showOnStartup;
  final bool rememberPosition;
  final double? lastWindowX;
  final double? lastWindowY;
  final double widgetOpacity;
  final int autoCollapseSeconds;
  final bool showModelName;
  final bool showPercentage;
  final bool showResetTimer;
  final int staleThresholdMinutes;
  final String? quotaFilePath;
  final bool edgeSnappingEnabled;
  final bool isDemoMode;
  final bool hasCompletedOnboarding;
  final bool enableDebugLogging;
  final String primaryMetric;
  final int autoSyncIntervalMinutes;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.displayMode = DisplayMode.compact,
    this.alwaysOnTop = true,
    this.launchAtStartup = false,
    this.showOnStartup = true,
    this.rememberPosition = true,
    this.lastWindowX,
    this.lastWindowY,
    this.widgetOpacity = AppConstants.defaultOpacity,
    this.autoCollapseSeconds = 0,
    this.showModelName = true,
    this.showPercentage = true,
    this.showResetTimer = true,
    this.staleThresholdMinutes = 15,
    this.quotaFilePath,
    this.edgeSnappingEnabled = true,
    this.isDemoMode = false,
    this.hasCompletedOnboarding = false,
    this.enableDebugLogging = false,
    this.primaryMetric = '5-Hour',
    this.autoSyncIntervalMinutes = 2,
  });

  /// Factory constructor to deserialize from key-value map.
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (e) => e.name == json['themeMode'],
        orElse: () => ThemeMode.system,
      ),
      displayMode: DisplayMode.values.firstWhere(
        (e) => e.name == json['displayMode'],
        orElse: () => DisplayMode.compact,
      ),
      alwaysOnTop: json['alwaysOnTop'] as bool? ?? true,
      launchAtStartup: json['launchAtStartup'] as bool? ?? false,
      showOnStartup: json['showOnStartup'] as bool? ?? true,
      rememberPosition: json['rememberPosition'] as bool? ?? true,
      lastWindowX: (json['lastWindowX'] as num?)?.toDouble(),
      lastWindowY: (json['lastWindowY'] as num?)?.toDouble(),
      widgetOpacity: (json['widgetOpacity'] as num?)?.toDouble() ?? AppConstants.defaultOpacity,
      autoCollapseSeconds: json['autoCollapseSeconds'] as int? ?? 0,
      showModelName: json['showModelName'] as bool? ?? true,
      showPercentage: json['showPercentage'] as bool? ?? true,
      showResetTimer: json['showResetTimer'] as bool? ?? true,
      staleThresholdMinutes: json['staleThresholdMinutes'] as int? ?? 15,
      quotaFilePath: json['quotaFilePath'] as String?,
      edgeSnappingEnabled: json['edgeSnappingEnabled'] as bool? ?? true,
      isDemoMode: json['isDemoMode'] as bool? ?? false,
      hasCompletedOnboarding: json['hasCompletedOnboarding'] as bool? ?? false,
      enableDebugLogging: json['enableDebugLogging'] as bool? ?? false,
      primaryMetric: json['primaryMetric'] as String? ?? '5-Hour',
      autoSyncIntervalMinutes: json['autoSyncIntervalMinutes'] as int? ?? 2,
    );
  }

  /// Serializes into JSON-compatible map for SharedPreferences.
  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.name,
      'displayMode': displayMode.name,
      'alwaysOnTop': alwaysOnTop,
      'launchAtStartup': launchAtStartup,
      'showOnStartup': showOnStartup,
      'rememberPosition': rememberPosition,
      'lastWindowX': lastWindowX,
      'lastWindowY': lastWindowY,
      'widgetOpacity': widgetOpacity,
      'autoCollapseSeconds': autoCollapseSeconds,
      'showModelName': showModelName,
      'showPercentage': showPercentage,
      'showResetTimer': showResetTimer,
      'staleThresholdMinutes': staleThresholdMinutes,
      'quotaFilePath': quotaFilePath,
      'edgeSnappingEnabled': edgeSnappingEnabled,
      'isDemoMode': isDemoMode,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'enableDebugLogging': enableDebugLogging,
      'primaryMetric': primaryMetric,
      'autoSyncIntervalMinutes': autoSyncIntervalMinutes,
    };
  }

  AppSettings copyWith({
    ThemeMode? themeMode,
    DisplayMode? displayMode,
    bool? alwaysOnTop,
    bool? launchAtStartup,
    bool? showOnStartup,
    bool? rememberPosition,
    double? lastWindowX,
    double? lastWindowY,
    double? widgetOpacity,
    int? autoCollapseSeconds,
    bool? showModelName,
    bool? showPercentage,
    bool? showResetTimer,
    int? staleThresholdMinutes,
    String? quotaFilePath,
    bool? edgeSnappingEnabled,
    bool? isDemoMode,
    bool? hasCompletedOnboarding,
    bool? enableDebugLogging,
    String? primaryMetric,
    int? autoSyncIntervalMinutes,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      displayMode: displayMode ?? this.displayMode,
      alwaysOnTop: alwaysOnTop ?? this.alwaysOnTop,
      launchAtStartup: launchAtStartup ?? this.launchAtStartup,
      showOnStartup: showOnStartup ?? this.showOnStartup,
      rememberPosition: rememberPosition ?? this.rememberPosition,
      lastWindowX: lastWindowX ?? this.lastWindowX,
      lastWindowY: lastWindowY ?? this.lastWindowY,
      widgetOpacity: widgetOpacity ?? this.widgetOpacity,
      autoCollapseSeconds: autoCollapseSeconds ?? this.autoCollapseSeconds,
      showModelName: showModelName ?? this.showModelName,
      showPercentage: showPercentage ?? this.showPercentage,
      showResetTimer: showResetTimer ?? this.showResetTimer,
      staleThresholdMinutes: staleThresholdMinutes ?? this.staleThresholdMinutes,
      quotaFilePath: quotaFilePath ?? this.quotaFilePath,
      edgeSnappingEnabled: edgeSnappingEnabled ?? this.edgeSnappingEnabled,
      isDemoMode: isDemoMode ?? this.isDemoMode,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      enableDebugLogging: enableDebugLogging ?? this.enableDebugLogging,
      primaryMetric: primaryMetric ?? this.primaryMetric,
      autoSyncIntervalMinutes: autoSyncIntervalMinutes ?? this.autoSyncIntervalMinutes,
    );
  }
}
