import 'dart:io';
import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';
import 'package:antigravity_usage_indicator/core/constants/app_constants.dart';
import 'package:antigravity_usage_indicator/core/services/logging_service.dart';

enum DisplayMode { minimal, compact, expanded }

/// Service managing the floating frameless window lifecycle, positioning, and animations.
class WindowService {
  WindowService._();
  static final WindowService instance = WindowService._();

  bool _initialized = false;
  bool _isSettingsOpen = false;
  DisplayMode _currentMode = DisplayMode.compact;

  DisplayMode get currentMode => _currentMode;
  bool get isSettingsOpen => _isSettingsOpen;

  void setSettingsOpen(bool open) {
    _isSettingsOpen = open;
  }

  Future<void> init() async {
    if (_initialized || !Platform.isWindows) return;

    await windowManager.ensureInitialized();

    final windowOptions = const WindowOptions(
      size: AppConstants.compactSize,
      center: false,
      backgroundColor: Colors.transparent,
      skipTaskbar: true,
      titleBarStyle: TitleBarStyle.hidden,
      alwaysOnTop: true,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setAsFrameless();
      await windowManager.setBackgroundColor(Colors.transparent);
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setSkipTaskbar(true);
      await windowManager.setPreventClose(true);
    });

    _initialized = true;
    LoggingService.instance.info('WindowService initialized');
  }

  /// Sets window size and smoothly aligns position based on the chosen mode.
  Future<void> setDisplayMode(DisplayMode mode, {bool animate = true}) async {
    if (!Platform.isWindows) return;
    _currentMode = mode;

    // Do not resize the window while the settings screen is active
    if (_isSettingsOpen) return;

    final targetSize = switch (mode) {
      DisplayMode.minimal => AppConstants.minimalSize,
      DisplayMode.compact => AppConstants.compactSize,
      DisplayMode.expanded => AppConstants.expandedSize,
    };

    try {
      final currentBounds = await windowManager.getBounds();
      final currentCenter = currentBounds.topLeft + Offset(currentBounds.width / 2, 0);

      // Expand downward while keeping horizontal center stable
      final newX = currentCenter.dx - (targetSize.width / 2);
      final newY = currentBounds.topLeft.dy;

      await windowManager.setSize(targetSize, animate: animate);
      await windowManager.setPosition(Offset(newX, newY), animate: animate);
    } catch (e, st) {
      LoggingService.instance.error('Failed to change display mode to $mode', e, st);
    }
  }

  /// Sets window position with optional animation.
  Future<void> setPosition(Offset position, {bool animate = false}) async {
    if (!Platform.isWindows) return;
    if (_isSettingsOpen) return;
    await windowManager.setPosition(position, animate: animate);
  }

  /// Positions the Settings window in the center of the primary display.
  Future<void> centerSettingsWindow() async {
    if (!Platform.isWindows) return;
    try {
      final primaryDisplay = await screenRetriever.getPrimaryDisplay();
      final displaySize = primaryDisplay.visibleSize ?? primaryDisplay.size;
      final displayOffset = primaryDisplay.visiblePosition ?? const Offset(0, 0);
      const targetSize = AppConstants.settingsWindowSize;

      final double x = displayOffset.dx + (displaySize.width - targetSize.width) / 2.0;
      final double y = displayOffset.dy + (displaySize.height - targetSize.height) / 2.0;

      await windowManager.setSize(targetSize, animate: false);
      await windowManager.setPosition(Offset(x, y), animate: false);
      LoggingService.instance.info('Centered settings window at ($x, $y)');
    } catch (e, st) {
      LoggingService.instance.error('Failed to center settings window', e, st);
      await windowManager.setSize(AppConstants.settingsWindowSize, animate: false);
      await windowManager.center();
    }
  }

  /// Calculates the target position for a preset placement on the primary display.
  Future<Offset?> calculatePresetPosition(
    String preset, {
    DisplayMode? mode,
    double margin = AppConstants.defaultTopMargin,
  }) async {
    if (!Platform.isWindows) return null;

    try {
      final primaryDisplay = await screenRetriever.getPrimaryDisplay();
      final displaySize = primaryDisplay.visibleSize ?? primaryDisplay.size;
      final displayOffset = primaryDisplay.visiblePosition ?? const Offset(0, 0);

      final targetMode = mode ?? _currentMode;
      final currentSize = switch (targetMode) {
        DisplayMode.minimal => AppConstants.minimalSize,
        DisplayMode.compact => AppConstants.compactSize,
        DisplayMode.expanded => AppConstants.expandedSize,
      };

      final double x;
      final double y;

      switch (preset) {
        case 'topLeft':
          x = displayOffset.dx + 20.0;
          y = displayOffset.dy + margin;
          break;
        case 'topRight':
          x = displayOffset.dx + displaySize.width - currentSize.width - 20.0;
          y = displayOffset.dy + margin;
          break;
        case 'bottomRight':
          x = displayOffset.dx + displaySize.width - currentSize.width - 20.0;
          y = displayOffset.dy + displaySize.height - currentSize.height - 40.0;
          break;
        case 'topCenter':
        default:
          x = displayOffset.dx + (displaySize.width - currentSize.width) / 2.0;
          y = displayOffset.dy + margin;
          break;
      }

      return Offset(x, y);
    } catch (e, st) {
      LoggingService.instance.error('Failed to calculate preset position: $preset', e, st);
      return null;
    }
  }

  /// Positions the window at the top center of the primary display.
  Future<Offset?> positionTopCenter({
    DisplayMode? mode,
    double topMargin = AppConstants.defaultTopMargin,
    bool applyImmediately = true,
  }) async {
    if (!Platform.isWindows) return null;

    final offset = await calculatePresetPosition('topCenter', mode: mode, margin: topMargin);
    if (offset != null && applyImmediately) {
      try {
        await windowManager.setPosition(offset);
        LoggingService.instance.info('Positioned window at top center: (${offset.dx}, ${offset.dy})');
      } catch (e, st) {
        LoggingService.instance.error('Failed to set window position to top center', e, st);
      }
    }
    return offset;
  }

  /// Snaps given coordinates to top-center if within snapping tolerance.
  Future<Offset> getSnappedPosition(Offset rawPos, {DisplayMode? mode}) async {
    final topCenter = await calculatePresetPosition('topCenter', mode: mode);
    if (topCenter == null) return rawPos;

    double x = rawPos.dx;
    double y = rawPos.dy;

    // Vertical snap to top margin if near top
    if (rawPos.dy < 65) {
      y = topCenter.dy;
    }

    // Horizontal snap to center if within 140px of center
    if ((rawPos.dx - topCenter.dx).abs() < 140) {
      x = topCenter.dx;
    }

    return Offset(x, y);
  }

  /// Restores saved window position or falls back to top center if off-screen.
  Future<void> restorePosition(double? savedX, double? savedY, {DisplayMode? mode}) async {
    if (!Platform.isWindows) return;

    if (mode != null) {
      _currentMode = mode;
      final sz = switch (mode) {
        DisplayMode.minimal => AppConstants.minimalSize,
        DisplayMode.compact => AppConstants.compactSize,
        DisplayMode.expanded => AppConstants.expandedSize,
      };
      await windowManager.setSize(sz, animate: false);
    }

    if (savedX == null || savedY == null) {
      await positionTopCenter();
      return;
    }

    try {
      // Validate across all connected displays
      final displays = await screenRetriever.getAllDisplays();
      bool isVisible = false;

      for (final display in displays) {
        final pos = display.visiblePosition ?? const Offset(0, 0);
        final size = display.visibleSize ?? display.size;
        final rect = Rect.fromLTWH(pos.dx, pos.dy, size.width, size.height);

        // Check if saved point is inside this display's area
        if (rect.contains(Offset(savedX + 20, savedY + 20))) {
          isVisible = true;
          break;
        }
      }

      if (isVisible) {
        await windowManager.setPosition(Offset(savedX, savedY));
        LoggingService.instance.info('Restored window position to ($savedX, $savedY)');
      } else {
        LoggingService.instance.warn('Saved position ($savedX, $savedY) off-screen. Resetting to primary display.');
        await positionTopCenter();
      }
    } catch (e) {
      await positionTopCenter();
    }
  }

  /// Toggles always-on-top state.
  Future<void> setAlwaysOnTop(bool isAlwaysOnTop) async {
    if (!Platform.isWindows) return;
    await windowManager.setAlwaysOnTop(isAlwaysOnTop);
    LoggingService.instance.info('Set always-on-top to $isAlwaysOnTop');
  }

  /// Initiates window drag from Flutter pointer event.
  Future<void> startDragging() async {
    if (!Platform.isWindows) return;
    await windowManager.startDragging();
  }

  /// Retrieves current window position for persistence.
  Future<Offset?> getPosition() async {
    if (!Platform.isWindows) return null;
    return await windowManager.getPosition();
  }

  /// Shows the window.
  Future<void> show() async {
    if (!Platform.isWindows) return;
    await windowManager.show();
    await windowManager.focus();
  }

  /// Hides the window to tray.
  Future<void> hide() async {
    if (!Platform.isWindows) return;
    await windowManager.hide();
  }

  /// Checks if window is currently visible.
  Future<bool> isVisible() async {
    if (!Platform.isWindows) return true;
    return await windowManager.isVisible();
  }
}
