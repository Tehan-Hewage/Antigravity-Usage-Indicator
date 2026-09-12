import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:antigravity_usage_indicator/core/constants/app_constants.dart';
import 'package:antigravity_usage_indicator/core/theme/app_theme.dart';
import 'package:antigravity_usage_indicator/features/settings/presentation/providers/settings_provider.dart';

/// Lightweight onboarding dialog shown on first launch explaining tray and quota data.
class OnboardingDialog extends ConsumerStatefulWidget {
  final VoidCallback onDismiss;
  final VoidCallback onOpenSettings;

  const OnboardingDialog({
    super.key,
    required this.onDismiss,
    required this.onOpenSettings,
  });

  @override
  ConsumerState<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends ConsumerState<OnboardingDialog> {
  bool _dontShowAgain = true;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.darkBackground.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.darkBorderHover, width: 1.2),
          boxShadow: AppTheme.widgetShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset('assets/icons/app_icon.png', width: 28, height: 28),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Welcome to Antigravity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryDark,
                    ),
                  ),
                ),
                InkWell(
                  onTap: _close,
                  child: const Icon(Icons.close, size: 18, color: AppTheme.textSecondaryDark),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'This widget floats at the top of your screen to show remaining Antigravity / Gemini quota.\n\n'
              '• Runs in your Windows system tray.\n'
              '• Click the pill to toggle details.\n'
              '• Waiting for your local quota data file.',
              style: TextStyle(fontSize: 12.5, height: 1.45, color: AppTheme.textSecondaryDark),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Use Demo Data
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(settingsNotifierProvider.notifier).setDemoMode(true);
                      _close();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.sparkleIndigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Use Demo Data', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 8),
                // Open Folder
                OutlinedButton(
                  onPressed: () {
                    _openDataFolder();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimaryDark,
                    side: const BorderSide(color: AppTheme.darkBorder),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Data Folder', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: _dontShowAgain,
                    onChanged: (val) => setState(() => _dontShowAgain = val ?? true),
                    activeColor: AppTheme.sparkleCyan,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "Don't show this again",
                  style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondaryDark),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _close() {
    if (_dontShowAgain) {
      ref.read(settingsNotifierProvider.notifier).setCompletedOnboarding(true);
    }
    widget.onDismiss();
  }

  void _openDataFolder() {
    final dir = AppConstants.defaultAppDirectory;
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    Process.run('explorer.exe', [dir.path]);
  }
}
