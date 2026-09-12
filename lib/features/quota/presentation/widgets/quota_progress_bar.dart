import 'package:flutter/material.dart';
import 'package:antigravity_usage_indicator/core/constants/app_constants.dart';
import 'package:antigravity_usage_indicator/core/theme/app_theme.dart';
import 'package:antigravity_usage_indicator/features/quota/domain/quota_snapshot.dart';

/// Animated progress bar displaying remaining quota with semantic gradient accents.
class QuotaProgressBar extends StatelessWidget {
  final QuotaSnapshot snapshot;
  final double height;
  final double borderRadius;

  const QuotaProgressBar({
    super.key,
    required this.snapshot,
    this.height = 4.0,
    this.borderRadius = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final targetProgress = (snapshot.remainingPercent / 100.0).clamp(0.0, 1.0);

    // Gradient based on quota health
    final List<Color> gradientColors;
    if (snapshot.isExhausted) {
      gradientColors = const [AppTheme.exhaustedAccent, AppTheme.exhaustedColor];
    } else if (snapshot.isCritical) {
      gradientColors = const [AppTheme.criticalGradientStart, AppTheme.criticalGradientEnd];
    } else if (snapshot.isLow) {
      gradientColors = const [AppTheme.lowGradientStart, AppTheme.lowGradientEnd];
    } else {
      gradientColors = const [AppTheme.normalGradientStart, AppTheme.normalGradientEnd];
    }

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: targetProgress),
            duration: AppConstants.progressAnimationDuration,
            curve: Curves.easeOutCubic,
            builder: (context, progress, _) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(borderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors.first.withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
