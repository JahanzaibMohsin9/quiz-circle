import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/repositories/base_repository.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/quiz.dart';
import '../../domain/entities/submission.dart';
import '../../domain/entities/question.dart';
import '../../domain/repositories/quiz_repository.dart';
import '../datasources/quiz_remote_datasource.dart';
import '../models/quiz_attempt_model.dart';

class QuizRepositoryImpl extends BaseRepository implements QuizRepository {
  final QuizRemoteDataSource remote;

  QuizRepositoryImpl({required NetworkInfo networkInfo, required this.remote})
    : super(networkInfo);

  @override
  Future<Either<Failure, List<Quiz>>> getQuizzes() {
    return execute(() => remote.getQuizzes());
  }

  @override
  Future<Either<Failure, Quiz>> getQuizById(String id) {
    return execute(() => remote.getQuizById(id));
  }

  @override
  Future<Either<Failure, List<Question>>> getQuestions(String quizId) {
    return execute(() => remote.getQuestions(quizId));
  }

  @override
  Future<Either<Failure, Submission>> submitQuiz({
    required String quizId,
    required String quizTitle,
    required String userId,
    required Map<String, String> answers,
    required int timeTakenSeconds,
  }) {
    return execute(
      () => remote.submitQuiz(
        quizId: quizId,
        quizTitle: quizTitle,
        userId: userId,
        answers: answers,
        timeTakenSeconds: timeTakenSeconds,
      ),
    );
  }

  @override
  Future<Either<Failure, List<Submission>>> getSubmissions(String userId) {
    return execute(() => remote.getSubmissions(userId));
  }

  @override
  Future<Either<Failure, Submission>> getSubmissionById(
    String submissionId,
    String quizId,
  ) {
    return execute(() => remote.getSubmissionById(submissionId, quizId));
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getLeaderboard(
    String quizId,
  ) {
    return execute(() => remote.getLeaderboard(quizId));
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getGlobalLeaderboard() {
    return execute(() => remote.getGlobalLeaderboard());
  }

  @override
  Future<Either<Failure, QuizAttemptModel>> startAttempt(
    String quizId,
    String userId,
    int questionsPerAttempt,
    bool randomizeQuestions,
  ) {
    return execute(
      () => remote.startAttempt(
        quizId,
        userId,
        questionsPerAttempt,
        randomizeQuestions,
      ),
    );
  }

  @override
  Future<Either<Failure, void>> updateAttemptProgress(
    String attemptId,
    Map<String, String> answers,
    int currentQuestionIndex,
  ) {
    return execute(
      () => remote.updateAttemptProgress(
        attemptId,
        answers,
        currentQuestionIndex,
      ),
    );
  }

  @override
  Future<Either<Failure, List<Question>>> getQuestionsByIds(
    String quizId,
    List<String> questionIds,
  ) {
    return execute(() => remote.getQuestionsByIds(quizId, questionIds));
  }
}
