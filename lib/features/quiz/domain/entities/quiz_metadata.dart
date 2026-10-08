import 'package:equatable/equatable.dart';

enum QuizCategory {
  mathematics,
  science,
  history,
  geography,
  literature,
  programming,
  general,
  custom
}

enum DifficultyLevel {
  beginner,
  intermediate,
  advanced,
  expert
}

class QuizStatistics extends Equatable {
  final int totalAttempts;
  final int uniqueParticipants;
  final double averageScore;
  final double completionRate;
  final int averageTimeSpent;
  final Map<String, int> scoreDistribution;

  const QuizStatistics({
    this.totalAttempts = 0,
    this.uniqueParticipants = 0,
    this.averageScore = 0.0,
    this.completionRate = 0.0,
    this.averageTimeSpent = 0,
    this.scoreDistribution = const {},
  });

  @override
  List<Object?> get props => [
    totalAttempts, uniqueParticipants, averageScore, 
    completionRate, averageTimeSpent, scoreDistribution
  ];
}

class QuizMetadata extends Equatable {
  final QuizCategory category;
  final List<String> tags;
  final DifficultyLevel difficulty;
  final int estimatedDuration;
  final bool isTemplate;
  final String? templateId;
  final QuizStatistics statistics;

  const QuizMetadata({
    required this.category,
    this.tags = const [],
    required this.difficulty,
    required this.estimatedDuration,
    this.isTemplate = false,
    this.templateId,
    required this.statistics,
  });

  @override
  List<Object?> get props => [
    category, tags, difficulty, estimatedDuration, 
    isTemplate, templateId, statistics
  ];
}
