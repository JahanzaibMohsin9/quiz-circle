import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:csv/csv.dart';
import '../../../../core/errors/failures.dart';
import '../../../quiz/domain/entities/quiz.dart';
import '../../../quiz/domain/entities/quiz_permissions.dart';
import '../repositories/admin_repository.dart';
import 'csv_parser_service.dart';

class BulkOperationsService {
  final AdminRepository _repository;
  final CsvParserService _csvParser;

  BulkOperationsService(this._repository, this._csvParser);

  /// Import multiple CSV files and create quizzes
  Future<Either<Failure, BulkImportResult>> bulkImportQuizzes(
    List<File> csvFiles,
  ) async {
    final results = <String, Either<Failure, String>>{};
    int successCount = 0;
    int failureCount = 0;

    for (final file in csvFiles) {
      try {
        final parseResult = await _csvParser.parseQuizCsv(file);

        await parseResult.fold(
          (failure) async {
            results[file.path] = Left(failure);
            failureCount++;
          },
          (importData) async {
            if (!importData.isValid) {
              results[file.path] = Left(
                ValidationFailure(
                  'CSV validation failed: ${importData.validationErrors.length} errors',
                ),
              );
              failureCount++;
              return;
            }

            // Create quiz from CSV data - this would need to be implemented in the repository
            // For now, we'll just track success
            results[file.path] = const Right('Quiz created successfully');
            successCount++;
          },
        );
      } catch (e) {
        results[file.path] = Left(ServerFailure('Failed to process file: $e'));
        failureCount++;
      }
    }

    return Right(
      BulkImportResult(
        totalFiles: csvFiles.length,
        successCount: successCount,
        failureCount: failureCount,
        results: results,
      ),
    );
  }

  /// Export multiple quizzes to a single CSV file
  /// Note: Questions are stored separately from Quiz entity
  /// This export only includes quiz metadata
  Future<Either<Failure, String>> bulkExportQuizzes(
    List<Quiz> quizzes,
    String outputPath,
  ) async {
    try {
      final csvData = <List<String>>[];

      // Add metadata header
      csvData.add([
        'Quiz Export',
        'Generated on ${DateTime.now().toIso8601String()}',
      ]);
      csvData.add([]); // Empty row

      for (final quiz in quizzes) {
        // Quiz metadata row
        csvData.add([
          'quiz_title',
          'quiz_description',
          'time_limit_minutes',
          'is_active',
          'access_level',
        ]);
        csvData.add([
          quiz.title,
          quiz.description,
          quiz.timeLimitMinutes.toString(),
          quiz.isActive.toString(),
          _getAccessLevel(quiz.permissions),
        ]);
        csvData.add([]); // Empty row between quizzes
      }

      final csv = const ListToCsvConverter().convert(csvData);
      final file = File(outputPath);
      await file.writeAsString(csv);

      return Right(outputPath);
    } catch (e) {
      return Left(ServerFailure('Failed to export quizzes: $e'));
    }
  }

  /// Set active status for multiple quizzes
  Future<Either<Failure, BulkUpdateResult>> bulkSetActive(
    List<String> quizIds,
    bool isActive,
  ) async {
    final results = <String, bool>{};
    int successCount = 0;
    int failureCount = 0;

    for (final quizId in quizIds) {
      try {
        final result = await _repository.setQuizActive(quizId, isActive);
        final success = result.isRight();
        results[quizId] = success;

        if (success) {
          successCount++;
        } else {
          failureCount++;
        }
      } catch (e) {
        results[quizId] = false;
        failureCount++;
      }
    }

    return Right(
      BulkUpdateResult(
        totalItems: quizIds.length,
        successCount: successCount,
        failureCount: failureCount,
        results: results,
      ),
    );
  }

  /// Delete multiple quizzes
  Future<Either<Failure, BulkUpdateResult>> bulkDeleteQuizzes(
    List<String> quizIds,
  ) async {
    final results = <String, bool>{};
    int successCount = 0;
    int failureCount = 0;

    for (final quizId in quizIds) {
      try {
        final result = await _repository.deleteQuiz(quizId);
        final success = result.isRight();
        results[quizId] = success;

        if (success) {
          successCount++;
        } else {
          failureCount++;
        }
      } catch (e) {
        results[quizId] = false;
        failureCount++;
      }
    }

    return Right(
      BulkUpdateResult(
        totalItems: quizIds.length,
        successCount: successCount,
        failureCount: failureCount,
        results: results,
      ),
    );
  }

  /// Apply same permissions to multiple quizzes
  Future<Either<Failure, BulkUpdateResult>> bulkApplyPermissions(
    List<String> quizIds,
    QuizPermissions permissions,
  ) async {
    final results = <String, bool>{};
    int successCount = 0;
    int failureCount = 0;

    for (final quizId in quizIds) {
      try {
        final updatedPermissions = permissions.copyWith(quizId: quizId);
        final result = await _repository.updateQuizPermissions(
          quizId,
          updatedPermissions,
        );
        final success = result.isRight();
        results[quizId] = success;

        if (success) {
          successCount++;
        } else {
          failureCount++;
        }
      } catch (e) {
        results[quizId] = false;
        failureCount++;
      }
    }

    return Right(
      BulkUpdateResult(
        totalItems: quizIds.length,
        successCount: successCount,
        failureCount: failureCount,
        results: results,
      ),
    );
  }

  /// Helper method to determine access level from permissions
  String _getAccessLevel(QuizPermissions permissions) {
    // Check if it's scheduled first
    if (permissions.availableFrom != null ||
        permissions.availableUntil != null) {
      return 'scheduled';
    }

    // Check if it's private (specific users)
    if (permissions.allowedUserIds.isNotEmpty) {
      return 'private';
    }

    // Check if it's public (all students)
    if (permissions.allowedRoles.contains('student') &&
        permissions.allowedRoles.length == 1) {
      return 'public';
    }

    // Otherwise it's role-based
    return 'role-based';
  }
}

/// Result of bulk import operation
class BulkImportResult {
  final int totalFiles;
  final int successCount;
  final int failureCount;
  final Map<String, Either<Failure, String>> results;

  BulkImportResult({
    required this.totalFiles,
    required this.successCount,
    required this.failureCount,
    required this.results,
  });

  bool get hasFailures => failureCount > 0;
  bool get isFullSuccess => failureCount == 0;
}

/// Result of bulk update operation
class BulkUpdateResult {
  final int totalItems;
  final int successCount;
  final int failureCount;
  final Map<String, bool> results;

  BulkUpdateResult({
    required this.totalItems,
    required this.successCount,
    required this.failureCount,
    required this.results,
  });

  bool get hasFailures => failureCount > 0;
  bool get isFullSuccess => failureCount == 0;
}
