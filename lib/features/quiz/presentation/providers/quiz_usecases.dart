import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_quizzes.dart';
import '../../domain/usecases/get_quiz_by_id.dart';
import '../../domain/usecases/get_quiz_questions.dart';
import '../../domain/usecases/submit_quiz.dart';
import '../../domain/usecases/get_submissions.dart';
import '../../domain/usecases/get_leaderboard.dart';
import '../../domain/usecases/get_global_leaderboard.dart';
import '../../domain/usecases/start_quiz_attempt.dart';
import '../../domain/usecases/get_questions_by_ids.dart';
import '../../domain/usecases/get_submission_by_id.dart';
import 'quiz_repository_provider.dart';

final getQuizzesUseCaseProvider = Provider<GetQuizzes>((ref) {
  final repo = ref.watch(quizRepositoryProvider);
  return GetQuizzes(repo);
});

final getQuizByIdUseCaseProvider = Provider<GetQuizById>((ref) {
  final repo = ref.watch(quizRepositoryProvider);
  return GetQuizById(repo);
});

final getQuizQuestionsUseCaseProvider = Provider<GetQuizQuestions>((ref) {
  final repo = ref.watch(quizRepositoryProvider);
  return GetQuizQuestions(repo);
});

final submitQuizUseCaseProvider = Provider<SubmitQuiz>((ref) {
  final repo = ref.watch(quizRepositoryProvider);
  return SubmitQuiz(repo);
});

final getSubmissionsUseCaseProvider = Provider<GetSubmissions>((ref) {
  final repo = ref.watch(quizRepositoryProvider);
  return GetSubmissions(repo);
});

final getLeaderboardUseCaseProvider = Provider<GetLeaderboard>((ref) {
  final repo = ref.watch(quizRepositoryProvider);
  return GetLeaderboard(repo);
});

final getGlobalLeaderboardUseCaseProvider = Provider<GetGlobalLeaderboard>((
  ref,
) {
  final repo = ref.watch(quizRepositoryProvider);
  return GetGlobalLeaderboard(repo);
});

final startQuizAttemptUseCaseProvider = Provider<StartQuizAttempt>((ref) {
  final repo = ref.watch(quizRepositoryProvider);
  return StartQuizAttempt(repo);
});

final getQuestionsByIdsUseCaseProvider = Provider<GetQuestionsByIds>((ref) {
  final repo = ref.watch(quizRepositoryProvider);
  return GetQuestionsByIds(repo);
});

final getSubmissionByIdUseCaseProvider = Provider<GetSubmissionById>((ref) {
  final repo = ref.watch(quizRepositoryProvider);
  return GetSubmissionById(repo);
});

final noParamsProvider = Provider<NoParams>((ref) => const NoParams());
