import '../../../features/authentication/domain/entities/user.dart';
import '../../../features/quiz/domain/entities/submission.dart';

/// Schema validation utilities for ensuring data integrity.
///
/// These validators check business rules and data constraints before
/// writing to Firestore, preventing invalid data from entering the database.
class SchemaValidators {
  /// Validates a User entity before persisting to Firestore.
  ///
  /// Validation rules:
  /// - ID must not be empty
  /// - Name must be 1-100 characters
  /// - Email must match valid email format
  /// - Total score must be non-negative (if present)
  /// - Average percentage must be 0-100 (if present)
  ///
  /// Throws [ArgumentError] if any validation fails.
  static void validateUser(User user) {
    if (user.id.isEmpty) {
      throw ArgumentError('User ID cannot be empty', 'user.id');
    }

    if (user.name.isEmpty || user.name.length > 100) {
      throw ArgumentError(
        'User name must be 1-100 characters (got: ${user.name.length})',
        'user.name',
      );
    }

    // RFC 5322 simplified email regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(user.email)) {
      throw ArgumentError('Invalid email format: ${user.email}', 'user.email');
    }

    if (user.totalScore != null && user.totalScore! < 0) {
      throw ArgumentError(
        'Total score cannot be negative (got: ${user.totalScore})',
        'user.totalScore',
      );
    }

    if (user.averagePercentage != null &&
        (user.averagePercentage! < 0 || user.averagePercentage! > 100)) {
      throw ArgumentError(
        'Average percentage must be between 0-100 (got: ${user.averagePercentage})',
        'user.averagePercentage',
      );
    }
  }

  /// Validates a Submission entity before persisting to Firestore.
  ///
  /// Validation rules:
  /// - Quiz ID must not be empty
  /// - User ID must not be empty
  /// - Score must be non-negative
  /// - Percentage must be 0-100
  /// - Time taken must be non-negative
  /// - Answers map must not be empty
  ///
  /// Throws [ArgumentError] if any validation fails.
  static void validateSubmission(Submission submission) {
    if (submission.quizId.isEmpty) {
      throw ArgumentError('Quiz ID cannot be empty', 'submission.quizId');
    }

    if (submission.userId.isEmpty) {
      throw ArgumentError('User ID cannot be empty', 'submission.userId');
    }

    if (submission.score < 0) {
      throw ArgumentError(
        'Score cannot be negative (got: ${submission.score})',
        'submission.score',
      );
    }

    if (submission.percentage < 0 || submission.percentage > 100) {
      throw ArgumentError(
        'Percentage must be between 0-100 (got: ${submission.percentage})',
        'submission.percentage',
      );
    }

    if (submission.timeTakenSeconds < 0) {
      throw ArgumentError(
        'Time taken cannot be negative (got: ${submission.timeTakenSeconds})',
        'submission.timeTakenSeconds',
      );
    }

    if (submission.answers.isEmpty) {
      throw ArgumentError(
        'Submission must have at least one answer',
        'submission.answers',
      );
    }
  }
}
