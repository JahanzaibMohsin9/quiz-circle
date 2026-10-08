import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/repositories/base_repository.dart';
import '../../../../core/services/cache_service.dart';
import '../../../authentication/domain/entities/user.dart';
import '../../../quiz/domain/entities/quiz.dart';
import '../../../quiz/domain/entities/quiz_permissions.dart';
import '../../../quiz/domain/entities/quiz_metadata.dart';
import '../../../quiz/domain/entities/question.dart';
import '../../domain/entities/admin_user.dart';
import '../../domain/entities/analytics.dart';
import '../../domain/entities/permission_audit.dart';
import '../../domain/entities/recent_activity.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_datasource.dart';
import '../models/analytics_model.dart';
import '../models/recent_activity_model.dart';

class AdminRepositoryImpl extends BaseRepository implements AdminRepository {
  final AdminRemoteDataSource remote;
  final CacheService cache;

  AdminRepositoryImpl({
    required NetworkInfo networkInfo,
    required this.remote,
    required this.cache,
  }) : super(networkInfo);

  @override
  Future<Either<Failure, List<Quiz>>> getQuizzes() {
    return execute(() => remote.getQuizzes());
  }

  @override
  Future<Either<Failure, Quiz>> createQuiz({
    required String title,
    required String description,
    required int timeLimitMinutes,
    required List<Question> questions,
    int questionsPerAttempt = 0,
    bool randomizeQuestions = false,
    QuizPermissions? permissions,
    QuizMetadata? metadata,
  }) {
    return execute(
      () => remote.createQuiz(
        title: title,
        description: description,
        timeLimitMinutes: timeLimitMinutes,
        questions: questions,
        questionsPerAttempt: questionsPerAttempt,
        randomizeQuestions: randomizeQuestions,
        permissions: permissions,
        metadata: metadata,
      ),
    );
  }

