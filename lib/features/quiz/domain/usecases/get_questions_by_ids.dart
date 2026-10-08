import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/question.dart';
import '../repositories/quiz_repository.dart';

class GetQuestionsByIds implements UseCase<List<Question>, GetQuestionsByIdsParams> {
  final QuizRepository repository;

  GetQuestionsByIds(this.repository);

  @override
  Future<Either<Failure, List<Question>>> call(GetQuestionsByIdsParams params) {
    return repository.getQuestionsByIds(params.quizId, params.questionIds);
  }
}

class GetQuestionsByIdsParams {
  final String quizId;
  final List<String> questionIds;

  const GetQuestionsByIdsParams({
    required this.quizId,
    required this.questionIds,
  });
}
