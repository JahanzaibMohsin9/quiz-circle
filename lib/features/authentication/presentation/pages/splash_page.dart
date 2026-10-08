import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/presentation/widgets/splash_screen.dart';
import '../../../../core/services/notification_service.dart';
import '../providers/auth_provider.dart';
import '../../domain/entities/user.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _handleSplashNavigation();
  }

  Future<void> _handleSplashNavigation() async {
    // Wait for minimum splash duration (3 seconds)
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Check auth state
    final authState = ref.read(authProvider);

    if (authState.isAuthenticated) {
      if (authState.role == UserRole.admin) {
        context.go(RouteConstants.adminDashboard);
      } else {
        // Subscribe students to 'students' topic for quiz notifications
        try {
          await NotificationService.instance.subscribeToTopic('students');
        } catch (e) {
          // Continue even if subscription fails
        }
        context.go(RouteConstants.studentDashboard);
      }
    } else {
      context.go(RouteConstants.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    // We don't watch authProvider here to avoid rebuilding/NAVIGATING during the delay
    // logic is handled in _handleSplashNavigation
    return const SplashScreen();
  }
}
