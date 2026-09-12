import 'dart:async';
import 'package:antigravity_usage_indicator/features/quota/data/quota_provider.dart';
import 'package:antigravity_usage_indicator/features/quota/domain/quota_snapshot.dart';

/// Mock quota provider for offline development, demonstrations, and tests.
class MockQuotaProvider implements QuotaProvider {
  static const List<int> demoPresets = [62, 27, 8, 0, 92];
  int _currentIndex = 0;

  final StreamController<QuotaSnapshot> _controller = StreamController<QuotaSnapshot>.broadcast();
  Timer? _autoRotateTimer;

  MockQuotaProvider({bool autoRotate = false, Duration rotateInterval = const Duration(seconds: 15)}) {
    if (autoRotate) {
      _autoRotateTimer = Timer.periodic(rotateInterval, (_) => nextPreset());
    }
  }

  int get currentPercent => demoPresets[_currentIndex];

  @override
  Future<QuotaSnapshot> getQuota() async {
    return _buildCurrentSnapshot();
  }

  @override
  Stream<QuotaSnapshot> watchQuota() {
    return _controller.stream;
  }

  /// Cycles to the next demo preset and emits an update.
  void nextPreset() {
    _currentIndex = (_currentIndex + 1) % demoPresets.length;
    _controller.add(_buildCurrentSnapshot());
  }

  /// Sets a specific preset percentage.
  void setPercent(int percent) {
    final idx = demoPresets.indexOf(percent);
    if (idx != -1) {
      _currentIndex = idx;
    }
    _controller.add(_buildCurrentSnapshot(customPercent: percent));
  }

  QuotaSnapshot _buildCurrentSnapshot({int? customPercent}) {
    final pct = customPercent ?? demoPresets[_currentIndex];
    return QuotaSnapshot.demo(
      percent: pct,
      model: 'Gemini',
      plan: 'Pro (DEMO)',
      resetOffset: const Duration(days: 2, hours: 13, minutes: 24),
    );
  }

  @override
  void dispose() {
    _autoRotateTimer?.cancel();
    _controller.close();
  }
}
