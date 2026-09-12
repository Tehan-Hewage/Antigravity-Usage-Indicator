import 'package:flutter/material.dart';
import 'package:antigravity_usage_indicator/features/quota/domain/quota_snapshot.dart';
import 'package:antigravity_usage_indicator/features/quota/presentation/widgets/quota_percentage.dart';
import 'package:antigravity_usage_indicator/features/quota/presentation/widgets/quota_progress_bar.dart';
import 'package:antigravity_usage_indicator/features/quota/presentation/widgets/stale_indicator.dart';

/// Minimal display mode: Ultra-compact (approx 126x48 px) showing sparkle, percent, and mini bar.
class MinimalWidget extends StatelessWidget {
  final QuotaSnapshot snapshot;

  const MinimalWidget({
    super.key,
    required this.snapshot,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                'assets/icons/tray_icon.png',
                width: 16,
                height: 16,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  QuotaPercentage(
                    snapshot: snapshot,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600,
                  ),
                  StaleIndicator(snapshot: snapshot, size: 12.0),
                ],
              ),
            ],
          ),
          const SizedBox(height: 5),
          QuotaProgressBar(
            snapshot: snapshot,
            height: 3.5,
            borderRadius: 1.75,
          ),
        ],
      ),
    );
  }
}
