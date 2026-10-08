import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/service_providers.dart';
import '../../domain/entities/recent_activity.dart';
import '../../domain/usecases/get_recent_activity.dart';
import 'admin_usecases.dart';

class RecentActivityState {
  final List<RecentActivity> activities;
  final bool isLoading;
  final bool isFromCache;
  final String? errorMessage;

  const RecentActivityState({
    this.activities = const [],
    this.isLoading = false,
    this.isFromCache = false,
    this.errorMessage,
  });

  RecentActivityState copyWith({
    List<RecentActivity>? activities,
    bool? isLoading,
    bool? isFromCache,
    String? errorMessage,
  }) {
    return RecentActivityState(
      activities: activities ?? this.activities,
      isLoading: isLoading ?? this.isLoading,
      isFromCache: isFromCache ?? this.isFromCache,
      errorMessage: errorMessage,
    );
  }
}

class RecentActivityNotifier extends Notifier<RecentActivityState> {
  @override
  RecentActivityState build() {
    return const RecentActivityState();
  }

  Future<void> loadRecentActivity({int limit = 10}) async {
    state = state.copyWith(isLoading: true);

    try {
      final getRecentActivityUseCase = ref.read(
        getRecentActivityUseCaseProvider,
      );
      final result = await getRecentActivityUseCase.call(
        GetRecentActivityParams(limit: limit),
      );

      final isOnline = ref.read(isOnlineProvider);

      result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: failure.message,
          );
        },
        (activities) {
          state = state.copyWith(
            isLoading: false,
            isFromCache: !isOnline,
            activities: activities,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load recent activity: ${e.toString()}',
      );
    }
  }

  void refresh() {
    loadRecentActivity();
  }
}

final recentActivityProvider =
    NotifierProvider<RecentActivityNotifier, RecentActivityState>(
      RecentActivityNotifier.new,
    );
