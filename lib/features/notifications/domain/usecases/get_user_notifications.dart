import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/app_notification.dart';
import '../repositories/notification_repository.dart';

/// Use case to get user notifications
class GetUserNotifications {
  final NotificationRepository repository;

  GetUserNotifications(this.repository);

  Future<Either<Failure, List<AppNotification>>> call(
    String userId, {
    int limit = 50,
  }) async {
    return await repository.getUserNotifications(userId, limit: limit);
  }
}
