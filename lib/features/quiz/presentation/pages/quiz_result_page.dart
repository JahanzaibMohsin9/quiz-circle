import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/constants/animation_constants.dart';
import '../../../../shared/widgets/common/animated_counter.dart';
import '../../../../shared/widgets/common/celebration_widgets.dart';
import '../../../../shared/widgets/common/custom_button.dart';
import '../providers/quiz_attempt_provider.dart';
import '../providers/historical_quiz_result_provider.dart';

class QuizResultPage extends ConsumerStatefulWidget {
  final String quizId;
  final String submissionId;
  const QuizResultPage({
    super.key,
    required this.quizId,
    required this.submissionId,
  });

  @override
  ConsumerState<QuizResultPage> createState() => _QuizResultPageState();
}

class _QuizResultPageState extends ConsumerState<QuizResultPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: AnimationConstants.durationSlow,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();

    // Trigger confetti after animation
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        final result = ref.read(quizResultProvider);
        if (result != null && result.percentage >= 80) {
          setState(() {
            _showConfetti = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if we just submitted this quiz (result is in memory)
    final attemptState = ref.watch(quizAttemptProvider);
    final justSubmitted = attemptState.lastSubmission?.id == widget.submissionId;

    if (justSubmitted && widget.submissionId.isNotEmpty) {
      // Use current quiz attempt provider for just-submitted results (immediate view)
      final quizResult = ref.watch(quizResultProvider);

      if (quizResult == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      return _buildResultScaffold(context, quizResult);
    } else if (widget.submissionId.isNotEmpty) {
      // Use historical quiz result provider for quiz history views
      final historicalResultAsync = ref.watch(
        historicalQuizResultProvider(
          HistoricalResultParams(
            submissionId: widget.submissionId,
            quizId: widget.quizId,
          ),
        ),
      );

      return historicalResultAsync.when(
        data: (quizResult) => _buildResultScaffold(context, quizResult),
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (error, stack) => Scaffold(
          appBar: AppBar(title: const Text('Quiz Result')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Failed to load quiz result',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Fallback: Use current quiz attempt provider
      final quizResult = ref.watch(quizResultProvider);

      if (quizResult == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      return _buildResultScaffold(context, quizResult);
    }
  }

  Widget _buildResultScaffold(BuildContext context, QuizResult quizResult) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Result'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => context.push(RouteConstants.quizList),
            icon: const Icon(Icons.list),
            tooltip: 'All Quizzes',
          ),
        ],
      ),
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: SafeArea(
              bottom: true,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildResultCard(context, quizResult),
                    const SizedBox(height: 24),
                    _buildPerformanceMetrics(context, quizResult),
                    const SizedBox(height: 24),
                    _buildActionButtons(context),
                    // Extra padding for system navigation
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          // Confetti overlay
          if (_showConfetti)
            ConfettiWidget(
              isActive: _showConfetti,
            ),
        ],
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, QuizResult result) {
    final theme = Theme.of(context);
    final isPassing = result.passed;
    final isExcellent = result.percentage >= 80;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isPassing
                  ? [
                      AppColors.success.withValues(alpha: 0.05),
                      Colors.transparent,
                    ]
                  : [
                      AppColors.error.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Icon or checkmark animation
                if (isExcellent)
                  const AnimatedCheckmark()
                else
                  Icon(
                    isPassing ? Icons.check_circle : Icons.cancel,
                    size: 80,
                    color: isPassing ? AppColors.success : AppColors.error,
                  ),
                const SizedBox(height: 16),
                Text(
                  isExcellent
                      ? 'Excellent!'
                      : isPassing
                      ? 'Congratulations!'
                      : 'Keep Trying!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: isPassing ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isExcellent
                      ? 'Outstanding performance! 🎉'
                      : isPassing
                      ? 'You have passed the quiz'
                      : 'Don\'t give up, try again!',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Score display with animated counters
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isPassing
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isPassing
                          ? AppColors.success.withValues(alpha: 0.3)
                          : AppColors.error.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildAnimatedScoreItem(
                        context,
                        'Score',
                        result.score,
                        suffix: '/${result.totalQuestions}',
                      ),
                      Container(width: 1, height: 50, color: AppColors.border),
                      _buildAnimatedScoreItem(
                        context,
                        'Percentage',
                        result.percentage.toInt(),
                        suffix: '%',
                      ),
                      Container(width: 1, height: 50, color: AppColors.border),
                      _buildScoreItem(
                        context,
                        'Grade',
                        result.grade,
                        isPassing,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedScoreItem(
    BuildContext context,
    String label,
    int value, {
    String? suffix,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedCounter(
          value: value,
          suffix: suffix,
          duration: const Duration(milliseconds: 1200),
          textStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreItem(
    BuildContext context,
    String label,
    String value,
    bool isPassing,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isPassing
                ? AppColors.success.withValues(alpha: 0.2)
                : AppColors.error.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isPassing ? AppColors.success : AppColors.error,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceMetrics(BuildContext context, QuizResult result) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              'Correct Answers',
              '${result.correctAnswers} out of ${result.totalQuestions}',
              Icons.check_circle_rounded,
              AppColors.success,
            ),
            const SizedBox(height: 12),
            _buildMetricRow(
              'Time Taken',
              result.formattedTime,
              Icons.timer_outlined,
              AppColors.info,
            ),
            const SizedBox(height: 12),
            _buildMetricRow(
              'Accuracy',
              '${(result.correctAnswers / result.totalQuestions * 100).toStringAsFixed(1)}%',
              Icons.gps_fixed_rounded,
              AppColors.secondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        CustomButton(
          text: 'Back to Dashboard',
          icon: Icons.dashboard_rounded,
          onPressed: () => context.go(RouteConstants.studentDashboard),
          width: double.infinity,
        ),
        const SizedBox(height: 12),
        CustomButton(
          text: 'View Leaderboard',
          icon: Icons.leaderboard_rounded,
          outlined: true,
          onPressed: () => context.push(
            '${RouteConstants.leaderboard}?quizId=${widget.quizId}&quizTitle=${Uri.encodeComponent('Quiz')}',
          ),
          width: double.infinity,
        ),
        const SizedBox(height: 12),
        CustomButton(
          text: 'Back to Quiz List',
          icon: Icons.list_rounded,
          outlined: true,
          onPressed: () => context.push(RouteConstants.quizList),
          width: double.infinity,
        ),
        const SizedBox(height: 12),
        CustomButton(
          text: 'View Quiz History',
          icon: Icons.history_rounded,
          outlined: true,
          onPressed: () => context.push(RouteConstants.quizHistory),
          width: double.infinity,
        ),
      ],
    );
  }
}
