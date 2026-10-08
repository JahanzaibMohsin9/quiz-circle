import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/quiz.dart';
import '../repositories/quiz_repository.dart';

class GetQuizByIdParams extends Equatable {
  final String quizId;

  const GetQuizByIdParams({required this.quizId});

  @override
  List<Object?> get props => [quizId];
}

class GetQuizById implements UseCase<Quiz, GetQuizByIdParams> {
  final QuizRepository repo;
  
  GetQuizById(this.repo);
  
  @override
  Future<Either<Failure, Quiz>> call(GetQuizByIdParams params) {
    return repo.getQuizById(params.quizId);
  }
}