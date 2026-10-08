import 'package:equatable/equatable.dart';
import 'quiz_permissions.dart';
import 'quiz_metadata.dart';

class Quiz extends Equatable {
  final String id;
  final String title;
  final String description;
  final int timeLimitMinutes;
  final bool isActive;
  final int questionsPerAttempt;
  final bool randomizeQuestions;
  final QuizPermissions permissions;
  final QuizMetadata metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String createdBy;

  const Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.timeLimitMinutes,
    this.isActive = true,
    this.questionsPerAttempt = 0, // 0 means all questions
    this.randomizeQuestions = false,
    required this.permissions,
    required this.metadata,
    required this.createdAt,
    this.updatedAt,
    required this.createdBy,
  });

  @override
  List<Object?> get props => [
    id, title, description, timeLimitMinutes, isActive, 
    permissions, metadata, createdAt, updatedAt, createdBy
  ];
}
