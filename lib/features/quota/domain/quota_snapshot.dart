import 'package:antigravity_usage_indicator/core/constants/app_constants.dart';
import 'package:antigravity_usage_indicator/core/utils/date_time_utils.dart';
import 'package:antigravity_usage_indicator/core/utils/percentage_utils.dart';
import 'package:antigravity_usage_indicator/features/quota/domain/quota_status.dart';

/// Strongly-typed immutable snapshot of model usage quota.
class QuotaSnapshot {
  final String provider;
  final String model;
  final String? quotaName;
  final double remainingFraction;
  final int remainingPercent;
  final String? plan;
  final DateTime? resetTime;
  final DateTime updatedAt;
  final QuotaDataStatus status;
  final String? errorMessage;
  final List<QuotaSnapshot> subQuotas;

  const QuotaSnapshot({
    required this.provider,
    required this.model,
    this.quotaName,
    required this.remainingFraction,
    required this.remainingPercent,
    this.plan,
    this.resetTime,
    required this.updatedAt,
    required this.status,
    this.errorMessage,
    this.subQuotas = const [],
  });

  /// Factory constructor for initial missing state (before quota.json is received).
  factory QuotaSnapshot.missing() {
    return QuotaSnapshot(
      provider: 'google-antigravity',
      model: 'Gemini',
      quotaName: 'gemini-quota',
      remainingFraction: 0.0,
      remainingPercent: 0,
      plan: 'Waiting for data',
      resetTime: null,
      updatedAt: DateTime.now(),
      status: QuotaDataStatus.missing,
      errorMessage: 'Waiting for quota data...',
      subQuotas: const [],
    );
  }

  /// Factory constructor for error state, optionally preserving last known valid numbers.
  factory QuotaSnapshot.error(String message, {QuotaSnapshot? lastKnown}) {
    if (lastKnown != null) {
      return lastKnown.copyWith(
        status: QuotaDataStatus.error,
        errorMessage: message,
      );
    }
    return QuotaSnapshot(
      provider: 'google-antigravity',
      model: 'Gemini',
      quotaName: 'gemini-quota',
      remainingFraction: 0.0,
      remainingPercent: 0,
      plan: 'Error',
      resetTime: null,
      updatedAt: DateTime.now(),
      status: QuotaDataStatus.error,
      errorMessage: message,
      subQuotas: const [],
    );
  }

  /// Factory constructor for demo/development presets with multi-limit simulation.
  factory QuotaSnapshot.demo({
    int percent = 69,
    String model = 'Gemini Weekly',
    String plan = 'Google AI Pro (DEMO)',
    Duration resetOffset = const Duration(days: 4, hours: 13),
  }) {
    final clamped = PercentageUtils.clampPercent(percent);
    final now = DateTime.now();

    final subQuotas = [
      QuotaSnapshot(
        provider: 'google-antigravity',
        model: 'Gemini Weekly',
        quotaName: 'Weekly Limit Remaining',
        remainingFraction: clamped / 100.0,
        remainingPercent: clamped,
        plan: plan,
        resetTime: now.add(resetOffset),
        updatedAt: now,
        status: QuotaDataStatus.fresh,
      ),
      QuotaSnapshot(
        provider: 'google-antigravity',
        model: 'Gemini 5-Hour',
        quotaName: 'Five Hour Limit Remaining',
        remainingFraction: 0.81,
        remainingPercent: 81,
        plan: plan,
        resetTime: now.add(const Duration(hours: 1, minutes: 57)),
        updatedAt: now,
        status: QuotaDataStatus.fresh,
      ),
      QuotaSnapshot(
        provider: 'google-antigravity',
        model: 'Claude / GPT Weekly',
        quotaName: 'Weekly Limit Remaining',
        remainingFraction: 0.72,
        remainingPercent: 72,
        plan: plan,
        resetTime: now.add(const Duration(days: 4, hours: 22)),
        updatedAt: now,
        status: QuotaDataStatus.fresh,
      ),
      QuotaSnapshot(
        provider: 'google-antigravity',
        model: 'Claude / GPT 5-Hour',
        quotaName: 'Five Hour Limit Remaining',
        remainingFraction: 1.00,
        remainingPercent: 100,
        plan: plan,
        resetTime: now.add(const Duration(hours: 1, minutes: 57)),
        updatedAt: now,
        status: QuotaDataStatus.fresh,
      ),
    ];

    return QuotaSnapshot(
      provider: 'google-antigravity',
      model: model,
      quotaName: 'Weekly Limit Remaining',
      remainingFraction: clamped / 100.0,
      remainingPercent: clamped,
      plan: plan,
      resetTime: now.add(resetOffset),
      updatedAt: now,
      status: QuotaDataStatus.fresh,
      subQuotas: subQuotas,
    );
  }

