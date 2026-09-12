import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:antigravity_usage_indicator/core/constants/app_constants.dart';
import 'package:antigravity_usage_indicator/core/services/window_service.dart';
import 'package:antigravity_usage_indicator/core/theme/app_theme.dart';
import 'package:antigravity_usage_indicator/core/utils/date_time_utils.dart';
import 'package:antigravity_usage_indicator/features/quota/presentation/providers/quota_state_provider.dart';
import 'package:antigravity_usage_indicator/features/quota/presentation/widgets/quota_progress_bar.dart';
import 'package:antigravity_usage_indicator/features/settings/presentation/providers/settings_provider.dart';
import 'package:antigravity_usage_indicator/shared/widgets/app_card.dart';
import 'package:antigravity_usage_indicator/shared/widgets/app_switch_tile.dart';

/// Overhauled desktop settings screen featuring glassmorphic design tokens,
/// real-time sync telemetry, and 5-Hour vs Weekly metric customization.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _tabs = [
    {'title': 'Live Sync', 'icon': Icons.bolt_rounded, 'badge': 'LIVE'},
    {'title': 'General', 'icon': Icons.tune_rounded},
    {'title': 'Appearance', 'icon': Icons.palette_outlined},
    {'title': 'Position', 'icon': Icons.open_with_rounded},
    {'title': 'Data Source', 'icon': Icons.storage_rounded},
    {'title': 'About', 'icon': Icons.info_outline_rounded},
  ];

  Timer? _tickerTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    // Refresh UI every 2 seconds so relative time ticker counts up accurately
    _tickerTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);
    final quotaState = ref.watch(quotaStateProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (_) => WindowService.instance.startDragging(),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.sparkleIndigo.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.sparkleCyan.withValues(alpha: 0.4)),
                ),
                child: Image.asset('assets/icons/tray_icon.png', width: 18, height: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Antigravity Settings',
                      style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryDark, letterSpacing: -0.2),
                    ),
                    Text(
                      'Drag header to reposition · Telemetry, widget layout & live session synchronization',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark, fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: AppTheme.darkCardBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimaryDark),
          tooltip: 'Return to Floating Widget',
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.center_focus_strong_rounded, size: 18, color: AppTheme.sparkleCyan),
            tooltip: 'Center Settings Window',
            onPressed: () => WindowService.instance.centerSettingsWindow(),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20, color: AppTheme.textSecondaryDark),
            tooltip: 'Close Settings',
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.darkBorder, width: 1)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppTheme.sparkleCyan,
              unselectedLabelColor: AppTheme.textSecondaryDark,
              indicatorColor: AppTheme.sparkleCyan,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
              tabs: _tabs.map((t) {
                final hasBadge = t['badge'] != null;
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(t['icon'] as IconData, size: 16),
                      const SizedBox(width: 6),
                      Text(t['title'] as String),
                      if (hasBadge) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppTheme.normalGradientStart.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppTheme.normalGradientStart.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            t['badge'] as String,
                            style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppTheme.normalGradientStart),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Live Sync & Telemetry
          _buildLiveSyncTab(settings, notifier, quotaState),

          // 2. General
          _buildGeneralTab(settings, notifier),

          // 3. Appearance
          _buildAppearanceTab(settings, notifier),

          // 4. Position
          _buildPositionTab(settings, notifier),

          // 5. Data Source
          _buildDataTab(settings, notifier, quotaState),

          // 6. About
          _buildAboutTab(settings, notifier),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: LIVE SYNC & TELEMETRY
  // ==========================================
  Widget _buildLiveSyncTab(dynamic settings, SettingsNotifier notifier, QuotaState quotaState) {
    final syncTime = quotaState.snapshot.updatedAt;
    final isMissing = quotaState.snapshot.isMissing;
    final timeFormatted = !isMissing ? DateFormat('h:mm:ss a').format(syncTime.toLocal()) : 'Never';
    final relativeText = !isMissing ? DateTimeUtils.formatPreciseRelativeTime(syncTime) : 'Never';
    final lastSyncText = !isMissing ? '$relativeText ($timeFormatted)' : 'Never';
    final allQuotas = quotaState.allQuotas;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Live Status Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkCardBackground,
                AppTheme.sparkleIndigo.withValues(alpha: 0.12),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: AppTheme.sparkleCyan.withValues(alpha: 0.3)),
            boxShadow: AppTheme.widgetShadow,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.normalGradientStart.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.normalGradientStart.withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppTheme.normalGradientStart, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Antigravity IDE Connected',
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.normalGradientStart.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('LOOPBACK HTTPS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.normalGradientStart)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Live metrics synced via local Language Server RPC • Last update: $lastSyncText',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryDark),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                icon: quotaState.isRefreshing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 1.8, color: Colors.black),
                      )
                    : const Icon(Icons.sync_rounded, size: 16),
                label: Text(quotaState.isRefreshing ? 'Syncing...' : 'Sync Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.sparkleCyan,
                  foregroundColor: Colors.black,
                  textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: quotaState.isRefreshing
                    ? null
                    : () async {
                        await ref.read(quotaStateProvider.notifier).refresh(triggerSync: true);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('⚡ Quota successfully synchronized from Antigravity session!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Primary Metric & Frequency Configuration Card
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.tune_rounded, size: 16, color: AppTheme.sparkleCyan),
                  SizedBox(width: 8),
                  Text('Primary Display & Sync Frequency', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimaryDark)),
                ],
              ),
              const SizedBox(height: 14),

              // Primary Metric Selector
              const Text('Default Floating Notch Metric', style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryDark, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text(
                'Choose which quota metric displays by default when the compact floating pill is idle.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryDark),
              ),
              const SizedBox(height: 10),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: '5-Hour',
                    label: Text('⚡ 5-Hour Limit (Recommended)'),
                    icon: Icon(Icons.flash_on_rounded, size: 14),
                  ),
                  ButtonSegment(
                    value: 'Weekly',
                    label: Text('📅 Weekly Limit'),
                    icon: Icon(Icons.calendar_today_rounded, size: 14),
                  ),
                ],
                selected: {settings.primaryMetric},
                onSelectionChanged: (val) {
                  final chosen = val.first;
                  notifier.setPrimaryMetric(chosen);
                  ref.read(quotaStateProvider.notifier).selectPreferredMetric(chosen);
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppTheme.sparkleIndigo.withValues(alpha: 0.35);
                    }
                    return Colors.transparent;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppTheme.sparkleCyan;
                    }
                    return AppTheme.textSecondaryDark;
                  }),
                ),
              ),

              const SizedBox(height: 18),
              const Divider(color: AppTheme.darkBorder),
              const SizedBox(height: 12),

              // Auto-sync Frequency
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Background Auto-Sync Interval', style: TextStyle(fontSize: 13.5, color: AppTheme.textPrimaryDark, fontWeight: FontWeight.w600)),
                      SizedBox(height: 2),
                      Text('How frequently the indicator queries the local IDE process', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryDark)),
                    ],
                  ),
                  DropdownButton<int>(
                    value: settings.autoSyncIntervalMinutes,
                    dropdownColor: AppTheme.darkCardBackground,
                    style: const TextStyle(color: AppTheme.sparkleCyan, fontSize: 13, fontWeight: FontWeight.w600),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1 minute (High Frequency)')),
                      DropdownMenuItem(value: 2, child: Text('2 minutes (Recommended)')),
                      DropdownMenuItem(value: 3, child: Text('3 minutes')),
                      DropdownMenuItem(value: 5, child: Text('5 minutes')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        notifier.setAutoSyncIntervalMinutes(val);
                        ref.read(quotaStateProvider.notifier).startAutoSync(interval: Duration(minutes: val));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Auto-sync interval set to $val minute(s).'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Live Quota Telemetry Cards
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.dashboard_customize_outlined, size: 16, color: AppTheme.sparkleCyan),
                  SizedBox(width: 8),
                  Text('Current Session Quotas Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimaryDark)),
                ],
              ),
              const SizedBox(height: 14),
              if (allQuotas.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text('No quota data available yet. Click "Sync Now" above to fetch metrics.', style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondaryDark)),
                )
              else
                Column(
                  children: allQuotas.map((q) {
                    final isPrimary = q.model.toLowerCase().contains(settings.primaryMetric.toLowerCase());
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isPrimary ? AppTheme.sparkleIndigo.withValues(alpha: 0.12) : AppTheme.darkSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isPrimary ? AppTheme.sparkleCyan.withValues(alpha: 0.4) : AppTheme.darkBorder,
                          width: isPrimary ? 1.2 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    q.model,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: isPrimary ? FontWeight.bold : FontWeight.w600,
                                      color: isPrimary ? AppTheme.sparkleCyan : AppTheme.textPrimaryDark,
                                    ),
                                  ),
                                  if (isPrimary) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.sparkleCyan.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('ACTIVE NOTCH', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.sparkleCyan)),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                '${q.remainingPercent}%',
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimaryDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          QuotaProgressBar(snapshot: q, height: 4.5, borderRadius: 2.5),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                q.quotaName ?? 'Remaining',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark),
                              ),
                              Text(
                                'Resets in ${DateTimeUtils.formatCountdown(q.resetTime)}',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 2: GENERAL
  // ==========================================
  Widget _buildGeneralTab(dynamic settings, SettingsNotifier notifier) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.tune_rounded, size: 16, color: AppTheme.sparkleCyan),
                  SizedBox(width: 8),
                  Text('System Integration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimaryDark)),
                ],
              ),
              const SizedBox(height: 12),
              AppSwitchTile(
                title: 'Start Antigravity with Windows',
                subtitle: 'Launch automatically into the system tray when logging into Windows',
                value: settings.launchAtStartup,
                onChanged: (val) => notifier.setLaunchAtStartup(val),
              ),
              const Divider(color: AppTheme.darkBorder),
              AppSwitchTile(
                title: 'Always on Top',
                subtitle: 'Keep the floating notch above full-screen editors and IDEs',
                value: settings.alwaysOnTop,
                onChanged: (val) => notifier.setAlwaysOnTop(val),
              ),
              const Divider(color: AppTheme.darkBorder),
              AppSwitchTile(
                title: 'Remember Screen Position',
                subtitle: 'Restore your saved coordinates when the application restarts',
                value: settings.rememberPosition,
                onChanged: (val) => notifier.setRememberPosition(val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 3: APPEARANCE
  // ==========================================
  Widget _buildAppearanceTab(dynamic settings, SettingsNotifier notifier) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.palette_outlined, size: 16, color: AppTheme.sparkleCyan),
                  SizedBox(width: 8),
                  Text('Widget Display Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimaryDark)),
                ],
              ),
              const SizedBox(height: 12),
              SegmentedButton<DisplayMode>(
                segments: const [
                  ButtonSegment(value: DisplayMode.minimal, label: Text('Minimal (Pill)')),
                  ButtonSegment(value: DisplayMode.compact, label: Text('Compact (Notch)')),
                  ButtonSegment(value: DisplayMode.expanded, label: Text('Expanded (Card)')),
                ],
                selected: {settings.displayMode},
                onSelectionChanged: (val) => notifier.setDisplayMode(val.first),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppTheme.sparkleIndigo.withValues(alpha: 0.35);
                    }
                    return Colors.transparent;
                  }),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Widget Background Opacity', style: TextStyle(fontSize: 13.5, color: AppTheme.textPrimaryDark, fontWeight: FontWeight.w500)),
                  Text('${(settings.widgetOpacity * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.sparkleCyan)),
                ],
              ),
              Slider(
                value: settings.widgetOpacity,
                min: AppConstants.minOpacity,
                max: AppConstants.maxOpacity,
                divisions: 30,
                activeColor: AppTheme.sparkleCyan,
                onChanged: (val) => notifier.setWidgetOpacity(val),
              ),
              const Divider(color: AppTheme.darkBorder),
              AppSwitchTile(
                title: 'Show Model Label',
                subtitle: 'Display model title (e.g. 5-Hour or Weekly) in the compact pill',
                value: settings.showModelName,
                onChanged: (val) => notifier.setShowModelName(val),
              ),
              const Divider(color: AppTheme.darkBorder),
              AppSwitchTile(
                title: 'Show Percentage Counter',
                subtitle: 'Display numerical percentage value in real-time',
                value: settings.showPercentage,
                onChanged: (val) => notifier.setShowPercentage(val),
              ),
              const Divider(color: AppTheme.darkBorder),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Auto-collapse Expanded View', style: TextStyle(fontSize: 13.5, color: AppTheme.textPrimaryDark, fontWeight: FontWeight.w500)),
                      Text('Return smoothly to compact mode after inactivity', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryDark)),
                    ],
                  ),
                  DropdownButton<int>(
                    value: settings.autoCollapseSeconds,
                    dropdownColor: AppTheme.darkCardBackground,
                    style: const TextStyle(color: AppTheme.sparkleCyan, fontSize: 13, fontWeight: FontWeight.w600),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Never (Manual)')),
                      DropdownMenuItem(value: 3, child: Text('3 seconds')),
                      DropdownMenuItem(value: 5, child: Text('5 seconds')),
                      DropdownMenuItem(value: 10, child: Text('10 seconds')),
                    ],
                    onChanged: (val) {
                      if (val != null) notifier.setAutoCollapseSeconds(val);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 4: POSITION
  // ==========================================
  Widget _buildPositionTab(dynamic settings, SettingsNotifier notifier) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.desktop_windows_rounded, size: 16, color: AppTheme.sparkleCyan),
                  SizedBox(width: 8),
                  Text('Settings Window Position', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimaryDark)),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'You can drag the Settings window anywhere on your screen using the top header bar. Click below to immediately center the window on your primary monitor.',
                style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondaryDark, height: 1.4),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                icon: const Icon(Icons.center_focus_strong_rounded, size: 16),
                label: const Text('Center Settings Window'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.sparkleIndigo.withValues(alpha: 0.25),
                  foregroundColor: AppTheme.sparkleCyan,
                  side: const BorderSide(color: AppTheme.sparkleCyan, width: 1.0),
                ),
                onPressed: () async {
                  await WindowService.instance.centerSettingsWindow();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings window centered on display.')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.open_with_rounded, size: 16, color: AppTheme.sparkleCyan),
                  SizedBox(width: 8),
                  Text('Floating Widget Placement & Edge Snapping', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimaryDark)),
                ],
              ),
              const SizedBox(height: 12),
              AppSwitchTile(
                title: 'Magnetic Top-Center Snapping',
                subtitle: 'Automatically snap floating widget to top center when dragged nearby',
                value: settings.edgeSnappingEnabled,
                onChanged: (val) => notifier.setEdgeSnapping(val),
              ),
              const SizedBox(height: 16),
              const Text('Quick Placement Presets (Floating Widget)', style: TextStyle(fontSize: 13.5, color: AppTheme.textPrimaryDark, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              const Text(
                'Configures where the floating notch appears when you close Settings.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryDark),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.vertical_align_top_rounded, size: 16),
                    label: const Text('Top Center (Default)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.sparkleIndigo.withValues(alpha: 0.3),
                      foregroundColor: AppTheme.sparkleCyan,
                      side: const BorderSide(color: AppTheme.sparkleCyan, width: 1.0),
                    ),
                    onPressed: () async {
                      final offset = await WindowService.instance.calculatePresetPosition('topCenter', mode: settings.displayMode);
                      if (offset != null) {
                        await notifier.updateWindowPosition(offset.dx, offset.dy);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Widget position set to Top Center. Takes effect when Settings is closed.')),
                          );
                        }
                      }
                    },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.align_horizontal_left_rounded, size: 16),
                    label: const Text('Top Left'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppTheme.textPrimaryDark, side: const BorderSide(color: AppTheme.darkBorder)),
                    onPressed: () async {
                      final offset = await WindowService.instance.calculatePresetPosition('topLeft', mode: settings.displayMode);
                      if (offset != null) {
                        await notifier.updateWindowPosition(offset.dx, offset.dy);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Widget position set to Top Left. Takes effect when Settings is closed.')),
                          );
                        }
                      }
                    },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.align_horizontal_right_rounded, size: 16),
                    label: const Text('Top Right'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppTheme.textPrimaryDark, side: const BorderSide(color: AppTheme.darkBorder)),
                    onPressed: () async {
                      final offset = await WindowService.instance.calculatePresetPosition('topRight', mode: settings.displayMode);
                      if (offset != null) {
                        await notifier.updateWindowPosition(offset.dx, offset.dy);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Widget position set to Top Right. Takes effect when Settings is closed.')),
                          );
                        }
                      }
                    },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.restore_rounded, size: 16),
                    label: const Text('Reset Location'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppTheme.textSecondaryDark, side: const BorderSide(color: AppTheme.darkBorder)),
                    onPressed: () async {
                      await notifier.resetWindowPosition();
                      final offset = await WindowService.instance.calculatePresetPosition('topCenter', mode: settings.displayMode);
                      if (offset != null) {
                        await notifier.updateWindowPosition(offset.dx, offset.dy);
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Widget position reset to default Top Center.')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 5: DATA SOURCE
  // ==========================================
  Widget _buildDataTab(dynamic settings, SettingsNotifier notifier, QuotaState quotaState) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.storage_rounded, size: 16, color: AppTheme.sparkleCyan),
                  SizedBox(width: 8),
                  Text('Quota Data & Storage', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimaryDark)),
                ],
              ),
              const SizedBox(height: 12),
              AppSwitchTile(
                title: 'Demo Mode (Offline Simulation)',
                subtitle: 'Simulate rotating quota states (92%, 62%, 27%, 8%, 0%) without querying the local session',
                value: settings.isDemoMode,
                onChanged: (val) => notifier.setDemoMode(val),
              ),
              const Divider(color: AppTheme.darkBorder),
              const SizedBox(height: 6),
              const Text('Active Quota File Path', style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryDark, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                settings.quotaFilePath ?? AppConstants.defaultQuotaFile.path,
                style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondaryDark, fontFamily: 'Consolas'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.folder_open_rounded, size: 16),
                    label: const Text('Open Data Folder'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.darkSurface, foregroundColor: AppTheme.textPrimaryDark),
                    onPressed: () {
                      final dir = AppConstants.defaultAppDirectory;
                      if (!dir.existsSync()) dir.createSync(recursive: true);
                      Process.run('explorer.exe', [dir.path]);
                    },
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Force Refresh'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppTheme.sparkleCyan, side: const BorderSide(color: AppTheme.darkBorder)),
                    onPressed: () => ref.read(quotaStateProvider.notifier).refresh(triggerSync: true),
                  ),
                ],
              ),
              const Divider(color: AppTheme.darkBorder),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Stale Data Warning Threshold', style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryDark, fontWeight: FontWeight.w600)),
                      Text('Show amber warning pill if file is not updated', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryDark)),
                    ],
                  ),
                  DropdownButton<int>(
                    value: settings.staleThresholdMinutes,
                    dropdownColor: AppTheme.darkCardBackground,
                    style: const TextStyle(color: AppTheme.sparkleCyan, fontSize: 13, fontWeight: FontWeight.w600),
                    items: const [
                      DropdownMenuItem(value: 5, child: Text('5 minutes')),
                      DropdownMenuItem(value: 15, child: Text('15 minutes')),
                      DropdownMenuItem(value: 30, child: Text('30 minutes')),
                      DropdownMenuItem(value: 60, child: Text('1 hour')),
                      DropdownMenuItem(value: -1, child: Text('Never mark stale')),
                    ],
                    onChanged: (val) {
                      if (val != null) notifier.setStaleThresholdMinutes(val);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 6: ABOUT & ADVANCED
  // ==========================================
  Widget _buildAboutTab(dynamic settings, SettingsNotifier notifier) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Image.asset('assets/icons/app_icon.png', width: 64, height: 64),
              const SizedBox(height: 14),
              const Text(
                AppConstants.appName,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark),
              ),
              const SizedBox(height: 4),
              Text(
                'Version ${AppConstants.appVersion} • Windows Desktop (x64)',
                style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondaryDark),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.darkBorder),
                ),
                child: const Text(
                  AppConstants.disclaimer,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppTheme.textSecondaryDark),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.article_outlined, size: 16),
                    label: const Text('View App Logs'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppTheme.textPrimaryDark, side: const BorderSide(color: AppTheme.darkBorder)),
                    onPressed: () {
                      final logFile = AppConstants.defaultLogFile;
                      if (logFile.existsSync()) {
                        Process.run('notepad.exe', [logFile.path]);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No logs generated yet.')));
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.restore_page_rounded, size: 16),
                    label: const Text('Factory Reset'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppTheme.criticalGradientStart, side: const BorderSide(color: AppTheme.criticalGradientStart)),
                    onPressed: () async {
                      await notifier.resetToDefaults();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All settings restored to factory defaults.')));
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }
}
