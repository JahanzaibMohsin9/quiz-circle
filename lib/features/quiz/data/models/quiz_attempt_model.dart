import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/utils/timestamp_parser.dart';

class QuizAttemptModel extends Equatable {
  final String id;
  final String userId;
  final String quizId;
  final List<String> questionIds;
  final Map<String, String> answers;
  final int currentQuestionIndex;
  final DateTime startedAt;
  final DateTime? completedAt;

  const QuizAttemptModel({
    required this.id,
    required this.userId,
    required this.quizId,
    required this.questionIds,
    this.answers = const {},
    this.currentQuestionIndex = 0,
    required this.startedAt,
    this.completedAt,
  });

  factory QuizAttemptModel.fromJson(Map<String, dynamic> json, String id) {
    return QuizAttemptModel(
      id: id,
      userId: json['userId'] as String,
      quizId: json['quizId'] as String,
      questionIds: List<String>.from(json['questionIds'] as List),
      answers: Map<String, String>.from(json['answers'] as Map? ?? {}),
      currentQuestionIndex: json['currentQuestionIndex'] as int? ?? 0,
      startedAt: TimestampParser.parse(json['startedAt']),
      completedAt: json['completedAt'] != null
          ? TimestampParser.parse(json['completedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'quizId': quizId,
      'questionIds': questionIds,
      'answers': answers,
      'currentQuestionIndex': currentQuestionIndex,
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
    };
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    quizId,
    questionIds,
    answers,
    currentQuestionIndex,
    startedAt,
    completedAt,
  ];
}
