import 'package:intl/intl.dart';

/// Formatting utilities for quota reset countdowns and update timestamps.
class DateTimeUtils {
  DateTimeUtils._();

  /// Formats the remaining time until reset into compact text (e.g. "Resets in 2d 13h").
  static String formatCountdown(DateTime? resetTime, {DateTime? now}) {
    if (resetTime == null) return 'No reset scheduled';
    final currentTime = now ?? DateTime.now();

    if (resetTime.isBefore(currentTime)) {
      return 'Reset expected';
    }

    final diff = resetTime.difference(currentTime);
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;

    if (days > 0) {
      return 'Resets in ${days}d ${hours}h';
    } else if (hours > 0) {
      return 'Resets in ${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return 'Resets in ${minutes}m';
    } else {
      return 'Resets in < 1m';
    }
  }

  /// Formats reset timestamp into human readable day & time (e.g. "Mon 1:20 PM").
  static String formatResetDateTime(DateTime? resetTime) {
    if (resetTime == null) return 'Not available';
    final local = resetTime.toLocal();
    final now = DateTime.now();
    final diff = resetTime.difference(now);

    if (diff.inDays.abs() < 7) {
      return DateFormat('EEE h:mm a').format(local);
    } else {
      return DateFormat('MMM d, h:mm a').format(local);
    }
  }

  /// Formats a relative timestamp (e.g. "Just now", "2 min ago", "7:45 PM").
  static String formatRelativeTime(DateTime dateTime, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final diff = currentTime.difference(dateTime);

    if (diff.inSeconds < 45) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m min ago';
    } else if (diff.inHours < 24 && dateTime.day == currentTime.day) {
      return DateFormat('h:mm a').format(dateTime.toLocal());
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime.toLocal());
    }
  }

  /// Formats a precise relative timestamp with second/minute granularity (e.g. "Just now", "25s ago", "2 min ago").
  static String formatPreciseRelativeTime(DateTime dateTime, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final diff = currentTime.difference(dateTime);

    if (diff.isNegative || diff.inSeconds < 10) {
      return 'Just now';
    } else if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m min ago';
    } else if (diff.inHours < 24 && dateTime.day == currentTime.day) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime.toLocal());
    }
  }

  /// Safely parses a dynamic input into a DateTime.
  static DateTime? parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) {
      // Unix timestamp (handle seconds vs milliseconds)
      if (value < 10000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true);
      }
      return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
    }
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
