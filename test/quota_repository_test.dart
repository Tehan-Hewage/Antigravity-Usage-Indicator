import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:antigravity_usage_indicator/features/quota/data/local_json_quota_provider.dart';
import 'package:antigravity_usage_indicator/features/quota/data/mock_quota_provider.dart';
import 'package:antigravity_usage_indicator/features/quota/data/quota_repository.dart';
import 'package:antigravity_usage_indicator/features/quota/domain/quota_status.dart';

void main() {
  group('MockQuotaProvider Tests', () {
    test('MockQuotaProvider initial state and preset rotation', () async {
      final mock = MockQuotaProvider();
      final initial = await mock.getQuota();
      expect(initial.remainingPercent, 62);
      expect(initial.model, 'Gemini');

      mock.nextPreset();
      final next = await mock.getQuota();
      expect(next.remainingPercent, 27);

      mock.nextPreset();
      final critical = await mock.getQuota();
      expect(critical.remainingPercent, 8);

      mock.nextPreset();
      final exhausted = await mock.getQuota();
      expect(exhausted.remainingPercent, 0);

      mock.nextPreset();
      final high = await mock.getQuota();
      expect(high.remainingPercent, 92);

      mock.dispose();
    });
  });

  group('LocalJsonQuotaProvider Tests', () {
    late Directory tempDir;
    late File testQuotaFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('quota_test_');
      testQuotaFile = File('${tempDir.path}\\quota.json');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Returns missing status when file does not exist', () async {
      final provider = LocalJsonQuotaProvider(file: testQuotaFile);
      final snapshot = await provider.getQuota();
      expect(snapshot.status, QuotaDataStatus.missing);
      expect(snapshot.remainingPercent, 0);
      provider.dispose();
    });

    test('Reads valid quota file successfully', () async {
      await testQuotaFile.writeAsString('''
{
  "provider": "google-antigravity",
  "model": "Gemini 1.5 Pro",
  "remainingPercent": 75,
  "plan": "Pro",
  "resetTime": "2026-09-15T12:00:00Z",
  "updatedAt": "${DateTime.now().toIso8601String()}"
}
''');

      final provider = LocalJsonQuotaProvider(file: testQuotaFile);
      final snapshot = await provider.getQuota();
      expect(snapshot.status, QuotaDataStatus.fresh);
      expect(snapshot.remainingPercent, 75);
      expect(snapshot.model, 'Gemini 1.5 Pro');
      provider.dispose();
    });

    test('Marks data stale if older than stale threshold', () async {
      final oldTime = DateTime.now().subtract(const Duration(minutes: 45));
      await testQuotaFile.writeAsString('''
{
  "model": "Gemini",
  "remainingPercent": 50,
  "updatedAt": "${oldTime.toIso8601String()}"
}
''');

      final provider = LocalJsonQuotaProvider(
        file: testQuotaFile,
        staleThresholdMinutes: 15,
      );
      final snapshot = await provider.getQuota();
      expect(snapshot.status, QuotaDataStatus.stale);
      expect(snapshot.isStale, isTrue);
      expect(snapshot.remainingPercent, 50); // retains last known value
      provider.dispose();
    });

    test('Handles malformed JSON gracefully', () async {
      await testQuotaFile.writeAsString('{ invalid_json: ');

      final provider = LocalJsonQuotaProvider(file: testQuotaFile);
      final snapshot = await provider.getQuota();
      expect(snapshot.status, QuotaDataStatus.error);
      expect(snapshot.hasError, isTrue);
      provider.dispose();
    });
  });

  group('QuotaRepository Tests', () {
    test('Switches between Demo mode and Local file mode', () async {
      final repo = QuotaRepository(isDemoMode: true);
      expect(repo.isDemoMode, isTrue);

      final demoSnap = await repo.refresh();
      expect(demoSnap.remainingPercent, 62);

      await repo.setDemoMode(false);
      expect(repo.isDemoMode, isFalse);

      repo.dispose();
    });
  });
}
