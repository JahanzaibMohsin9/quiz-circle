import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_type.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';
import '../models/notification_model.dart';

/// Implementation of NotificationRepository
class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<AppNotification>> watchUserNotifications(String userId) {
    return remoteDataSource.watchUserNotifications(userId);
  }

  @override
  Future<Either<Failure, List<AppNotification>>> getUserNotifications(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final notifications = await remoteDataSource.getUserNotifications(
        userId,
        limit: limit,
      );
      return Right(notifications);
    } catch (e) {
      debugPrint('Error in getUserNotifications: $e');
      return Left(
        ServerFailure('Failed to get notifications: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount(String userId) async {
    try {
      final count = await remoteDataSource.getUnreadCount(userId);
      return Right(count);
    } catch (e) {
      debugPrint('Error in getUnreadCount: $e');
      return Left(ServerFailure('Failed to get unread count: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(
    String notificationId,
    String userId,
  ) async {
    try {
      await remoteDataSource.markAsRead(notificationId, userId);
      return const Right(null);
    } catch (e) {
      debugPrint('Error in markAsRead: $e');
      return Left(
        ServerFailure('Failed to mark notification as read: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> markAllAsRead(String userId) async {
    try {
      await remoteDataSource.markAllAsRead(userId);
      return const Right(null);
    } catch (e) {
      debugPrint('Error in markAllAsRead: $e');
      return Left(ServerFailure('Failed to mark all as read: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotification(
    String notificationId,
    String userId,
  ) async {
    try {
      await remoteDataSource.deleteNotification(notificationId, userId);
      return const Right(null);
    } catch (e) {
      debugPrint('Error in deleteNotification: $e');
      return Left(
        ServerFailure('Failed to delete notification: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> createNotification(
    AppNotification notification,
  ) async {
    try {
      final model = NotificationModel.fromEntity(notification);
      await remoteDataSource.createNotification(model);
      return const Right(null);
    } catch (e) {
      debugPrint('Error in createNotification: $e');
      return Left(
        ServerFailure('Failed to create notification: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> createNotificationsForUsers(
    List<String> userIds,
    String title,
    String message,
    NotificationType type, {
    Map<String, dynamic>? data,
    String? actionUrl,
  }) async {
    try {
      await remoteDataSource.createNotificationsForUsers(
        userIds,
        title,
        message,
        type,
        data: data,
        actionUrl: actionUrl,
      );
      return const Right(null);
    } catch (e) {
      debugPrint('Error in createNotificationsForUsers: $e');
      return Left(
        ServerFailure('Failed to create notifications: ${e.toString()}'),
      );
    }
  }
}
