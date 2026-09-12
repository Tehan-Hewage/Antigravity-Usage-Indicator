import 'dart:async';
import 'dart:io';
import 'package:antigravity_usage_indicator/core/services/logging_service.dart';
import 'package:antigravity_usage_indicator/features/quota/data/local_json_quota_provider.dart';
import 'package:antigravity_usage_indicator/features/quota/data/mock_quota_provider.dart';
import 'package:antigravity_usage_indicator/features/quota/data/quota_provider.dart';
import 'package:antigravity_usage_indicator/features/quota/domain/quota_snapshot.dart';

/// Repository that orchestrates the active quota data source and provides streams to Riverpod.
class QuotaRepository {
  QuotaProvider _activeProvider;
  bool _isDemoMode;
  StreamSubscription<QuotaSnapshot>? _providerSubscription;
  final StreamController<QuotaSnapshot> _streamController = StreamController<QuotaSnapshot>.broadcast();
  QuotaSnapshot? _cachedSnapshot;
  DateTime? _lastSyncTime;

  QuotaRepository({
    bool isDemoMode = false,
    File? customFile,
    int staleThresholdMinutes = 15,
  })  : _isDemoMode = isDemoMode,
        _activeProvider = isDemoMode
            ? MockQuotaProvider()
            : LocalJsonQuotaProvider(file: customFile, staleThresholdMinutes: staleThresholdMinutes) {
    _bindProvider();
  }

  bool get isDemoMode => _isDemoMode;
  QuotaSnapshot? get cachedSnapshot => _cachedSnapshot;

  Stream<QuotaSnapshot> watchQuota() => _streamController.stream;

  void _bindProvider() {
    _providerSubscription?.cancel();
    _providerSubscription = _activeProvider.watchQuota().listen(
      (snapshot) {
        _cachedSnapshot = snapshot;
        _streamController.add(snapshot);
      },
      onError: (e) {
        LoggingService.instance.error('Error from active quota provider', e);
      },
    );
  }

  /// Refreshes quota from the current provider, optionally triggering sync bridge.
  Future<QuotaSnapshot> refresh({bool triggerSync = false}) async {
    if (triggerSync && !_isDemoMode && Platform.isWindows) {
      await _tryRunSyncBridge();
    }

    final snapshot = await _activeProvider.getQuota();
    _cachedSnapshot = snapshot;
    _streamController.add(snapshot);
    return snapshot;
  }

  Future<void> _tryRunSyncBridge() async {
    // Debounce rapid sync requests (minimum 5s interval)
    if (_lastSyncTime != null && DateTime.now().difference(_lastSyncTime!) < const Duration(seconds: 5)) {
      LoggingService.instance.info('Sync bridge invocation debounced');
      return;
    }

    try {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final candidates = [
        File(r'scripts\sync_daemon.ps1'),
        File('${Directory.current.path}\\scripts\\sync_daemon.ps1'),
        File('$exeDir\\scripts\\sync_daemon.ps1'),
        File('$exeDir\\..\\scripts\\sync_daemon.ps1'),
        File(r'bridge\quota_bridge.ps1'),
        File('${Directory.current.path}\\bridge\\quota_bridge.ps1'),
        File('$exeDir\\bridge\\quota_bridge.ps1'),
        File('$exeDir\\..\\bridge\\quota_bridge.ps1'),
      ];

      for (final f in candidates) {
        if (f.existsSync()) {
          _lastSyncTime = DateTime.now();
          LoggingService.instance.info('Triggering sync bridge: ${f.path}');
          final isDaemon = f.path.toLowerCase().contains('sync_daemon');
          final args = [
            '-WindowStyle',
            'Hidden',
            '-ExecutionPolicy',
            'Bypass',
            '-File',
            f.absolute.path,
            if (isDaemon) '-RunOnce',
          ];
          await Process.run('powershell.exe', args).timeout(const Duration(seconds: 5));
          break;
        }
      }
    } catch (e) {
      LoggingService.instance.warn('Sync bridge invocation skipped: $e');
    }
  }

  /// Toggles demo mode on or off.
  Future<void> setDemoMode(bool enableDemo, {File? quotaFile, int staleThresholdMinutes = 15}) async {
    if (_isDemoMode == enableDemo) return;

    _isDemoMode = enableDemo;
    _activeProvider.dispose();

    if (enableDemo) {
      _activeProvider = MockQuotaProvider();
      LoggingService.instance.info('Switched QuotaRepository to MockQuotaProvider (Demo Mode)');
    } else {
      _activeProvider = LocalJsonQuotaProvider(file: quotaFile, staleThresholdMinutes: staleThresholdMinutes);
      LoggingService.instance.info('Switched QuotaRepository to LocalJsonQuotaProvider');
    }

    _bindProvider();
    await refresh();
  }

  /// Cycles to the next demo preset if currently in demo mode.
  void nextDemoPreset() {
    if (_activeProvider is MockQuotaProvider) {
      (_activeProvider as MockQuotaProvider).nextPreset();
    }
  }

  void updateStaleThreshold(int minutes) {
    if (_activeProvider is LocalJsonQuotaProvider) {
      (_activeProvider as LocalJsonQuotaProvider).staleThresholdMinutes = minutes;
    }
  }

  void dispose() {
    _providerSubscription?.cancel();
    _activeProvider.dispose();
    _streamController.close();
  }
}
