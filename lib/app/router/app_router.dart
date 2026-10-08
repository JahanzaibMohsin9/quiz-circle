import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/route_constants.dart';
import '../../features/announcements/presentation/pages/announcements_page.dart';
import '../../features/announcements/presentation/pages/create_announcement_page.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin/presentation/pages/analytics_page.dart';
import '../../features/admin/presentation/pages/create_quiz_page.dart';
import '../../features/admin/presentation/pages/edit_quiz_page.dart';
import '../../features/admin/presentation/pages/manage_quizzes_page.dart';
import '../../features/admin/presentation/pages/manage_users_page.dart';
import '../../features/admin/presentation/pages/view_submissions_page.dart';
import '../../features/admin/presentation/pages/submission_detail_page.dart';
import '../../features/authentication/domain/entities/user.dart';
import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/authentication/presentation/pages/register_page.dart';
import '../../features/authentication/presentation/pages/splash_page.dart';
import '../../features/authentication/presentation/providers/auth_provider.dart';
import '../../features/quiz/presentation/pages/global_leaderboard_page.dart';
import '../../features/quiz/presentation/pages/leaderboard_page.dart';
import '../../features/quiz/presentation/pages/my_leaderboards_page.dart';
import '../../features/quiz/presentation/pages/quiz_attempt_page.dart';
import '../../features/quiz/presentation/pages/quiz_list_page.dart';
import '../../features/quiz/presentation/pages/quiz_result_page.dart';
import '../../features/quiz/presentation/pages/quiz_history_page.dart';
import '../../features/student/presentation/pages/student_dashboard_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart'
    as admin_profile;
import '../../features/student/presentation/pages/profile_page.dart'
    as student_profile;

