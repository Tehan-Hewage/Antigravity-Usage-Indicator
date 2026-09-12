import 'package:flutter/material.dart';
import 'package:antigravity_usage_indicator/core/theme/app_theme.dart';
import 'package:antigravity_usage_indicator/core/utils/date_time_utils.dart';
import 'package:antigravity_usage_indicator/features/quota/domain/quota_snapshot.dart';
import 'package:antigravity_usage_indicator/features/quota/presentation/widgets/quota_percentage.dart';
import 'package:antigravity_usage_indicator/features/quota/presentation/widgets/quota_progress_bar.dart';
import 'package:antigravity_usage_indicator/features/quota/presentation/widgets/stale_indicator.dart';

/// Expanded display mode with multi-quota limit switching (Weekly vs 5-Hour etc.).
class ExpandedWidget extends StatelessWidget {
  final QuotaSnapshot snapshot;
  final List<QuotaSnapshot> allQuotas;
  final int selectedQuotaIndex;
  final ValueChanged<int>? onSelectQuota;
  final bool isRefreshing;
  final VoidCallback onRefresh;
  final VoidCallback onOpenSettings;
  final VoidCallback onCollapse;
  final VoidCallback? onCycleDemo;
  final GestureDragStartCallback? onHeaderDragStart;
  final GestureDragEndCallback? onHeaderDragEnd;

  const ExpandedWidget({
    super.key,
    required this.snapshot,
    this.allQuotas = const [],
    this.selectedQuotaIndex = 0,
    this.onSelectQuota,
    required this.isRefreshing,
    required this.onRefresh,
    required this.onOpenSettings,
    required this.onCollapse,
    this.onCycleDemo,
    this.onHeaderDragStart,
    this.onHeaderDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    final hasMultiple = allQuotas.length > 1;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Draggable Header Row
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: onHeaderDragStart,
                    onPanEnd: onHeaderDragEnd,
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/icons/tray_icon.png',
                          width: 17,
                          height: 17,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Antigravity / ${snapshot.model}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.0,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (onCycleDemo != null) ...[
                  Tooltip(
                    message: 'Cycle demo percentage',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onCycleDemo,
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.sparkleIndigo.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppTheme.sparkleIndigo.withValues(alpha: 0.4)),
                          ),
                          child: const Text(
                            'DEMO',
                            style: TextStyle(fontSize: 9.0, fontWeight: FontWeight.bold, color: AppTheme.sparkleCyan),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                // Collapse button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onCollapse,
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.keyboard_arrow_up_rounded, size: 20, color: AppTheme.textSecondaryDark),
                    ),
                  ),
                ),
              ],
            ),

            // Multi-Quota Selector Tabs (Weekly vs 5-Hour)
            if (hasMultiple) ...[
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: allQuotas.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final q = entry.value;
                    final isSelected = idx == selectedQuotaIndex;

                    // Clean label: e.g. "Weekly: 69%" or "5-Hour: 81%"
                    final shortTitle = q.model.replaceAll('Gemini ', '').replaceAll('Claude / GPT ', '');
                    final label = '$shortTitle ${q.remainingPercent}%';

                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => onSelectQuota?.call(idx),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.sparkleIndigo.withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppTheme.sparkleCyan : AppTheme.darkBorder,
                                width: isSelected ? 1.2 : 0.8,
                              ),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 11.0,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                color: isSelected ? AppTheme.sparkleCyan : AppTheme.textSecondaryDark,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 8),

            // Percentage & Health Status Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                QuotaPercentage(
                  snapshot: snapshot,
                  fontSize: 20.0,
                  fontWeight: FontWeight.w700,
                ),
                const SizedBox(width: 6),
                Text(
                  snapshot.isMissing
                      ? 'waiting'
                      : (snapshot.quotaName != null ? snapshot.quotaName! : 'remaining'),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppTheme.textSecondaryDark,
                  ),
                ),
                const Spacer(),
                StaleIndicator(snapshot: snapshot, size: 15.0),
              ],
            ),

            const SizedBox(height: 6),

            // Progress Bar
            QuotaProgressBar(
              snapshot: snapshot,
              height: 5.0,
              borderRadius: 2.5,
            ),

            const SizedBox(height: 10),

            // Key-Value Rows
            _buildInfoRow('Resets in', DateTimeUtils.formatCountdown(snapshot.resetTime)),
            _buildInfoRow('Reset time', DateTimeUtils.formatResetDateTime(snapshot.resetTime)),
            _buildInfoRow('Plan', snapshot.plan ?? 'Standard'),
            _buildInfoRow(
              'Updated',
              snapshot.isMissing ? 'Never' : DateTimeUtils.formatRelativeTime(snapshot.updatedAt),
            ),

            const SizedBox(height: 10),

            // Bottom Action Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Settings Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onOpenSettings,
                    borderRadius: BorderRadius.circular(6),
                    hoverColor: Colors.white.withValues(alpha: 0.08),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      child: Row(
                        children: [
                          Icon(Icons.settings_outlined, size: 14, color: AppTheme.textSecondaryDark),
                          SizedBox(width: 5),
                          Text(
                            'Settings',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Refresh Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isRefreshing ? null : onRefresh,
                    borderRadius: BorderRadius.circular(6),
                    hoverColor: AppTheme.sparkleCyan.withValues(alpha: 0.12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      child: Row(
                        children: [
                          if (isRefreshing)
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.6,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.sparkleCyan),
                              ),
                            )
                          else
                            const Icon(Icons.refresh_rounded, size: 14, color: AppTheme.sparkleCyan),
                          const SizedBox(width: 5),
                          Text(
                            isRefreshing ? 'Refreshing...' : 'Refresh',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.sparkleCyan,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppTheme.textSecondaryDark,
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppTheme.textPrimaryDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
