import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  debugPrint('Message data: ${message.data}');
  debugPrint('Message notification: ${message.notification?.title}');
}

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance {
    _instance ??= NotificationService._();
    return _instance!;
  }

  NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Stream controller for notification taps
  final StreamController<Map<String, dynamic>> _notificationTapController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onNotificationTap =>
      _notificationTapController.stream;

  /// Initialize notification service
  Future<void> initialize() async {
    try {
      // Request permission
      final settings = await _requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get FCM token
        final token = await _messaging.getToken();
        debugPrint('FCM Token: $token');

        // Initialize local notifications for Android
        await _initializeLocalNotifications();

        // Set up foreground notification presentation options
        await _messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

        // Handle notification taps when app is terminated/background
        _handleInitialMessage();

        // Handle notification taps when app is in background
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        debugPrint('Notification service initialized successfully');
      } else {
        debugPrint('Notification permission denied');
      }
    } catch (e) {
      debugPrint('Failed to initialize notification service: $e');
    }
  }

  /// Request notification permissions
  Future<NotificationSettings> _requestPermission() async {
    return await _messaging.requestPermission(

    );
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    const channel = AndroidNotificationChannel(
      'quiz_app_notifications',
      'Quiz App Notifications',
      description: 'Notifications for quiz updates and announcements',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    if (response.payload != null) {
      try {
        final rawPayload = response.payload!;
        final decoded =
            jsonDecode(rawPayload) as Map<String, dynamic>? ?? <String, dynamic>{};
        _notificationTapController.add(decoded);
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
        _notificationTapController.add(<String, dynamic>{
          'payload': response.payload,
        });
      }
    }
  }

  /// Handle initial message (when app is opened from terminated state)
  void _handleInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message != null) {
      debugPrint('App opened from notification: ${message.messageId}');
      _handleNotificationData(message.data);
    }
  }

  /// Handle message opened from background
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Notification opened from background: ${message.messageId}');
    _handleNotificationData(message.data);
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Foreground message received: ${message.messageId}');

    // Show local notification when in foreground
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'quiz_app_notifications',
            'Quiz App Notifications',
            channelDescription:
                'Notifications for quiz updates and announcements',
            importance: Importance.high,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: _encodePayload(message.data),
      );
    }
  }

  /// Handle notification data for navigation
  void _handleNotificationData(Map<String, dynamic> data) {
    debugPrint('Handling notification data: $data');
    _notificationTapController.add(data);
  }

  /// Encode payload to string
  String _encodePayload(Map<String, dynamic> data) {
    return jsonEncode(data);
  }

  /// Get FCM token
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
      return null;
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Failed to subscribe to topic $topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Failed to unsubscribe from topic $topic: $e');
    }
  }

  /// Dispose
  void dispose() {
    _notificationTapController.close();
  }
}
