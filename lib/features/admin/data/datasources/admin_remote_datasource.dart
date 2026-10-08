import '../../../authentication/domain/entities/user.dart';
import '../../../quiz/domain/entities/quiz.dart';
import '../../../quiz/domain/entities/quiz_permissions.dart';
import '../../../quiz/domain/entities/quiz_metadata.dart';
import '../../../quiz/domain/entities/question.dart';
import '../../domain/entities/admin_user.dart';
import '../../domain/entities/analytics.dart';
import '../../domain/entities/permission_audit.dart';
import '../../domain/entities/recent_activity.dart';

abstract class AdminRemoteDataSource {
  Future<List<Quiz>> getQuizzes();
  Future<Quiz> createQuiz({
    required String title,
    required String description,
    required int timeLimitMinutes,
    required List<Question> questions,
    int questionsPerAttempt = 0,
    bool randomizeQuestions = false,
    QuizPermissions? permissions,
    QuizMetadata? metadata,
  });
  Future<Quiz> updateQuiz({
    required String id,
    required String title,
    required String description,
    required int timeLimitMinutes,
    required List<Question> questions,
    int questionsPerAttempt = 0,
    bool randomizeQuestions = false,
    QuizPermissions? permissions,
    QuizMetadata? metadata,
  });
  Future<void> deleteQuiz(String id);
  Future<Quiz> setQuizActive(String id, bool isActive);
  Future<String> uploadQuestionImage(String questionId, String filePath);
  Future<List<Question>> getQuestions(String quizId);

  Future<List<AdminUser>> getUsers();
  Future<AdminUser> blockUser(String userId, bool block);
  Future<AdminUser> updateUserAccess(String userId, UserRole role);
  Future<AdminUser> getUserAnalytics(String userId);

  // Permission methods
  Future<QuizPermissions> getQuizPermissions(String quizId);
  Future<void> updateQuizPermissions(
    String quizId,
    QuizPermissions permissions,
  );
  Future<void> logPermissionChange(PermissionAudit audit);

  // Analytics methods
  Future<QuizAnalytics> getQuizAnalytics(String quizId, DateRange? dateRange);
  Future<UserAnalytics> getDetailedUserAnalytics(String userId);
  Future<SystemAnalytics> getSystemAnalytics(DateRange? dateRange);
  Future<List<UserAnalytics>> getTopPerformingUsers(int limit);
  Future<List<QuizAnalytics>> getTopPerformingQuizzes(int limit);

  // Recent Activity
  Future<List<RecentActivity>> getRecentActivity(int limit);
}
