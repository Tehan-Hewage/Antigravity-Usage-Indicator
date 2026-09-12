import 'package:flutter/material.dart';
import 'package:antigravity_usage_indicator/core/theme/app_theme.dart';
import 'package:antigravity_usage_indicator/features/quota/domain/quota_snapshot.dart';

/// Subtle warning indicator shown when quota data has not been updated recently.
class StaleIndicator extends StatelessWidget {
  final QuotaSnapshot snapshot;
  final double size;

  const StaleIndicator({
    super.key,
    required this.snapshot,
    this.size = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    if (!snapshot.isStale && !snapshot.hasError) {
      return const SizedBox.shrink();
    }

    final isError = snapshot.hasError;
    final icon = isError ? Icons.error_outline_rounded : Icons.warning_amber_rounded;
    final color = isError ? AppTheme.criticalGradientStart : AppTheme.lowGradientStart;
    final tooltip = isError
        ? (snapshot.errorMessage ?? 'Error reading quota data.')
        : 'Quota data has not been updated recently.';

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.only(left: 3.0),
        child: Icon(
          icon,
          size: size,
          color: color,
        ),
      ),
    );
  }
}
