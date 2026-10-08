import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/timestamp_parser.dart';
import '../../../../core/services/quiz_scoring_service.dart';
import '../../../authentication/domain/entities/user.dart';
import '../../../quiz/domain/entities/quiz.dart';
import '../../../quiz/domain/entities/quiz_permissions.dart';
import '../../../quiz/domain/entities/quiz_metadata.dart';
import '../../../quiz/domain/entities/question.dart';
import '../../../quiz/data/models/question_model.dart';
import '../../domain/entities/admin_user.dart';
import '../../domain/entities/analytics.dart';
import '../../domain/entities/permission_audit.dart';
import '../../domain/entities/recent_activity.dart';
import 'admin_remote_datasource.dart';

class FirestoreAdminDataSource implements AdminRemoteDataSource {
  final FirebaseFirestore _firestore;

  FirestoreAdminDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // Collections
  static const String _quizzesCollection = 'quizzes';
  static const String _questionsSubcollection = 'questions';
  static const String _usersCollection = 'users';
  static const String _submissionsCollection = 'submissions';
  static const String _permissionAuditsCollection = 'permission_audits';

  // Helper method to convert DateRange enum to actual DateTime range
  ({DateTime? start, DateTime? end}) _getDateRangeValues(DateRange? range) {
    if (range == null) return (start: null, end: null);

    final now = DateTime.now();
    switch (range) {
      case DateRange.today:
        return (start: DateTime(now.year, now.month, now.day), end: now);
      case DateRange.week:
        return (start: now.subtract(const Duration(days: 7)), end: now);
      case DateRange.month:
        return (start: now.subtract(const Duration(days: 30)), end: now);
      case DateRange.quarter:
        return (start: now.subtract(const Duration(days: 90)), end: now);
      case DateRange.year:
        return (start: now.subtract(const Duration(days: 365)), end: now);
      case DateRange.all:
        return (start: null, end: null);
    }
  }

