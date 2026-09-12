import 'package:flutter_test/flutter_test.dart';
import 'package:antigravity_usage_indicator/core/utils/date_time_utils.dart';
import 'package:antigravity_usage_indicator/core/utils/percentage_utils.dart';
import 'package:antigravity_usage_indicator/features/quota/domain/quota_snapshot.dart';
import 'package:antigravity_usage_indicator/features/quota/domain/quota_status.dart';

void main() {
  group('PercentageUtils Tests', () {
    test('Percentage clamping bounds', () {
      expect(PercentageUtils.clampPercent(-1), 0);
      expect(PercentageUtils.clampPercent(-50), 0);
      expect(PercentageUtils.clampPercent(0), 0);
      expect(PercentageUtils.clampPercent(62), 62);
      expect(PercentageUtils.clampPercent(100), 100);
      expect(PercentageUtils.clampPercent(150), 100);
    });

    test('Fraction to percent conversion and clamping', () {
      expect(PercentageUtils.fractionToPercent(0.62), 62);
      expect(PercentageUtils.fractionToPercent(0.0), 0);
      expect(PercentageUtils.fractionToPercent(1.0), 100);
      expect(PercentageUtils.fractionToPercent(-0.1), 0);
      expect(PercentageUtils.fractionToPercent(1.5), 100);
    });

    test('Dynamic percent parsing', () {
      expect(PercentageUtils.parsePercent(62), 62);
      expect(PercentageUtils.parsePercent(62.4), 62);
      expect(PercentageUtils.parsePercent('62%'), 62);
      expect(PercentageUtils.parsePercent('150'), 100);
      expect(PercentageUtils.parsePercent('-5'), 0);
      expect(PercentageUtils.parsePercent(null), isNull);
    });
  });

  group('DateTimeUtils Tests', () {
    test('Reset countdown formatting future intervals', () {
      final now = DateTime(2026, 9, 11, 12, 0, 0);

      // 2 days 13 hours
      final t1 = now.add(const Duration(days: 2, hours: 13));
      expect(DateTimeUtils.formatCountdown(t1, now: now), 'Resets in 2d 13h');

      // 5 hours 24 minutes
      final t2 = now.add(const Duration(hours: 5, minutes: 24));
      expect(DateTimeUtils.formatCountdown(t2, now: now), 'Resets in 5h 24m');

      // 12 minutes
      final t3 = now.add(const Duration(minutes: 12));
      expect(DateTimeUtils.formatCountdown(t3, now: now), 'Resets in 12m');

      // < 1 minute
      final t4 = now.add(const Duration(seconds: 30));
      expect(DateTimeUtils.formatCountdown(t4, now: now), 'Resets in < 1m');
    });

    test('Reset countdown formatting past interval', () {
      final now = DateTime(2026, 9, 11, 12, 0, 0);
      final past = now.subtract(const Duration(minutes: 5));
      expect(DateTimeUtils.formatCountdown(past, now: now), 'Reset expected');
    });

    test('Relative time formatting', () {
      final now = DateTime(2026, 9, 11, 12, 0, 0);
      expect(DateTimeUtils.formatRelativeTime(now.subtract(const Duration(seconds: 20)), now: now), 'Just now');
      expect(DateTimeUtils.formatRelativeTime(now.subtract(const Duration(minutes: 2)), now: now), '2 min ago');
      expect(DateTimeUtils.formatRelativeTime(now.subtract(const Duration(minutes: 21)), now: now), '21 min ago');
    });
  });

  group('QuotaSnapshot Thresholds & Calculations', () {
    test('Normal threshold (> 30%)', () {
      final s = QuotaSnapshot.demo(percent: 62);
      expect(s.remainingPercent, 62);
      expect(s.usedPercent, 38);
      expect(s.isNormal, isTrue);
      expect(s.isLow, isFalse);
      expect(s.isCritical, isFalse);
      expect(s.isExhausted, isFalse);
    });

    test('Low threshold (11 - 30%)', () {
      final s = QuotaSnapshot.demo(percent: 23);
      expect(s.remainingPercent, 23);
      expect(s.usedPercent, 77);
      expect(s.isNormal, isFalse);
      expect(s.isLow, isTrue);
      expect(s.isCritical, isFalse);
      expect(s.isExhausted, isFalse);
    });

    test('Critical threshold (1 - 10%)', () {
      final s = QuotaSnapshot.demo(percent: 7);
      expect(s.remainingPercent, 7);
      expect(s.usedPercent, 93);
      expect(s.isNormal, isFalse);
      expect(s.isLow, isFalse);
      expect(s.isCritical, isTrue);
      expect(s.isExhausted, isFalse);
    });

    test('Exhausted threshold (0%)', () {
      final s = QuotaSnapshot.demo(percent: 0);
      expect(s.remainingPercent, 0);
      expect(s.usedPercent, 100);
      expect(s.isNormal, isFalse);
      expect(s.isLow, isFalse);
      expect(s.isCritical, isFalse);
      expect(s.isExhausted, isTrue);
    });
  });

  group('QuotaSnapshot JSON Deserialization', () {
    test('Parses complete standard JSON', () {
      final json = {
        "provider": "google-antigravity",
        "model": "Gemini",
        "quotaName": "gemini-weekly",
        "remainingPercent": 62,
        "plan": "Pro",
        "resetTime": "2026-09-15T07:50:32Z",
        "updatedAt": "2026-09-11T19:42:00Z"
      };

      final s = QuotaSnapshot.fromJson(json);
      expect(s.provider, 'google-antigravity');
      expect(s.model, 'Gemini');
      expect(s.quotaName, 'gemini-weekly');
      expect(s.remainingPercent, 62);
      expect(s.remainingFraction, 0.62);
      expect(s.plan, 'Pro');
      expect(s.resetTime, isNotNull);
      expect(s.status, QuotaDataStatus.fresh);
    });

    test('Parses JSON with fraction instead of percent', () {
      final json = {
        "remainingFraction": 0.45,
        "model": "Gemini 1.5 Flash"
      };

      final s = QuotaSnapshot.fromJson(json);
      expect(s.remainingPercent, 45);
      expect(s.remainingFraction, 0.45);
      expect(s.model, 'Gemini 1.5 Flash');
      expect(s.plan, 'Pro'); // default fallback
    });

    test('Parses multi-model quota schema', () {
      final json = {
        "quotas": [
          {"model": "Gemini 1.5 Pro", "remainingPercent": 85},
          {"model": "Gemini Flash", "remainingPercent": 95}
        ]
      };

      final s = QuotaSnapshot.fromJson(json);
      expect(s.model, 'Gemini 1.5 Pro');
      expect(s.remainingPercent, 85);
    });

    test('Missing factory constructor', () {
      final s = QuotaSnapshot.missing();
      expect(s.status, QuotaDataStatus.missing);
      expect(s.isMissing, isTrue);
      expect(s.remainingPercent, 0);
    });

    test('Error factory preserves last known snapshot', () {
      final valid = QuotaSnapshot.demo(percent: 62);
      final err = QuotaSnapshot.error('Disk read error', lastKnown: valid);
      expect(err.hasError, isTrue);
      expect(err.remainingPercent, 62);
      expect(err.errorMessage, 'Disk read error');
    });
  });
}
