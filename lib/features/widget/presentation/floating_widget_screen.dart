import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:antigravity_usage_indicator/core/constants/app_constants.dart';
import 'package:antigravity_usage_indicator/core/services/tray_service.dart';
import 'package:antigravity_usage_indicator/core/services/window_service.dart';
import 'package:antigravity_usage_indicator/core/theme/app_theme.dart';
import 'package:antigravity_usage_indicator/features/quota/presentation/providers/quota_state_provider.dart';
import 'package:antigravity_usage_indicator/features/settings/presentation/providers/settings_provider.dart';
import 'package:antigravity_usage_indicator/features/settings/presentation/settings_screen.dart';
import 'package:antigravity_usage_indicator/features/widget/presentation/compact_widget.dart';
import 'package:antigravity_usage_indicator/features/widget/presentation/expanded_widget.dart';
import 'package:antigravity_usage_indicator/features/widget/presentation/minimal_widget.dart';
import 'package:antigravity_usage_indicator/features/widget/presentation/onboarding_dialog.dart';

/// The primary floating frameless widget window container.
class FloatingWidgetScreen extends ConsumerStatefulWidget {
  const FloatingWidgetScreen({super.key});

  @override
  ConsumerState<FloatingWidgetScreen> createState() => _FloatingWidgetScreenState();
}

class _FloatingWidgetScreenState extends ConsumerState<FloatingWidgetScreen> {
  Timer? _autoCollapseTimer;
  bool _isHovering = false;
  bool _isOnboardingVisible = false;
  bool _isSettingsOpen = false;

