import 'package:equatable/equatable.dart';

class Question extends Equatable {
  final String id;
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final String? imageUrl;
  final int points;

  const Question({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    this.imageUrl,
    this.points = 1,
  });

  @override
  List<Object?> get props => [id, questionText, options, correctAnswer, imageUrl, points];
}