  /// Parses JSON payload defensively, extracting sub-quotas when present.
  factory QuotaSnapshot.fromJson(
    Map<String, dynamic> json, {
    QuotaDataStatus status = QuotaDataStatus.fresh,
  }) {
    // 1. Extract sub-quotas if present
    final List<QuotaSnapshot> subQuotas = [];
    if (json.containsKey('quotas') && json['quotas'] is List) {
      for (final item in json['quotas']) {
        if (item is Map<String, dynamic>) {
          final merged = Map<String, dynamic>.from(item);
          merged['provider'] ??= json['provider'];
          merged['plan'] ??= json['plan'];
          merged['updatedAt'] ??= json['updatedAt'];
          subQuotas.add(QuotaSnapshot.fromJson(merged, status: status));
        }
      }
    }

    // 2. Determine target fields (either root or first item of quotas array)
    Map<String, dynamic> target = json;
    if (subQuotas.isNotEmpty && !json.containsKey('remainingPercent') && !json.containsKey('remainingFraction')) {
      final first = (json['quotas'] as List).first;
      if (first is Map<String, dynamic>) {
        target = first;
      }
    }

    // Determine percentage & fraction
    int percent;
    double fraction;

    final rawPercent = PercentageUtils.parsePercent(target['remainingPercent'] ?? target['percentRemaining']);
    final rawFraction = PercentageUtils.parseFraction(target['remainingFraction'] ?? target['fractionRemaining']);

    if (rawPercent != null) {
      percent = rawPercent;
      fraction = rawFraction ?? (percent / 100.0);
    } else if (rawFraction != null) {
      percent = PercentageUtils.fractionToPercent(rawFraction);
      fraction = rawFraction;
    } else {
      percent = 0;
      fraction = 0.0;
    }

    final provider = target['provider']?.toString() ?? json['provider']?.toString() ?? 'google-antigravity';
    final model = target['model']?.toString() ?? 'Gemini';
    final quotaName = target['quotaName']?.toString();
    final plan = target['plan']?.toString() ?? json['plan']?.toString() ?? 'Pro';

    final resetTime = DateTimeUtils.parseDateTime(target['resetTime']);
    final updatedAt = DateTimeUtils.parseDateTime(target['updatedAt'] ?? json['updatedAt']) ?? DateTime.now();

    return QuotaSnapshot(
      provider: provider,
      model: model,
      quotaName: quotaName,
      remainingFraction: fraction,
      remainingPercent: percent,
      plan: plan,
      resetTime: resetTime,
      updatedAt: updatedAt,
      status: status,
      subQuotas: subQuotas,
    );
  }

  /// Serializes to JSON map matching standard schema.
  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'model': model,
      if (quotaName != null) 'quotaName': quotaName,
      'remainingFraction': remainingFraction,
      'remainingPercent': remainingPercent,
      if (plan != null) 'plan': plan,
      if (resetTime != null) 'resetTime': resetTime!.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (subQuotas.isNotEmpty) 'quotas': subQuotas.map((s) => s.toJson()).toList(),
    };
  }

  /// Used percentage: (100 - remainingPercent).
  int get usedPercent => 100 - remainingPercent;

  /// Human-readable remaining time until reset.
  String get timeUntilReset => DateTimeUtils.formatCountdown(resetTime);

  /// Status flags based on thresholds:
  bool get isNormal => remainingPercent > AppConstants.lowThreshold;
  bool get isLow => remainingPercent > AppConstants.criticalThreshold && remainingPercent <= AppConstants.lowThreshold;
  bool get isCritical => remainingPercent > AppConstants.exhaustedThreshold && remainingPercent <= AppConstants.criticalThreshold;
  bool get isExhausted => remainingPercent <= AppConstants.exhaustedThreshold;
  bool get isStale => status == QuotaDataStatus.stale;
  bool get isMissing => status == QuotaDataStatus.missing;
  bool get hasError => status == QuotaDataStatus.error;

  /// Creates a copy with optional updated fields.
  QuotaSnapshot copyWith({
    String? provider,
    String? model,
    String? quotaName,
    double? remainingFraction,
    int? remainingPercent,
    String? plan,
    DateTime? resetTime,
    DateTime? updatedAt,
    QuotaDataStatus? status,
    String? errorMessage,
    List<QuotaSnapshot>? subQuotas,
  }) {
    return QuotaSnapshot(
      provider: provider ?? this.provider,
      model: model ?? this.model,
      quotaName: quotaName ?? this.quotaName,
      remainingFraction: remainingFraction ?? this.remainingFraction,
      remainingPercent: remainingPercent ?? this.remainingPercent,
      plan: plan ?? this.plan,
      resetTime: resetTime ?? this.resetTime,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      subQuotas: subQuotas ?? this.subQuotas,
    );
  }
}
