import 'package:flutter/material.dart';
import 'package:antigravity_usage_indicator/core/theme/app_theme.dart';
import 'package:antigravity_usage_indicator/features/quota/domain/quota_snapshot.dart';

/// Renders the numerical percentage with health-aware colors and typography.
class QuotaPercentage extends StatelessWidget {
  final QuotaSnapshot snapshot;
  final double fontSize;
  final FontWeight fontWeight;

  const QuotaPercentage({
    super.key,
    required this.snapshot,
    this.fontSize = 14.0,
    this.fontWeight = FontWeight.w600,
  });

  @override
  Widget build(BuildContext context) {
    final String text;
    final Color textColor;

    if (snapshot.isMissing) {
      text = '--%';
      textColor = AppTheme.textSecondaryDark;
    } else {
      text = '${snapshot.remainingPercent}%';
      if (snapshot.isExhausted) {
        textColor = AppTheme.criticalGradientStart;
      } else if (snapshot.isCritical) {
        textColor = AppTheme.criticalGradientStart;
      } else if (snapshot.isLow) {
        textColor = AppTheme.lowGradientStart;
      } else {
        textColor = AppTheme.textPrimaryDark;
      }
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: textColor,
        letterSpacing: -0.2,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
