import 'package:equatable/equatable.dart';

class Submission extends Equatable {
  final String id;
  final String quizId;
  final String userId;
  final int score;
  final int totalQuestions;
  final double percentage;
  final DateTime submittedAt;
  final String quizTitle;
  final int correctAnswersCount;
  final Map<String, String> answers; // questionId -> selectedAnswer
  final int timeTakenSeconds; // Time taken to complete the quiz

  const Submission({
    required this.id,
    required this.quizId,
    required this.userId,
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    required this.submittedAt,
    this.quizTitle = 'Quiz Unknown',
    this.correctAnswersCount = 0,
    required this.answers,
    required this.timeTakenSeconds,
  });

  @override
  List<Object?> get props => [
    id,
    quizId,
    userId,
    score,
    totalQuestions,
    percentage,
    submittedAt,
    quizTitle,
    correctAnswersCount,
    answers,
    timeTakenSeconds,
  ];
}
