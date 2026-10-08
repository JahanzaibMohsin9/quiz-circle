import '../entities/app_notification.dart';
import '../repositories/notification_repository.dart';

/// Use case to watch user notifications in real-time
class WatchUserNotifications {
  final NotificationRepository repository;

  WatchUserNotifications(this.repository);

  Stream<List<AppNotification>> call(String userId) {
    return repository.watchUserNotifications(userId);
  }
}
