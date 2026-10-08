import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../quiz/domain/entities/quiz_metadata.dart';
import '../../data/models/csv_quiz_import.dart';
import '../../data/models/csv_validation_error.dart';

class CsvParserService {
  static const int maxFileSize = 5 * 1024 * 1024; // 5MB
  static const int maxQuestions = 100;

  Future<Either<Failure, CsvQuizImport>> parseQuizCsv(File csvFile) async {
    try {
      // Validate file
      final validation = await _validateFile(csvFile);
      if (validation != null) return Left(validation);

      // Read and parse CSV with encoding detection
      final content = await _readCsvWithEncoding(csvFile);
      final rows = const CsvToListConverter().convert(content);

      if (rows.isEmpty) {
        return const Left(ValidationFailure('CSV file is empty'));
      }

      // Parse quiz metadata
      CsvQuizMetadata? metadata;
      int questionsStartIndex = 1;

      // Check if first row is header by looking for common header keywords
      if (rows.isNotEmpty && rows.first.isNotEmpty) {
        final firstCell = rows.first[0].toString().trim().toLowerCase();
        if (firstCell == 'quiz_title' ||
            firstCell == 'title' ||
            firstCell == 'quiz title') {
          // Row 0 is header, Row 1 should be metadata
          if (rows.length < 2) {
            return const Left(
              ValidationFailure(
                'CSV has header row but no metadata row. Row 2 should contain quiz details.',
              ),
            );
          }

          // Validate that Row 1 is not also a header
          if (rows[1].isNotEmpty) {
            final secondRowFirstCell = rows[1][0]
                .toString()
                .trim()
                .toLowerCase();
            if (secondRowFirstCell == 'quiz_title' ||
                secondRowFirstCell == 'title') {
              return const Left(
                ValidationFailure(
                  'Multiple header rows detected. Please use the correct CSV format.',
                ),
              );
            }
          }

          metadata = _parseQuizMetadata(rows[1]);
          questionsStartIndex = 2;
        } else {
          // Legacy support: Row 0 is metadata (no header row)
          metadata = _parseQuizMetadata(rows.first);
        }
      }

      if (metadata == null) {
        return const Left(
          ValidationFailure(
            'Invalid quiz metadata format. Please ensure row contains: title, description, time_limit_minutes',
          ),
        );
      }

      // Parse questions
      final questions = <CsvQuestion>[];
      final errors = <CsvValidationError>[];

      for (int i = questionsStartIndex; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty ||
            row.every((cell) => cell.toString().trim().isEmpty)) {
          continue; // Skip empty rows
        }

        // Skip question header row if present
        if (row.isNotEmpty &&
            row[0].toString().toLowerCase() == 'question_text') {
          continue;
        }

        final questionResult = _parseQuestion(row, i + 1);
        questionResult.fold(
          (error) => errors.add(error),
          (question) => questions.add(question),
        );
      }

      if (questions.isEmpty) {
        return const Left(ValidationFailure('No valid questions found in CSV'));
      }

      return Right(
        CsvQuizImport(
          metadata: metadata,
          questions: questions,
          validationErrors: errors,
        ),
      );
    } catch (e) {
      return Left(ValidationFailure('Failed to parse CSV: ${e.toString()}'));
    }
  }

  Future<Failure?> _validateFile(File file) async {
    if (!await file.exists()) {
      return const ValidationFailure('File does not exist');
    }

    final fileSize = await file.length();
    if (fileSize > maxFileSize) {
      return const ValidationFailure(
        'File size exceeds ${maxFileSize ~/ (1024 * 1024)}MB limit',
      );
    }

    final extension = file.path.toLowerCase().split('.').last;
    if (extension != 'csv') {
      return const ValidationFailure(
        'Invalid file format. Please upload a CSV file',
      );
    }

    return null;
  }

  /// Reads CSV file with proper encoding detection
  /// Handles UTF-8 with BOM and falls back to latin1 if needed
  Future<String> _readCsvWithEncoding(File file) async {
    try {
      // First, try reading as UTF-8
      final bytes = await file.readAsBytes();

      // Check for UTF-8 BOM and remove it if present
      List<int> processedBytes = bytes;
      if (bytes.length >= 3 &&
          bytes[0] == 0xEF &&
          bytes[1] == 0xBB &&
          bytes[2] == 0xBF) {
        // Remove UTF-8 BOM
        processedBytes = bytes.sublist(3);
      }

      // Try UTF-8 decoding
      try {
        return utf8.decode(processedBytes, allowMalformed: false);
      } catch (e) {
        // If UTF-8 fails, try latin1 (ISO-8859-1)
        return latin1.decode(processedBytes);
      }
    } catch (e) {
      throw Exception('Failed to read file with proper encoding: $e');
    }
  }

  CsvQuizMetadata? _parseQuizMetadata(List<dynamic> row) {
    if (row.length < 3) return null;

    final title = row[0]?.toString().trim() ?? '';
    final description = row[1]?.toString().trim() ?? '';
    final timeLimitStr = row[2]?.toString().trim() ?? '';

    // Validate that this is not a header row
    if (title.toLowerCase() == 'quiz_title' ||
        title.toLowerCase() == 'title' ||
        description.toLowerCase() == 'quiz_description' ||
        description.toLowerCase() == 'description') {
      return null;
    }

    // Validate title and description are not empty
    if (title.isEmpty || description.isEmpty) {
      return null;
    }

    // Parse time limit with validation
    final timeLimitMinutes = int.tryParse(timeLimitStr);
    if (timeLimitMinutes == null || timeLimitMinutes <= 0) {
      return null;
    }

    return CsvQuizMetadata(
      title: title,
      description: description,
      timeLimitMinutes: timeLimitMinutes,
      category: _parseCategory(row.length > 3 ? row[3]?.toString() : null),
      difficulty: _parseDifficulty(row.length > 4 ? row[4]?.toString() : null),
    );
  }

  Either<CsvValidationError, CsvQuestion> _parseQuestion(
    List<dynamic> row,
    int rowNumber,
  ) {
    // Validate required fields
    if (row.length < 6) {
      return Left(
        CsvValidationError(
          rowNumber: rowNumber,
          field: 'general',
          message:
              'Question requires at least 6 columns: question, 4 options, correct answer',
          type: ValidationErrorType.missingField,
        ),
      );
    }

    final questionText = row[0]?.toString().trim() ?? '';

    // Additional check: ensure this is not a header row
    if (questionText.toLowerCase() == 'question_text' ||
        questionText.toLowerCase() == 'question') {
      return Left(
        CsvValidationError(
          rowNumber: rowNumber,
          field: 'question',
          message: 'Header row detected in questions section',
          type: ValidationErrorType.invalidFormat,
        ),
      );
    }

    if (questionText.isEmpty) {
      return Left(
        CsvValidationError(
          rowNumber: rowNumber,
          field: 'question',
          message: 'Question text cannot be empty',
          type: ValidationErrorType.missingField,
        ),
      );
    }

    // Parse options
    final options = <String>[];
    for (int i = 1; i <= 4; i++) {
      final option = row[i]?.toString().trim() ?? '';
      if (option.isNotEmpty) {
        options.add(option);
      }
    }

    if (options.length < 2) {
      return Left(
        CsvValidationError(
          rowNumber: rowNumber,
          field: 'options',
          message: 'Question must have at least 2 options',
          type: ValidationErrorType.invalidOptions,
        ),
      );
    }

    final correctAnswer = row[5]?.toString().trim() ?? '';
    if (correctAnswer.isEmpty) {
      return Left(
        CsvValidationError(
          rowNumber: rowNumber,
          field: 'correctAnswer',
          message: 'Correct answer cannot be empty',
          type: ValidationErrorType.missingField,
        ),
      );
    }

    // Normalize correct answer to ALWAYS be full option text
    // This handles both text match and index-based answers from CSV
    String normalizedCorrectAnswer = correctAnswer;

    if (!options.contains(correctAnswer)) {
      // Check if it's a 1-based index
      final index = int.tryParse(correctAnswer);
      if (index != null && index >= 1 && index <= options.length) {
        // Convert index to actual option text for consistency
        normalizedCorrectAnswer = options[index - 1];
      } else {
        return Left(
          CsvValidationError(
            rowNumber: rowNumber,
            field: 'correctAnswer',
            message:
                'Correct answer "$correctAnswer" is neither an option text nor a valid index (1-${options.length})',
            type: ValidationErrorType.invalidFormat,
          ),
        );
      }
    }

    final points = int.tryParse(row[6]?.toString() ?? '') ?? 1;
    if (points < 1 || points > 10) {
      return Left(
        CsvValidationError(
          rowNumber: rowNumber,
          field: 'points',
          message: 'Points must be between 1 and 10',
          type: ValidationErrorType.invalidPoints,
        ),
      );
    }

    final imageUrl = row.length > 7 ? row[7]?.toString().trim() : null;
    final explanation = row.length > 8 ? row[8]?.toString().trim() : null;

    return Right(
      CsvQuestion(
        questionText: questionText,
        options: options,
        correctAnswer: normalizedCorrectAnswer, // Use normalized value
        points: points,
        imageUrl: imageUrl?.isNotEmpty == true ? imageUrl : null,
        explanation: explanation?.isNotEmpty == true ? explanation : null,
        rowNumber: rowNumber,
      ),
    );
  }

  QuizCategory _parseCategory(String? categoryStr) {
    if (categoryStr == null) return QuizCategory.general;

    switch (categoryStr.toLowerCase()) {
      case 'mathematics':
      case 'math':
        return QuizCategory.mathematics;
      case 'science':
        return QuizCategory.science;
      case 'history':
        return QuizCategory.history;
      case 'geography':
        return QuizCategory.geography;
      case 'literature':
        return QuizCategory.literature;
      case 'programming':
      case 'coding':
        return QuizCategory.programming;
      default:
        return QuizCategory.general;
    }
  }

  DifficultyLevel _parseDifficulty(String? difficultyStr) {
    if (difficultyStr == null) return DifficultyLevel.intermediate;

    switch (difficultyStr.toLowerCase()) {
      case 'beginner':
      case 'easy':
        return DifficultyLevel.beginner;
      case 'intermediate':
      case 'medium':
        return DifficultyLevel.intermediate;
      case 'advanced':
      case 'hard':
        return DifficultyLevel.advanced;
      case 'expert':
      case 'very hard':
        return DifficultyLevel.expert;
      default:
        return DifficultyLevel.intermediate;
    }
  }
}
