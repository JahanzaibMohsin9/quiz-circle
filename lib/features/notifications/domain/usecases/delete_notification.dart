import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/notification_repository.dart';

/// Use case to delete a notification
class DeleteNotification {
  final NotificationRepository repository;

  DeleteNotification(this.repository);

  Future<Either<Failure, void>> call(
    String notificationId,
    String userId,
  ) async {
    return await repository.deleteNotification(notificationId, userId);
  }
}
