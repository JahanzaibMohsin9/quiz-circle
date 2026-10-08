import 'package:flutter/material.dart';

/// Extension on String for common operations
extension StringExtensions on String {
  /// Check if string is null or empty
  bool get isNullOrEmpty => isEmpty;

  /// Check if string is not null or empty
  bool get isNotNullOrEmpty => isNotEmpty;

  /// Capitalize first letter
  String get capitalize =>
      '${this[0].toUpperCase()}${substring(1).toLowerCase()}';

  /// Capitalize first letter of each word
  String get capitalizeWords =>
      split(' ').map((word) => word.isEmpty ? word : word.capitalize).join(' ');

  /// Truncate string to specified length
  String truncate(int length, {String suffix = '...'}) {
    if (this.length <= length) return this;
    return '${substring(0, length)}$suffix';
  }

  /// Remove all whitespace
  String get removeWhitespace => replaceAll(RegExp(r'\s+'), '');

  /// Check if string is a valid email
  bool get isValidEmail =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);

  /// Check if string contains only numbers
  bool get isNumeric => RegExp(r'^\d+$').hasMatch(this);

  /// Convert to title case
  String get toTitleCase => replaceAll(
    RegExp(' +'),
    ' ',
  ).split(' ').map((str) => str.capitalize).join(' ');
}

/// Extension on DateTime for common operations
extension DateTimeExtensions on DateTime {
  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Check if date is tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  /// Get start of day
  DateTime get startOfDay => DateTime(year, month, day);

  /// Get end of day
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  /// Get start of week (Monday)
  DateTime get startOfWeek {
    final daysToSubtract = weekday - 1;
    return subtract(Duration(days: daysToSubtract)).startOfDay;
  }

  /// Get end of week (Sunday)
  DateTime get endOfWeek {
    final daysToAdd = 7 - weekday;
    return add(Duration(days: daysToAdd)).endOfDay;
  }

  /// Get start of month
  DateTime get startOfMonth => DateTime(year, month);

  /// Get end of month
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59, 999);

  /// Check if date is same day as another
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Get difference in days (absolute value)
  int daysDifference(DateTime other) {
    final thisDate = startOfDay;
    final otherDate = other.startOfDay;
    return thisDate.difference(otherDate).inDays.abs();
  }
}

/// Extension on List for common operations
extension ListExtensions<T> on List<T> {
  /// Get first element or null if list is empty
  T? get firstOrNull => isEmpty ? null : first;

  /// Get last element or null if list is empty
  T? get lastOrNull => isEmpty ? null : last;

  /// Get element at index or null if index is out of bounds
  T? getOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }

  /// Check if list is null or empty
  bool get isNullOrEmpty => isEmpty;

  /// Check if list is not null or empty
  bool get isNotNullOrEmpty => isNotEmpty;

  /// Split list into chunks of specified size
  List<List<T>> chunked(int chunkSize) {
    if (chunkSize <= 0) return [this];

    final chunks = <List<T>>[];
    for (int i = 0; i < length; i += chunkSize) {
      final end = (i + chunkSize < length) ? i + chunkSize : length;
      chunks.add(sublist(i, end));
    }
    return chunks;
  }

  /// Remove duplicates from list
  List<T> unique() {
    final seen = <dynamic>{};
    return where((element) => seen.add(element)).toList();
  }

  /// Check if list contains any element that satisfies the predicate
  bool any(bool Function(T element) predicate) {
    for (final element in this) {
      if (predicate(element)) return true;
    }
    return false;
  }

  /// Check if all elements satisfy the predicate
  bool all(bool Function(T element) predicate) {
    for (final element in this) {
      if (!predicate(element)) return false;
    }
    return true;
  }
}

/// Extension on int for common operations
extension IntExtensions on int {
  /// Convert minutes to duration string
  String get toDurationString {
    if (this < 60) {
      return '$this min${this == 1 ? '' : 's'}';
    } else {
      final hours = this ~/ 60;
      final remainingMinutes = this % 60;
      if (remainingMinutes == 0) {
        return '$hours hour${hours == 1 ? '' : 's'}';
      } else {
        return '$hours hour${hours == 1 ? '' : 's'} $remainingMinutes min${remainingMinutes == 1 ? '' : 's'}';
      }
    }
  }

  /// Convert to percentage string
  String get toPercentageString => '$this%';

  /// Add leading zeros
  String withLeadingZeros(int width) => toString().padLeft(width, '0');
}

/// Extension on double for common operations
extension DoubleExtensions on double {
  /// Round to specified decimal places
  double roundToDecimalPlaces(int places) {
    final factor = 10 * places;
    return (this * factor).round() / factor;
  }

  /// Convert to percentage string
  String toPercentageString({int decimalPlaces = 1}) {
    return '${roundToDecimalPlaces(decimalPlaces)}%';
  }
}

/// Extension on Color for common operations
extension ColorExtensions on Color {
  /// Convert color to hex string
  String get toHex {
    return '#${(toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  /// Get color brightness (light or dark)
  bool get isLight => computeLuminance() > 0.5;

  /// Get contrasting text color
  Color get contrastingTextColor => isLight ? Colors.black : Colors.white;
}

/// Extension on BuildContext for common operations
extension BuildContextExtensions on BuildContext {
  /// Get screen size
  Size get screenSize => MediaQuery.of(this).size;

  /// Get screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Check if device is tablet
  bool get isTablet => screenWidth >= 600;

  /// Check if device is mobile
  bool get isMobile => screenWidth < 600;

  /// Get theme
  ThemeData get theme => Theme.of(this);

  /// Get text theme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Get color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Show snackbar
  void showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  /// Hide current snackbar
  void hideCurrentSnackBar() {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
  }

  /// Pop current route
  void pop([Object? result]) {
    Navigator.of(this).pop(result);
  }

  /// Push named route
  Future<T?> pushNamed<T>(String routeName, {Object? arguments}) {
    return Navigator.of(this).pushNamed<T>(routeName, arguments: arguments);
  }

  /// Push replacement named route
  Future<T?> pushReplacementNamed<T, TO>(
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.of(
      this,
    ).pushReplacementNamed<T, TO>(routeName, arguments: arguments);
  }
}
