import '../../domain/entities/recent_activity.dart';

class RecentActivityModel extends RecentActivity {
  const RecentActivityModel({
    required super.id,
    required super.type,
    required super.title,
    required super.subtitle,
    required super.timestamp,
    super.metadata,
  });

  factory RecentActivityModel.fromJson(Map<String, dynamic> json) {
    return RecentActivityModel(
      id: json['id'] as String,
      type: ActivityType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => ActivityType.quizCreated,
      ),
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'title': title,
      'subtitle': subtitle,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  static RecentActivityModel fromDomain(RecentActivity activity) {
    return RecentActivityModel(
      id: activity.id,
      type: activity.type,
      title: activity.title,
      subtitle: activity.subtitle,
      timestamp: activity.timestamp,
      metadata: activity.metadata,
    );
  }
}
