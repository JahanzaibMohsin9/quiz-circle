import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/providers/service_providers.dart';
import '../../domain/entities/analytics.dart';
import '../../domain/usecases/get_quiz_analytics.dart';
import '../../domain/usecases/get_system_analytics.dart';
import '../../domain/usecases/get_detailed_user_analytics.dart';
import '../../domain/usecases/get_top_performing_users.dart';
import '../../domain/usecases/get_top_performing_quizzes.dart';
import 'admin_repository_provider.dart';

// Analytics state classes
class AnalyticsState {
  final bool isLoading;
  final bool isFromCache;
  final DateTime? lastSyncTime;
  final String? error;
  final SystemAnalytics? systemAnalytics;
  final QuizAnalytics? quizAnalytics;
  final UserAnalytics? userAnalytics;
  final List<UserAnalytics>? topUsers;
  final List<QuizAnalytics>? topQuizzes;

  // Cache expiry tracking
  final DateTime? systemAnalyticsLoadedAt;
  final DateTime? quizAnalyticsLoadedAt;
  final DateTime? userAnalyticsLoadedAt;

  const AnalyticsState({
    this.isLoading = false,
    this.isFromCache = false,
    this.lastSyncTime,
    this.error,
    this.systemAnalytics,
    this.quizAnalytics,
    this.userAnalytics,
    this.topUsers,
    this.topQuizzes,
    this.systemAnalyticsLoadedAt,
    this.quizAnalyticsLoadedAt,
    this.userAnalyticsLoadedAt,
  });

  // Cache duration - 5 minutes
  static const cacheDuration = Duration(minutes: 5);

  bool get isSystemAnalyticsCacheValid {
    if (systemAnalyticsLoadedAt == null) return false;
    return DateTime.now().difference(systemAnalyticsLoadedAt!) < cacheDuration;
  }

  bool get isQuizAnalyticsCacheValid {
    if (quizAnalyticsLoadedAt == null) return false;
    return DateTime.now().difference(quizAnalyticsLoadedAt!) < cacheDuration;
  }

  bool get isUserAnalyticsCacheValid {
    if (userAnalyticsLoadedAt == null) return false;
    return DateTime.now().difference(userAnalyticsLoadedAt!) < cacheDuration;
  }

  AnalyticsState copyWith({
    bool? isLoading,
    bool? isFromCache,
    DateTime? lastSyncTime,
    String? error,
    SystemAnalytics? systemAnalytics,
    QuizAnalytics? quizAnalytics,
    UserAnalytics? userAnalytics,
    List<UserAnalytics>? topUsers,
    List<QuizAnalytics>? topQuizzes,
    DateTime? systemAnalyticsLoadedAt,
    DateTime? quizAnalyticsLoadedAt,
    DateTime? userAnalyticsLoadedAt,
  }) {
    return AnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      isFromCache: isFromCache ?? this.isFromCache,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      error: error,
      systemAnalytics: systemAnalytics ?? this.systemAnalytics,
      quizAnalytics: quizAnalytics ?? this.quizAnalytics,
      userAnalytics: userAnalytics ?? this.userAnalytics,
      topUsers: topUsers ?? this.topUsers,
      topQuizzes: topQuizzes ?? this.topQuizzes,
      systemAnalyticsLoadedAt:
          systemAnalyticsLoadedAt ?? this.systemAnalyticsLoadedAt,
      quizAnalyticsLoadedAt:
          quizAnalyticsLoadedAt ?? this.quizAnalyticsLoadedAt,
      userAnalyticsLoadedAt:
          userAnalyticsLoadedAt ?? this.userAnalyticsLoadedAt,
    );
  }
}

// Analytics notifier
class AnalyticsNotifier extends Notifier<AnalyticsState> {
  @override
  AnalyticsState build() {
    return const AnalyticsState();
  }

