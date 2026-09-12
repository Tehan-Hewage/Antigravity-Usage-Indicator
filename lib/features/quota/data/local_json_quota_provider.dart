import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:antigravity_usage_indicator/core/constants/app_constants.dart';
import 'package:antigravity_usage_indicator/core/services/logging_service.dart';
import 'package:antigravity_usage_indicator/features/quota/data/quota_provider.dart';
import 'package:antigravity_usage_indicator/features/quota/domain/quota_snapshot.dart';
import 'package:antigravity_usage_indicator/features/quota/domain/quota_status.dart';

/// Reads and monitors local quota.json file on Windows.
class LocalJsonQuotaProvider implements QuotaProvider {
  final File file;
  int staleThresholdMinutes;

  final StreamController<QuotaSnapshot> _controller = StreamController<QuotaSnapshot>.broadcast();
  StreamSubscription<FileSystemEvent>? _watchSubscription;
  Timer? _debounceTimer;
  Timer? _fallbackPollingTimer;
  QuotaSnapshot? _lastValidSnapshot;
  bool _isDisposed = false;

  LocalJsonQuotaProvider({
    File? file,
    this.staleThresholdMinutes = 15,
  }) : file = file ?? AppConstants.defaultQuotaFile {
    _startWatching();
    _startFallbackPolling();
  }

  @override
  Future<QuotaSnapshot> getQuota() async {
    return _readFromFile();
  }

  @override
  Stream<QuotaSnapshot> watchQuota() {
    return _controller.stream;
  }

  void _startWatching() {
    try {
      final parentDir = file.parent;
      if (!parentDir.existsSync()) {
        parentDir.createSync(recursive: true);
      }

      // Watch parent directory to catch file creation, deletion, and rename events
      _watchSubscription = parentDir.watch().listen(
        (event) {
          final eventPath = event.path.toLowerCase();
          final targetPath = file.path.toLowerCase();
          if (eventPath.endsWith('quota.json') || eventPath == targetPath) {
            _onFileEvent();
          }
        },
        onError: (e) {
          LoggingService.instance.warn('Directory watcher error, relying on fallback polling', e);
        },
      );
      LoggingService.instance.info('Started watching quota directory: ${parentDir.path}');
    } catch (e, st) {
      LoggingService.instance.warn('Could not initialize directory watcher: $e', st);
    }
  }

  void _startFallbackPolling() {
    // Check every 30 seconds as fallback
    _fallbackPollingTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (_isDisposed) return;
      final snapshot = await _readFromFile();
      _controller.add(snapshot);
    });
  }

  void _onFileEvent() {
    _debounceTimer?.cancel();
    // Wait 300ms for atomic file operations or multi-part writes to finalize
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (_isDisposed) return;
      final snapshot = await _readFromFile();
      _controller.add(snapshot);
    });
  }

  Future<QuotaSnapshot> _readFromFile() async {
    try {
      if (!await file.exists()) {
        return QuotaSnapshot.missing();
      }

      // If file is very large (> 512KB), reject for security
      final length = await file.length();
      if (length > 512 * 1024) {
        LoggingService.instance.error('quota.json exceeded size limit: $length bytes');
        return QuotaSnapshot.error(
          'quota.json exceeds maximum size (512KB)',
          lastKnown: _lastValidSnapshot,
        );
      }

      String content = '';
      try {
        content = await file.readAsString();
      } catch (_) {
        // File may be temporarily locked by bridge/writer, retry once after 120ms
        await Future.delayed(const Duration(milliseconds: 120));
        content = await file.readAsString();
      }

      if (content.trim().isEmpty) {
        return QuotaSnapshot.missing();
      }

      final dynamic decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Root JSON element must be an object');
      }

      var snapshot = QuotaSnapshot.fromJson(decoded);

      // Check stale status
      if (staleThresholdMinutes > 0) {
        final age = DateTime.now().difference(snapshot.updatedAt).inMinutes;
        if (age >= staleThresholdMinutes) {
          snapshot = snapshot.copyWith(status: QuotaDataStatus.stale);
        }
      }

      _lastValidSnapshot = snapshot;
      return snapshot;
    } on FormatException catch (e, st) {
      LoggingService.instance.error('Malformed JSON in quota.json', e, st);
      return QuotaSnapshot.error('Malformed JSON in quota.json', lastKnown: _lastValidSnapshot);
    } catch (e, st) {
      LoggingService.instance.error('Error reading quota.json', e, st);
      return QuotaSnapshot.error('Error reading quota data: $e', lastKnown: _lastValidSnapshot);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounceTimer?.cancel();
    _fallbackPollingTimer?.cancel();
    _watchSubscription?.cancel();
    _controller.close();
  }
}
