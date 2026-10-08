import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../app/theme/colors.dart';
import '../../../../shared/widgets/common/shimmer_loading.dart';
import '../../../../shared/widgets/common/error_state_widget.dart';
import '../../../../shared/widgets/common/custom_button.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../providers/quiz_attempt_provider.dart';
import '../providers/quiz_usecases.dart';
import '../../domain/usecases/get_quiz_by_id.dart';
import '../../../../shared/widgets/quiz/question_card.dart';
import '../../../../shared/widgets/quiz/quiz_progress_indicator.dart';
import '../../../../core/utils/quiz_timer.dart';

class QuizAttemptPage extends ConsumerStatefulWidget {
  final String quizId;
  const QuizAttemptPage({super.key, required this.quizId});

  @override
  ConsumerState<QuizAttemptPage> createState() => _QuizAttemptPageState();
}

class _QuizAttemptPageState extends ConsumerState<QuizAttemptPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeQuiz();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // When app resumes from background, recalculate time from server timestamp
    if (state == AppLifecycleState.resumed) {
      _handleAppResume();
    } else if (state == AppLifecycleState.paused) {
      // Optionally save progress when app goes to background
      _handleAppPause();
    }
  }

  void _handleAppResume() {
    // Recalculate remaining time from server-side start timestamp
    ref.read(quizAttemptProvider.notifier).recalculateRemainingTime();

    // Update timer with recalculated time
    final attemptState = ref.read(quizAttemptProvider);
    if (attemptState.quizAttempt != null &&
        attemptState.remainingTimeSeconds > 0) {
      // Reinitialize timer with accurate remaining time
      final quizUseCase = ref.read(getQuizByIdUseCaseProvider);
      quizUseCase.call(GetQuizByIdParams(quizId: widget.quizId)).then((
        quizResult,
      ) {
        quizResult.fold(
          (failure) {
            // Handle error silently or show snackbar
          },
          (quiz) {
            ref
                .read(quizTimerProvider.notifier)
                .initializeTimer(
                  totalSeconds: quiz.timeLimitMinutes * 60,
                  initialRemaining: attemptState.remainingTimeSeconds,
                  onTick: (seconds) {
                    ref
                        .read(quizAttemptProvider.notifier)
                        .updateRemainingTime(seconds);
                  },
                  onTimeUp: () {
                    _submitQuiz();
                  },
                );
            ref.read(quizTimerProvider.notifier).startTimer();
          },
        );
      });
    } else if (attemptState.quizAttempt != null &&
        attemptState.remainingTimeSeconds <= 0) {
      // Time expired while app was in background
      _submitQuiz();
    }
  }

  void _handleAppPause() {
    // Timer automatically pauses in background, no action needed
    // Progress is already being synced on every answer selection
  }

  Future<void> _initializeQuiz() async {
    final quizUseCase = ref.read(getQuizByIdUseCaseProvider);

    final quizResult = await quizUseCase.call(
      GetQuizByIdParams(quizId: widget.quizId),
    );

    if (!mounted) return;

    quizResult.fold(
      (failure) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading quiz: ${failure.message}')),
        );
      },
      (quiz) async {
        if (!mounted) return;
        final authState = ref.read(authProvider);
        if (authState.userId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: User not logged in')),
          );
          return;
        }

        // Initialize attempt (fetches questions based on persistent attempt)
        await ref
            .read(quizAttemptProvider.notifier)
            .initializeQuizAttempt(
              quizId: widget.quizId,
              quizTitle: quiz.title,
              timeLimitMinutes: quiz.timeLimitMinutes,
              questionsPerAttempt: quiz.questionsPerAttempt,
              randomizeQuestions: quiz.randomizeQuestions,
              userId: authState.userId!,
            );

        if (!mounted) return;

        // Check for error in state
        final state = ref.read(quizAttemptProvider);
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          return;
        }

        // Start timer
        ref
            .read(quizTimerProvider.notifier)
            .initializeTimer(
              totalSeconds: quiz.timeLimitMinutes * 60,
              initialRemaining: ref
                  .read(quizAttemptProvider)
                  .remainingTimeSeconds,
              onTick: (seconds) {
                ref
                    .read(quizAttemptProvider.notifier)
                    .updateRemainingTime(seconds);
              },
              onTimeUp: () {
                _submitQuiz();
              },
            );

        ref.read(quizTimerProvider.notifier).startTimer();
        ref.read(quizAttemptProvider.notifier).startTimer();
      },
    );
  }

  void _selectAnswer(String questionId, String answer) {
    ref.read(quizAttemptProvider.notifier).selectAnswer(questionId, answer);
  }

  void _goToNextQuestion() {
    ref.read(quizAttemptProvider.notifier).goToNextQuestion();
  }

  void _goToPreviousQuestion() {
    ref.read(quizAttemptProvider.notifier).goToPreviousQuestion();
  }

  Future<void> _submitQuiz() async {
    ref.read(quizTimerProvider.notifier).stopTimer();

    // Await quiz submission before navigating
    await ref.read(quizAttemptProvider.notifier).submitQuiz();

    if (!mounted) return;

    // Check for errors before navigating
    final state = ref.read(quizAttemptProvider);
    if (state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit quiz: ${state.errorMessage}'),
          backgroundColor: Theme.of(context).colorScheme.error,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _submitQuiz,
            textColor: Colors.white,
          ),
        ),
      );
      return; // Don't navigate if submission failed
    }

    // Only navigate if submission succeeded - use actual submission ID
    final submissionId = state.lastSubmission?.id ?? '';
    context.go(
      Uri(
        path: RouteConstants.quizResult,
        queryParameters: {
          'quizId': widget.quizId,
          'submissionId': submissionId,
        },
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attemptState = ref.watch(quizAttemptProvider);
    final currentQuestion = ref.watch(currentQuestionProvider);
    final progress = ref.watch(quizProgressProvider);
    final timerState = ref.watch(quizTimerProvider);

    if (attemptState.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Quiz: ${widget.quizId}'),
          elevation: 0,
        ),
        body: Column(
          children: [
            // Shimmer progress indicator
            Container(
              margin: const EdgeInsets.all(8),
              child: const ShimmerLoading(
                width: double.infinity,
                height: 120,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const ShimmerLoading(
                      width: double.infinity,
                      height: 80,
                      margin: EdgeInsets.only(bottom: 16),
                    ),
                    ...List.generate(4, (index) => const ShimmerListTile()),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (attemptState.errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Quiz: ${widget.quizId}'),
          elevation: 0,
        ),
        body: ErrorStateWidget(
          message: attemptState.errorMessage!,
          onRetry: () => _initializeQuiz(),
        ),
      );
    }

    if (attemptState.quizAttempt == null || currentQuestion == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Quiz: ${widget.quizId}'),
          elevation: 0,
        ),
        body: const Center(child: Text('No quiz data available')),
      );
    }

    final quizAttempt = attemptState.quizAttempt!;
    final selectedAnswer = quizAttempt.selectedAnswers[currentQuestion.id];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          // Intercept back navigation and show exit dialog
          _showExitDialog(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(quizAttempt.quizTitle),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => _showExitDialog(context),
            tooltip: 'Exit Quiz',
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
              minHeight: 4,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app_rounded),
              onPressed: () => _showExitDialog(context),
              tooltip: 'Exit Quiz',
            ),
          ],
        ),
        body: Column(
          children: [
            QuizProgressIndicator(
              progress: progress,
              currentQuestion: quizAttempt.currentQuestionIndex + 1,
              totalQuestions: quizAttempt.questions.length,
              remainingTimeSeconds: timerState.remainingSeconds,
              isTimerRunning: timerState.isRunning,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.05, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: SingleChildScrollView(
                  key: ValueKey<String>(currentQuestion.id),
                  child: QuestionCard(
                    question: currentQuestion,
                    questionNumber: quizAttempt.currentQuestionIndex + 1,
                    selectedAnswer: selectedAnswer,
                    onAnswerSelected: (answer) =>
                        _selectAnswer(currentQuestion.id, answer),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Previous button
                    SizedBox(
                      width: 120,
                      child: CustomButton(
                        text: 'Previous',
                        icon: Icons.arrow_back_rounded,
                        outlined: true,
                        onPressed: quizAttempt.isFirstQuestion
                            ? null
                            : _goToPreviousQuestion,
                      ),
                    ),
                    // Next or Submit button
                    SizedBox(
                      width: 120,
                      child: !quizAttempt.isLastQuestion
                          ? CustomButton(
                              text: 'Next',
                              icon: Icons.arrow_forward_rounded,
                              iconRight: true,
                              onPressed: selectedAnswer != null
                                  ? _goToNextQuestion
                                  : null,
                            )
                          : CustomButton.gradient(
                              text: 'Submit',
                              icon: Icons.check_rounded,
                              onPressed: selectedAnswer != null
                                  ? _submitQuiz
                                  : null,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
              size: 28,
            ),
            SizedBox(width: 12),
            Text('Exit Quiz?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to exit this quiz? Your progress will be saved and you can continue later from where you left off.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(quizTimerProvider.notifier).stopTimer();
              ref.read(quizAttemptProvider.notifier).resetState();
              Navigator.of(dialogContext).pop();
              if (context.mounted) {
                context.pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Exit Quiz'),
          ),
        ],
      ),
    );
  }
}
