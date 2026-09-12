import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:antigravity_usage_indicator/app/routes.dart';
import 'package:antigravity_usage_indicator/core/constants/app_constants.dart';
import 'package:antigravity_usage_indicator/core/theme/app_theme.dart';
import 'package:antigravity_usage_indicator/features/settings/presentation/providers/settings_provider.dart';
import 'package:antigravity_usage_indicator/features/settings/presentation/settings_screen.dart';
import 'package:antigravity_usage_indicator/features/widget/presentation/floating_widget_screen.dart';

/// Root application widget configuring themes, routes, and provider scope.
class AntigravityApp extends ConsumerWidget {
  const AntigravityApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      initialRoute: AppRoutes.widget,
      routes: {
        AppRoutes.widget: (context) => const FloatingWidgetScreen(),
        AppRoutes.settings: (context) => const SettingsScreen(),
      },
    );
  }
}
