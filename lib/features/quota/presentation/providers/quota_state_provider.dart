import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:antigravity_usage_indicator/features/quota/data/quota_repository.dart';
import 'package:antigravity_usage_indicator/features/quota/domain/quota_snapshot.dart';
import 'package:antigravity_usage_indicator/features/settings/presentation/providers/settings_provider.dart';

class QuotaState {
  final QuotaSnapshot snapshot;
  final int selectedIndex;
  final bool isRefreshing;
  final DateTime? lastRefreshTime;
  final int countdownPulse; // Increments every minute for countdown refresh

  const QuotaState({
    required this.snapshot,
    this.selectedIndex = 0,
    this.isRefreshing = false,
    this.lastRefreshTime,
    this.countdownPulse = 0,
  });

  /// The active quota to display in widgets.
  QuotaSnapshot get activeQuota {
    if (snapshot.subQuotas.isNotEmpty && selectedIndex >= 0 && selectedIndex < snapshot.subQuotas.length) {
      return snapshot.subQuotas[selectedIndex];
    }
    return snapshot;
  }

  bool get hasMultipleQuotas => snapshot.subQuotas.length > 1;
  List<QuotaSnapshot> get allQuotas => snapshot.subQuotas.isNotEmpty ? snapshot.subQuotas : [snapshot];

  QuotaState copyWith({
    QuotaSnapshot? snapshot,
    int? selectedIndex,
    bool? isRefreshing,
    DateTime? lastRefreshTime,
    int? countdownPulse,
  }) {
    return QuotaState(
      snapshot: snapshot ?? this.snapshot,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      lastRefreshTime: lastRefreshTime ?? this.lastRefreshTime,
      countdownPulse: countdownPulse ?? this.countdownPulse,
    );
  }
}

final quotaRepositoryProvider = Provider<QuotaRepository>((ref) {
  final settings = ref.watch(settingsNotifierProvider);
  final repo = QuotaRepository(
    isDemoMode: settings.isDemoMode,
    customFile: settings.quotaFilePath != null ? File(settings.quotaFilePath!) : null,
    staleThresholdMinutes: settings.staleThresholdMinutes,
  );

  ref.onDispose(() {
    repo.dispose();
  });

  return repo;
});

final quotaStateProvider = StateNotifierProvider<QuotaNotifier, QuotaState>((ref) {
  final repository = ref.watch(quotaRepositoryProvider);
  return QuotaNotifier(repository);
});

class QuotaNotifier extends StateNotifier<QuotaState> {
  final QuotaRepository _repository;
  StreamSubscription<QuotaSnapshot>? _subscription;
  Timer? _minutePulseTimer;

  QuotaNotifier(this._repository)
      : super(QuotaState(snapshot: _repository.cachedSnapshot ?? QuotaSnapshot.missing())) {
    _init();
  }

  void _init() {
    _subscription = _repository.watchQuota().listen((snapshot) {
      state = state.copyWith(
        snapshot: snapshot,
        isRefreshing: false,
        lastRefreshTime: DateTime.now(),
      );
    });

    // Minute timer for countdown label recalculation without hitting disk
    _minutePulseTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      state = state.copyWith(countdownPulse: state.countdownPulse + 1);
    });

    // Initial load
    refresh();
  }

  Future<void> refresh({bool triggerSync = false}) async {
    state = state.copyWith(isRefreshing: true);
    try {
      final snapshot = await _repository.refresh(triggerSync: triggerSync);
      state = state.copyWith(
        snapshot: snapshot,
        isRefreshing: false,
        lastRefreshTime: DateTime.now(),
      );
    } catch (_) {
      state = state.copyWith(isRefreshing: false);
    }
  }

  void selectQuotaIndex(int index) {
    if (index >= 0 && index < state.allQuotas.length) {
      state = state.copyWith(selectedIndex: index);
    }
  }

  void cycleNextQuota() {
    final list = state.allQuotas;
    if (list.length > 1) {
      final nextIdx = (state.selectedIndex + 1) % list.length;
      state = state.copyWith(selectedIndex: nextIdx);
    }
  }

  void selectPreferredMetric(String metric) {
    final list = state.allQuotas;
    final idx = list.indexWhere((q) => q.model.toLowerCase().contains(metric.toLowerCase()));
    if (idx != -1) {
      selectQuotaIndex(idx);
    }
  }

  void nextDemoPreset() {
    _repository.nextDemoPreset();
  }

  Timer? _autoSyncTimer;

  /// Starts background auto-synchronization loop.
  void startAutoSync({Duration interval = const Duration(minutes: 2)}) {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(interval, (_) {
      refresh(triggerSync: true);
    });
  }

  /// Stops background auto-synchronization loop.
  void stopAutoSync() {
    _autoSyncTimer?.cancel();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _minutePulseTimer?.cancel();
    _autoSyncTimer?.cancel();
    super.dispose();
  }
}
