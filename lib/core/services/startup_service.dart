import 'dart:io';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:antigravity_usage_indicator/core/constants/app_constants.dart';
import 'package:antigravity_usage_indicator/core/services/logging_service.dart';

/// Manages Windows startup registration using launch_at_startup.
class StartupService {
  StartupService._();
  static final StartupService instance = StartupService._();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized || !Platform.isWindows) return;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      launchAtStartup.setup(
        appName: AppConstants.appName,
        appPath: Platform.resolvedExecutable,
        packageName: packageInfo.packageName.isNotEmpty ? packageInfo.packageName : 'com.antigravity.usageindicator',
      );
      _initialized = true;
      LoggingService.instance.info('StartupService initialized for ${Platform.resolvedExecutable}');
    } catch (e, st) {
      LoggingService.instance.error('Failed to initialize StartupService', e, st);
    }
  }

  Future<bool> isEnabled() async {
    if (!Platform.isWindows || !_initialized) return false;
    try {
      return await launchAtStartup.isEnabled();
    } catch (e) {
      LoggingService.instance.warn('Error checking startup status', e);
      return false;
    }
  }

  Future<bool> setEnabled(bool enable) async {
    if (!Platform.isWindows) return false;
    if (!_initialized) await init();

    try {
      if (enable) {
        await launchAtStartup.enable();
      } else {
        await launchAtStartup.disable();
      }
      LoggingService.instance.info('Set launch-at-startup to $enable');
      return true;
    } catch (e, st) {
      LoggingService.instance.error('Failed to update launch-at-startup', e, st);
      return false;
    }
  }
}
