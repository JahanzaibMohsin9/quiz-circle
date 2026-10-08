import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../domain/entities/quiz.dart';
import '../providers/quiz_provider.dart';
import '../../../../shared/widgets/quiz/quiz_card.dart';
import '../../../../shared/widgets/common/shimmer_loading.dart';
import '../../../../shared/widgets/common/error_state_widget.dart';
import '../../../../shared/widgets/common/empty_state_widget.dart';

class QuizListPage extends ConsumerWidget {
  const QuizListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizzes = ref.watch(quizListProvider);

    return PopScope(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quizzes'),
          elevation: 0,
        ),

        body: quizzes.when(
          data: (list) {
            if (list.isEmpty) {
              return const EmptyStateWidget.quizzes(
                message:
                    'No quizzes are available at the moment. Check back later!',
              );
            }

            return SafeArea(
              bottom: true,
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  top: 8,
                  bottom: 24, // Extra padding for system navigation
                ),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final Quiz q = list[index];
                  return QuizCard(
                    quiz: q,
                    index: index,
                    onTap: () {
                      final url = Uri(
                        path: RouteConstants.quizAttempt,
                        queryParameters: {'quizId': q.id},
                      ).toString();
                      context.push(url);
                    },
                  );
                },
              ),
            );
          },
          loading: () => ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: 5,
            itemBuilder: (context, index) => const ShimmerQuizCard(),
          ),
          error: (error, stackTrace) => ErrorStateWidget(
            message: 'Unable to load quizzes. Please try again.',
            onRetry: () {
              ref.invalidate(quizListProvider);
            },
          ),
        ),
      ),
    );
  }
}
