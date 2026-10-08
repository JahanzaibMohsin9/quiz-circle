import '../../domain/entities/quiz.dart';
import '../../domain/entities/submission.dart';
import '../../domain/entities/question.dart';
import '../models/quiz_attempt_model.dart';

abstract class QuizRemoteDataSource {
  Future<List<Quiz>> getQuizzes();
  Future<Quiz> getQuizById(String id);
  Future<List<Question>> getQuestions(String quizId);
  Future<Submission> submitQuiz({
    required String quizId,
    required String quizTitle,
    required String userId,
    required Map<String, String> answers,
    required int timeTakenSeconds,
  });
  Future<List<Submission>> getSubmissions(String userId);
  Future<Submission> getSubmissionById(String submissionId, String quizId);
  Future<List<Map<String, dynamic>>> getLeaderboard(String quizId);
  Future<List<Map<String, dynamic>>> getGlobalLeaderboard();
  Future<QuizAttemptModel> startAttempt(
    String quizId,
    String userId,
    int questionsPerAttempt,
    bool randomizeQuestions,
  );
  Future<void> updateAttemptProgress(
    String attemptId,
    Map<String, String> answers,
    int currentQuestionIndex,
  );
  Future<List<Question>> getQuestionsByIds(
    String quizId,
    List<String> questionIds,
  );
}
