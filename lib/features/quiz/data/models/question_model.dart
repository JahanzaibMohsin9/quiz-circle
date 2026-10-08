import 'package:equatable/equatable.dart';
import '../../domain/entities/question.dart';

class QuestionModel extends Equatable {
  final String id;
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final String? imageUrl;
  final int points;

  const QuestionModel({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    this.imageUrl,
    this.points = 1,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    // IMPROVED: Add validation for required fields
    final id = json['id'];
    if (id == null || (id is String && id.isEmpty)) {
      throw ArgumentError('Question ID is required and cannot be empty');
    }

    final questionText = json['questionText'];
    if (questionText == null || (questionText is String && questionText.isEmpty)) {
      throw ArgumentError('Question text is required and cannot be empty');
    }

    final options = json['options'];
    if (options == null || (options is List && options.isEmpty)) {
      throw ArgumentError('Question must have at least one option');
    }
    if (options is List && options.length < 2) {
      throw ArgumentError('Question must have at least 2 options');
    }

    final correctAnswer = json['correctAnswer'];
    if (correctAnswer == null || (correctAnswer is String && correctAnswer.isEmpty)) {
      throw ArgumentError('Question correctAnswer is required and cannot be empty');
    }

    final points = json['points'] as int? ?? 1;
    if (points <= 0) {
      throw ArgumentError('Question points must be positive, got: $points');
    }

    return QuestionModel(
      id: id as String,
      questionText: questionText as String,
      options: List<String>.from(options as List),
      correctAnswer: correctAnswer as String,
      imageUrl: json['imageUrl'] as String?,
      points: points,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionText': questionText,
      'options': options,
      'correctAnswer': correctAnswer,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'points': points,
    };
  }

  Question toDomain() {
    return Question(
      id: id,
      questionText: questionText,
      options: options,
      correctAnswer: correctAnswer,
      imageUrl: imageUrl,
      points: points,
    );
  }

  factory QuestionModel.fromDomain(Question question) {
    return QuestionModel(
      id: question.id,
      questionText: question.questionText,
      options: question.options,
      correctAnswer: question.correctAnswer,
      imageUrl: question.imageUrl,
      points: question.points,
    );
  }

  @override
  List<Object?> get props => [id, questionText, options, correctAnswer, imageUrl, points];
}