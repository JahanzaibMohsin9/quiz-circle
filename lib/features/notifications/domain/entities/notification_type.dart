/// Enum representing different types of notifications
enum NotificationType {
  quiz,
  announcement,
  system,
  submission;

  /// Get display name for the notification type
  String get displayName {
    switch (this) {
      case NotificationType.quiz:
        return 'Quiz';
      case NotificationType.announcement:
        return 'Announcement';
      case NotificationType.system:
        return 'System';
      case NotificationType.submission:
        return 'Submission';
    }
  }

  /// Get icon name for the notification type
  String get iconName {
    switch (this) {
      case NotificationType.quiz:
        return 'quiz';
      case NotificationType.announcement:
        return 'campaign';
      case NotificationType.system:
        return 'info';
      case NotificationType.submission:
        return 'assignment_turned_in';
    }
  }

  /// Convert string to NotificationType
  static NotificationType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'quiz':
        return NotificationType.quiz;
      case 'announcement':
        return NotificationType.announcement;
      case 'system':
        return NotificationType.system;
      case 'submission':
        return NotificationType.submission;
      default:
        return NotificationType.system;
    }
  }
}
