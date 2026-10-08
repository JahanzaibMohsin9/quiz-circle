import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/notification_repository.dart';

/// Use case to mark all notifications as read
class MarkAllNotificationsRead {
  final NotificationRepository repository;

  MarkAllNotificationsRead(this.repository);

  Future<Either<Failure, void>> call(String userId) async {
    return await repository.markAllAsRead(userId);
  }
}
