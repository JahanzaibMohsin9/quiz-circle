import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/models/quiz_attempt_model.dart';
import '../repositories/quiz_repository.dart';

class StartQuizAttempt implements UseCase<QuizAttemptModel, StartQuizAttemptParams> {
  final QuizRepository repository;

  StartQuizAttempt(this.repository);

  @override
  Future<Either<Failure, QuizAttemptModel>> call(StartQuizAttemptParams params) {
    return repository.startAttempt(
      params.quizId, 
      params.userId, 
      params.questionsPerAttempt, 
      params.randomizeQuestions
    );
  }
}

class StartQuizAttemptParams {
  final String quizId;
  final String userId;
  final int questionsPerAttempt;
  final bool randomizeQuestions;

  const StartQuizAttemptParams({
    required this.quizId,
    required this.userId,
    required this.questionsPerAttempt,
    required this.randomizeQuestions,
  });
}
