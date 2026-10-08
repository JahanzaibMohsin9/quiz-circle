import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/app_notification.dart';
import '../entities/notification_type.dart';

/// Repository interface for notification operations
abstract class NotificationRepository {
  /// Watch user notifications in real-time
  Stream<List<AppNotification>> watchUserNotifications(String userId);

  /// Get user notifications with pagination
  Future<Either<Failure, List<AppNotification>>> getUserNotifications(
    String userId, {
    int limit = 50,
  });

  /// Get unread notification count
  Future<Either<Failure, int>> getUnreadCount(String userId);

  /// Mark a notification as read
  Future<Either<Failure, void>> markAsRead(
    String notificationId,
    String userId,
  );

  /// Mark all notifications as read
  Future<Either<Failure, void>> markAllAsRead(String userId);

  /// Delete a notification
  Future<Either<Failure, void>> deleteNotification(
    String notificationId,
    String userId,
  );

  /// Create a new notification
  Future<Either<Failure, void>> createNotification(
    AppNotification notification,
  );

  /// Create notifications for multiple users (batch operation)
  Future<Either<Failure, void>> createNotificationsForUsers(
    List<String> userIds,
    String title,
    String message,
    NotificationType type, {
    Map<String, dynamic>? data,
    String? actionUrl,
  });
}
