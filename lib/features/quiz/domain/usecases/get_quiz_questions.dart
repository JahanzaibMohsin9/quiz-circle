import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/question.dart';
import '../repositories/quiz_repository.dart';

class GetQuizQuestionsParams extends Equatable {
  final String quizId;

  const GetQuizQuestionsParams({required this.quizId});

  @override
  List<Object?> get props => [quizId];
}

class GetQuizQuestions implements UseCase<List<Question>, GetQuizQuestionsParams> {
  final QuizRepository repo;
  
  GetQuizQuestions(this.repo);
  
  @override
  Future<Either<Failure, List<Question>>> call(GetQuizQuestionsParams params) {
    return repo.getQuestions(params.quizId);
  }
}

