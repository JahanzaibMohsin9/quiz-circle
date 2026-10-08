import 'package:equatable/equatable.dart';
import '../../domain/entities/quiz.dart';
import '../../domain/entities/quiz_metadata.dart';
import 'quiz_permissions_model.dart';
import 'quiz_metadata_model.dart';

class QuizModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final int timeLimitMinutes;
  final bool isActive;
  final int questionsPerAttempt;
  final bool randomizeQuestions;
  final QuizPermissionsModel permissions;
  final QuizMetadataModel metadata;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const QuizModel({
    required this.id,
    required this.title,
    required this.description,
    required this.timeLimitMinutes,
    this.isActive = true,
    this.questionsPerAttempt = 0,
    this.randomizeQuestions = false,
    required this.permissions,
    required this.metadata,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    // IMPROVED: Add validation for required fields
    if (json.isEmpty) {
      throw ArgumentError('Quiz JSON data cannot be empty');
    }

    final id = json['id'];
    if (id == null || (id is String && id.isEmpty)) {
      throw ArgumentError('Quiz ID is required and cannot be empty');
    }

    final title = json['title'];
    if (title == null || (title is String && title.isEmpty)) {
      throw ArgumentError('Quiz title is required and cannot be empty');
    }

    final timeLimitMinutes = json['timeLimitMinutes'];
    if (timeLimitMinutes == null) {
      throw ArgumentError('Quiz timeLimitMinutes is required');
    }
    if (timeLimitMinutes is! int || timeLimitMinutes <= 0) {
      throw ArgumentError(
        'Quiz timeLimitMinutes must be a positive integer, got: $timeLimitMinutes',
      );
    }

    return QuizModel(
      id: id as String,
      title: title as String,
      description: json['description'] as String? ?? '',
      timeLimitMinutes: timeLimitMinutes,
      isActive: json['isActive'] as bool? ?? true,
      questionsPerAttempt: json['questionsPerAttempt'] as int? ?? 0,
      randomizeQuestions: json['randomizeQuestions'] as bool? ?? false,
      permissions: json['permissions'] != null
          ? QuizPermissionsModel.fromJson(
              json['permissions'] as Map<String, dynamic>,
              quizId: id,
            )
          : QuizPermissionsModel(
              quizId: id,
            ),
      metadata: json['metadata'] != null
          ? QuizMetadataModel.fromJson(json['metadata'] as Map<String, dynamic>)
          : const QuizMetadataModel(
              category: QuizCategory.general,
              difficulty: DifficultyLevel.intermediate,
              estimatedDuration: 30, // Default duration
              statistics: QuizStatisticsModel(),
            ),
      createdBy: json['createdBy'] as String? ?? 'system', // Default for legacy
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(), // Default for legacy
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'timeLimitMinutes': timeLimitMinutes,
      'isActive': isActive,
      'questionsPerAttempt': questionsPerAttempt,
      'randomizeQuestions': randomizeQuestions,
      'permissions': permissions.toJson(),
      'metadata': metadata.toJson(),
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Quiz toDomain() {
    return Quiz(
      id: id,
      title: title,
      description: description,
      timeLimitMinutes: timeLimitMinutes,
      isActive: isActive,
      permissions: permissions,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
      createdBy: createdBy,
    );
  }

  factory QuizModel.fromDomain(Quiz quiz) {
    return QuizModel(
      id: quiz.id,
      title: quiz.title,
      description: quiz.description,
      timeLimitMinutes: quiz.timeLimitMinutes,
      isActive: quiz.isActive,
      questionsPerAttempt: quiz.questionsPerAttempt,
      randomizeQuestions: quiz.randomizeQuestions,
      permissions: QuizPermissionsModel.fromEntity(quiz.permissions),
      metadata: QuizMetadataModel.fromEntity(quiz.metadata),
      createdBy: quiz.createdBy,
      createdAt: quiz.createdAt,
      updatedAt: quiz.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    timeLimitMinutes,
    isActive,
    permissions,
    metadata,
    createdBy,
    createdAt,
    updatedAt,
  ];
}
