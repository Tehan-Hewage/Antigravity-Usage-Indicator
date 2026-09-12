import 'package:flutter/material.dart';

/// Centralized design tokens and theme palettes.
class AppTheme {
  AppTheme._();

  // Dark Palette (Primary Desktop Aesthetic)
  static const Color darkBackground = Color(0xFF0F1117);
  static const Color darkCardBackground = Color(0xFF161922);
  static const Color darkSurface = Color(0xFF1E2330);
  static const Color darkBorder = Color(0x22FFFFFF);
  static const Color darkBorderHover = Color(0x44FFFFFF);

  // Light Palette (Adaptive)
  static const Color lightBackground = Color(0xFFF3F4F6);
  static const Color lightCardBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFE5E7EB);
  static const Color lightBorder = Color(0x1F000000);
  static const Color lightBorderHover = Color(0x3D000000);

  // Typography Colors (Dark)
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  static const Color textTertiaryDark = Color(0xFF6B7280);

  // Typography Colors (Light)
  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF4B5563);
  static const Color textTertiaryLight = Color(0xFF9CA3AF);

  // Quota Status Accent Colors
  static const Color normalGradientStart = Color(0xFF10B981); // Emerald
  static const Color normalGradientEnd = Color(0xFF06B6D4);   // Cyan

  static const Color lowGradientStart = Color(0xFFF59E0B);    // Amber
  static const Color lowGradientEnd = Color(0xFFEAB308);      // Gold

  static const Color criticalGradientStart = Color(0xFFEF4444); // Red
  static const Color criticalGradientEnd = Color(0xFFF43F5E);   // Rose

  static const Color exhaustedColor = Color(0xFF9CA3AF);       // Muted gray
  static const Color exhaustedAccent = Color(0xFFDC2626);      // Dark red

  // AI Sparkle Branding Color
  static const Color sparkleCyan = Color(0xFF38BDF8);
  static const Color sparkleIndigo = Color(0xFF818CF8);

  // Radii
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 14.0;
  static const double radiusPill = 22.0;
  static const double radiusExpanded = 24.0;

  // Box Shadows
  static const List<BoxShadow> widgetShadow = [
    BoxShadow(
      color: Color(0x55000000),
      blurRadius: 18.0,
      spreadRadius: 2.0,
      offset: Offset(0, 6),
    ),
    BoxShadow(
      color: Color(0x22000000),
      blurRadius: 4.0,
      offset: Offset(0, 1),
    ),
  ];

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: sparkleCyan,
        secondary: sparkleIndigo,
        surface: darkSurface,
        onPrimary: Colors.black,
        onSurface: textPrimaryDark,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: darkSurface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: darkBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        textStyle: const TextStyle(
          color: textPrimaryDark,
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
        ),
        waitDuration: const Duration(milliseconds: 500),
      ),
      fontFamily: 'Segoe UI',
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: sparkleIndigo,
        secondary: sparkleCyan,
        surface: lightSurface,
        onPrimary: Colors.white,
        onSurface: textPrimaryLight,
      ),
      fontFamily: 'Segoe UI',
    );
  }
}
