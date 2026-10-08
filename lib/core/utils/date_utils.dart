import 'package:intl/intl.dart';

class AppDateUtils {
  static const String defaultDateFormat = 'yyyy-MM-dd';
  static const String defaultDateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateFormat = 'MMM dd, yyyy';
  static const String displayDateTimeFormat = 'MMM dd, yyyy HH:mm';
  static const String timeFormat = 'HH:mm';
  
  /// Format date to string
  static String formatDate(DateTime date, {String format = defaultDateFormat}) {
    return DateFormat(format).format(date);
  }
  
  /// Format date time to string
  static String formatDateTime(DateTime dateTime, {String format = defaultDateTimeFormat}) {
    return DateFormat(format).format(dateTime);
  }
  
  /// Parse string to date
  static DateTime? parseDate(String dateString, {String format = defaultDateFormat}) {
    try {
      return DateFormat(format).parse(dateString);
    } catch (e) {
      return null;
    }
  }
  
  /// Parse string to date time
  static DateTime? parseDateTime(String dateTimeString, {String format = defaultDateTimeFormat}) {
    try {
      return DateFormat(format).parse(dateTimeString);
    } catch (e) {
      return null;
    }
  }
  
  /// Format date for display
  static String formatDateForDisplay(DateTime date) {
    return formatDate(date, format: displayDateFormat);
  }
  
  /// Format date time for display
  static String formatDateTimeForDisplay(DateTime dateTime) {
    return formatDateTime(dateTime, format: displayDateTimeFormat);
  }
  
  /// Format time for display
  static String formatTimeForDisplay(DateTime time) {
    return formatDateTime(time, format: timeFormat);
  }
  
  /// Get time ago from now
  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
  
  /// Get relative time (today, yesterday, or date)
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else {
      return formatDateForDisplay(dateTime);
    }
  }
  
  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
  
  /// Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && 
           date.month == yesterday.month && 
           date.day == yesterday.day;
  }
  
  /// Add days to date
  static DateTime addDays(DateTime date, int days) {
    return date.add(Duration(days: days));
  }
  
  /// Subtract days from date
  static DateTime subtractDays(DateTime date, int days) {
    return date.subtract(Duration(days: days));
  }
  
  /// Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
  
  /// Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }
  
  /// Get difference in days between two dates
  static int daysBetween(DateTime from, DateTime to) {
    from = startOfDay(from);
    to = startOfDay(to);
    return (to.difference(from).inHours / 24).round();
  }
  
  /// Convert minutes to duration string
  static String formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min${minutes == 1 ? '' : 's'}';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '$hours hour${hours == 1 ? '' : 's'}';
      } else {
        return '$hours hour${hours == 1 ? '' : 's'} $remainingMinutes min${remainingMinutes == 1 ? '' : 's'}';
      }
    }
  }
}