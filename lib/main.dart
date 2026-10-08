import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'app/app.dart';
import 'core/services/firebase_service.dart';
import 'core/services/notification_service.dart';

void main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      try {
        await FirebaseService.instance.initialize();
        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );
        await NotificationService.instance.initialize();
        await NotificationService.instance.subscribeToTopic('announcements');
      } catch (e) {
        // Continue with app startup even if Firebase fails
        // Error is already logged by Firebase internally
      }

      runApp(const ProviderScope(child: QuizCircleApp()));
    },
    (error, stack) {
      // Zone errors are caught by the global error handler
    },
  );
}

/// Main app widget - GoRouter handles splash screen and navigation
class QuizCircleApp extends StatelessWidget {
  const QuizCircleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const App();
  }
}