  @override
  Future<List<Quiz>> getQuizzes() async {
    final snapshot = await _firestore
        .collection(_quizzesCollection)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => _quizFromFirestore(doc)).toList();
  }

  @override
  Future<Quiz> createQuiz({
    required String title,
    required String description,
    required int timeLimitMinutes,
    required List<Question> questions,
    int questionsPerAttempt = 0,
    bool randomizeQuestions = false,
    QuizPermissions? permissions,
    QuizMetadata? metadata,
  }) async {
    // CRITICAL FIX: Validate correctAnswer format for all questions
    for (var question in questions) {
      if (!QuizScoringService.isValidCorrectAnswer(
        question.correctAnswer,
        question.options,
      )) {
        throw ArgumentError(
          'Invalid correctAnswer "${question.correctAnswer}" for question "${question.questionText}". '
          'Must be either a valid 1-based index (1-${question.options.length}) or match one of the options exactly.',
        );
      }
    }

    final quizRef = _firestore.collection(_quizzesCollection).doc();
    final quizId = quizRef.id;

    final quizPermissions =
        permissions ??
        QuizPermissions(
          quizId: quizId,
        );

    final quizMetadata =
        metadata ??
        const QuizMetadata(
          category: QuizCategory.general,
          difficulty: DifficultyLevel.intermediate,
          estimatedDuration: 30,
          statistics: QuizStatistics(),
        );

    final quiz = Quiz(
      id: quizId,
      title: title,
      description: description,
      timeLimitMinutes: timeLimitMinutes,
      questionsPerAttempt: questionsPerAttempt,
      randomizeQuestions: randomizeQuestions,
      permissions: quizPermissions,
      metadata: quizMetadata,
      createdBy: 'admin',
      createdAt: DateTime.now(),
    );

    // CRITICAL FIX: Use a single batch for atomic quiz creation
    final batch = _firestore.batch();

    // 1. Create quiz document
    batch.set(quizRef, _quizToFirestore(quiz));

    // 2. Save questions as subcollection
    for (var i = 0; i < questions.length; i++) {
      final question = questions[i];
      final questionRef = quizRef
          .collection(_questionsSubcollection)
          .doc(question.id);
      final questionData = QuestionModel.fromDomain(question).toJson();
      questionData['order'] = i;
      questionData['quizId'] = quizId;
      batch.set(questionRef, questionData);
    }

    // Commit both quiz and questions atomically
    await batch.commit();

    return quiz;
  }

  @override
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
  }) async {
    final quizRef = _firestore.collection(_quizzesCollection).doc(id);
    final doc = await quizRef.get();

    if (!doc.exists) throw Exception('Quiz not found');

    final existingQuiz = _quizFromFirestore(doc);

    final updatedQuiz = Quiz(
      id: id,
      title: title,
      description: description,
      timeLimitMinutes: timeLimitMinutes,
      isActive: existingQuiz.isActive,
      questionsPerAttempt: questionsPerAttempt,
      randomizeQuestions: randomizeQuestions,
      permissions: permissions ?? existingQuiz.permissions,
      metadata: metadata ?? existingQuiz.metadata,
      createdBy: existingQuiz.createdBy,
      createdAt: existingQuiz.createdAt,
      updatedAt: DateTime.now(),
    );

    // CRITICAL FIX: Use a single batch for atomicity
    // Update questions
    final questionsRef = quizRef.collection(_questionsSubcollection);
    final existingQuestions = await questionsRef.get();

    // Use a single batch for all operations to ensure atomicity
    final batch = _firestore.batch();

    // 1. Update quiz document
    batch.update(quizRef, _quizToFirestore(updatedQuiz));

    // 2. Delete old questions
    for (var doc in existingQuestions.docs) {
      batch.delete(doc.reference);
    }

    // 3. Add new questions
    for (var i = 0; i < questions.length; i++) {
      final question = questions[i];
      final questionRef = questionsRef.doc(question.id);
      final questionData = QuestionModel.fromDomain(question).toJson();
      questionData['order'] = i;
      questionData['quizId'] = id;
      batch.set(questionRef, questionData);
    }

    // Commit all operations atomically
    await batch.commit();

    return updatedQuiz;
  }

  @override
  Future<void> deleteQuiz(String id) async {
    final quizRef = _firestore.collection(_quizzesCollection).doc(id);
    final questionsSnapshot = await quizRef
        .collection(_questionsSubcollection)
        .get();

    final batch = _firestore.batch();
    for (var doc in questionsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(quizRef);
    await batch.commit();
  }

  @override
  Future<Quiz> setQuizActive(String id, bool isActive) async {
    final quizRef = _firestore.collection(_quizzesCollection).doc(id);
    await quizRef.update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final doc = await quizRef.get();
    return _quizFromFirestore(doc);
  }

  @override
  Future<String> uploadQuestionImage(String questionId, String filePath) async {
    throw UnimplementedError(
      'Image upload disabled - Firebase Storage requires billing',
    );
  }

  @override
  Future<List<Question>> getQuestions(String quizId) async {
    final snapshot = await _firestore
        .collection(_quizzesCollection)
        .doc(quizId)
        .collection(_questionsSubcollection)
        .orderBy('order')
        .get();

    return snapshot.docs
        .map((doc) => QuestionModel.fromJson(doc.data()).toDomain())
        .toList();
  }

  @override
  Future<List<AdminUser>> getUsers() async {
    final snapshot = await _firestore.collection(_usersCollection).get();
    return snapshot.docs.map((doc) => _adminUserFromFirestore(doc)).toList();
  }

  @override
  Future<AdminUser> blockUser(String userId, bool block) async {
    final userRef = _firestore.collection(_usersCollection).doc(userId);
    await userRef.update({'isBlocked': block});

    final doc = await userRef.get();
    return _adminUserFromFirestore(doc);
  }

  @override
  Future<AdminUser> updateUserAccess(String userId, UserRole role) async {
    final userRef = _firestore.collection(_usersCollection).doc(userId);
    await userRef.update({'role': role.name});

    final doc = await userRef.get();
    return _adminUserFromFirestore(doc);
  }

  @override
  Future<AdminUser> getUserAnalytics(String userId) async {
    final doc = await _firestore.collection(_usersCollection).doc(userId).get();
    return _adminUserFromFirestore(doc);
  }

  @override
  Future<QuizPermissions> getQuizPermissions(String quizId) async {
    final doc = await _firestore
        .collection(_quizzesCollection)
        .doc(quizId)
        .get();
    final quiz = _quizFromFirestore(doc);
    return quiz.permissions;
  }

  @override
  Future<void> updateQuizPermissions(
    String quizId,
    QuizPermissions permissions,
  ) async {
    await _firestore.collection(_quizzesCollection).doc(quizId).update({
      'permissions': _permissionsToMap(permissions),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> logPermissionChange(PermissionAudit audit) async {
    await _firestore.collection(_permissionAuditsCollection).add({
      'quizId': audit.quizId,
      'userId': audit.userId,
      'action': audit.action.name,
      'performedBy': audit.performedBy,
      'oldValues': audit.oldValues,
      'newValues': audit.newValues,
      'timestamp': Timestamp.fromDate(audit.timestamp),
      'reason': audit.reason,
    });
  }

  @override
  Future<QuizAnalytics> getQuizAnalytics(
    String quizId,
    DateRange? dateRange,
  ) async {
    final quizDoc = await _firestore
        .collection(_quizzesCollection)
        .doc(quizId)
        .get();
    if (!quizDoc.exists) throw Exception('Quiz not found');

    final quiz = _quizFromFirestore(quizDoc);
    final questions = await getQuestions(quizId);

    Query<Map<String, dynamic>> submissionsQuery = _firestore
        .collection(_submissionsCollection)
        .where('quizId', isEqualTo: quizId);

    // Apply date range if provided
    final dateRangeValues = _getDateRangeValues(dateRange);
    if (dateRangeValues.start != null) {
      submissionsQuery = submissionsQuery.where(
        'submittedAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(dateRangeValues.start!),
      );
    }
    if (dateRangeValues.end != null) {
      submissionsQuery = submissionsQuery.where(
        'submittedAt',
        isLessThanOrEqualTo: Timestamp.fromDate(dateRangeValues.end!),
      );
    }

    final submissionsSnapshot = await submissionsQuery.get();
    final submissions = submissionsSnapshot.docs;

    if (submissions.isEmpty) {
      return QuizAnalytics(
        quizId: quizId,
        quizTitle: quiz.title,
        totalAttempts: 0,
        averageScore: 0.0,
        averagePercentage: 0.0,
        totalParticipants: 0,
        completionRate: 100.0,
        averageTimeSeconds: 0,
        questionAnalytics: const [],
        dailyAnalytics: const [],
      );
    }

    final totalAttempts = submissions.length;
    final uniqueParticipants = submissions
        .map((s) => s.data()['userId'])
        .toSet()
        .length;

    double totalScore = 0;
    double totalPercentage = 0;
    int totalTimeSeconds = 0;
    int completedCount = 0;

    for (var sub in submissions) {
      final data = sub.data();
      totalScore += (data['score'] as num?)?.toDouble() ?? 0;
      totalPercentage += (data['percentage'] as num?)?.toDouble() ?? 0;
      totalTimeSeconds += (data['timeTakenSeconds'] as int?) ?? 0;
      if (data['completed'] == true) completedCount++;
    }

    final averageScore = totalScore / totalAttempts;
    final averagePercentage = totalPercentage / totalAttempts;
    final averageTimeSeconds = (totalTimeSeconds / totalAttempts).round();
    final completionRate = (completedCount / totalAttempts) * 100;

    // Calculate question analytics
    final questionAnalyticsList = <QuestionAnalytics>[];
    for (var question in questions) {
      final answerCounts = <String, int>{};
      int correctAnswerCount = 0;

      for (var sub in submissions) {
        final answers = sub.data()['answers'] as Map<String, dynamic>?;
        if (answers != null) {
          final userAnswer = answers[question.id] as String?;
          if (userAnswer != null) {
            answerCounts[userAnswer] = (answerCounts[userAnswer] ?? 0) + 1;
            if (userAnswer == question.correctAnswer) correctAnswerCount++;
          }
        }
      }

      questionAnalyticsList.add(
        QuestionAnalytics(
          questionId: question.id,
          questionText: question.questionText,
          answerCounts: answerCounts,
          correctAnswer: question.correctAnswer,
          correctAnswerCount: correctAnswerCount,
          correctAnswerPercentage: totalAttempts > 0
              ? (correctAnswerCount / totalAttempts) * 100
              : 0,
        ),
      );
    }

    // Calculate daily analytics (last 7 days)
    final dailyAnalyticsList = <DailyAnalytics>[];
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      final nextDate = date.add(const Duration(days: 1));

      final daySubmissions = submissions.where((s) {
        final submittedAt = TimestampParser.parse(s.data()['submittedAt']);
        return submittedAt.isAfter(date) && submittedAt.isBefore(nextDate);
      }).toList();

      if (daySubmissions.isNotEmpty) {
        final dayScore = daySubmissions.fold<double>(
          0,
          (total, s) => total + ((s.data()['score'] as num?)?.toDouble() ?? 0),
        );
        final dayPercentage = daySubmissions.fold<double>(
          0,
          (total, s) =>
              total + ((s.data()['percentage'] as num?)?.toDouble() ?? 0),
        );
        final uniqueUsers = daySubmissions
            .map((s) => s.data()['userId'])
            .toSet()
            .length;

        dailyAnalyticsList.add(
          DailyAnalytics(
            date: date,
            attempts: daySubmissions.length,
            averageScore: dayScore / daySubmissions.length,
            averagePercentage: dayPercentage / daySubmissions.length,
            uniqueParticipants: uniqueUsers,
          ),
        );
      } else {
        dailyAnalyticsList.add(
          DailyAnalytics(
            date: date,
            attempts: 0,
            averageScore: 0,
            averagePercentage: 0,
            uniqueParticipants: 0,
          ),
        );
      }
    }

    return QuizAnalytics(
      quizId: quizId,
      quizTitle: quiz.title,
      totalAttempts: totalAttempts,
      averageScore: averageScore,
      averagePercentage: averagePercentage,
      totalParticipants: uniqueParticipants,
      completionRate: completionRate,
      averageTimeSeconds: averageTimeSeconds,
      questionAnalytics: questionAnalyticsList,
      dailyAnalytics: dailyAnalyticsList,
    );
  }

  @override
  Future<UserAnalytics> getDetailedUserAnalytics(String userId) async {
    final userDoc = await _firestore
        .collection(_usersCollection)
        .doc(userId)
        .get();
    if (!userDoc.exists) throw Exception('User not found');

    final user = _adminUserFromFirestore(userDoc);

    final submissionsSnapshot = await _firestore
        .collection(_submissionsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('submittedAt', descending: true)
        .get();

    final submissions = submissionsSnapshot.docs;

    if (submissions.isEmpty) {
      return UserAnalytics(
        userId: userId,
        userName: user.name,
        userEmail: user.email,
        totalQuizzesTaken: 0,
        totalScore: 0,
        averagePercentage: 0.0,
        totalTimeSpentSeconds: 0,
        quizAttempts: const [],
      );
    }

    final totalQuizzesTaken = submissions
        .map((s) => s.data()['quizId'])
        .toSet()
        .length;
    final totalScore = submissions.fold<int>(
      0,
      (total, s) => total + ((s.data()['score'] as int?) ?? 0),
    );
    final totalPercentage = submissions.fold<double>(
      0,
      (total, s) => total + ((s.data()['percentage'] as num?)?.toDouble() ?? 0),
    );
    final totalTimeSpentSeconds = submissions.fold<int>(
      0,
      (total, s) => total + ((s.data()['timeTakenSeconds'] as int?) ?? 0),
    );
    final averagePercentage = totalPercentage / submissions.length;

    // Get quiz titles
    final quizIds = submissions
        .map((s) => s.data()['quizId'] as String)
        .toSet();
    final quizTitles = <String, String>{};
    for (var quizId in quizIds) {
      final quizDoc = await _firestore
          .collection(_quizzesCollection)
          .doc(quizId)
          .get();
      if (quizDoc.exists) {
        quizTitles[quizId] = quizDoc.data()!['title'] as String;
      }
    }

    final quizAttempts = submissions.map((sub) {
      final data = sub.data();
      return QuizAttemptAnalytics(
        quizId: data['quizId'] as String,
        quizTitle: quizTitles[data['quizId']] ?? 'Unknown Quiz',
        score: (data['score'] as int?) ?? 0,
        percentage: (data['percentage'] as num?)?.toDouble() ?? 0,
        attemptDate: TimestampParser.parse(data['submittedAt']),
        timeTakenSeconds: (data['timeTakenSeconds'] as int?) ?? 0,
        completed: (data['completed'] as bool?) ?? true,
      );
    }).toList();

    final lastActivity = submissions.isNotEmpty
        ? TimestampParser.parse(submissions.first.data()['submittedAt'])
        : null;

    return UserAnalytics(
      userId: userId,
      userName: user.name,
      userEmail: user.email,
      totalQuizzesTaken: totalQuizzesTaken,
      totalScore: totalScore,
      averagePercentage: averagePercentage,
      totalTimeSpentSeconds: totalTimeSpentSeconds,
      quizAttempts: quizAttempts,
      lastActivity: lastActivity,
    );
  }

  @override
  Future<SystemAnalytics> getSystemAnalytics(DateRange? dateRange) async {
    // Parallelize all independent base queries
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 7));
    final monthAgo = today.subtract(const Duration(days: 30));

    Query<Map<String, dynamic>> submissionsQuery = _firestore.collection(
      _submissionsCollection,
    );

    final dateRangeValues = _getDateRangeValues(dateRange);
    if (dateRangeValues.start != null) {
      submissionsQuery = submissionsQuery.where(
        'submittedAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(dateRangeValues.start!),
      );
    }
    if (dateRangeValues.end != null) {
      submissionsQuery = submissionsQuery.where(
        'submittedAt',
        isLessThanOrEqualTo: Timestamp.fromDate(dateRangeValues.end!),
      );
    }

    // Execute all base queries in parallel
    final results = await Future.wait([
      _firestore.collection(_usersCollection).get(), // 0
      _firestore.collection(_quizzesCollection).get(), // 1
      submissionsQuery.get(), // 2
      _firestore
          .collection(_submissionsCollection)
          .where(
            'submittedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(today),
          )
          .get(), // 3
      _firestore
          .collection(_submissionsCollection)
          .where(
            'submittedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo),
          )
          .get(), // 4
      _firestore
          .collection(_submissionsCollection)
          .where(
            'submittedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(monthAgo),
          )
          .get(), // 5
    ]);

    final usersSnapshot = results[0];
    final quizzesSnapshot = results[1];
    final submissionsSnapshot = results[2];
    final todaySubmissions = results[3];
    final weekSubmissions = results[4];
    final monthSubmissions = results[5];

    final totalUsers = usersSnapshot.size;
    final totalQuizzes = quizzesSnapshot.size;
    final totalSubmissions = submissionsSnapshot.size;

    double averageScore = 0.0;
    if (submissionsSnapshot.docs.isNotEmpty) {
      final totalScore = submissionsSnapshot.docs.fold<double>(
        0,
        (total, doc) =>
            total + ((doc.data()['score'] as num?)?.toDouble() ?? 0),
      );
      averageScore = totalScore / submissionsSnapshot.docs.length;
    }

    // Calculate active users from parallel queries
    final activeUsersToday = todaySubmissions.docs
        .map((d) => d.data()['userId'])
        .toSet()
        .length;
    final activeUsersThisWeek = weekSubmissions.docs
        .map((d) => d.data()['userId'])
        .toSet()
        .length;
    final activeUsersThisMonth = monthSubmissions.docs
        .map((d) => d.data()['userId'])
        .toSet()
        .length;

    // Parallelize top performers and monthly analytics
    final topPerformersAndMonthlyFutures = <Future>[];

    // Add top performers
    topPerformersAndMonthlyFutures.add(
      _getTopPerformingQuizzesOptimized(submissionsSnapshot.docs, 3),
    );
    topPerformersAndMonthlyFutures.add(
      _getTopPerformingUsersOptimized(submissionsSnapshot.docs, 3),
    );

    // Add monthly analytics queries
    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i);
      final nextMonth = DateTime(now.year, now.month - i + 1);

      topPerformersAndMonthlyFutures.add(
        Future.wait([
          _firestore
              .collection(_usersCollection)
              .where(
                'createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(monthDate),
              )
              .where('createdAt', isLessThan: Timestamp.fromDate(nextMonth))
              .get(),
          _firestore
              .collection(_submissionsCollection)
              .where(
                'submittedAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(monthDate),
              )
              .where('submittedAt', isLessThan: Timestamp.fromDate(nextMonth))
              .get(),
        ]),
      );
    }

    final topPerformersAndMonthlyResults = await Future.wait(
      topPerformersAndMonthlyFutures,
    );

    final topQuizzes = topPerformersAndMonthlyResults[0] as List<QuizAnalytics>;
    final topUsers = topPerformersAndMonthlyResults[1] as List<UserAnalytics>;

    // Process monthly analytics
    final monthlyAnalytics = <MonthlyAnalytics>[];
    for (int i = 0; i < 6; i++) {
      final monthDate = DateTime(now.year, now.month - (5 - i));
      final monthResults = topPerformersAndMonthlyResults[i + 2] as List;
      final newUsersQuery =
          monthResults[0] as QuerySnapshot<Map<String, dynamic>>;
      final monthSubmissionsQuery =
          monthResults[1] as QuerySnapshot<Map<String, dynamic>>;

      double monthAvgScore = 0.0;
      if (monthSubmissionsQuery.docs.isNotEmpty) {
        final monthScore = monthSubmissionsQuery.docs.fold<double>(
          0,
          (total, doc) =>
              total + ((doc.data()['score'] as num?)?.toDouble() ?? 0),
        );
        monthAvgScore = monthScore / monthSubmissionsQuery.docs.length;
      }

      monthlyAnalytics.add(
        MonthlyAnalytics(
          month: monthDate,
          newUsers: newUsersQuery.size,
          quizAttempts: monthSubmissionsQuery.size,
          averageScore: monthAvgScore,
        ),
      );
    }

    // Calculate user role distribution
    final userRoleDistribution = <String, int>{};
    for (var doc in usersSnapshot.docs) {
      final role = doc.data()['role'] as String? ?? 'student';
      userRoleDistribution[role] = (userRoleDistribution[role] ?? 0) + 1;
    }

    return SystemAnalytics(
      totalUsers: totalUsers,
      totalQuizzes: totalQuizzes,
      totalSubmissions: totalSubmissions,
      averageScore: averageScore,
      activeUsersToday: activeUsersToday,
      activeUsersThisWeek: activeUsersThisWeek,
      activeUsersThisMonth: activeUsersThisMonth,
      topPerformingQuizzes: topQuizzes,
      topPerformingUsers: topUsers,
      userRoleDistribution: userRoleDistribution,
      monthlyAnalytics: monthlyAnalytics,
    );
  }

  /// Optimized version that works with already-fetched submissions
  Future<List<UserAnalytics>> _getTopPerformingUsersOptimized(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> allSubmissions,
    int limit,
  ) async {
    // Group submissions by userId
    final submissionsByUser = <String, List<Map<String, dynamic>>>{};
    for (var sub in allSubmissions) {
      final userId = sub.data()['userId'] as String;
      submissionsByUser.putIfAbsent(userId, () => []).add(sub.data());
    }

    // Fetch user details for users who have submissions
    final userIds = submissionsByUser.keys.toList();
    if (userIds.isEmpty) return [];

    // Batch fetch users (max 10 at a time due to Firestore 'in' limit)
    final userDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (int i = 0; i < userIds.length; i += 10) {
      final batch = userIds.skip(i).take(10).toList();
      final snapshot = await _firestore
          .collection(_usersCollection)
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      userDocs.addAll(snapshot.docs);
    }

    final userAnalyticsList = <UserAnalytics>[];

    for (var userDoc in userDocs) {
      final userId = userDoc.id;
      final submissions = submissionsByUser[userId] ?? [];
      if (submissions.isEmpty) continue;

      final user = _adminUserFromFirestore(userDoc);

      final totalQuizzesTaken = submissions
          .map((s) => s['quizId'])
          .toSet()
          .length;
      final totalScore = submissions.fold<int>(
        0,
        (total, s) => total + ((s['score'] as int?) ?? 0),
      );
      final totalPercentage = submissions.fold<double>(
        0,
        (total, s) => total + ((s['percentage'] as num?)?.toDouble() ?? 0),
      );
      final totalTimeSpentSeconds = submissions.fold<int>(
        0,
        (total, s) => total + ((s['timeTakenSeconds'] as int?) ?? 0),
      );
      final averagePercentage = totalPercentage / submissions.length;

      final lastActivity = submissions.isNotEmpty
          ? TimestampParser.parse(submissions.first['submittedAt'])
          : null;

      userAnalyticsList.add(
        UserAnalytics(
          userId: userId,
          userName: user.name,
          userEmail: user.email,
          totalQuizzesTaken: totalQuizzesTaken,
          totalScore: totalScore,
          averagePercentage: averagePercentage,
          totalTimeSpentSeconds: totalTimeSpentSeconds,
          quizAttempts: const [],
          lastActivity: lastActivity,
        ),
      );
    }

    userAnalyticsList.sort(
      (a, b) => b.averagePercentage.compareTo(a.averagePercentage),
    );

    return userAnalyticsList.take(limit).toList();
  }

  /// Optimized version that works with already-fetched submissions
  Future<List<QuizAnalytics>> _getTopPerformingQuizzesOptimized(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> allSubmissions,
    int limit,
  ) async {
    // Group submissions by quizId
    final submissionsByQuiz = <String, List<Map<String, dynamic>>>{};
    for (var sub in allSubmissions) {
      final quizId = sub.data()['quizId'] as String;
      submissionsByQuiz.putIfAbsent(quizId, () => []).add(sub.data());
    }

    // Fetch quiz details for quizzes that have submissions
    final quizIds = submissionsByQuiz.keys.toList();
    if (quizIds.isEmpty) return [];

    // Batch fetch quizzes (max 10 at a time due to Firestore 'in' limit)
    final quizDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (int i = 0; i < quizIds.length; i += 10) {
      final batch = quizIds.skip(i).take(10).toList();
      final snapshot = await _firestore
          .collection(_quizzesCollection)
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      quizDocs.addAll(snapshot.docs);
    }

    final quizAnalyticsList = <QuizAnalytics>[];

    for (var quizDoc in quizDocs) {
      final quizId = quizDoc.id;
      final quiz = _quizFromFirestore(quizDoc);
      final submissions = submissionsByQuiz[quizId] ?? [];
      if (submissions.isEmpty) continue;

      final totalAttempts = submissions.length;
      final uniqueParticipants = submissions
          .map((s) => s['userId'])
          .toSet()
          .length;

      final totalScore = submissions.fold<double>(
        0,
        (total, s) => total + ((s['score'] as num?)?.toDouble() ?? 0),
      );
      final totalPercentage = submissions.fold<double>(
        0,
        (total, s) => total + ((s['percentage'] as num?)?.toDouble() ?? 0),
      );
      final totalTimeSeconds = submissions.fold<int>(
        0,
        (total, s) => total + ((s['timeTakenSeconds'] as int?) ?? 0),
      );
      final completedCount = submissions
          .where((s) => s['completed'] == true)
          .length;

      final averageScore = totalScore / totalAttempts;
      final averagePercentage = totalPercentage / totalAttempts;
      final averageTimeSeconds = (totalTimeSeconds / totalAttempts).round();
      final completionRate = (completedCount / totalAttempts) * 100;

      quizAnalyticsList.add(
        QuizAnalytics(
          quizId: quizId,
          quizTitle: quiz.title,
          totalAttempts: totalAttempts,
          averageScore: averageScore,
          averagePercentage: averagePercentage,
          totalParticipants: uniqueParticipants,
          completionRate: completionRate,
          averageTimeSeconds: averageTimeSeconds,
          questionAnalytics: const [],
          dailyAnalytics: const [],
        ),
      );
    }

    quizAnalyticsList.sort(
      (a, b) => b.averagePercentage.compareTo(a.averagePercentage),
    );

    return quizAnalyticsList.take(limit).toList();
  }

  @override
  Future<List<UserAnalytics>> getTopPerformingUsers(int limit) async {
    final usersSnapshot = await _firestore
        .collection(_usersCollection)
        .limit(100)
        .get();

    final userAnalyticsList = <UserAnalytics>[];

    for (var userDoc in usersSnapshot.docs) {
      final userId = userDoc.id;

      final submissionsSnapshot = await _firestore
          .collection(_submissionsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      if (submissionsSnapshot.docs.isEmpty) continue;

      final user = _adminUserFromFirestore(userDoc);
      final submissions = submissionsSnapshot.docs;

      final totalQuizzesTaken = submissions
          .map((s) => s.data()['quizId'])
          .toSet()
          .length;
      final totalScore = submissions.fold<int>(
        0,
        (total, s) => total + ((s.data()['score'] as int?) ?? 0),
      );
      final totalPercentage = submissions.fold<double>(
        0,
        (total, s) =>
            total + ((s.data()['percentage'] as num?)?.toDouble() ?? 0),
      );
      final totalTimeSpentSeconds = submissions.fold<int>(
        0,
        (total, s) => total + ((s.data()['timeTakenSeconds'] as int?) ?? 0),
      );
      final averagePercentage = totalPercentage / submissions.length;

      final lastActivity = submissions.isNotEmpty
          ? TimestampParser.parse(submissions.first.data()['submittedAt'])
          : null;

      userAnalyticsList.add(
        UserAnalytics(
          userId: userId,
          userName: user.name,
          userEmail: user.email,
          totalQuizzesTaken: totalQuizzesTaken,
          totalScore: totalScore,
          averagePercentage: averagePercentage,
          totalTimeSpentSeconds: totalTimeSpentSeconds,
          quizAttempts: const [],
          lastActivity: lastActivity,
        ),
      );
    }

    userAnalyticsList.sort(
      (a, b) => b.averagePercentage.compareTo(a.averagePercentage),
    );

    return userAnalyticsList.take(limit).toList();
  }

  @override
  Future<List<QuizAnalytics>> getTopPerformingQuizzes(int limit) async {
    final quizzesSnapshot = await _firestore
        .collection(_quizzesCollection)
        .get();

    final quizAnalyticsList = <QuizAnalytics>[];

    for (var quizDoc in quizzesSnapshot.docs) {
      final quizId = quizDoc.id;
      final quiz = _quizFromFirestore(quizDoc);

      final submissionsSnapshot = await _firestore
          .collection(_submissionsCollection)
          .where('quizId', isEqualTo: quizId)
          .get();

      if (submissionsSnapshot.docs.isEmpty) continue;

      final submissions = submissionsSnapshot.docs;
      final totalAttempts = submissions.length;
      final uniqueParticipants = submissions
          .map((s) => s.data()['userId'])
          .toSet()
          .length;

      final totalScore = submissions.fold<double>(
        0,
        (total, s) => total + ((s.data()['score'] as num?)?.toDouble() ?? 0),
      );
      final totalPercentage = submissions.fold<double>(
        0,
        (total, s) =>
            total + ((s.data()['percentage'] as num?)?.toDouble() ?? 0),
      );
      final totalTimeSeconds = submissions.fold<int>(
        0,
        (total, s) => total + ((s.data()['timeTakenSeconds'] as int?) ?? 0),
      );
      final completedCount = submissions
          .where((s) => s.data()['completed'] == true)
          .length;

      final averageScore = totalScore / totalAttempts;
      final averagePercentage = totalPercentage / totalAttempts;
      final averageTimeSeconds = (totalTimeSeconds / totalAttempts).round();
      final completionRate = (completedCount / totalAttempts) * 100;

      quizAnalyticsList.add(
        QuizAnalytics(
          quizId: quizId,
          quizTitle: quiz.title,
          totalAttempts: totalAttempts,
          averageScore: averageScore,
          averagePercentage: averagePercentage,
          totalParticipants: uniqueParticipants,
          completionRate: completionRate,
          averageTimeSeconds: averageTimeSeconds,
          questionAnalytics: const [],
          dailyAnalytics: const [],
        ),
      );
    }

    quizAnalyticsList.sort(
      (a, b) => b.averagePercentage.compareTo(a.averagePercentage),
    );

    return quizAnalyticsList.take(limit).toList();
  }

  // Helper methods

  Quiz _quizFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Quiz(
      id: doc.id,
      title: data['title'] as String,
      description: data['description'] as String,
      timeLimitMinutes: data['timeLimitMinutes'] as int,
      isActive: data['isActive'] as bool? ?? true,
      questionsPerAttempt: data['questionsPerAttempt'] as int? ?? 0,
      randomizeQuestions: data['randomizeQuestions'] as bool? ?? false,
      permissions: _permissionsFromMap(
        (data['permissions'] as Map<String, dynamic>?) ?? {},
        doc.id,
      ),
      metadata: _metadataFromMap(
        (data['metadata'] as Map<String, dynamic>?) ?? {},
      ),
      createdBy: data['createdBy'] as String,
      createdAt: TimestampParser.parse(data['createdAt']),
      updatedAt: data['updatedAt'] != null
          ? TimestampParser.parse(data['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> _quizToFirestore(Quiz quiz) {
    return {
      'title': quiz.title,
      'description': quiz.description,
      'timeLimitMinutes': quiz.timeLimitMinutes,
      'isActive': quiz.isActive,
      'questionsPerAttempt': quiz.questionsPerAttempt,
      'randomizeQuestions': quiz.randomizeQuestions,
      'permissions': _permissionsToMap(quiz.permissions),
      'metadata': _metadataToMap(quiz.metadata),
      'createdBy': quiz.createdBy,
      'createdAt': Timestamp.fromDate(quiz.createdAt),
      if (quiz.updatedAt != null)
        'updatedAt': Timestamp.fromDate(quiz.updatedAt!),
    };
  }

  QuizPermissions _permissionsFromMap(Map<String, dynamic> map, String quizId) {
    return QuizPermissions(
      quizId: quizId,
      allowedUserIds: Set<String>.from(map['allowedUserIds'] as List? ?? []),
      allowedRoles: Set<String>.from(
        map['allowedRoles'] as List? ?? ['student'],
      ),
      availableFrom: map['availableFrom'] != null
          ? TimestampParser.parse(map['availableFrom'])
          : null,
      availableUntil: map['availableUntil'] != null
          ? TimestampParser.parse(map['availableUntil'])
          : null,
      maxAttempts: map['maxAttempts'] as int? ?? 1,
    );
  }

  Map<String, dynamic> _permissionsToMap(QuizPermissions permissions) {
    return {
      'allowedUserIds': permissions.allowedUserIds.toList(),
      'allowedRoles': permissions.allowedRoles.toList(),
      if (permissions.availableFrom != null)
        'availableFrom': Timestamp.fromDate(permissions.availableFrom!),
      if (permissions.availableUntil != null)
        'availableUntil': Timestamp.fromDate(permissions.availableUntil!),
      'maxAttempts': permissions.maxAttempts,
    };
  }

  QuizMetadata _metadataFromMap(Map<String, dynamic> map) {
    return QuizMetadata(
      category: QuizCategory.values.firstWhere(
        (e) => e.name == (map['category'] as String? ?? 'general'),
        orElse: () => QuizCategory.general,
      ),
      tags: List<String>.from(map['tags'] as List? ?? []),
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.name == (map['difficulty'] as String? ?? 'intermediate'),
        orElse: () => DifficultyLevel.intermediate,
      ),
      estimatedDuration: map['estimatedDuration'] as int? ?? 30,
      isTemplate: map['isTemplate'] as bool? ?? false,
      templateId: map['templateId'] as String?,
      statistics: const QuizStatistics(),
    );
  }

  Map<String, dynamic> _metadataToMap(QuizMetadata metadata) {
    return {
      'category': metadata.category.name,
      'tags': metadata.tags,
      'difficulty': metadata.difficulty.name,
      'estimatedDuration': metadata.estimatedDuration,
      'isTemplate': metadata.isTemplate,
      if (metadata.templateId != null) 'templateId': metadata.templateId,
    };
  }

  AdminUser _adminUserFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminUser(
      id: doc.id,
      name: data['name'] as String,
      email: data['email'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == (data['role'] as String? ?? 'student'),
        orElse: () => UserRole.student,
      ),
      isBlocked: data['isBlocked'] as bool? ?? false,
      totalScore: data['totalScore'] as int? ?? 0,
      averagePercentage: (data['averagePercentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  Future<List<RecentActivity>> getRecentActivity(int limit) async {
    final activities = <RecentActivity>[];

    // Fetch recent quizzes
    final recentQuizzesSnapshot = await _firestore
        .collection(_quizzesCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    for (var doc in recentQuizzesSnapshot.docs) {
      final data = doc.data();
      final createdAt = data['createdAt'];

      // Skip if timestamp is null
      if (createdAt == null) continue;

      activities.add(
        RecentActivity(
          id: doc.id,
          type: ActivityType.quizCreated,
          title: 'New quiz created',
          subtitle: data['title'] as String,
          timestamp: TimestampParser.parse(createdAt),
          metadata: {'quizId': doc.id},
        ),
      );
    }

    // Fetch recent users
    final recentUsersSnapshot = await _firestore
        .collection(_usersCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    for (var doc in recentUsersSnapshot.docs) {
      final data = doc.data();
      final createdAt = data['createdAt'];

      // Skip if timestamp is null
      if (createdAt == null) continue;

      activities.add(
        RecentActivity(
          id: doc.id,
          type: ActivityType.userRegistered,
          title: 'New user registered',
          subtitle: '${data['name'] as String? ?? 'Unknown'} joined',
          timestamp: TimestampParser.parse(createdAt),
          metadata: {'userId': doc.id},
        ),
      );
    }

    // Fetch recent submissions
    final recentSubmissionsSnapshot = await _firestore
        .collection(_submissionsCollection)
        .orderBy('submittedAt', descending: true)
        .limit(limit)
        .get();

    for (var doc in recentSubmissionsSnapshot.docs) {
      final data = doc.data();
      final submittedAt = data['submittedAt'];

      // Skip if timestamp is null
      if (submittedAt == null) continue;

      // Get quiz title
      String quizTitle = 'Quiz';
      try {
        final quizDoc = await _firestore
            .collection(_quizzesCollection)
            .doc(data['quizId'] as String)
            .get();
        if (quizDoc.exists) {
          quizTitle = quizDoc.data()?['title'] as String? ?? 'Quiz';
        }
      } catch (e) {
        // Use default if quiz not found
      }

      activities.add(
        RecentActivity(
          id: doc.id,
          type: ActivityType.quizSubmission,
          title: 'Quiz submitted',
          subtitle: quizTitle,
          timestamp: TimestampParser.parse(submittedAt),
          metadata: {
            'submissionId': doc.id,
            'score': data['score'],
            'percentage': data['percentage'],
          },
        ),
      );
    }

    // Sort all activities by timestamp (most recent first)
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Return only the requested limit
    return activities.take(limit).toList();
  }
}
