import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/timestamp_parser.dart';
import '../../../quiz/domain/entities/submission.dart';

// Enhanced state class for quiz submissions with statistics
class QuizSubmissionsState {
  final List<SubmissionWithQuizInfo> submissions;
  final bool isLoading;
  final String? error;
  final SubmissionStatistics? statistics;
  final String? selectedQuizId;

  const QuizSubmissionsState({
    this.submissions = const [],
    this.isLoading = false,
    this.error,
    this.statistics,
    this.selectedQuizId,
  });

  QuizSubmissionsState copyWith({
    List<SubmissionWithQuizInfo>? submissions,
    bool? isLoading,
    String? error,
    SubmissionStatistics? statistics,
    String? selectedQuizId,
  }) {
    return QuizSubmissionsState(
      submissions: submissions ?? this.submissions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      statistics: statistics ?? this.statistics,
      selectedQuizId: selectedQuizId ?? this.selectedQuizId,
    );
  }
}

// Submission with quiz and user information
class SubmissionWithQuizInfo {
  final Submission submission;
  final String quizTitle;
  final String quizCategory;
  final String userName;
  final String userEmail;

  const SubmissionWithQuizInfo({
    required this.submission,
    required this.quizTitle,
    required this.quizCategory,
    required this.userName,
    required this.userEmail,
  });
}

// Statistics for submissions
class SubmissionStatistics {
  final int totalSubmissions;
  final double averageScore;
  final double averagePercentage;
  final int totalQuizzes;
  final int totalUsers;

  const SubmissionStatistics({
    required this.totalSubmissions,
    required this.averageScore,
    required this.averagePercentage,
    required this.totalQuizzes,
    required this.totalUsers,
  });
}

// Notifier for managing quiz submissions
class QuizSubmissionsNotifier extends Notifier<QuizSubmissionsState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  QuizSubmissionsState build() {
    return const QuizSubmissionsState();
  }

  // Load submissions for a specific quiz or all submissions
  Future<void> loadSubmissions([String? quizId]) async {
    state = state.copyWith(
      isLoading: true,
      selectedQuizId: quizId,
    );

    try {
      Query<Map<String, dynamic>> query = _firestore.collection('submissions');

      // Filter by quizId if provided
      if (quizId != null && quizId.isNotEmpty) {
        query = query.where('quizId', isEqualTo: quizId);
      }

      final snapshot = await query
          .orderBy('submittedAt', descending: true)
          .get();

      // Fetch quiz information for each submission
      final submissionsWithInfo = await Future.wait(
        snapshot.docs.map((doc) async {
          final data = doc.data();
          final submission = Submission(
            id: doc.id,
            quizId: data['quizId'] as String,
            userId: data['userId'] as String,
            score: data['score'] as int,
            totalQuestions: data['totalQuestions'] as int,
            percentage: (data['percentage'] as num).toDouble(),
            submittedAt: TimestampParser.parse(data['submittedAt']),
            answers: Map<String, String>.from(data['answers'] as Map? ?? {}),
            timeTakenSeconds: data['timeTakenSeconds'] as int,
          );

          // Fetch quiz details
          String quizTitle = 'Unknown Quiz';
          String quizCategory = 'General';

          try {
            final quizDoc = await _firestore
                .collection('quizzes')
                .doc(submission.quizId)
                .get();

            if (quizDoc.exists) {
              final quizData = quizDoc.data();
              quizTitle = quizData?['title'] as String? ?? 'Unknown Quiz';
              quizCategory = quizData?['category'] as String? ?? 'General';
            }
          } catch (e) {
            // If quiz fetch fails, use defaults
          }

          // Fetch user details
          String userName = 'Unknown User';
          String userEmail = '';

          try {
            final userDoc = await _firestore
                .collection('users')
                .doc(submission.userId)
                .get();

            if (userDoc.exists) {
              final userData = userDoc.data();
              userName = userData?['name'] as String? ?? 'Unknown User';
              userEmail = userData?['email'] as String? ?? '';
            }
          } catch (e) {
            // If user fetch fails, use defaults
          }

          return SubmissionWithQuizInfo(
            submission: submission,
            quizTitle: quizTitle,
            quizCategory: quizCategory,
            userName: userName,
            userEmail: userEmail,
          );
        }),
      );

      // Calculate statistics
      final statistics = _calculateStatistics(submissionsWithInfo);

      state = state.copyWith(
        isLoading: false,
        submissions: submissionsWithInfo,
        statistics: statistics,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load submissions: $e',
      );
    }
  }

  SubmissionStatistics _calculateStatistics(
    List<SubmissionWithQuizInfo> submissions,
  ) {
    if (submissions.isEmpty) {
      return const SubmissionStatistics(
        totalSubmissions: 0,
        averageScore: 0,
        averagePercentage: 0,
        totalQuizzes: 0,
        totalUsers: 0,
      );
    }

    final totalScore = submissions.fold<int>(
      0,
      (previousValue, item) => previousValue + item.submission.score,
    );
    final totalPercentage = submissions.fold<double>(
      0,
      (previousValue, item) => previousValue + item.submission.percentage,
    );

    final uniqueQuizzes = submissions
        .map((item) => item.submission.quizId)
        .toSet()
        .length;
    final uniqueUsers = submissions
        .map((item) => item.submission.userId)
        .toSet()
        .length;

    return SubmissionStatistics(
      totalSubmissions: submissions.length,
      averageScore: totalScore / submissions.length,
      averagePercentage: totalPercentage / submissions.length,
      totalQuizzes: uniqueQuizzes,
      totalUsers: uniqueUsers,
    );
  }

  void refresh([String? quizId]) {
    loadSubmissions(quizId);
  }

  void filterByQuiz(String? quizId) {
    loadSubmissions(quizId);
  }
}

// Provider for quiz submissions
final quizSubmissionsProvider =
    NotifierProvider<QuizSubmissionsNotifier, QuizSubmissionsState>(
      () => QuizSubmissionsNotifier(),
    );
