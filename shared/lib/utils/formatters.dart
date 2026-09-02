import 'package:intl/intl.dart';

class Formatters {
  /// Relative time formatter for chat list and messages ("5m ago", "just now", "1h ago", etc.)
  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 45) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  /// Clock time format (e.g. "6:00 PM")
  static String formatTimeOnly(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  /// Human friendly date + time (e.g., "today 6:00 PM", "tomorrow 10:30 AM", "Sep 4, 6:00 PM")
  static String formatFriendlyDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final timeStr = DateFormat('h:mm a').format(dateTime);

    if (targetDate == today) {
      return 'today $timeStr';
    } else if (targetDate == today.add(const Duration(days: 1))) {
      return 'tomorrow $timeStr';
    } else {
      return '${DateFormat('MMM d').format(dateTime)} at $timeStr';
    }
  }

  /// Full date format for logs e.g. "Wed, Sep 2, 2026"
  static String formatDateFull(DateTime dateTime) {
    return DateFormat('EEE, MMM d, yyyy').format(dateTime);
  }

  /// Format duration in seconds to standard readable string ("12m 45s", "45s", "1h 15m")
  static String formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    }
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes < 60) {
      return remainingSeconds > 0 ? '${minutes}m ${remainingSeconds}s' : '${minutes}m';
    }
    final hours = minutes ~/ 60;
    final remMinutes = minutes % 60;
    return remMinutes > 0 ? '${hours}h ${remMinutes}m' : '${hours}h';
  }
}
