import 'dart:developer' as developer;
import 'dart:io';
import 'package:antigravity_usage_indicator/core/constants/app_constants.dart';

enum LogLevel { debug, info, warn, error }

/// Lightweight rotating logger for desktop diagnostics.
class LoggingService {
  LoggingService._();
  static final LoggingService instance = LoggingService._();

  File? _logFile;
  bool _debugLoggingEnabled = false;
  static const int _maxLogSizeBytes = 2 * 1024 * 1024; // 2 MB

  Future<void> init({bool enableDebug = false}) async {
    _debugLoggingEnabled = enableDebug;
    try {
      final file = AppConstants.defaultLogFile;
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }
      _logFile = file;
      info('LoggingService initialized. Target: ${file.path}');
    } catch (e) {
      developer.log('Failed to initialize logging file: $e', name: 'LoggingService');
    }
  }

  void setDebugLogging(bool enabled) {
    _debugLoggingEnabled = enabled;
  }

  void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (_debugLoggingEnabled) {
      _writeLog(LogLevel.debug, message, error, stackTrace);
    }
  }

  void info(String message) {
    _writeLog(LogLevel.info, message);
  }

  void warn(String message, [Object? error]) {
    _writeLog(LogLevel.warn, message, error);
  }

  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _writeLog(LogLevel.error, message, error, stackTrace);
  }

  void _writeLog(LogLevel level, String message, [Object? error, StackTrace? stackTrace]) {
    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase().padRight(5);
    final errorPart = error != null ? ' | Error: $error' : '';
    final stackPart = stackTrace != null ? '\n$stackTrace' : '';
    final logLine = '[$timestamp] [$levelStr] $message$errorPart$stackPart\n';

    // Console output
    developer.log(message, name: 'AGY', error: error, stackTrace: stackTrace);

    // File output
    final file = _logFile;
    if (file != null) {
      _rotateIfNeeded(file);
      file.writeAsString(logLine, mode: FileMode.append, flush: false).catchError((_) => file);
    }
  }

  void _rotateIfNeeded(File file) {
    try {
      if (file.existsSync() && file.lengthSync() > _maxLogSizeBytes) {
        final backup = File('${file.path}.1');
        if (backup.existsSync()) {
          backup.deleteSync();
        }
        file.renameSync(backup.path);
      }
    } catch (_) {}
  }
}
