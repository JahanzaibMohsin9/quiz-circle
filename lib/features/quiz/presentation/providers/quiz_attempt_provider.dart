import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/question.dart';
import '../../domain/entities/quiz_attempt.dart';
import '../../domain/entities/submission.dart';
import '../../domain/usecases/submit_quiz.dart';
import '../../domain/usecases/start_quiz_attempt.dart';
import '../../domain/usecases/get_questions_by_ids.dart';
import '../providers/quiz_usecases.dart';
import 'quiz_repository_provider.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../../core/services/quiz_scoring_service.dart';

class QuizAttemptState {
  final QuizAttempt? quizAttempt;
  final bool isLoading;
  final String? errorMessage;
  final bool isTimerRunning;
  final int remainingTimeSeconds;
  final Submission? lastSubmission; // Store the last submission result

  const QuizAttemptState({
    this.quizAttempt,
    this.isLoading = false,
    this.errorMessage,
    this.isTimerRunning = false,
    this.remainingTimeSeconds = 0,
    this.lastSubmission,
  });

  QuizAttemptState copyWith({
    QuizAttempt? quizAttempt,
    bool? isLoading,
    String? errorMessage,
    bool? isTimerRunning,
    int? remainingTimeSeconds,
    Submission? lastSubmission,
  }) {
    return QuizAttemptState(
      quizAttempt: quizAttempt ?? this.quizAttempt,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      remainingTimeSeconds: remainingTimeSeconds ?? this.remainingTimeSeconds,
      lastSubmission: lastSubmission ?? this.lastSubmission,
    );
  }
}

class QuizAttemptNotifier extends Notifier<QuizAttemptState> {
  @override
  QuizAttemptState build() {
    return const QuizAttemptState();
  }

