import 'package:flutter/material.dart';
import 'package:antigravity_usage_indicator/core/theme/app_theme.dart';
import 'package:antigravity_usage_indicator/core/utils/date_time_utils.dart';
import 'package:antigravity_usage_indicator/features/quota/domain/quota_snapshot.dart';

/// Renders the remaining countdown until the quota cycle resets.
class ResetCountdown extends StatelessWidget {
  final QuotaSnapshot snapshot;
  final bool showIcon;
  final double fontSize;
  final Color? color;

  const ResetCountdown({
    super.key,
    required this.snapshot,
    this.showIcon = false,
    this.fontSize = 12.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final text = DateTimeUtils.formatCountdown(snapshot.resetTime);
    final textColor = color ?? AppTheme.textSecondaryDark;

    if (!showIcon) {
      return Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          color: textColor,
          fontWeight: FontWeight.w400,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.schedule_rounded,
          size: fontSize + 2,
          color: textColor.withValues(alpha: 0.8),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            color: textColor,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
