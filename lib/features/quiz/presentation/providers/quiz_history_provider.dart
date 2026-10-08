import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/submission.dart';
import '../providers/quiz_usecases.dart';
import '../../domain/usecases/get_submissions.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

class QuizHistoryState {
  final List<Submission> submissions;
  final bool isLoading;
  final String? error;

  const QuizHistoryState({
    this.submissions = const [],
    this.isLoading = false,
    this.error,
  });

  QuizHistoryState copyWith({
    List<Submission>? submissions,
    bool? isLoading,
    String? error,
  }) {
    return QuizHistoryState(
      submissions: submissions ?? this.submissions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class QuizHistoryNotifier extends Notifier<QuizHistoryState> {
  @override
  QuizHistoryState build() {
    // Load history when provider is first created
    Future.microtask(() => loadHistory());
    return const QuizHistoryState();
  }

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final authState = ref.read(authProvider);
      if (authState.userId == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'User not authenticated',
        );
        return;
      }

      final getSubmissionsUseCase = ref.read(getSubmissionsUseCaseProvider);
      final result = await getSubmissionsUseCase.call(
        GetSubmissionsParams(userId: authState.userId!),
      );

      result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            error: failure.message,
          );
        },
        (submissions) {
          state = state.copyWith(
            isLoading: false,
            submissions: submissions,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load quiz history: $e',
      );
    }
  }

  Future<void> refreshHistory() async {
    await loadHistory();
  }
}

final quizHistoryProvider = NotifierProvider<QuizHistoryNotifier, QuizHistoryState>(() {
  return QuizHistoryNotifier();
});
