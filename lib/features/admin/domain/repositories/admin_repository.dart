import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../authentication/domain/entities/user.dart';
import '../../../quiz/domain/entities/quiz.dart';
import '../../../quiz/domain/entities/quiz_permissions.dart';
import '../../../quiz/domain/entities/quiz_metadata.dart';
import '../../../quiz/domain/entities/question.dart';
import '../entities/admin_user.dart';
import '../entities/analytics.dart';
import '../entities/permission_audit.dart';
import '../entities/recent_activity.dart';

abstract class AdminRepository {
  Future<Either<Failure, List<Quiz>>> getQuizzes();
  Future<Either<Failure, Quiz>> createQuiz({
    required String title,
    required String description,
    required int timeLimitMinutes,
    required List<Question> questions,
    int questionsPerAttempt = 0,
    bool randomizeQuestions = false,
    QuizPermissions? permissions,
    QuizMetadata? metadata,
  });
  Future<Either<Failure, Quiz>> updateQuiz({
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
  Future<Either<Failure, void>> deleteQuiz(String id);
  Future<Either<Failure, Quiz>> setQuizActive(String id, bool isActive);
  Future<Either<Failure, String>> uploadQuestionImage(
    String questionId,
    String filePath,
  );
  Future<Either<Failure, List<Question>>> getQuestions(String quizId);

  Future<Either<Failure, List<AdminUser>>> getUsers();
  Future<Either<Failure, AdminUser>> blockUser(String userId, bool block);
  Future<Either<Failure, AdminUser>> updateUserAccess(
    String userId,
    UserRole role,
  );
  Future<Either<Failure, AdminUser>> getUserAnalytics(String userId);

  // Permission methods
  Future<Either<Failure, QuizPermissions>> getQuizPermissions(String quizId);
  Future<Either<Failure, void>> updateQuizPermissions(
    String quizId,
    QuizPermissions permissions,
  );
  Future<Either<Failure, void>> logPermissionChange(PermissionAudit audit);

  // Analytics methods
  Future<Either<Failure, QuizAnalytics>> getQuizAnalytics(
    String quizId,
    DateRange? dateRange,
  );
  Future<Either<Failure, UserAnalytics>> getDetailedUserAnalytics(
    String userId,
  );
  Future<Either<Failure, SystemAnalytics>> getSystemAnalytics(
    DateRange? dateRange,
  );
  Future<Either<Failure, List<UserAnalytics>>> getTopPerformingUsers(int limit);
  Future<Either<Failure, List<QuizAnalytics>>> getTopPerformingQuizzes(
    int limit,
  );

  // Recent Activity
  Future<Either<Failure, List<RecentActivity>>> getRecentActivity(int limit);
}
