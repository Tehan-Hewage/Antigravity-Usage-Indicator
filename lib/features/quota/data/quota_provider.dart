import 'package:antigravity_usage_indicator/features/quota/domain/quota_snapshot.dart';

/// Abstract interface for decoupled quota data sources.
abstract class QuotaProvider {
  /// Fetches a one-time snapshot of the current quota.
  Future<QuotaSnapshot> getQuota();

  /// Watches for real-time changes to the quota.
  Stream<QuotaSnapshot> watchQuota();

  /// Releases resources (file watchers, timers, streams).
  void dispose();
}