  Future<void> initializeQuizAttempt({
    required String quizId,
    required String quizTitle,
    required int timeLimitMinutes,
    required int questionsPerAttempt,
    required bool randomizeQuestions,
    required String userId,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      // 1. Start Attempt (get/create persistent attempt)
      final startAttemptUseCase = ref.read(startQuizAttemptUseCaseProvider);
      final attemptResult = await startAttemptUseCase.call(
        StartQuizAttemptParams(
          quizId: quizId,
          userId: userId,
          questionsPerAttempt: questionsPerAttempt,
          randomizeQuestions: randomizeQuestions,
        ),
      );

      await attemptResult.fold(
        (failure) async {
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'Failed to start attempt: ${failure.message}',
          );
        },
        (attemptModel) async {
          // 2. Fetch Questions
          final getQuestionsUseCase = ref.read(
            getQuestionsByIdsUseCaseProvider,
          );
          final questionsResult = await getQuestionsUseCase.call(
            GetQuestionsByIdsParams(
              quizId: quizId,
              questionIds: attemptModel.questionIds,
            ),
          );

          questionsResult.fold(
            (failure) {
              state = state.copyWith(
                isLoading: false,
                errorMessage: 'Failed to load questions: ${failure.message}',
              );
            },
            (questions) {
              // RESUME LOGIC: Calculate remaining time based on server-side start time
              // This ensures the timer is accurate even if the app was backgrounded or closed
              final elapsedSeconds = DateTime.now()
                  .difference(attemptModel.startedAt)
                  .inSeconds;
              final totalAllowedSeconds = timeLimitMinutes * 60;
              final remainingSeconds = totalAllowedSeconds - elapsedSeconds;

              // RESUME LOGIC: Restore previous answers and current question index
              // If this is an existing attempt, the user will continue where they left off
              final quizAttempt = QuizAttempt(
                id: attemptModel.id,
                quizId: quizId,
                quizTitle: quizTitle,
                questions: questions,
                selectedAnswers: attemptModel.answers, // Restored answers
                currentQuestionIndex:
                    attemptModel.currentQuestionIndex, // Restored position
                timeLimitMinutes: timeLimitMinutes,
                timeRemainingSeconds: remainingSeconds > 0
                    ? remainingSeconds
                    : 0,
                startTime: attemptModel.startedAt,
              );

              state = state.copyWith(
                quizAttempt: quizAttempt,
                isLoading: false,
                remainingTimeSeconds: remainingSeconds > 0
                    ? remainingSeconds
                    : 0,
              );

              // Auto-submit if time has expired
              if (remainingSeconds <= 0) {
                submitQuiz();
              }
            },
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to initialize quiz: ${e.toString()}',
      );
    }
  }

  Future<void> _syncProgress() async {
    if (state.quizAttempt == null) return;

    final repo = ref.read(quizRepositoryProvider);
    await repo.updateAttemptProgress(
      state.quizAttempt!.id,
      state.quizAttempt!.selectedAnswers,
      state.quizAttempt!.currentQuestionIndex,
    );
  }

  void selectAnswer(String questionId, String answer) {
    if (state.quizAttempt == null || state.isTimerRunning == false) {
      // Allow selection only if timer is running? Or generally?
      // Usually allow if not submitted.
      if (state.quizAttempt?.isSubmitted == true) return;
    }

    final updatedAnswers = Map<String, String>.from(
      state.quizAttempt!.selectedAnswers,
    );
    updatedAnswers[questionId] = answer;

    final updatedAttempt = state.quizAttempt!.copyWith(
      selectedAnswers: updatedAnswers,
    );
    state = state.copyWith(quizAttempt: updatedAttempt);

    _syncProgress();
  }

  void goToNextQuestion() {
    if (state.quizAttempt == null || state.quizAttempt!.isLastQuestion) return;

    final updatedAttempt = state.quizAttempt!.copyWith(
      currentQuestionIndex: state.quizAttempt!.currentQuestionIndex + 1,
    );
    state = state.copyWith(quizAttempt: updatedAttempt);
    _syncProgress();
  }

  void goToPreviousQuestion() {
    if (state.quizAttempt == null || state.quizAttempt!.isFirstQuestion) return;

    final updatedAttempt = state.quizAttempt!.copyWith(
      currentQuestionIndex: state.quizAttempt!.currentQuestionIndex - 1,
    );
    state = state.copyWith(quizAttempt: updatedAttempt);
    _syncProgress();
  }

  void startTimer() {
    if (state.quizAttempt == null) return;

    state = state.copyWith(isTimerRunning: true);
  }

  void stopTimer() {
    state = state.copyWith(isTimerRunning: false);
  }

  void updateRemainingTime(int seconds) {
    state = state.copyWith(remainingTimeSeconds: seconds);
  }

  /// Recalculate remaining time from server-side start time
  /// This should be called when app resumes from background to ensure accurate time
  void recalculateRemainingTime() {
    if (state.quizAttempt == null) return;

    final elapsedSeconds = DateTime.now()
        .difference(state.quizAttempt!.startTime)
        .inSeconds;
    final totalAllowedSeconds = state.quizAttempt!.timeLimitMinutes * 60;
    final remainingSeconds = totalAllowedSeconds - elapsedSeconds;

    final updatedAttempt = state.quizAttempt!.copyWith(
      timeRemainingSeconds: remainingSeconds > 0 ? remainingSeconds : 0,
    );

    state = state.copyWith(
      quizAttempt: updatedAttempt,
      remainingTimeSeconds: remainingSeconds > 0 ? remainingSeconds : 0,
    );

    // Auto-submit if time has expired
    if (remainingSeconds <= 0 && !state.quizAttempt!.isSubmitted) {
      submitQuiz();
    }
  }

  Future<void> submitQuiz() async {
    if (state.quizAttempt == null) return;
    // Double-submit prevention guards
    if (state.quizAttempt!.isSubmitted) return;
    if (state.isLoading) return;

    // Mark as submitted in local state and set loading lock
    final updatedAttempt = state.quizAttempt!.copyWith(isSubmitted: true);
    state = state.copyWith(
      quizAttempt: updatedAttempt,
      isTimerRunning: false,
      isLoading: true,
    );

    // Actually submit to Firestore
    try {
      final submitQuizUseCase = ref.read(submitQuizUseCaseProvider);
      final authState = ref.read(authProvider);

      if (authState.userId == null) {
        state = state.copyWith(
          errorMessage: 'Cannot submit quiz: User not authenticated',
        );

        return;
      }

      final result = await submitQuizUseCase.call(
        SubmitQuizParams(
          quizId: state.quizAttempt!.quizId,
          quizTitle: state.quizAttempt!.quizTitle,
          userId: authState.userId!,
          answers: state.quizAttempt!.selectedAnswers,
          timeTakenSeconds:
              state.quizAttempt!.timeLimitMinutes * 60 -
              state.remainingTimeSeconds,
        ),
      );

      result.fold(
        (failure) {
          // Surface error to user instead of just logging
          state = state.copyWith(
            errorMessage: 'Failed to save submission: ${failure.message}',
            isLoading: false,
          );
        },
        (submission) {
          // Clear any previous errors on success and store the submission
          state = state.copyWith(
            isLoading: false,
            lastSubmission: submission,
          );
        },
      );
    } catch (e) {
      // Surface exception to user
      state = state.copyWith(
        errorMessage: 'Error submitting quiz: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  void resetState() {
    state = const QuizAttemptState();
  }
}

final quizAttemptProvider =
    NotifierProvider<QuizAttemptNotifier, QuizAttemptState>(() {
      return QuizAttemptNotifier();
    });

final currentQuestionProvider = Provider<Question?>((ref) {
  final attemptState = ref.watch(quizAttemptProvider);
  return attemptState.quizAttempt?.currentQuestion;
});

final quizProgressProvider = Provider<double>((ref) {
  final attemptState = ref.watch(quizAttemptProvider);
  return attemptState.quizAttempt?.progressPercentage ?? 0.0;
});

final answeredQuestionsCountProvider = Provider<int>((ref) {
  final attemptState = ref.watch(quizAttemptProvider);
  return attemptState.quizAttempt?.answeredQuestionsCount ?? 0;
});

final quizSubmissionProvider = FutureProvider.family<Submission?, String>((
  ref,
  quizId,
) async {
  final attemptState = ref.watch(quizAttemptProvider);
  final submitQuizUseCase = ref.watch(submitQuizUseCaseProvider);

  if (attemptState.quizAttempt == null ||
      !attemptState.quizAttempt!.isSubmitted) {
    return null;
  }

  // Fix: Use actual authenticated user ID instead of hardcoded string
  final authState = ref.read(authProvider);
  if (authState.userId == null) {
    throw StateError('User not authenticated');
  }

  final result = await submitQuizUseCase.call(
    SubmitQuizParams(
      quizId: attemptState.quizAttempt!.quizId,
      quizTitle: attemptState.quizAttempt!.quizTitle,
      userId: authState.userId!,
      answers: attemptState.quizAttempt!.selectedAnswers,
      timeTakenSeconds:
          attemptState.quizAttempt!.timeLimitMinutes * 60 -
          attemptState.remainingTimeSeconds,
    ),
  );

  return result.fold(
    (failure) => throw Exception(failure.message),
    (submission) => submission,
  );
});

final quizResultProvider = Provider<QuizResult?>((ref) {
  final attemptState = ref.watch(quizAttemptProvider);

  if (attemptState.quizAttempt == null ||
      !attemptState.quizAttempt!.isSubmitted) {
    return null;
  }

  final quizAttempt = attemptState.quizAttempt!;
  final totalQuestions = quizAttempt.questions.length;

  // Use centralized QuizScoringService instead of duplicate logic
  final scoringResult = QuizScoringService.calculateScore(
    questions: quizAttempt.questions,
    userAnswers: quizAttempt.selectedAnswers,
  );
  final score = scoringResult.score;
  final correctAnswers = scoringResult.correctCount;
  final percentage = totalQuestions > 0
      ? (correctAnswers / totalQuestions) * 100
      : 0.0;

  return QuizResult(
    score: score,
    totalQuestions: totalQuestions,
    percentage: percentage,
    correctAnswers: correctAnswers,
    timeTakenSeconds:
        quizAttempt.timeLimitMinutes * 60 - attemptState.remainingTimeSeconds,
    passed: percentage >= 50.0, // Passing threshold can be configurable
  );
});

// Removed: _calculateCorrectAnswers function
// Now using centralized QuizScoringService.calculateScore() instead

class QuizResult {
  final int score;
  final int totalQuestions;
  final double percentage;
  final int correctAnswers;
  final int timeTakenSeconds;
  final bool passed;

  const QuizResult({
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    required this.correctAnswers,
    required this.timeTakenSeconds,
    required this.passed,
  });

  String get grade {
    if (percentage >= 90) return 'A+';
    if (percentage >= 85) return 'A';
    if (percentage >= 80) return 'A-';
    if (percentage >= 75) return 'B+';
    if (percentage >= 70) return 'B';
    if (percentage >= 65) return 'B-';
    if (percentage >= 60) return 'C+';
    if (percentage >= 55) return 'C';
    if (percentage >= 50) return 'C-';
    return 'F';
  }

  String get formattedTime {
    final minutes = timeTakenSeconds ~/ 60;
    final seconds = timeTakenSeconds % 60;
    return '${minutes}m ${seconds}s';
  }
}
