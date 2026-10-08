import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/constants/route_constants.dart';
import '../providers/my_leaderboards_provider.dart';
import '../../domain/entities/quiz.dart';
import '../../domain/entities/quiz_metadata.dart';

class MyLeaderboardsPage extends ConsumerWidget {
  const MyLeaderboardsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibleQuizzesAsync = ref.watch(myLeaderboardsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Leaderboards'), elevation: 0),
      body: accessibleQuizzesAsync.when(
        data: (accessibleQuizzes) {
          if (accessibleQuizzes.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildQuizList(context, accessibleQuizzes);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load quizzes',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.leaderboard_outlined,
              size: 80,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No Leaderboards Available',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'You don\'t have access to any quiz leaderboards yet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push(RouteConstants.quizList),
              icon: const Icon(Icons.quiz_rounded),
              label: const Text('Browse Quizzes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizList(BuildContext context, List<Quiz> quizzes) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: quizzes.length,
      itemBuilder: (context, index) {
        final quiz = quizzes[index];
        return _buildQuizCard(context, quiz);
      },
    );
  }

  Widget _buildQuizCard(BuildContext context, Quiz quiz) {
    final difficultyColor = _getDifficultyColor(quiz.metadata.difficulty);
    final categoryIcon = _getCategoryIcon(quiz.metadata.category);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: InkWell(
        onTap: () {
          context.push(
            '${RouteConstants.leaderboard}?quizId=${quiz.id}&quizTitle=${Uri.encodeComponent(quiz.title)}',
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      categoryIcon,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: difficultyColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                quiz.metadata.difficulty.name.toUpperCase(),
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: difficultyColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.timer_outlined,
                              size: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${quiz.timeLimitMinutes} min',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (quiz.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  quiz.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return AppColors.success;
      case DifficultyLevel.intermediate:
        return AppColors.warning;
      case DifficultyLevel.advanced:
      case DifficultyLevel.expert:
        return AppColors.error;
    }
  }

  IconData _getCategoryIcon(QuizCategory category) {
    switch (category) {
      case QuizCategory.general:
        return Icons.quiz_rounded;
      case QuizCategory.science:
        return Icons.science_rounded;
      case QuizCategory.mathematics:
        return Icons.calculate_rounded;
      case QuizCategory.history:
        return Icons.history_edu_rounded;
      case QuizCategory.geography:
        return Icons.public_rounded;
      case QuizCategory.programming:
        return Icons.computer_rounded;
      case QuizCategory.literature:
        return Icons.menu_book_rounded;
      case QuizCategory.custom:
        return Icons.category_rounded;
    }
  }
}
