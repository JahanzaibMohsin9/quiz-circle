import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../quiz/presentation/providers/quiz_usecases.dart';

/// State for global leaderboard
class GlobalLeaderboardState {
  final List<Map<String, dynamic>> leaderboard;
  final bool isLoading;
  final String? errorMessage;

  const GlobalLeaderboardState({
    this.leaderboard = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  GlobalLeaderboardState copyWith({
    List<Map<String, dynamic>>? leaderboard,
    bool? isLoading,
    String? errorMessage,
  }) {
    return GlobalLeaderboardState(
      leaderboard: leaderboard ?? this.leaderboard,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier for global leaderboard
class GlobalLeaderboardNotifier extends Notifier<GlobalLeaderboardState> {
  @override
  GlobalLeaderboardState build() {
    Future.microtask(() => loadLeaderboard());
    return const GlobalLeaderboardState(isLoading: true);
  }

  Future<void> loadLeaderboard() async {
    try {
      state = state.copyWith(isLoading: true);

      final getGlobalLeaderboardUseCase = ref.read(
        getGlobalLeaderboardUseCaseProvider,
      );
      final result = await getGlobalLeaderboardUseCase.call(const NoParams());

      result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            errorMessage:
                'Failed to load global leaderboard: ${failure.message}',
          );
        },
        (leaderboard) {
          state = state.copyWith(leaderboard: leaderboard, isLoading: false);
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load global leaderboard: ${e.toString()}',
      );
    }
  }

  void refreshLeaderboard() {
    loadLeaderboard();
  }
}

/// Provider for global leaderboard
final globalLeaderboardProvider =
    NotifierProvider<GlobalLeaderboardNotifier, GlobalLeaderboardState>(
      GlobalLeaderboardNotifier.new,
    );

/// Provider for top global score
final topGlobalScoreProvider = Provider<int?>((ref) {
  final leaderboardState = ref.watch(globalLeaderboardProvider);
  if (leaderboardState.leaderboard.isEmpty) return null;
  return leaderboardState.leaderboard.first['totalScore'] as int?;
});

/// Provider for user's global rank
final userGlobalRankProvider = Provider.family<int?, String>((ref, userId) {
  final leaderboardState = ref.watch(globalLeaderboardProvider);
  if (leaderboardState.leaderboard.isEmpty) return null;

  final userIndex = leaderboardState.leaderboard.indexWhere(
    (entry) => entry['userId'] == userId,
  );

  return userIndex >= 0 ? userIndex + 1 : null;
});
