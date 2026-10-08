import '../../domain/entities/quiz_metadata.dart';

class QuizMetadataModel extends QuizMetadata {
  const QuizMetadataModel({
    required super.category,
    super.tags,
    required super.difficulty,
    required super.estimatedDuration,
    super.isTemplate,
    super.templateId,
    required super.statistics,
  });

  factory QuizMetadataModel.fromJson(Map<String, dynamic> json) {
    return QuizMetadataModel(
      category: QuizCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => QuizCategory.general,
      ),
      tags: (json['tags'] as List?)?.map((e) => e as String).toList() ?? [],
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => DifficultyLevel.intermediate,
      ),
      estimatedDuration: json['estimatedDuration'] as int? ?? 0,
      isTemplate: json['isTemplate'] as bool? ?? false,
      templateId: json['templateId'] as String?,
      statistics: QuizStatisticsModel.fromJson(json['statistics'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category.name,
      'tags': tags,
      'difficulty': difficulty.name,
      'estimatedDuration': estimatedDuration,
      'isTemplate': isTemplate,
      'templateId': templateId,
      'statistics': (statistics as QuizStatisticsModel).toJson(),
    };
  }

  factory QuizMetadataModel.fromEntity(QuizMetadata entity) {
    return QuizMetadataModel(
      category: entity.category,
      tags: entity.tags,
      difficulty: entity.difficulty,
      estimatedDuration: entity.estimatedDuration,
      isTemplate: entity.isTemplate,
      templateId: entity.templateId,
      statistics: QuizStatisticsModel.fromEntity(entity.statistics),
    );
  }
}

class QuizStatisticsModel extends QuizStatistics {
  const QuizStatisticsModel({
    super.totalAttempts,
    super.uniqueParticipants,
    super.averageScore,
    super.completionRate,
    super.averageTimeSpent,
    super.scoreDistribution,
  });

  factory QuizStatisticsModel.fromJson(Map<String, dynamic> json) {
    return QuizStatisticsModel(
      totalAttempts: json['totalAttempts'] as int? ?? 0,
      uniqueParticipants: json['uniqueParticipants'] as int? ?? 0,
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0.0,
      completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0.0,
      averageTimeSpent: json['averageTimeSpent'] as int? ?? 0,
      scoreDistribution: (json['scoreDistribution'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value as int),
      ) ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalAttempts': totalAttempts,
      'uniqueParticipants': uniqueParticipants,
      'averageScore': averageScore,
      'completionRate': completionRate,
      'averageTimeSpent': averageTimeSpent,
      'scoreDistribution': scoreDistribution,
    };
  }

  factory QuizStatisticsModel.fromEntity(QuizStatistics entity) {
    return QuizStatisticsModel(
      totalAttempts: entity.totalAttempts,
      uniqueParticipants: entity.uniqueParticipants,
      averageScore: entity.averageScore,
      completionRate: entity.completionRate,
      averageTimeSpent: entity.averageTimeSpent,
      scoreDistribution: entity.scoreDistribution,
    );
  }
}
