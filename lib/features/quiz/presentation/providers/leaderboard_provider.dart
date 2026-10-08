import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/quiz_usecases.dart';
import '../../domain/usecases/get_leaderboard.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

class LeaderboardState {
  final List<Map<String, dynamic>> leaderboard;
  final bool isLoading;
  final String? errorMessage;

  const LeaderboardState({
    this.leaderboard = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  LeaderboardState copyWith({
    List<Map<String, dynamic>>? leaderboard,
    bool? isLoading,
    String? errorMessage,
  }) {
    return LeaderboardState(
      leaderboard: leaderboard ?? this.leaderboard,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class LeaderboardNotifier extends Notifier<LeaderboardState> {
  final String quizId;

  LeaderboardNotifier(this.quizId);

  @override
  LeaderboardState build() {
    Future.microtask(() => loadLeaderboard());
    return const LeaderboardState(isLoading: true);
  }

  Future<void> loadLeaderboard() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final getLeaderboardUseCase = ref.read(getLeaderboardUseCaseProvider);
      final result = await getLeaderboardUseCase.call(
        GetLeaderboardParams(quizId: quizId),
      );

      result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: failure.message,
          );
        },
        (leaderboard) {
          // Sort by score (descending) and then by time taken (ascending)
          final sortedLeaderboard = List<Map<String, dynamic>>.from(leaderboard);
          sortedLeaderboard.sort((a, b) {
            final scoreComparison = (b['score'] as int).compareTo(a['score'] as int);
            if (scoreComparison != 0) return scoreComparison;
            
            // If scores are equal, the one with less time ranks higher
            return (a['timeTakenSeconds'] as int).compareTo(b['timeTakenSeconds'] as int);
          });

          state = state.copyWith(
            isLoading: false,
            leaderboard: sortedLeaderboard,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load leaderboard: ${e.toString()}',
      );
    }
  }

  void refreshLeaderboard() {
    loadLeaderboard();
  }
}

final leaderboardProvider = NotifierProvider.family<LeaderboardNotifier, LeaderboardState, String>(LeaderboardNotifier.new);

final leaderboardProviderForQuiz = Provider.family<LeaderboardState, String>((ref, quizId) {
  return ref.watch(leaderboardProvider(quizId));
});

final topScoreProvider = Provider.family<int?, String>((ref, quizId) {
  final leaderboardState = ref.watch(leaderboardProviderForQuiz(quizId));
  if (leaderboardState.leaderboard.isEmpty) return null;
  return leaderboardState.leaderboard.first['score'] as int?;
});

final userRankProvider = Provider.family<int?, String>((ref, quizId) {
  final leaderboardState = ref.watch(leaderboardProviderForQuiz(quizId));
  if (leaderboardState.leaderboard.isEmpty) return null;
  
  final authState = ref.watch(authProvider);
  if (authState.userId == null) return null;
  
  final userIndex = leaderboardState.leaderboard.indexWhere(
    (entry) => entry['userId'] == authState.userId,
  );
  
  return userIndex >= 0 ? userIndex + 1 : null;
});
