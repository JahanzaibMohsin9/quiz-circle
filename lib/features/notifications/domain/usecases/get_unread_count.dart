import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/notification_repository.dart';

/// Use case to get unread notification count
class GetUnreadCount {
  final NotificationRepository repository;

  GetUnreadCount(this.repository);

  Future<Either<Failure, int>> call(String userId) async {
    return await repository.getUnreadCount(userId);
  }
}
