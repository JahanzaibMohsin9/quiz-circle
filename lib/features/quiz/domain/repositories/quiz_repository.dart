import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/quiz.dart';
import '../entities/submission.dart';
import '../entities/question.dart';
import '../../data/models/quiz_attempt_model.dart';

abstract class QuizRepository {
  Future<Either<Failure, List<Quiz>>> getQuizzes();
  Future<Either<Failure, Quiz>> getQuizById(String id);
  Future<Either<Failure, List<Question>>> getQuestions(String quizId);
  Future<Either<Failure, Submission>> submitQuiz({
    required String quizId,
    required String quizTitle,
    required String userId,
    required Map<String, String> answers,
    required int timeTakenSeconds,
  });
  Future<Either<Failure, List<Submission>>> getSubmissions(String userId);
  Future<Either<Failure, Submission>> getSubmissionById(
    String submissionId,
    String quizId,
  );
  Future<Either<Failure, List<Map<String, dynamic>>>> getLeaderboard(
    String quizId,
  );
  Future<Either<Failure, List<Map<String, dynamic>>>> getGlobalLeaderboard();
  Future<Either<Failure, QuizAttemptModel>> startAttempt(
    String quizId,
    String userId,
    int questionsPerAttempt,
    bool randomizeQuestions,
  );
  Future<Either<Failure, void>> updateAttemptProgress(
    String attemptId,
    Map<String, String> answers,
    int currentQuestionIndex,
  );
  Future<Either<Failure, List<Question>>> getQuestionsByIds(
    String quizId,
    List<String> questionIds,
  );
}
