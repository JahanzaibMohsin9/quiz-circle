import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/notification_repository.dart';

/// Use case to mark notification as read
class MarkNotificationRead {
  final NotificationRepository repository;

  MarkNotificationRead(this.repository);

  Future<Either<Failure, void>> call(
    String notificationId,
    String userId,
  ) async {
    return await repository.markAsRead(notificationId, userId);
  }
}
