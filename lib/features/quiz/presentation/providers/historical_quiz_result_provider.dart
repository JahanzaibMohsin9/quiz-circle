import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/get_submission_by_id.dart';
import '../../domain/usecases/get_questions_by_ids.dart';
import '../providers/quiz_usecases.dart';
import '../providers/quiz_attempt_provider.dart';
import '../../../../core/services/quiz_scoring_service.dart';

/// Provider family to get historical quiz results from a submission
/// Used when viewing past quiz results from quiz history
final historicalQuizResultProvider =
    FutureProvider.family<QuizResult, HistoricalResultParams>((
      ref,
      params,
    ) async {
      final getSubmissionUseCase = ref.read(getSubmissionByIdUseCaseProvider);
      final getQuestionsUseCase = ref.read(getQuestionsByIdsUseCaseProvider);

      // 1. Fetch the submission
      final submissionResult = await getSubmissionUseCase.call(
        GetSubmissionByIdParams(
          submissionId: params.submissionId,
          quizId: params.quizId,
        ),
      );

      return await submissionResult.fold(
        (failure) =>
            throw Exception('Failed to load submission: ${failure.message}'),
        (submission) async {
          // 2. Fetch questions used in this submission
          final questionIds = submission.answers.keys.toList();
          final questionsResult = await getQuestionsUseCase.call(
            GetQuestionsByIdsParams(
              quizId: params.quizId,
              questionIds: questionIds,
            ),
          );

          return questionsResult.fold(
            (failure) =>
                throw Exception('Failed to load questions: ${failure.message}'),
            (questions) {
              // 3. Calculate score using the scoring service
              final scoringResult = QuizScoringService.calculateScore(
                questions: questions,
                userAnswers: submission.answers,
              );

              // 4. Return QuizResult
              return QuizResult(
                score: scoringResult.score,
                totalQuestions: submission.totalQuestions,
                percentage: submission.percentage,
                correctAnswers: scoringResult.correctCount,
                timeTakenSeconds: submission.timeTakenSeconds,
                passed: submission.percentage >= 50.0,
              );
            },
          );
        },
      );
    });

/// Parameters for fetching historical quiz results
class HistoricalResultParams {
  final String submissionId;
  final String quizId;

  const HistoricalResultParams({
    required this.submissionId,
    required this.quizId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoricalResultParams &&
          submissionId == other.submissionId &&
          quizId == other.quizId;

  @override
  int get hashCode => submissionId.hashCode ^ quizId.hashCode;
}
