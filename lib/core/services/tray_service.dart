import 'dart:io';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:antigravity_usage_indicator/core/constants/app_constants.dart';
import 'package:antigravity_usage_indicator/core/services/logging_service.dart';
import 'package:antigravity_usage_indicator/core/services/window_service.dart';

import 'package:flutter/services.dart';

typedef TrayCallback = void Function();
typedef ModeChangeCallback = void Function(DisplayMode mode);
typedef BoolChangeCallback = void Function(bool value);
typedef PositionCallback = void Function(double x, double y);

/// Service for managing the Windows system tray icon and context menu.
class TrayService with TrayListener {
  TrayService._();
  static final TrayService instance = TrayService._();

  bool _isAlwaysOnTop = true;
  bool _startWithWindows = false;

  TrayCallback? onRefreshRequested;
  TrayCallback? onSettingsRequested;
  TrayCallback? onAboutRequested;
  ModeChangeCallback? onModeChanged;
  BoolChangeCallback? onAlwaysOnTopChanged;
  BoolChangeCallback? onStartWithWindowsChanged;
  PositionCallback? onPositionReset;

  Future<String> _resolveTrayIconPath() async {
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData != null) {
      final localDir = Directory('$localAppData\\AntigravityUsageIndicator');
      if (!localDir.existsSync()) {
        localDir.createSync(recursive: true);
      }
      final targetFile = File('${localDir.path}\\tray_icon.ico');
      if (!targetFile.existsSync()) {
        try {
          final byteData = await rootBundle.load('assets/icons/tray_icon.ico');
          await targetFile.writeAsBytes(byteData.buffer.asUint8List());
        } catch (_) {}
      }
      if (targetFile.existsSync()) {
        return targetFile.path;
      }
    }
    return 'assets/icons/tray_icon.ico';
  }

  Future<void> init({
    bool isAlwaysOnTop = true,
    bool startWithWindows = false,
  }) async {
    if (!Platform.isWindows) return;

    _isAlwaysOnTop = isAlwaysOnTop;
    _startWithWindows = startWithWindows;

    trayManager.addListener(this);

    try {
      final iconPath = await _resolveTrayIconPath();
      await trayManager.setIcon(iconPath);
      await trayManager.setToolTip(AppConstants.appName);
      await updateContextMenu();
      LoggingService.instance.info('TrayService initialized with icon: $iconPath');
    } catch (e, st) {
      LoggingService.instance.error('Failed to initialize tray icon', e, st);
    }
  }

  Future<void> updateState({
    bool? isAlwaysOnTop,
    bool? startWithWindows,
  }) async {
    if (isAlwaysOnTop != null) _isAlwaysOnTop = isAlwaysOnTop;
    if (startWithWindows != null) _startWithWindows = startWithWindows;
    await updateContextMenu();
  }

  Future<void> updateContextMenu() async {
    if (!Platform.isWindows) return;

    final Menu menu = Menu(
      items: [
        MenuItem(
          key: 'open_widget',
          label: 'Show / Hide Widget',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'mode_minimal',
          label: 'Minimal Mode (Small)',
        ),
        MenuItem(
          key: 'mode_compact',
          label: 'Compact Mode (Default)',
        ),
        MenuItem(
          key: 'mode_expanded',
          label: 'Expanded Mode (Details)',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'refresh_quota',
          label: 'Refresh Quota',
        ),
        MenuItem(
          key: 'move_to_primary',
          label: 'Reset Position to Top Center',
        ),
        MenuItem.separator(),
        MenuItem.checkbox(
          key: 'always_on_top',
          label: 'Always on Top',
          checked: _isAlwaysOnTop,
        ),
        MenuItem.checkbox(
          key: 'start_with_windows',
          label: 'Start with Windows',
          checked: _startWithWindows,
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'open_settings',
          label: 'Settings',
        ),
        MenuItem(
          key: 'about_app',
          label: 'About',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit_app',
          label: 'Exit',
        ),
      ],
    );

    await trayManager.setContextMenu(menu);
  }

  @override
  void onTrayIconMouseDown() async {
    // Left-click: toggle visibility
    final isVisible = await WindowService.instance.isVisible();
    if (isVisible) {
      await WindowService.instance.hide();
    } else {
      await WindowService.instance.show();
    }
  }

  @override
  void onTrayIconRightMouseDown() async {
    await trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    switch (menuItem.key) {
      case 'open_widget':
        final isVisible = await WindowService.instance.isVisible();
        if (isVisible) {
          await WindowService.instance.hide();
        } else {
          await WindowService.instance.show();
        }
        break;
      case 'mode_minimal':
        onModeChanged?.call(DisplayMode.minimal);
        break;
      case 'mode_compact':
        onModeChanged?.call(DisplayMode.compact);
        break;
      case 'mode_expanded':
        onModeChanged?.call(DisplayMode.expanded);
        break;
      case 'refresh_quota':
        onRefreshRequested?.call();
        break;
      case 'move_to_primary':
        final offset = await WindowService.instance.positionTopCenter();
        await WindowService.instance.show();
        if (offset != null) {
          onPositionReset?.call(offset.dx, offset.dy);
        }
        break;
      case 'always_on_top':
        final newVal = !_isAlwaysOnTop;
        _isAlwaysOnTop = newVal;
        await WindowService.instance.setAlwaysOnTop(newVal);
        onAlwaysOnTopChanged?.call(newVal);
        await updateContextMenu();
        break;
      case 'start_with_windows':
        final newVal = !_startWithWindows;
        _startWithWindows = newVal;
        onStartWithWindowsChanged?.call(newVal);
        await updateContextMenu();
        break;
      case 'open_settings':
        onSettingsRequested?.call();
        break;
      case 'about_app':
        onAboutRequested?.call();
        break;
      case 'exit_app':
        LoggingService.instance.info('User requested exit via tray menu');
        await windowManager.destroy();
        exit(0);
    }
  }

  void dispose() {
    trayManager.removeListener(this);
  }
}
