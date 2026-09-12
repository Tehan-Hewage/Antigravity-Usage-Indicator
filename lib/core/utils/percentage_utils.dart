/// Utility functions for safe percentage calculations and clamping.
class PercentageUtils {
  PercentageUtils._();

  /// Clamps an integer percentage between 0 and 100.
  static int clampPercent(int percent) {
    if (percent < 0) return 0;
    if (percent > 100) return 100;
    return percent;
  }

  /// Converts a fraction (e.g. 0.62) to integer percent (62) clamped to [0, 100].
  static int fractionToPercent(double fraction) {
    final raw = (fraction * 100).round();
    return clampPercent(raw);
  }

  /// Safe extraction from dynamic value (can be int, double, or String).
  static int? parsePercent(dynamic value) {
    if (value == null) return null;
    if (value is int) return clampPercent(value);
    if (value is double) return clampPercent(value.round());
    if (value is String) {
      final parsed = double.tryParse(value.replaceAll('%', '').trim());
      if (parsed != null) return clampPercent(parsed.round());
    }
    return null;
  }

  /// Safe extraction of fraction from dynamic value.
  static double? parseFraction(dynamic value) {
    if (value == null) return null;
    if (value is double) return value.clamp(0.0, 1.0);
    if (value is int) return (value / 100.0).clamp(0.0, 1.0);
    if (value is String) {
      final parsed = double.tryParse(value.trim());
      if (parsed != null) {
        if (parsed > 1.0) return (parsed / 100.0).clamp(0.0, 1.0);
        return parsed.clamp(0.0, 1.0);
      }
    }
    return null;
  }

  /// Converts integer percent to double progress value [0.0, 1.0].
  static double percentToProgress(int percent) {
    return clampPercent(percent) / 100.0;
  }
}