  @override
  void initState() {
    super.initState();
    TrayService.instance.onSettingsRequested = _openSettingsWindow;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstRun();
    });
  }

  void _checkFirstRun() {
    final settings = ref.read(settingsNotifierProvider);
    final quotaState = ref.read(quotaStateProvider);
    if (!settings.hasCompletedOnboarding && quotaState.snapshot.isMissing) {
      setState(() {
        _isOnboardingVisible = true;
      });
    }
  }

  void _startAutoCollapseTimerIfNeeded() {
    _autoCollapseTimer?.cancel();
    final settings = ref.read(settingsNotifierProvider);
    if (settings.autoCollapseSeconds > 0 &&
        settings.displayMode == DisplayMode.expanded &&
        !_isHovering &&
        !_isSettingsOpen) {
      _autoCollapseTimer = Timer(Duration(seconds: settings.autoCollapseSeconds), () {
        if (mounted &&
            !_isHovering &&
            !_isSettingsOpen &&
            ref.read(settingsNotifierProvider).displayMode == DisplayMode.expanded) {
          ref.read(settingsNotifierProvider.notifier).setDisplayMode(DisplayMode.compact);
        }
      });
    }
  }

  void _onWidgetTapped() {
    final currentMode = ref.read(settingsNotifierProvider).displayMode;
    final nextMode = switch (currentMode) {
      DisplayMode.minimal => DisplayMode.compact,
      DisplayMode.compact => DisplayMode.expanded,
      DisplayMode.expanded => DisplayMode.compact,
    };
    ref.read(settingsNotifierProvider.notifier).setDisplayMode(nextMode);
    _startAutoCollapseTimerIfNeeded();
  }

  Future<void> _startDragging() async {
    await WindowService.instance.startDragging();
  }

  Future<void> _savePosition() async {
    final settings = ref.read(settingsNotifierProvider);
    if (settings.rememberPosition) {
      final pos = await WindowService.instance.getPosition();
      if (pos != null) {
        Offset targetPos = pos;
        if (settings.edgeSnappingEnabled) {
          targetPos = await WindowService.instance.getSnappedPosition(pos, mode: settings.displayMode);
          if (targetPos != pos) {
            await WindowService.instance.setPosition(targetPos, animate: true);
          }
        }
        await ref.read(settingsNotifierProvider.notifier).updateWindowPosition(targetPos.dx, targetPos.dy);
      }
    }
    _startAutoCollapseTimerIfNeeded();
  }

  Future<void> _openSettingsWindow() async {
    if (_isSettingsOpen) return;
    _isSettingsOpen = true;
    WindowService.instance.setSettingsOpen(true);
    _autoCollapseTimer?.cancel();

    // Center settings window without size animation stutter or displacement
    await WindowService.instance.centerSettingsWindow();
    await windowManager.setAlwaysOnTop(false);

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );

    _isSettingsOpen = false;
    WindowService.instance.setSettingsOpen(false);

    // Restore floating widget size and position
    final latestSettings = ref.read(settingsNotifierProvider);
    await WindowService.instance.restorePosition(
      latestSettings.lastWindowX,
      latestSettings.lastWindowY,
      mode: latestSettings.displayMode,
    );
    await WindowService.instance.setAlwaysOnTop(latestSettings.alwaysOnTop);
    _startAutoCollapseTimerIfNeeded();
  }

  @override
  void dispose() {
    _autoCollapseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);
    final quotaState = ref.watch(quotaStateProvider);
    final activeSnapshot = quotaState.activeQuota;

    final isExpanded = settings.displayMode == DisplayMode.expanded;
    final borderRadius = isExpanded ? AppTheme.radiusExpanded : AppTheme.radiusPill;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Center(
            child: RepaintBoundary(
              child: MouseRegion(
                onEnter: (_) {
                  _isHovering = true;
                  _autoCollapseTimer?.cancel();
                },
                onExit: (_) {
                  _isHovering = false;
                  _startAutoCollapseTimerIfNeeded();
                },
                child: AnimatedContainer(
                  duration: AppConstants.windowResizeDuration,
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: AppTheme.darkBackground.withValues(alpha: settings.widgetOpacity),
                    borderRadius: BorderRadius.circular(borderRadius),
                    border: Border.all(
                      color: _isHovering ? AppTheme.darkBorderHover : AppTheme.darkBorder,
                      width: 1.0,
                    ),
                    boxShadow: AppTheme.widgetShadow,
                  ),
                  child: AnimatedSwitcher(
                    duration: AppConstants.fadeAnimationDuration,
                    layoutBuilder: (currentChild, previousChildren) => Stack(
                      alignment: Alignment.topCenter,
                      children: [...previousChildren, if (currentChild != null) currentChild],
                    ),
                    child: switch (settings.displayMode) {
                      DisplayMode.minimal => GestureDetector(
                          key: const ValueKey('minimal'),
                          behavior: HitTestBehavior.opaque,
                          onTap: _onWidgetTapped,
                          onPanStart: (_) => _startDragging(),
                          onPanEnd: (_) => _savePosition(),
                          onSecondaryTap: () => trayManager.popUpContextMenu(),
                          child: MinimalWidget(snapshot: activeSnapshot),
                        ),
                      DisplayMode.compact => GestureDetector(
                          key: const ValueKey('compact'),
                          behavior: HitTestBehavior.opaque,
                          onTap: _onWidgetTapped,
                          onPanStart: (_) => _startDragging(),
                          onPanEnd: (_) => _savePosition(),
                          onSecondaryTap: () => trayManager.popUpContextMenu(),
                          child: CompactWidget(
                            snapshot: activeSnapshot,
                            showModelName: settings.showModelName,
                            showPercentage: settings.showPercentage,
                            hasMultipleQuotas: quotaState.hasMultipleQuotas,
                            onCycleQuota: () => ref.read(quotaStateProvider.notifier).cycleNextQuota(),
                          ),
                        ),
                      DisplayMode.expanded => GestureDetector(
                          key: const ValueKey('expanded'),
                          behavior: HitTestBehavior.deferToChild,
                          onSecondaryTap: () => trayManager.popUpContextMenu(),
                          child: ExpandedWidget(
                            snapshot: activeSnapshot,
                            allQuotas: quotaState.allQuotas,
                            selectedQuotaIndex: quotaState.selectedIndex,
                            onSelectQuota: (idx) => ref.read(quotaStateProvider.notifier).selectQuotaIndex(idx),
                            isRefreshing: quotaState.isRefreshing,
                            onRefresh: () => ref.read(quotaStateProvider.notifier).refresh(triggerSync: true),
                            onOpenSettings: _openSettingsWindow,
                            onCollapse: () => ref
                                .read(settingsNotifierProvider.notifier)
                                .setDisplayMode(DisplayMode.compact),
                            onCycleDemo: settings.isDemoMode
                                ? () => ref.read(quotaStateProvider.notifier).nextDemoPreset()
                                : null,
                            onHeaderDragStart: (_) => _startDragging(),
                            onHeaderDragEnd: (_) => _savePosition(),
                          ),
                        ),
                    },
                  ),
                ),
              ),
            ),
          ),

          // First run onboarding modal
          if (_isOnboardingVisible)
            Positioned.fill(
              child: OnboardingDialog(
                onDismiss: () => setState(() => _isOnboardingVisible = false),
                onOpenSettings: _openSettingsWindow,
              ),
            ),
        ],
      ),
    );
  }
}
