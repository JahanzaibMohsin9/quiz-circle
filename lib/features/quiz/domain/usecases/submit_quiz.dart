import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/submission.dart';
import '../repositories/quiz_repository.dart';

class SubmitQuizParams extends Equatable {
  final String quizId;
  final String quizTitle;
  final String userId;
  final Map<String, String> answers; // questionId -> selectedAnswer
  final int timeTakenSeconds;

  const SubmitQuizParams({
    required this.quizId,
    required this.quizTitle,
    required this.userId,
    required this.answers,
    required this.timeTakenSeconds,
  });

  @override
  List<Object?> get props => [
    quizId,
    quizTitle,
    userId,
    answers,
    timeTakenSeconds,
  ];
}

class SubmitQuiz implements UseCase<Submission, SubmitQuizParams> {
  final QuizRepository repo;

  SubmitQuiz(this.repo);

  @override
  Future<Either<Failure, Submission>> call(SubmitQuizParams params) {
    return repo.submitQuiz(
      quizId: params.quizId,
      quizTitle: params.quizTitle,
      userId: params.userId,
      answers: params.answers,
      timeTakenSeconds: params.timeTakenSeconds,
    );
  }
}
