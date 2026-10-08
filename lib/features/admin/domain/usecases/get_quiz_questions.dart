import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../quiz/domain/entities/question.dart';
import '../repositories/admin_repository.dart';

class GetQuizQuestions implements UseCase<List<Question>, GetQuizQuestionsParams> {
  final AdminRepository repository;
  GetQuizQuestions(this.repository);

  @override
  Future<Either<Failure, List<Question>>> call(GetQuizQuestionsParams params) {
    return repository.getQuestions(params.quizId);
  }
}

class GetQuizQuestionsParams {
  final String quizId;
  const GetQuizQuestionsParams(this.quizId);
}