// Router provider that watches auth state
// Router provider that watches auth state
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteConstants.splash,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: _AuthStateNotifier(ref),
    redirect: (context, state) {
      // Read fresh auth state on each redirect
      final authState = ref.read(authProvider);
      final isAuthenticated = authState.isAuthenticated;
      final userRole = authState.role;
      final currentPath = state.uri.path;

      // List of public routes that don't require authentication
      final publicRoutes = [
        RouteConstants.splash,
        RouteConstants.login,
        RouteConstants.register,
      ];

      // List of admin-only routes
      final adminRoutes = [
        RouteConstants.adminDashboard,
        RouteConstants.adminProfile,
        RouteConstants.createQuiz,
        RouteConstants.editQuiz,
        RouteConstants.manageQuizzes,
        RouteConstants.manageUsers,
        RouteConstants.viewSubmissions,
        RouteConstants.analytics,
        RouteConstants.createAnnouncement,
      ];

      // List of student-only routes
      final studentRoutes = [
        RouteConstants.studentDashboard,
        RouteConstants.quizList,
        RouteConstants.quizAttempt,
        RouteConstants.quizResult,
        RouteConstants.leaderboard,
        RouteConstants.myLeaderboards,
        RouteConstants.profile,
        RouteConstants.quizHistory,
        RouteConstants.announcements,
      ];

      // If on splash, let it handle navigation
      if (currentPath == RouteConstants.splash) {
        return null;
      }

      // If not authenticated and trying to access protected route
      if (!isAuthenticated && !publicRoutes.contains(currentPath)) {
        return RouteConstants.login;
      }

      // If authenticated but on login/register, redirect to appropriate dashboard
      if (isAuthenticated &&
          (currentPath == RouteConstants.login ||
              currentPath == RouteConstants.register)) {
        if (userRole == UserRole.admin) {
          return RouteConstants.adminDashboard;
        } else {
          return RouteConstants.studentDashboard;
        }
      }

      // Role-based route protection
      if (isAuthenticated) {
        // Admin trying to access student routes
        if (userRole == UserRole.admin && studentRoutes.contains(currentPath)) {
          return RouteConstants.adminDashboard;
        }
        // Student trying to access admin routes
        if (userRole == UserRole.student && adminRoutes.contains(currentPath)) {
          return RouteConstants.studentDashboard;
        }
      }

      // No redirect needed
      return null;
    },
    routes: [
      // Splash Screen
      GoRoute(
        name: RouteConstants.splashName,
        path: RouteConstants.splash,
        builder: (context, state) => const SplashPage(),
      ),

      // Authentication Routes
      GoRoute(
        name: RouteConstants.loginName,
        path: RouteConstants.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        name: RouteConstants.registerName,
        path: RouteConstants.register,
        builder: (context, state) => const RegisterPage(),
      ),

      // Student Routes
      GoRoute(
        name: RouteConstants.quizListName,
        path: RouteConstants.quizList,
        builder: (context, state) => const QuizListPage(),
      ),
      GoRoute(
        name: RouteConstants.quizAttemptName,
        path: RouteConstants.quizAttempt,
        builder: (context, state) {
          final quizId = state.uri.queryParameters['quizId'];
          if (quizId == null) {
            return const Scaffold(
              body: Center(child: Text('Quiz ID is required')),
            );
          }
          return QuizAttemptPage(quizId: quizId);
        },
      ),
      GoRoute(
        name: RouteConstants.quizResultName,
        path: RouteConstants.quizResult,
        builder: (context, state) {
          final quizId = state.uri.queryParameters['quizId'];
          final submissionId = state.uri.queryParameters['submissionId'];
          if (quizId == null || submissionId == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(
                child: Text('Quiz ID and Submission ID are required'),
              ),
            );
          }
          return QuizResultPage(quizId: quizId, submissionId: submissionId);
        },
      ),
      GoRoute(
        name: RouteConstants.leaderboardName,
        path: RouteConstants.leaderboard,
        builder: (context, state) {
          final quizId = state.uri.queryParameters['quizId'];
          final quizTitle =
              state.uri.queryParameters['quizTitle'] ?? 'Quiz Leaderboard';

          if (quizId == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Leaderboard')),
              body: const Center(
                child: Text('Quiz ID is required to view leaderboard'),
              ),
            );
          }

          return LeaderboardPage(quizId: quizId, quizTitle: quizTitle);
        },
      ),
      GoRoute(
        name: RouteConstants.globalLeaderboardName,
        path: RouteConstants.globalLeaderboard,
        builder: (context, state) => const GlobalLeaderboardPage(),
      ),
      GoRoute(
        name: RouteConstants.myLeaderboardsName,
        path: RouteConstants.myLeaderboards,
        builder: (context, state) => const MyLeaderboardsPage(),
      ),
      GoRoute(
        name: RouteConstants.studentDashboardName,
        path: RouteConstants.studentDashboard,
        builder: (context, state) => const StudentDashboardPage(),
      ),
      GoRoute(
        name: RouteConstants.profileName,
        path: RouteConstants.profile,
        builder: (context, state) => const student_profile.ProfilePage(),
      ),
      GoRoute(
        name: RouteConstants.quizHistoryName,
        path: RouteConstants.quizHistory,
        builder: (context, state) => const QuizHistoryPage(),
      ),
      GoRoute(
        name: RouteConstants.announcementsName,
        path: RouteConstants.announcements,
        builder: (context, state) => const AnnouncementsPage(),
      ),
      GoRoute(
        name: RouteConstants.notificationsName,
        path: RouteConstants.notifications,
        builder: (context, state) => const NotificationsPage(),
      ),

      // Admin Routes
      GoRoute(
        name: RouteConstants.adminDashboardName,
        path: RouteConstants.adminDashboard,
        builder: (context, state) => const AdminDashboardPage(),
      ),
      GoRoute(
        name: RouteConstants.createQuizName,
        path: RouteConstants.createQuiz,
        builder: (context, state) => const CreateQuizPage(),
      ),

      GoRoute(
        name: RouteConstants.editQuizName,
        path: RouteConstants.editQuiz,
        builder: (context, state) {
          final quizId = state.uri.queryParameters['quizId'];
          if (quizId == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(child: Text('Quiz ID is required')),
            );
          }
          return EditQuizPage(quizId: quizId);
        },
      ),
      GoRoute(
        name: RouteConstants.manageQuizzesName,
        path: RouteConstants.manageQuizzes,
        builder: (context, state) => const ManageQuizzesPage(),
      ),
      GoRoute(
        name: RouteConstants.manageUsersName,
        path: RouteConstants.manageUsers,
        builder: (context, state) => const ManageUsersPage(),
      ),
      GoRoute(
        name: RouteConstants.viewSubmissionsName,
        path: RouteConstants.viewSubmissions,
        builder: (context, state) {
          final quizId = state.uri.queryParameters['quizId'];
          return ViewSubmissionsPage(quizId: quizId);
        },
      ),
      GoRoute(
        name: RouteConstants.submissionDetailName,
        path: RouteConstants.submissionDetail,
        builder: (context, state) {
          final submissionId = state.uri.queryParameters['submissionId'];
          final quizId = state.uri.queryParameters['quizId'];

          if (submissionId == null) {
            return const Scaffold(
              body: Center(child: Text('Submission ID is required')),
            );
          }

          return SubmissionDetailPage(
            submissionId: submissionId,
            quizId: quizId,
          );
        },
      ),
      GoRoute(
        name: RouteConstants.analyticsName,
        path: RouteConstants.analytics,
        builder: (context, state) => const AnalyticsPage(),
      ),
      GoRoute(
        name: RouteConstants.createAnnouncementName,
        path: RouteConstants.createAnnouncement,
        builder: (context, state) => const CreateAnnouncementPage(),
      ),
      GoRoute(
        name: RouteConstants.adminProfileName,
        path: RouteConstants.adminProfile,
        builder: (context, state) => const admin_profile.ProfilePage(),
      ),
    ],
    errorPageBuilder: (context, state) => MaterialPage(
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Page Not Found',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Could not find route: ${state.uri.toString()}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(RouteConstants.splash),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
});

// Helper class to notify GoRouter when auth state changes
class _AuthStateNotifier extends ChangeNotifier {
  final Ref _ref;

  _AuthStateNotifier(this._ref) {
    // Listen to auth state changes and notify GoRouter
    _ref.listen(authProvider, (previous, next) {
      notifyListeners();
    });
  }
}

/// Extension methods for navigation
extension RouterExtensions on BuildContext {
  void goNamed(
    String name, {
    Map<String, String>? pathParameters,
    Map<String, String>? queryParameters,
  }) {
    final params = <String, String>{};
    if (pathParameters != null) params.addAll(pathParameters);
    if (queryParameters != null) params.addAll(queryParameters);
    GoRouter.of(this).goNamed(name, pathParameters: params);
  }

  Future<T?> pushNamed<T>(
    String name, {
    Map<String, String>? pathParameters,
    Map<String, String>? queryParameters,
  }) {
    final params = <String, String>{};
    if (pathParameters != null) params.addAll(pathParameters);
    if (queryParameters != null) params.addAll(queryParameters);
    return GoRouter.of(this).pushNamed<T>(name, pathParameters: params);
  }

  void pop<T extends Object?>([T? result]) {
    GoRouter.of(this).pop(result);
  }
}
