import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/app_notification.dart';
import '../repositories/notification_repository.dart';

/// Use case to create a notification
class CreateNotification {
  final NotificationRepository repository;

  CreateNotification(this.repository);

  Future<Either<Failure, void>> call(AppNotification notification) async {
    return await repository.createNotification(notification);
  }
}
