import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance {
    _instance ??= FirebaseService._();
    return _instance!;
  }

  FirebaseService._();

  // Firebase instances
  late final FirebaseApp _app;
  late final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore;
  late final FirebaseStorage _storage;
  late final FirebaseMessaging _messaging;
  late final FirebaseAppCheck _appCheck;

  // Getters
  FirebaseApp get app => _app;
  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
  FirebaseStorage get storage => _storage;
  FirebaseMessaging get messaging => _messaging;
  FirebaseAppCheck get appCheck => _appCheck;

  /// Initialize Firebase services
  Future<void> initialize() async {
    try {
      // Initialize Firebase Core
      _app = await Firebase.initializeApp();

      // Initialize Firebase Auth
      _auth = FirebaseAuth.instance;

      // Initialize Firestore
      _firestore = FirebaseFirestore.instance;

      // Initialize Firebase Storage
      _storage = FirebaseStorage.instance;

      // Initialize Firebase Messaging
      _messaging = FirebaseMessaging.instance;

      // Initialize Firebase App Check
      await _initializeAppCheck();

      // Request notification permissions (for mobile platforms)
      if (!kIsWeb) {
        await _requestNotificationPermissions();
      }

      // Configure Firestore settings
      await _configureFirestore();

      debugPrint('Firebase services initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize Firebase: $e');
      rethrow;
    }
  }

  /// Request notification permissions
  Future<void> _requestNotificationPermissions() async {
    final settings = await _messaging.requestPermission(
      
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }
  }

  /// Configure Firestore settings
  Future<void> _configureFirestore() async {
    // Configure cache size
    _firestore.settings = const Settings(
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      persistenceEnabled: true,
    );
  }

  /// Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Check if user is authenticated
  bool isUserAuthenticated() {
    return _auth.currentUser != null;
  }

  /// Sign out current user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get FCM token for push notifications
  Future<String?> getFCMToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
      return null;
    }
  }

  /// Subscribe to a topic for push notifications
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Failed to subscribe to topic $topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Failed to unsubscribe from topic $topic: $e');
    }
  }

  /// Initialize Firebase App Check
  Future<void> _initializeAppCheck() async {
    try {
      _appCheck = FirebaseAppCheck.instance;

      // Configure App Check provider based on platform and environment
      if (kDebugMode) {
        // Use debug provider for development
        if (Platform.isAndroid) {
          await _appCheck.activate(providerAndroid: const AndroidDebugProvider());
          debugPrint(
            'Firebase App Check initialized with debug provider (Android)',
          );
        } else if (Platform.isIOS) {
          await _appCheck.activate(providerApple: const AppleDebugProvider());
          debugPrint(
            'Firebase App Check initialized with debug provider (iOS)',
          );
        } else {
          debugPrint(
            'Firebase App Check initialized (unsupported platform for debug provider)',
          );
        }
      } else {
        // In production, use device check (iOS) or Play Integrity (Android)
        // Note: You'll need to configure these in Firebase Console for production
        if (Platform.isAndroid) {
          await _appCheck.activate(
            
          );
          debugPrint(
            'Firebase App Check initialized with Play Integrity (Android)',
          );
        } else if (Platform.isIOS) {
          await _appCheck.activate();
          debugPrint('Firebase App Check initialized with DeviceCheck (iOS)');
        }
      }
    } catch (e) {
      debugPrint('Failed to initialize Firebase App Check: $e');
      // Continue without App Check - this is acceptable for development
      // but should be fixed before production deployment
    }
  }
}
