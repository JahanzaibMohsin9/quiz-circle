import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/notification_type.dart';
import '../models/notification_model.dart';

/// Remote data source for notification operations
class NotificationRemoteDataSource {
  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();

  NotificationRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get notifications collection reference for a user
  CollectionReference _getUserNotificationsCollection(String userId) {
    return _firestore
        .collection('notifications')
        .doc(userId)
        .collection('userNotifications');
  }

  /// Watch user notifications in real-time
  Stream<List<NotificationModel>> watchUserNotifications(String userId) {
    return _getUserNotificationsCollection(userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Get user notifications
  Future<List<NotificationModel>> getUserNotifications(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _getUserNotificationsCollection(
        userId,
      ).orderBy('timestamp', descending: true).limit(limit).get();

      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting user notifications: $e');
      rethrow;
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _getUserNotificationsCollection(
        userId,
      ).where('isRead', isEqualTo: false).count().get();

      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      rethrow;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId, String userId) async {
    try {
      await _getUserNotificationsCollection(
        userId,
      ).doc(notificationId).update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _getUserNotificationsCollection(
        userId,
      ).where('isRead', isEqualTo: false).get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId, String userId) async {
    try {
      await _getUserNotificationsCollection(
        userId,
      ).doc(notificationId).delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      rethrow;
    }
  }

  /// Create notification
  Future<void> createNotification(NotificationModel notification) async {
    try {
      await _getUserNotificationsCollection(
        notification.userId,
      ).doc(notification.id).set(notification.toFirestore());
    } catch (e) {
      debugPrint('Error creating notification: $e');
      rethrow;
    }
  }

  /// Create notifications for multiple users (batch operation)
  Future<void> createNotificationsForUsers(
    List<String> userIds,
    String title,
    String message,
    NotificationType type, {
    Map<String, dynamic>? data,
    String? actionUrl,
  }) async {
    try {
      final batch = _firestore.batch();
      final timestamp = DateTime.now();

      for (final userId in userIds) {
        final notificationId = _uuid.v4();
        final notificationRef = _getUserNotificationsCollection(
          userId,
        ).doc(notificationId);

        final notification = NotificationModel(
          id: notificationId,
          userId: userId,
          type: type,
          title: title,
          message: message,
          data: data ?? {},
          timestamp: timestamp,
          actionUrl: actionUrl,
        );

        batch.set(notificationRef, notification.toFirestore());
      }

      await batch.commit();
      debugPrint('Created notifications for ${userIds.length} users');
    } catch (e) {
      debugPrint('Error creating notifications for users: $e');
      rethrow;
    }
  }
}
