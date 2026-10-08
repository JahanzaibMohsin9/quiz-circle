import 'package:equatable/equatable.dart';

/// Custom exception for data layer operations.
///
/// This exception provides rich context about data-related errors,
/// making debugging and error tracking much easier than generic exceptions.
///
/// Example usage:
/// ```dart
/// throw DataException(
///   code: 'INVALID_TIMESTAMP',
///   message: 'Failed to parse timestamp from Firestore',
///   collection: 'submissions',
///   documentId: 'sub_123',
///   originalError: e,
///   context: {'field': 'submittedAt', 'value': value},
/// );
/// ```
class DataException extends Equatable implements Exception {
  /// Error code for categorizing the exception (e.g., 'INVALID_TIMESTAMP', 'VALIDATION_FAILED')
  final String code;

  /// Human-readable error message
  final String message;

  /// The original error that caused this exception (if any)
  final dynamic originalError;

  /// Additional context about the error (field names, values, etc.)
  final Map<String, dynamic>? context;

  /// The Firestore collection where the error occurred (if applicable)
  final String? collection;

  /// The document ID where the error occurred (if applicable)
  final String? documentId;

  const DataException({
    required this.code,
    required this.message,
    this.originalError,
    this.context,
    this.collection,
    this.documentId,
  });

  @override
  String toString() {
    final buffer = StringBuffer('DataException($code): $message');

    if (collection != null) {
      buffer.write(' [collection: $collection]');
    }

    if (documentId != null) {
      buffer.write(' [document: $documentId]');
    }

    if (context != null && context!.isNotEmpty) {
      buffer.write(' [context: $context]');
    }

    if (originalError != null) {
      buffer.write(' [original: $originalError]');
    }

    return buffer.toString();
  }

  @override
  List<Object?> get props => [
    code,
    message,
    originalError,
    context,
    collection,
    documentId,
  ];
}
