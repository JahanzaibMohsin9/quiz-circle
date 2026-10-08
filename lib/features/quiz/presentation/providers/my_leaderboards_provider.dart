import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/quiz.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import 'quiz_provider.dart';

/// Provider that fetches quiz IDs where user has submissions
final _userSubmittedQuizIdsProvider = FutureProvider<Set<String>>((ref) async {
  final authState = ref.watch(authProvider);

  if (authState.userId == null) {
    return {};
  }

  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('submissions')
        .where('userId', isEqualTo: authState.userId)
        .get();

    return snapshot.docs.map((doc) => doc.data()['quizId'] as String).toSet();
  } catch (e) {
    return {};
  }
});

/// Provider that returns quizzes the current user has access to
/// Shows quizzes where user has submitted at least once OR has explicit permission
final myLeaderboardsProvider = FutureProvider<List<Quiz>>((ref) async {
  // Watch quiz list, auth state, and submitted quiz IDs
  final quizzes = await ref.watch(quizListProvider.future);
  final authState = ref.watch(authProvider);
  final submittedQuizIds = await ref.watch(
    _userSubmittedQuizIdsProvider.future,
  );

  final userId = authState.userId;
  final userRole = authState.role?.name ?? 'student';

  if (userId == null) return [];

  // Filter quizzes where:
  // 1. User has submitted the quiz at least once, OR
  // 2. User has explicit permission
  return quizzes.where((quiz) {
    // Check if user has submitted this quiz
    if (submittedQuizIds.contains(quiz.id)) {
      return true;
    }

    // Check if user has explicit permission
    return quiz.permissions.hasPermission(userId, userRole);
  }).toList();
});
