import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/create_quiz.dart';
import '../../domain/usecases/update_quiz.dart';
import '../../domain/usecases/delete_quiz.dart';
import '../../domain/usecases/set_quiz_active.dart';
import '../../domain/usecases/get_admin_quizzes.dart';
import '../../domain/usecases/get_admin_users.dart';
import '../../domain/usecases/get_quiz_questions.dart';
import '../../domain/usecases/block_user.dart';
import '../../domain/usecases/update_user_access.dart';
import '../../domain/usecases/get_user_analytics.dart';
import '../../domain/usecases/upload_question_image.dart';
import '../../domain/usecases/get_quiz_analytics.dart';
import '../../domain/usecases/get_system_analytics.dart';
import '../../domain/usecases/get_detailed_user_analytics.dart';
import '../../domain/usecases/get_recent_activity.dart';
import '../../domain/usecases/get_top_performing_users.dart';
import '../../domain/usecases/get_top_performing_quizzes.dart';
import 'admin_repository_provider.dart';

final noParamsProvider = Provider<NoParams>((ref) => const NoParams());

final getAdminQuizzesUseCaseProvider = Provider<GetAdminQuizzes>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return GetAdminQuizzes(repo);
});

final createQuizUseCaseProvider = Provider<CreateQuiz>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return CreateQuiz(repo);
});

final updateQuizUseCaseProvider = Provider<UpdateQuiz>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return UpdateQuiz(repo);
});

final deleteQuizUseCaseProvider = Provider<DeleteQuiz>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return DeleteQuiz(repo);
});

final setQuizActiveUseCaseProvider = Provider<SetQuizActive>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return SetQuizActive(repo);
});

final uploadQuestionImageUseCaseProvider = Provider<UploadQuestionImage>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return UploadQuestionImage(repo);
});

final getAdminUsersUseCaseProvider = Provider<GetAdminUsers>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return GetAdminUsers(repo);
});

final getQuizQuestionsUseCaseProvider = Provider<GetQuizQuestions>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return GetQuizQuestions(repo);
});

final blockUserUseCaseProvider = Provider<BlockUser>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return BlockUser(repo);
});

final updateUserAccessUseCaseProvider = Provider<UpdateUserAccess>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return UpdateUserAccess(repo);
});

final getUserAnalyticsUseCaseProvider = Provider<GetUserAnalytics>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return GetUserAnalytics(repo);
});

// Analytics use case providers
final getQuizAnalyticsProvider = Provider<GetQuizAnalytics>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return GetQuizAnalytics(repo);
});

final getSystemAnalyticsProvider = Provider<GetSystemAnalytics>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return GetSystemAnalytics(repo);
});

final getDetailedUserAnalyticsProvider = Provider<GetDetailedUserAnalytics>((
  ref,
) {
  final repo = ref.watch(adminRepositoryProvider);
  return GetDetailedUserAnalytics(repo);
});

final getTopPerformingUsersProvider = Provider<GetTopPerformingUsers>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return GetTopPerformingUsers(repo);
});

final getTopPerformingQuizzesProvider = Provider<GetTopPerformingQuizzes>((
  ref,
) {
  final repo = ref.watch(adminRepositoryProvider);
  return GetTopPerformingQuizzes(repo);
});

final getRecentActivityUseCaseProvider = Provider<GetRecentActivity>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return GetRecentActivity(repo);
});
