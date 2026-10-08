import 'package:equatable/equatable.dart';
import '../../domain/entities/submission.dart';

class SubmissionModel extends Equatable {
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

  const SubmissionModel({
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

  factory SubmissionModel.fromJson(Map<String, dynamic> json) {
    // IMPROVED: Add validation for required fields
    final id = json['id'];
    if (id == null || (id is String && id.isEmpty)) {
      throw ArgumentError('Submission ID is required');
    }

    final quizId = json['quizId'];
    if (quizId == null || (quizId is String && quizId.isEmpty)) {
      throw ArgumentError('Submission quizId is required');
    }

    final userId = json['userId'];
    if (userId == null || (userId is String && userId.isEmpty)) {
      throw ArgumentError('Submission userId is required');
    }

    final score = json['score'];
    if (score == null || score is! int || score < 0) {
      throw ArgumentError('Submission score must be a non-negative integer');
    }

    final totalQuestions = json['totalQuestions'];
    if (totalQuestions == null ||
        totalQuestions is! int ||
        totalQuestions <= 0) {
      throw ArgumentError(
        'Submission totalQuestions must be a positive integer',
      );
    }

    final percentage = json['percentage'];
    if (percentage == null || percentage is! num) {
      throw ArgumentError(
        'Submission percentage is required and must be a number',
      );
    }
    final percentageValue = percentage.toDouble();
    if (percentageValue < 0.0 || percentageValue > 100.0) {
      throw ArgumentError(
        'Submission percentage must be between 0 and 100, got: $percentageValue',
      );
    }

    final timeTakenSeconds = json['timeTakenSeconds'];
    if (timeTakenSeconds == null ||
        timeTakenSeconds is! int ||
        timeTakenSeconds < 0) {
      throw ArgumentError(
        'Submission timeTakenSeconds must be a non-negative integer',
      );
    }

    return SubmissionModel(
      id: id,
      quizId: quizId,
      userId: userId,
      score: score,
      totalQuestions: totalQuestions,
      percentage: percentageValue,
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      quizTitle: json['quizTitle'] as String? ?? 'Quiz Unknown',
      correctAnswersCount: json['correctAnswersCount'] as int? ?? 0,
      answers: Map<String, String>.from(json['answers'] as Map? ?? {}),
      timeTakenSeconds: timeTakenSeconds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quizId': quizId,
      'userId': userId,
      'score': score,
      'totalQuestions': totalQuestions,
      'percentage': percentage,
      'submittedAt': submittedAt.toIso8601String(),
      'quizTitle': quizTitle,
      'correctAnswersCount': correctAnswersCount,
      'answers': answers,
      'timeTakenSeconds': timeTakenSeconds,
    };
  }

  Submission toDomain() {
    return Submission(
      id: id,
      quizId: quizId,
      userId: userId,
      score: score,
      totalQuestions: totalQuestions,
      percentage: percentage,
      submittedAt: submittedAt,
      quizTitle: quizTitle,
      correctAnswersCount: correctAnswersCount,
      answers: answers,
      timeTakenSeconds: timeTakenSeconds,
    );
  }

  factory SubmissionModel.fromDomain(Submission submission) {
    return SubmissionModel(
      id: submission.id,
      quizId: submission.quizId,
      userId: submission.userId,
      score: submission.score,
      totalQuestions: submission.totalQuestions,
      percentage: submission.percentage,
      submittedAt: submission.submittedAt,
      quizTitle: submission.quizTitle,
      correctAnswersCount: submission.correctAnswersCount,
      answers: submission.answers,
      timeTakenSeconds: submission.timeTakenSeconds,
    );
  }

  @override
  List<Object?> get props => [
    id,
    quizId,
    userId,
    score,
    totalQuestions,
    percentage,
    submittedAt,
    answers,
    timeTakenSeconds,
  ];
}