  Future<void> loadSystemAnalytics({
    DateRange? dateRange,
    bool forceRefresh = false,
  }) async {
    // Check if cache is still valid and we're not forcing refresh
    if (!forceRefresh && state.isSystemAnalyticsCacheValid) {
      // Use cached data, no need to reload
      return;
    }

    state = state.copyWith(isLoading: true);

    final getSystemAnalytics = ref.read(getSystemAnalyticsProvider);
    final result = await getSystemAnalytics(
      GetSystemAnalyticsParams(dateRange: dateRange),
    );

    final isOnline = ref.read(isOnlineProvider);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
      (analytics) => state = state.copyWith(
        isLoading: false,
        isFromCache: !isOnline,
        lastSyncTime: isOnline ? DateTime.now() : state.lastSyncTime,
        systemAnalytics: analytics,
        systemAnalyticsLoadedAt: DateTime.now(),
      ),
    );
  }

  Future<void> loadQuizAnalytics(String quizId, {DateRange? dateRange}) async {
    state = state.copyWith(isLoading: true);

    final getQuizAnalytics = ref.read(getQuizAnalyticsProvider);
    final result = await getQuizAnalytics(
      GetQuizAnalyticsParams(quizId: quizId, dateRange: dateRange),
    );

    final isOnline = ref.read(isOnlineProvider);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
      (analytics) => state = state.copyWith(
        isLoading: false,
        isFromCache: !isOnline,
        quizAnalytics: analytics,
      ),
    );
  }

  Future<void> loadUserAnalytics(String userId) async {
    state = state.copyWith(isLoading: true);

    final getDetailedUserAnalytics = ref.read(getDetailedUserAnalyticsProvider);
    final result = await getDetailedUserAnalytics(
      GetDetailedUserAnalyticsParams(userId: userId),
    );

    final isOnline = ref.read(isOnlineProvider);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
      (analytics) => state = state.copyWith(
        isLoading: false,
        isFromCache: !isOnline,
        userAnalytics: analytics,
      ),
    );
  }

  Future<void> loadTopPerformingUsers({int limit = 10}) async {
    state = state.copyWith(isLoading: true);

    final getTopPerformingUsers = ref.read(getTopPerformingUsersProvider);
    final result = await getTopPerformingUsers(
      GetTopPerformingUsersParams(limit: limit),
    );

    final isOnline = ref.read(isOnlineProvider);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
      (users) => state = state.copyWith(
        isLoading: false,
        isFromCache: !isOnline,
        topUsers: users,
      ),
    );
  }

  Future<void> loadTopPerformingQuizzes({int limit = 10}) async {
    state = state.copyWith(isLoading: true);

    final getTopPerformingQuizzes = ref.read(getTopPerformingQuizzesProvider);
    final result = await getTopPerformingQuizzes(
      GetTopPerformingQuizzesParams(limit: limit),
    );

    final isOnline = ref.read(isOnlineProvider);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
      (quizzes) => state = state.copyWith(
        isLoading: false,
        isFromCache: !isOnline,
        topQuizzes: quizzes,
      ),
    );
  }

  Future<void> refreshAllAnalytics({DateRange? dateRange}) async {
    // Force refresh bypasses cache
    await Future.wait([
      loadSystemAnalytics(dateRange: dateRange, forceRefresh: true),
      loadTopPerformingUsers(),
      loadTopPerformingQuizzes(),
    ]);
  }

  void clearError() {
    state = state.copyWith();
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure _:
        return 'Server error occurred. Please try again later.';
      case NetworkFailure _:
        return 'Network error. Please check your internet connection.';
      case CacheFailure _:
        return 'Cache error. Please try again.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}

// Use case providers
final getSystemAnalyticsProvider = Provider<GetSystemAnalytics>((ref) {
  return GetSystemAnalytics(ref.read(adminRepositoryProvider));
});

final getQuizAnalyticsProvider = Provider<GetQuizAnalytics>((ref) {
  return GetQuizAnalytics(ref.read(adminRepositoryProvider));
});

final getDetailedUserAnalyticsProvider = Provider<GetDetailedUserAnalytics>((
  ref,
) {
  return GetDetailedUserAnalytics(ref.read(adminRepositoryProvider));
});

final getTopPerformingUsersProvider = Provider<GetTopPerformingUsers>((ref) {
  return GetTopPerformingUsers(ref.read(adminRepositoryProvider));
});

final getTopPerformingQuizzesProvider = Provider<GetTopPerformingQuizzes>((
  ref,
) {
  return GetTopPerformingQuizzes(ref.read(adminRepositoryProvider));
});

// Providers
final analyticsProvider = NotifierProvider<AnalyticsNotifier, AnalyticsState>(
  () {
    return AnalyticsNotifier();
  },
);

// Individual providers for different analytics data
final systemAnalyticsProvider = Provider<SystemAnalytics?>((ref) {
  return ref.watch(analyticsProvider).systemAnalytics;
});

final quizAnalyticsProvider = Provider<QuizAnalytics?>((ref) {
  return ref.watch(analyticsProvider).quizAnalytics;
});

final userAnalyticsProvider = Provider<UserAnalytics?>((ref) {
  return ref.watch(analyticsProvider).userAnalytics;
});

final topUsersProvider = Provider<List<UserAnalytics>?>((ref) {
  return ref.watch(analyticsProvider).topUsers;
});

final topQuizzesProvider = Provider<List<QuizAnalytics>?>((ref) {
  return ref.watch(analyticsProvider).topQuizzes;
});

final analyticsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(analyticsProvider).isLoading;
});

final analyticsErrorProvider = Provider<String?>((ref) {
  return ref.watch(analyticsProvider).error;
});