  @override
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
  }) {
    return execute(
      () => remote.updateQuiz(
        id: id,
        title: title,
        description: description,
        timeLimitMinutes: timeLimitMinutes,
        questions: questions,
        questionsPerAttempt: questionsPerAttempt,
        randomizeQuestions: randomizeQuestions,
        permissions: permissions,
        metadata: metadata,
      ),
    );
  }

  @override
  Future<Either<Failure, void>> deleteQuiz(String id) {
    return execute(() => remote.deleteQuiz(id));
  }

  @override
  Future<Either<Failure, Quiz>> setQuizActive(String id, bool isActive) {
    return execute(() => remote.setQuizActive(id, isActive));
  }

  @override
  Future<Either<Failure, String>> uploadQuestionImage(
    String questionId,
    String filePath,
  ) {
    return execute(() => remote.uploadQuestionImage(questionId, filePath));
  }

  @override
  Future<Either<Failure, List<Question>>> getQuestions(String quizId) {
    return execute(() => remote.getQuestions(quizId));
  }

  @override
  Future<Either<Failure, List<AdminUser>>> getUsers() {
    return execute(() => remote.getUsers());
  }

  @override
  Future<Either<Failure, AdminUser>> blockUser(String userId, bool block) {
    return execute(() => remote.blockUser(userId, block));
  }

  @override
  Future<Either<Failure, AdminUser>> updateUserAccess(
    String userId,
    UserRole role,
  ) {
    return execute(() => remote.updateUserAccess(userId, role));
  }

  @override
  Future<Either<Failure, AdminUser>> getUserAnalytics(String userId) {
    return execute(() => remote.getUserAnalytics(userId));
  }

  @override
  Future<Either<Failure, QuizPermissions>> getQuizPermissions(String quizId) {
    return execute(() => remote.getQuizPermissions(quizId));
  }

  @override
  Future<Either<Failure, void>> updateQuizPermissions(
    String quizId,
    QuizPermissions permissions,
  ) {
    return execute(() => remote.updateQuizPermissions(quizId, permissions));
  }

  @override
  Future<Either<Failure, void>> logPermissionChange(PermissionAudit audit) {
    return execute(() => remote.logPermissionChange(audit));
  }

  @override
  Future<Either<Failure, QuizAnalytics>> getQuizAnalytics(
    String quizId,
    DateRange? dateRange,
  ) async {
    final cacheKey =
        '${CacheKeys.quizAnalytics(quizId)}_${dateRange?.name ?? 'all'}';

    // Try to get from cache first (offline-first)
    final cachedWithMetadata = await cache.getWithMetadata<QuizAnalyticsModel>(
      key: cacheKey,
      fromJson: QuizAnalyticsModel.fromJson,
    );

    final connected = await networkInfo.isConnected;

    // If offline, return cached data even if expired
    if (!connected) {
      if (cachedWithMetadata != null) {
        return Right(cachedWithMetadata.data.data.toDomain());
      }
      return const Left(NetworkFailure('Offline and no cached data available'));
    }

    // If online, fetch from remote and update cache
    try {
      final result = await remote.getQuizAnalytics(quizId, dateRange);
      await cache.setWithExtendedTTL<QuizAnalyticsModel>(
        key: cacheKey,
        data: QuizAnalyticsModel.fromDomain(result),
        toJson: (m) => m.toJson(),
        ttl: const Duration(hours: 24),
      );
      return Right(result);
    } catch (e) {
      // Fallback to cache on error (even if expired)
      if (cachedWithMetadata != null) {
        return Right(cachedWithMetadata.data.data.toDomain());
      }
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserAnalytics>> getDetailedUserAnalytics(
    String userId,
  ) async {
    final cacheKey = CacheKeys.userAnalytics(userId);

    // Try to get from cache first (offline-first)
    final cachedWithMetadata = await cache.getWithMetadata<UserAnalyticsModel>(
      key: cacheKey,
      fromJson: UserAnalyticsModel.fromJson,
    );

    final connected = await networkInfo.isConnected;

    // If offline, return cached data even if expired
    if (!connected) {
      if (cachedWithMetadata != null) {
        return Right(cachedWithMetadata.data.data.toDomain());
      }
      return const Left(NetworkFailure('Offline and no cached data available'));
    }

    // If online, fetch from remote and update cache
    try {
      final result = await remote.getDetailedUserAnalytics(userId);
      await cache.setWithExtendedTTL<UserAnalyticsModel>(
        key: cacheKey,
        data: UserAnalyticsModel.fromDomain(result),
        toJson: (m) => m.toJson(),
        ttl: const Duration(hours: 24),
      );
      return Right(result);
    } catch (e) {
      // Fallback to cache on error (even if expired)
      if (cachedWithMetadata != null) {
        return Right(cachedWithMetadata.data.data.toDomain());
      }
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SystemAnalytics>> getSystemAnalytics(
    DateRange? dateRange,
  ) async {
    final cacheKey = '${CacheKeys.systemAnalytics}_${dateRange?.name ?? 'all'}';

    // Try to get from cache first (offline-first)
    final cachedWithMetadata = await cache
        .getWithMetadata<SystemAnalyticsModel>(
          key: cacheKey,
          fromJson: SystemAnalyticsModel.fromJson,
        );

    final connected = await networkInfo.isConnected;

    // If offline, return cached data even if expired
    if (!connected) {
      if (cachedWithMetadata != null) {
        return Right(cachedWithMetadata.data.data.toDomain());
      }
      return const Left(NetworkFailure('Offline and no cached data available'));
    }

    // If online, fetch from remote and update cache
    try {
      final result = await remote.getSystemAnalytics(dateRange);
      await cache.setWithExtendedTTL<SystemAnalyticsModel>(
        key: cacheKey,
        data: SystemAnalyticsModel.fromDomain(result),
        toJson: (m) => m.toJson(),
        ttl: const Duration(hours: 24),
      );
      return Right(result);
    } catch (e) {
      // Fallback to cache on error (even if expired)
      if (cachedWithMetadata != null) {
        return Right(cachedWithMetadata.data.data.toDomain());
      }
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UserAnalytics>>> getTopPerformingUsers(
    int limit,
  ) async {
    final cacheKey = 'top_performing_users_$limit';

    // Try to get from cache first (offline-first)
    final cachedWithMetadata = await cache
        .getWithMetadata<Map<String, dynamic>>(
          key: cacheKey,
          fromJson: (json) => json,
        );

    final connected = await networkInfo.isConnected;

    // If offline, return cached data even if expired
    if (!connected) {
      if (cachedWithMetadata != null) {
        final cachedList =
            cachedWithMetadata.data.data['items'] as List<dynamic>;
        final users = cachedList
            .map(
              (e) => UserAnalyticsModel.fromJson(
                e as Map<String, dynamic>,
              ).toDomain(),
            )
            .toList();
        return Right(users);
      }
      return const Left(NetworkFailure('Offline and no cached data available'));
    }

    // If online, fetch from remote and update cache
    try {
      final result = await remote.getTopPerformingUsers(limit);
      final modelList = result
          .map((e) => UserAnalyticsModel.fromDomain(e))
          .toList();
      await cache.setWithExtendedTTL<Map<String, dynamic>>(
        key: cacheKey,
        data: {'items': modelList.map((e) => e.toJson()).toList()},
        toJson: (m) => m,
        ttl: const Duration(hours: 12),
      );
      return Right(result);
    } catch (e) {
      // Fallback to cache on error (even if expired)
      if (cachedWithMetadata != null) {
        final cachedList =
            cachedWithMetadata.data.data['items'] as List<dynamic>;
        final users = cachedList
            .map(
              (e) => UserAnalyticsModel.fromJson(
                e as Map<String, dynamic>,
              ).toDomain(),
            )
            .toList();
        return Right(users);
      }
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<QuizAnalytics>>> getTopPerformingQuizzes(
    int limit,
  ) async {
    final cacheKey = 'top_performing_quizzes_$limit';

    // Try to get from cache first (offline-first)
    final cachedWithMetadata = await cache
        .getWithMetadata<Map<String, dynamic>>(
          key: cacheKey,
          fromJson: (json) => json,
        );

    final connected = await networkInfo.isConnected;

    // If offline, return cached data even if expired
    if (!connected) {
      if (cachedWithMetadata != null) {
        final cachedList =
            cachedWithMetadata.data.data['items'] as List<dynamic>;
        final quizzes = cachedList
            .map(
              (e) => QuizAnalyticsModel.fromJson(
                e as Map<String, dynamic>,
              ).toDomain(),
            )
            .toList();
        return Right(quizzes);
      }
      return const Left(NetworkFailure('Offline and no cached data available'));
    }

    // If online, fetch from remote and update cache
    try {
      final result = await remote.getTopPerformingQuizzes(limit);
      final modelList = result
          .map((e) => QuizAnalyticsModel.fromDomain(e))
          .toList();
      await cache.setWithExtendedTTL<Map<String, dynamic>>(
        key: cacheKey,
        data: {'items': modelList.map((e) => e.toJson()).toList()},
        toJson: (m) => m,
        ttl: const Duration(hours: 12),
      );
      return Right(result);
    } catch (e) {
      // Fallback to cache on error (even if expired)
      if (cachedWithMetadata != null) {
        final cachedList =
            cachedWithMetadata.data.data['items'] as List<dynamic>;
        final quizzes = cachedList
            .map(
              (e) => QuizAnalyticsModel.fromJson(
                e as Map<String, dynamic>,
              ).toDomain(),
            )
            .toList();
        return Right(quizzes);
      }
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RecentActivity>>> getRecentActivity(
    int limit,
  ) async {
    final cacheKey = '${CacheKeys.recentActivity}_$limit';

    // Try to get from cache first (offline-first)
    final cachedWithMetadata = await cache
        .getWithMetadata<Map<String, dynamic>>(
          key: cacheKey,
          fromJson: (json) => json,
        );

    final connected = await networkInfo.isConnected;

    // If offline, return cached data even if expired
    if (!connected) {
      if (cachedWithMetadata != null) {
        final cachedList =
            cachedWithMetadata.data.data['items'] as List<dynamic>;
        final activities = cachedList
            .map((e) => RecentActivityModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return Right(activities);
      }
      return const Left(NetworkFailure('Offline and no cached data available'));
    }

    // If online, fetch from remote and update cache
    try {
      final result = await remote.getRecentActivity(limit);
      final modelList = result
          .map((e) => RecentActivityModel.fromDomain(e))
          .toList();
      await cache.setWithExtendedTTL<Map<String, dynamic>>(
        key: cacheKey,
        data: {'items': modelList.map((e) => e.toJson()).toList()},
        toJson: (m) => m,
        ttl: const Duration(hours: 6),
      );
      return Right(result);
    } catch (e) {
      // Fallback to cache on error (even if expired)
      if (cachedWithMetadata != null) {
        final cachedList =
            cachedWithMetadata.data.data['items'] as List<dynamic>;
        final activities = cachedList
            .map((e) => RecentActivityModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return Right(activities);
      }
      return Left(UnknownFailure(e.toString()));
    }
  }
}
