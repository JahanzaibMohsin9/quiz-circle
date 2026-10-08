import 'package:equatable/equatable.dart';
import '../../../../features/quiz/domain/entities/quiz_metadata.dart';
import 'csv_validation_error.dart';

class CsvQuizImport extends Equatable {
  final CsvQuizMetadata metadata;
  final List<CsvQuestion> questions;
  final List<CsvValidationError> validationErrors;

  const CsvQuizImport({
    required this.metadata,
    required this.questions,
    this.validationErrors = const [],
  });

  bool get isValid => validationErrors.isEmpty;

  @override
  List<Object?> get props => [metadata, questions, validationErrors];
}

class CsvQuizMetadata extends Equatable {
  final String title;
  final String description;
  final int timeLimitMinutes;
  final QuizCategory category;
  final DifficultyLevel difficulty;

  const CsvQuizMetadata({
    required this.title,
    required this.description,
    required this.timeLimitMinutes,
    required this.category,
    required this.difficulty,
  });

  @override
  List<Object?> get props => [title, description, timeLimitMinutes, category, difficulty];
}

class CsvQuestion extends Equatable {
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final int points;
  final String? imageUrl;
  final String? explanation;
  final int rowNumber;

  const CsvQuestion({
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    this.points = 1,
    this.imageUrl,
    this.explanation,
    required this.rowNumber,
  });

  @override
  List<Object?> get props => [
    questionText, options, correctAnswer, points, 
    imageUrl, explanation, rowNumber
  ];
}
