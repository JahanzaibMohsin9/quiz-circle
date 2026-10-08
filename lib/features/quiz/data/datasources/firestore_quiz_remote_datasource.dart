import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/quiz.dart';
import '../../domain/entities/quiz_permissions.dart';
import '../../domain/entities/quiz_metadata.dart';
import '../../domain/entities/question.dart';
import '../../domain/entities/submission.dart';
import '../../data/models/question_model.dart';
import '../../data/models/quiz_attempt_model.dart';
import 'quiz_remote_datasource.dart';
import '../../../../core/utils/timestamp_parser.dart';
import '../../../../core/validators/schema_validators.dart';
import '../../../../core/services/quiz_scoring_service.dart';

class FirestoreQuizRemoteDataSource implements QuizRemoteDataSource {
  final FirebaseFirestore _firestore;

  FirestoreQuizRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // Collections
  static const String _quizzesCollection = 'quizzes';
  static const String _questionsSubcollection = 'questions';
  static const String _submissionsCollection = 'submissions';
  static const String _attemptsCollection = 'quiz_attempts';
  static const String _usersCollection = 'users';

  // Leaderboard constants
  static const int minQuestionThreshold = 5;

  @override
  Future<List<Quiz>> getQuizzes() async {
    try {
      final snapshot = await _firestore
          .collection(_quizzesCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      // Filter to only return public quizzes for students
      final quizzes = snapshot.docs
          .map((doc) => _quizFromFirestore(doc))
          .where((quiz) => quiz.permissions.allowedRoles.contains('student'))
          .toList();

      debugPrint(
        '✅ Fetched ${quizzes.length} public quizzes from ${snapshot.docs.length} total active quizzes',
      );
      return quizzes;
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching quizzes: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<Quiz> getQuizById(String id) async {
    final doc = await _firestore.collection(_quizzesCollection).doc(id).get();

    if (!doc.exists) {
      throw Exception('Quiz not found');
    }

    return _quizFromFirestore(doc);
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
  Future<Submission> submitQuiz({
    required String quizId,
    required String quizTitle,
    required String userId,
    required Map<String, String> answers,
    required int timeTakenSeconds,
  }) async {
    // Get questions to calculate score
    final questions = await getQuestions(quizId);

    // Use centralized QuizScoringService for score calculation
    final scoringResult = QuizScoringService.calculateScore(
      questions: questions,
      userAnswers: answers,
    );
    final score = scoringResult.score;
    final correctAnswersCount = scoringResult.correctCount;

    // Calculate total points for percentage
    final totalPoints = questions.fold<int>(0, (sum, q) => sum + q.points);
    final percentage = totalPoints > 0 ? (score / totalPoints) * 100 : 0.0;

    // Create submission document
    final submissionRef = _firestore.collection(_submissionsCollection).doc();
    final submissionId = submissionRef.id;

    final submission = Submission(
      id: submissionId,
      quizId: quizId,
      userId: userId,
      score: score,
      totalQuestions: questions.length,
      percentage: percentage,
      submittedAt: DateTime.now(),
      quizTitle: quizTitle,
      correctAnswersCount: correctAnswersCount,
      answers: answers,
      timeTakenSeconds: timeTakenSeconds,
    );

    // Validate submission data before writing to Firestore
    SchemaValidators.validateSubmission(submission);

    // Find active quiz attempt before starting transaction
    final activeAttempts = await _firestore
        .collection(_attemptsCollection)
        .where('userId', isEqualTo: userId)
        .where('quizId', isEqualTo: quizId)
        .where('completedAt', isNull: true)
        .limit(1)
        .get();

    // CRITICAL FIX: Use Firestore Transaction instead of Batch to prevent race condition
    // This ensures atomic read-modify-write for user statistics
    await _firestore.runTransaction((transaction) async {
      // 1. Read user document inside transaction
      final userRef = _firestore.collection(_usersCollection).doc(userId);
      final userDoc = await transaction.get(userRef);

      // 2. Calculate new average atomically
      final currentData = userDoc.data() ?? {};
      final currentTotalPerc =
          (currentData['totalPercentageSum'] as num?)?.toDouble() ?? 0.0;
      final currentCount = (currentData['quizzesTaken'] as int?) ?? 0;
      final newCount = currentCount + 1;
      final newTotalPerc = currentTotalPerc + percentage;
      final newAvg = newTotalPerc / newCount;

      // 3. Save submission document
      transaction.set(submissionRef, {
        'id': submission.id,
        'quizId': submission.quizId,
        'userId': submission.userId,
        'score': submission.score,
        'totalQuestions': submission.totalQuestions,
        'percentage': submission.percentage,
        'submittedAt': Timestamp.fromDate(submission.submittedAt),
        'quizTitle': submission.quizTitle,
        'correctAnswersCount': submission.correctAnswersCount,
        'answers': submission.answers,
        'timeTakenSeconds': submission.timeTakenSeconds,
        'completed': true,
      });

      // 4. Update quiz attempt if exists
      if (activeAttempts.docs.isNotEmpty) {
        final attemptRef = activeAttempts.docs.first.reference;
        transaction.update(attemptRef, {
          'completedAt': FieldValue.serverTimestamp(),
          'finalScore': score,
          'finalPercentage': percentage,
          'submissionId': submissionId,
          'quizTitle': quizTitle,
        });
      }

      // 5. Update user statistics atomically
      transaction.set(userRef, {
        'totalScore': FieldValue.increment(score),
        'quizzesTaken': FieldValue.increment(1),
        'totalPercentageSum': FieldValue.increment(percentage),
        'averagePercentage': newAvg,
        'lastActiveAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    return submission;
  }

  @override
  Future<List<Submission>> getSubmissions(String userId) async {
    final snapshot = await _firestore
        .collection(_submissionsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('submittedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => _submissionFromFirestore(doc)).toList();
  }

  @override
  Future<Submission> getSubmissionById(
    String submissionId,
    String quizId,
  ) async {
    final doc = await _firestore
        .collection(_submissionsCollection)
        .doc(submissionId)
        .get();

    if (!doc.exists) {
      throw Exception('Submission not found');
    }

    final data = doc.data() as Map<String, dynamic>;
    final actualQuizId = data['quizId'] as String?;

    // Verify the submission belongs to the correct quiz
    if (actualQuizId != quizId) {
      throw Exception('Submission does not belong to the specified quiz');
    }

    return _submissionFromFirestore(doc);
  }

  @override
  Future<QuizAttemptModel> startAttempt(
    String quizId,
    String userId,
    int questionsPerAttempt,
    bool randomizeQuestions,
  ) async {
    // 1. Check for existing active attempt
    final existingAttempts = await _firestore
        .collection(_attemptsCollection)
        .where('userId', isEqualTo: userId)
        .where('quizId', isEqualTo: quizId)
        .where('completedAt', isNull: true)
        .limit(1)
        .get();

    if (existingAttempts.docs.isNotEmpty) {
      return QuizAttemptModel.fromJson(
        existingAttempts.docs.first.data(),
        existingAttempts.docs.first.id,
      );
    }

    // 2. Fetch all question IDs
    final questionsSnapshot = await _firestore
        .collection(_quizzesCollection)
        .doc(quizId)
        .collection(_questionsSubcollection)
        .get();

    final allQuestionIds = questionsSnapshot.docs.map((doc) => doc.id).toList();

    // 3. Select questions
    List<String> selectedIds = List.from(allQuestionIds);
    if (randomizeQuestions) {
      selectedIds.shuffle();
    }

    if (questionsPerAttempt > 0 && questionsPerAttempt < selectedIds.length) {
      selectedIds = selectedIds.take(questionsPerAttempt).toList();
    }

    // 4. Create new attempt
    final attemptRef = _firestore.collection(_attemptsCollection).doc();
    final attempt = QuizAttemptModel(
      id: attemptRef.id,
      userId: userId,
      quizId: quizId,
      questionIds: selectedIds,
      startedAt: DateTime.now(),
    );

    await attemptRef.set(attempt.toJson());

    return attempt;
  }

  @override
  Future<void> updateAttemptProgress(
    String attemptId,
    Map<String, String> answers,
    int currentQuestionIndex,
  ) async {
    await _firestore.collection(_attemptsCollection).doc(attemptId).update({
      'answers': answers,
      'currentQuestionIndex': currentQuestionIndex,
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<Question>> getQuestionsByIds(
    String quizId,
    List<String> questionIds,
  ) async {
    if (questionIds.isEmpty) return [];

    // Firestore 'whereIn' is limited to 10 (or 30 in some SDKs).
    // To be safe and simple for larger sets, we'll fetch all questions for the quiz
    // and filter in memory. This is acceptable since we are already fetching all questions
    // to select the subset in startAttempt anyway (though that was just IDs).
    // Optimization: If questionsPerAttempt is small (<= 10), use whereIn.

    if (questionIds.length <= 10) {
      final snapshot = await _firestore
          .collection(_quizzesCollection)
          .doc(quizId)
          .collection(_questionsSubcollection)
          .where(FieldPath.documentId, whereIn: questionIds)
          .get();

      // We need to maintain the order of questionIds
      final questionMap = {
        for (var doc in snapshot.docs)
          doc.id: QuestionModel.fromJson(doc.data()).toDomain(),
      };

      return questionIds
          .map((id) => questionMap[id])
          .whereType<Question>()
          .toList();
    } else {
      // Fallback: Fetch all and filter
      final allQuestions = await getQuestions(quizId);
      final questionMap = {for (var q in allQuestions) q.id: q};
      return questionIds
          .map((id) => questionMap[id])
          .whereType<Question>()
          .toList();
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getLeaderboard(String quizId) async {
    final submissionsSnapshot = await _firestore
        .collection(_submissionsCollection)
        .where('quizId', isEqualTo: quizId)
        .orderBy('percentage', descending: true)
        .orderBy('timeTakenSeconds', descending: false)
        .limit(100)
        .get();

    // IMPROVED: Batch fetch user data to avoid N+1 query problem
    final userIds = submissionsSnapshot.docs
        .map((doc) => doc.data()['userId'] as String)
        .toSet()
        .toList();

    // Fetch all user documents in batches (Firestore 'whereIn' limit is 10)
    final Map<String, String> userNames = {};

    debugPrint('🔍 [LEADERBOARD] Fetching names for ${userIds.length} users: $userIds');

    for (var i = 0; i < userIds.length; i += 10) {
      final batch = userIds.skip(i).take(10).toList();
      debugPrint('🔍 [LEADERBOARD] Processing batch ${(i ~/ 10) + 1}: $batch');
      try {
        final usersSnapshot = await _firestore
            .collection(_usersCollection)
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        debugPrint('🔍 [LEADERBOARD] Batch returned ${usersSnapshot.docs.length} documents');

        for (var userDoc in usersSnapshot.docs) {
          final userData = userDoc.data();
          final userName = userData['name'] as String? ?? 'Unknown User';
          userNames[userDoc.id] = userName;
          debugPrint('🔍 [LEADERBOARD] User ${userDoc.id}: $userName (data: $userData)');
        }
      } catch (e) {
        // If batch fetch fails, continue with default names
        debugPrint('❌ [LEADERBOARD] Error fetching user batch: $e');
        debugPrint('❌ [LEADERBOARD] Stack trace: ${StackTrace.current}');
      }
    }

    debugPrint('🔍 [LEADERBOARD] Final userNames map: $userNames');

    // Build leaderboard with pre-fetched user names
    final leaderboard = <Map<String, dynamic>>[];
    for (var doc in submissionsSnapshot.docs) {
      final data = doc.data();
      final userId = data['userId'] as String;
      final totalQuestions = data['totalQuestions'] as int? ?? 0;

      // Filter out entries with too few questions to prevent inflated rankings
      if (totalQuestions < minQuestionThreshold) continue;

      final userName = userNames[userId] ?? 'Unknown User';
      debugPrint('🔍 [LEADERBOARD] Building entry for userId=$userId, name=$userName');

      leaderboard.add({
        'userId': userId,
        'name': userName,
        'score': data['score'] as int? ?? 0,
        'percentage': (data['percentage'] as num?)?.toDouble() ?? 0.0,
        'totalQuestions': totalQuestions,
        'correctAnswersCount': data['correctAnswersCount'] as int? ?? 0,
        'timeTakenSeconds': data['timeTakenSeconds'] as int? ?? 0,
        'submittedAt': (data['submittedAt'] as Timestamp)
            .toDate()
            .toIso8601String(),
      });
    }

    debugPrint('🔍 [LEADERBOARD] Final leaderboard: $leaderboard');
    return leaderboard;
  }

  @override
  Future<List<Map<String, dynamic>>> getGlobalLeaderboard() async {
    // IMPROVED: Limit initial fetch and add proper ordering
    // Note: For large-scale apps, consider using aggregation with Cloud Functions
    final submissionsSnapshot = await _firestore
        .collection(_submissionsCollection)
        .orderBy('submittedAt', descending: true)
        .limit(
          1000,
        ) // Limit to recent 1000 submissions to prevent excessive data fetch
        .get();

    // Group submissions by user and aggregate scores
    final Map<String, Map<String, dynamic>> userScores = {};

    for (var doc in submissionsSnapshot.docs) {
      final data = doc.data();
      final userId = data['userId'] as String;
      final score = data['score'] as int? ?? 0;
      final percentage = (data['percentage'] as num?)?.toDouble() ?? 0.0;
      final timeTaken = data['timeTakenSeconds'] as int? ?? 0;

      if (userScores.containsKey(userId)) {
        // Aggregate scores for this user
        userScores[userId]!['totalScore'] =
            (userScores[userId]!['totalScore'] as int) + score;
        userScores[userId]!['quizzesTaken'] =
            (userScores[userId]!['quizzesTaken'] as int) + 1;
        userScores[userId]!['totalPercentage'] =
            (userScores[userId]!['totalPercentage'] as double) + percentage;
        userScores[userId]!['totalTimeTaken'] =
            (userScores[userId]!['totalTimeTaken'] as int) + timeTaken;
      } else {
        userScores[userId] = {
          'userId': userId,
          'totalScore': score,
          'quizzesTaken': 1,
          'totalPercentage': percentage,
          'totalTimeTaken': timeTaken,
        };
      }
    }

    // IMPROVED: Batch fetch user names to avoid N+1 query problem
    final userIds = userScores.keys.toList();
    final Map<String, String> userNames = {};

    for (var i = 0; i < userIds.length; i += 10) {
      final batch = userIds.skip(i).take(10).toList();
      try {
        final usersSnapshot = await _firestore
            .collection(_usersCollection)
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (var userDoc in usersSnapshot.docs) {
          userNames[userDoc.id] =
              userDoc.data()['name'] as String? ?? 'Unknown User';
        }
      } catch (e) {
        debugPrint('Error fetching user batch: $e');
      }
    }

    // Build leaderboard with pre-fetched user names
    final leaderboard = <Map<String, dynamic>>[];

    for (var entry in userScores.entries) {
      final userId = entry.key;
      final data = entry.value;

      final quizzesTaken = data['quizzesTaken'] as int;
      final avgPercentage = (data['totalPercentage'] as double) / quizzesTaken;
      final avgTimeTaken = (data['totalTimeTaken'] as int) ~/ quizzesTaken;

      leaderboard.add({
        'userId': userId,
        'name': userNames[userId] ?? 'Unknown User',
        'totalScore': data['totalScore'] as int,
        'quizzesTaken': quizzesTaken,
        'averagePercentage': avgPercentage,
        'averageTimeTaken': avgTimeTaken,
      });
    }

    // Sort by total score (descending), then by average percentage (descending)
    leaderboard.sort((a, b) {
      final scoreComparison = (b['totalScore'] as int).compareTo(
        a['totalScore'] as int,
      );
      if (scoreComparison != 0) return scoreComparison;
      return (b['averagePercentage'] as double).compareTo(
        a['averagePercentage'] as double,
      );
    });

    // Limit to top 100
    return leaderboard.take(100).toList();
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
      permissions: _permissionsFromMap(
        data['permissions'] as Map<String, dynamic>? ?? {},
        doc.id,
      ),
      metadata: _metadataFromMap(
        data['metadata'] as Map<String, dynamic>? ?? {},
      ),
      createdBy: data['createdBy'] as String,
      createdAt: TimestampParser.parse(data['createdAt']),
      updatedAt: data['updatedAt'] != null
          ? TimestampParser.parse(data['updatedAt'])
          : null,
    );
  }

  QuizPermissions _permissionsFromMap(Map<String, dynamic> map, String quizId) {
    return QuizPermissions(
      quizId: quizId,
      allowedUserIds: Set<String>.from(map['allowedUserIds'] as List? ?? []),
      allowedRoles: Set<String>.from(
        map['allowedRoles'] as List? ?? ['student'],
      ),
      availableFrom: map['availableFrom'] != null
          ? (map['availableFrom'] as Timestamp).toDate()
          : null,
      availableUntil: map['availableUntil'] != null
          ? (map['availableUntil'] as Timestamp).toDate()
          : null,
      maxAttempts: map['maxAttempts'] as int? ?? 1,
    );
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

  Submission _submissionFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Submission(
      id: data['id'] as String? ?? doc.id,
      quizId: data['quizId'] as String,
      userId: data['userId'] as String,
      score: data['score'] as int,
      totalQuestions: data['totalQuestions'] as int,
      percentage: (data['percentage'] as num).toDouble(),
      submittedAt: (data['submittedAt'] as Timestamp).toDate(),
      quizTitle: data['quizTitle'] as String? ?? 'Quiz Unknown',
      correctAnswersCount: data['correctAnswersCount'] as int? ?? 0,
      answers: Map<String, String>.from(
        data['answers'] as Map<String, dynamic>? ?? {},
      ),
      timeTakenSeconds: data['timeTakenSeconds'] as int,
    );
  }
}
