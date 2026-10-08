import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../app/theme/colors.dart';
import '../../../../shared/widgets/common/shimmer_loading.dart';
import '../../../../shared/widgets/common/error_state_widget.dart';
import '../../../../shared/widgets/common/empty_state_widget.dart';
import '../providers/quiz_history_provider.dart';
import '../../../../features/authentication/presentation/providers/auth_provider.dart';
import '../../domain/entities/submission.dart';

class QuizHistoryPage extends ConsumerWidget {
  const QuizHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authProvider);
    final historyState = ref.watch(quizHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(quizHistoryProvider.notifier).refreshHistory(),
          ),
        ],
      ),
      body: _buildBody(context, ref, historyState),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    QuizHistoryState state,
  ) {
    if (state.isLoading) {
      return Column(
        children: [for (int i = 0; i < 3; i++) const ShimmerQuizCard()],
      );
    }

    if (state.error != null) {
      return ErrorStateWidget(
        message: state.error!,
        errorType: ErrorType.network,
        onRetry: () => ref.read(quizHistoryProvider.notifier).refreshHistory(),
      );
    }

    final submissions = state.submissions;
    if (submissions.isEmpty) {
      return EmptyStateWidget.history(
        onAction: () => context.push(RouteConstants.quizList),
      );
    }

    return SafeArea(
      bottom: true,
      child: ListView.builder(
        padding: const EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: 24.0, // Extra padding for system navigation
        ),
        itemCount: submissions.length,
        itemBuilder: (context, index) {
          final submission = submissions[index];
          return AnimatedQuizHistoryCard(
            submission: submission,
            onTap: () => _viewQuizResults(context, submission),
            index: index,
          );
        },
      ),
    );
  }

  void _viewQuizResults(BuildContext context, Submission submission) {
    context.push(
      Uri(
        path: RouteConstants.quizResult,
        queryParameters: {
          'quizId': submission.quizId,
          'submissionId': submission.id,
        },
      ).toString(),
    );
  }
}

class AnimatedQuizHistoryCard extends StatefulWidget {
  final Submission submission;
  final VoidCallback onTap;
  final int index;

  const AnimatedQuizHistoryCard({
    super.key,
    required this.submission,
    required this.onTap,
    required this.index,
  });

  @override
  State<AnimatedQuizHistoryCard> createState() =>
      _AnimatedQuizHistoryCardState();
}

class _AnimatedQuizHistoryCardState extends State<AnimatedQuizHistoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Start animation with staggered delay
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: QuizHistoryCard(
          submission: widget.submission,
          onTap: widget.onTap,
        ),
      ),
    );
  }
}

class QuizHistoryCard extends StatelessWidget {
  final Submission submission;
  final VoidCallback onTap;

  const QuizHistoryCard({
    super.key,
    required this.submission,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scorePercentage = submission.percentage.round();
    final scoreColor = scorePercentage >= 80
        ? AppColors.success
        : scorePercentage >= 60
        ? AppColors.warning
        : AppColors.error;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.surface,
                scoreColor.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            submission.quizTitle,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Submitted on ${_formatDate(submission.submittedAt)}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: scoreColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '$scorePercentage%',
                        style: TextStyle(
                          color: scoreColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.quiz_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${submission.correctAnswersCount}/${submission.totalQuestions} questions correct',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.access_time_rounded,
                        size: 18,
                        color: AppColors.info,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDuration(submission.timeTakenSeconds),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${submission.percentage.toStringAsFixed(1)}% Score',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
