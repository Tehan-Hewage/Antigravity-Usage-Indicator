import 'package:flutter/material.dart';
import 'package:antigravity_usage_indicator/core/theme/app_theme.dart';
import 'package:antigravity_usage_indicator/features/quota/domain/quota_snapshot.dart';
import 'package:antigravity_usage_indicator/features/quota/presentation/widgets/quota_percentage.dart';
import 'package:antigravity_usage_indicator/features/quota/presentation/widgets/quota_progress_bar.dart';
import 'package:antigravity_usage_indicator/features/quota/presentation/widgets/stale_indicator.dart';

/// Compact display mode: Default notch view with multi-limit switching support.
class CompactWidget extends StatelessWidget {
  final QuotaSnapshot snapshot;
  final bool showModelName;
  final bool showPercentage;
  final VoidCallback? onCycleQuota;
  final bool hasMultipleQuotas;

  const CompactWidget({
    super.key,
    required this.snapshot,
    this.showModelName = true,
    this.showPercentage = true,
    this.onCycleQuota,
    this.hasMultipleQuotas = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/icons/tray_icon.png',
                width: 17,
                height: 17,
              ),
              const SizedBox(width: 8),
              if (showModelName)
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          snapshot.model,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimaryDark,
                          ),
                        ),
                      ),
                      if (hasMultipleQuotas && onCycleQuota != null) ...[
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: onCycleQuota,
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.all(2.0),
                            child: Icon(Icons.sync_alt_rounded, size: 12, color: AppTheme.sparkleCyan),
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              else
                const Spacer(),
              if (showPercentage) ...[
                QuotaPercentage(
                  snapshot: snapshot,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
                StaleIndicator(snapshot: snapshot, size: 13.0),
              ],
            ],
          ),
          const SizedBox(height: 6),
          QuotaProgressBar(
            snapshot: snapshot,
            height: 4.0,
            borderRadius: 2.0,
          ),
        ],
      ),
    );
  }
}
