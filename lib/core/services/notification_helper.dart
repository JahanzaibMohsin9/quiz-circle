import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../features/notifications/data/datasources/notification_remote_datasource.dart';
import '../../features/notifications/domain/entities/notification_type.dart';

/// Helper service to create notifications for system events
class NotificationHelper {
  static final NotificationHelper instance = NotificationHelper._();
  NotificationHelper._();

  final NotificationRemoteDataSource _dataSource =
      NotificationRemoteDataSource();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create notifications for all users when an announcement is created
  Future<void> createAnnouncementNotifications({
    required String announcementId,
    required String title,
    required String message,
  }) async {
    try {
      // Get all user IDs from Firestore
      final usersSnapshot = await _firestore.collection('users').get();
      final userIds = usersSnapshot.docs.map((doc) => doc.id).toList();

      if (userIds.isEmpty) {
        debugPrint('No users found to send notifications to');
        return;
      }

      // Create notifications for all users
      await _dataSource.createNotificationsForUsers(
        userIds,
        '📢 $title',
        message,
        NotificationType.announcement,
        data: {'announcementId': announcementId, 'type': 'announcement'},
        actionUrl: '/student/announcements',
      );

      // Send push notification to all users via FCM topic
      await _sendPushNotificationToTopic(
        topic: 'announcements',
        title: '📢 $title',
        body: message,
        data: {
          'type': 'announcement',
          'announcementId': announcementId,
          'actionUrl': '/student/announcements',
        },
      );

      debugPrint(
        'Created announcement notifications for ${userIds.length} users',
      );
    } catch (e) {
      debugPrint('Error creating announcement notifications: $e');
    }
  }

  /// Create notification for a specific user when a quiz is published
  Future<void> createQuizNotification({
    required String userId,
    required String quizId,
    required String quizTitle,
  }) async {
    try {
      await _dataSource.createNotificationsForUsers(
        [userId],
        '📝 New Quiz Available',
        'A new quiz "$quizTitle" has been published. Take it now!',
        NotificationType.quiz,
        data: {'quizId': quizId, 'type': 'quiz'},
        actionUrl: '/student/quizzes',
      );

      debugPrint('Created quiz notification for user $userId');
    } catch (e) {
      debugPrint('Error creating quiz notification: $e');
    }
  }

  /// Create notifications for all users when a quiz is published
  Future<void> createQuizNotificationsForAll({
    required String quizId,
    required String quizTitle,
  }) async {
    try {
      // Get all student user IDs
      final usersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();
      final userIds = usersSnapshot.docs.map((doc) => doc.id).toList();

      if (userIds.isEmpty) {
        debugPrint('No students found to send quiz notifications to');
        return;
      }

      await _dataSource.createNotificationsForUsers(
        userIds,
        '📝 New Quiz Available',
        'A new quiz "$quizTitle" has been published. Take it now!',
        NotificationType.quiz,
        data: {'quizId': quizId, 'type': 'quiz'},
        actionUrl: '/student/quizzes',
      );

      // Send push notification to students via FCM topic
      await _sendPushNotificationToTopic(
        topic: 'students',
        title: '📝 New Quiz Available',
        body: 'A new quiz "$quizTitle" has been published. Take it now!',
        data: {
          'type': 'quiz',
          'quizId': quizId,
          'actionUrl': '/student/quizzes',
        },
      );

      debugPrint('Created quiz notifications for ${userIds.length} students');
    } catch (e) {
      debugPrint('Error creating quiz notifications: $e');
    }
  }

  /// Create notification when a quiz submission is graded
  Future<void> createSubmissionNotification({
    required String userId,
    required String quizId,
    required String quizTitle,
    required String submissionId,
    required double score,
  }) async {
    try {
      await _dataSource.createNotificationsForUsers(
        [userId],
        '✅ Quiz Graded',
        'Your submission for "$quizTitle" has been graded. Score: ${score.toStringAsFixed(1)}%',
        NotificationType.submission,
        data: {
          'quizId': quizId,
          'submissionId': submissionId,
          'score': score,
          'type': 'submission',
        },
        actionUrl:
            '/student/quizzes/result?quizId=$quizId&submissionId=$submissionId',
      );

      debugPrint('Created submission notification for user $userId');
    } catch (e) {
      debugPrint('Error creating submission notification: $e');
    }
  }

  /// Create a system notification for a specific user
  Future<void> createSystemNotification({
    required String userId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    String? actionUrl,
  }) async {
    try {
      await _dataSource.createNotificationsForUsers(
        [userId],
        title,
        message,
        NotificationType.system,
        data: data ?? {},
        actionUrl: actionUrl,
      );

      debugPrint('Created system notification for user $userId');
    } catch (e) {
      debugPrint('Error creating system notification: $e');
    }
  }

  /// Send push notification to an FCM topic
  /// Note: This requires Cloud Functions or backend server to actually send
  /// For now, this is a placeholder showing the structure
  Future<void> _sendPushNotificationToTopic({
    required String topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      debugPrint('Push notification would be sent to topic: $topic');
      debugPrint('Title: $title');
      debugPrint('Body: $body');
      debugPrint('Data: $data');

      // NOTE: To actually send push notifications, you need to:
      // 1. Set up Firebase Cloud Functions or a backend server
      // 2. Use the Firebase Admin SDK to send messages
      // 3. Call your Cloud Function/API endpoint here

      // Example Cloud Function call (commented out):
      /*
      final response = await http.post(
        Uri.parse('YOUR_CLOUD_FUNCTION_URL/sendNotification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'topic': topic,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': data ?? {},
        }),
      );
      
      if (response.statusCode == 200) {
        debugPrint('Push notification sent successfully');
      } else {
        debugPrint('Failed to send push notification: ${response.body}');
      }
      */
    } catch (e) {
      debugPrint('Error sending push notification: $e');
    }
  }
}
