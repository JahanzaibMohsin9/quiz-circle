import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/quiz.dart';
import '../repositories/quiz_repository.dart';

class GetQuizzes implements UseCase<List<Quiz>, NoParams> {
  final QuizRepository repo;
  GetQuizzes(this.repo);
  @override
  Future<Either<Failure, List<Quiz>>> call(NoParams params) {
    return repo.getQuizzes();
  }
}

