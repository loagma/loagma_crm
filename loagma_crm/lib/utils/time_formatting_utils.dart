import 'package:intl/intl.dart';

/// Utility class for consistent time formatting across the application
class TimeFormattingUtils {
  /// 24-hour threshold for determining relative vs absolute time display
  static const int _hoursThreshold = 24;

  /// Returns a relative time string (e.g., "2h 30m ago", "3d ago")
  /// for times within the last 24 hours, or absolute time for older dates
  static String getTimeAgo(DateTime dateTime) {
    final Duration diff = DateTime.now().difference(dateTime);

    // Use relative time for recent dates (within 24 hours)
    if (diff.inHours < _hoursThreshold) {
      return _getRelativeTime(diff);
    }

    // Use absolute time for older dates
    return getFormattedDateTime(dateTime);
  }

  /// Returns a relative time string (e.g., "2h 30m ago", "3d ago")
  /// regardless of the time threshold
  static String getRelativeTime(DateTime dateTime) {
    final Duration diff = DateTime.now().difference(dateTime);
    return _getRelativeTime(diff);
  }

  /// Returns a formatted absolute date and time string
  /// Format: "Dec 22, 2024 • 02:30 PM"
  static String getFormattedDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
  }

  /// Returns a relative time string with null safety
  /// Returns "Unknown" if dateTime is null
  static String getTimeAgoSafe(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';
    return getTimeAgo(dateTime);
  }

  /// Returns a relative time string with null safety and custom fallback
  static String getTimeAgoWithFallback(DateTime? dateTime, String fallback) {
    if (dateTime == null) return fallback;
    return getTimeAgo(dateTime);
  }

  /// Internal method to calculate relative time string from duration
  static String _getRelativeTime(Duration diff) {
    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()}y ago';
    } else if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()}mo ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      // Show hours and minutes for better precision within the day
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      if (minutes > 0) {
        return '${hours}h ${minutes}m ago';
      } else {
        return '${hours}h ago';
      }
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inSeconds > 30) {
      return '${diff.inSeconds}s ago';
    } else {
      return 'Just now';
    }
  }

  /// Determines if a date should use relative time formatting
  /// Returns true if the date is within the 24-hour threshold
  static bool shouldUseRelativeTime(DateTime dateTime) {
    final Duration diff = DateTime.now().difference(dateTime);
    return diff.inHours < _hoursThreshold;
  }

  /// Returns appropriate time format based on the 24-hour threshold
  /// - Relative format for recent dates (< 24 hours)
  /// - Absolute format for older dates (>= 24 hours)
  static String getAdaptiveTimeFormat(DateTime dateTime) {
    return shouldUseRelativeTime(dateTime)
        ? getRelativeTime(dateTime)
        : getFormattedDateTime(dateTime);
  }
}
