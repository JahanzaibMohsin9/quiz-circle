import 'package:cloud_firestore/cloud_firestore.dart';

/// Centralized utility for parsing timestamps from various formats.
///
/// This class standardizes timestamp parsing across the entire application,
/// replacing multiple inconsistent implementations. It handles:
/// - Firestore Timestamp objects
/// - ISO8601 strings
/// - Milliseconds since epoch (int)
/// - DateTime objects (passthrough)
///
/// **Important**: This parser throws ArgumentError for null or invalid values
/// instead of silently falling back to DateTime.now(), which could mask data
/// integrity issues.
class TimestampParser {
  /// Parses a timestamp from various formats into a DateTime object.
  ///
  /// Supported formats:
  /// - [Timestamp]: Firestore Timestamp object
  /// - [String]: ISO8601 formatted string
  /// - [int]: Milliseconds since epoch
  /// - [DateTime]: Passthrough (returns as-is)
  ///
  /// Throws [ArgumentError] if:
  /// - value is null
  /// - value is an unsupported type
  /// - String value is not valid ISO8601 format
  ///
  /// Example:
  /// ```dart
  /// final timestamp = TimestampParser.parse(data['createdAt']);
  /// ```
  static DateTime parse(dynamic value) {
    if (value == null) {
      throw ArgumentError('Timestamp cannot be null');
    }

    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      try {
        return DateTime.parse(value);
      } on FormatException {
        throw ArgumentError('Invalid timestamp string format: $value', 'value');
      }
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } else if (value is DateTime) {
      return value;
    }

    throw ArgumentError(
      'Invalid timestamp format: ${value.runtimeType}. '
          'Expected Timestamp, String, int, or DateTime.',
      'value',
    );
  }

  /// Converts a DateTime object to a Firestore Timestamp for JSON serialization.
  ///
  /// This should be used when writing data to Firestore to ensure consistent
  /// timestamp storage.
  ///
  /// Example:
  /// ```dart
  /// final data = {
  ///   'createdAt': TimestampParser.toJson(DateTime.now()),
  /// };
  /// ```
  static Timestamp toJson(DateTime dateTime) {
    return Timestamp.fromDate(dateTime);
  }
}
