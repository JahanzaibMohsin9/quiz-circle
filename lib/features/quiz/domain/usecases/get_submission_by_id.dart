import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/submission.dart';
import '../repositories/quiz_repository.dart';

class GetSubmissionById
    implements UseCase<Submission, GetSubmissionByIdParams> {
  final QuizRepository repository;

  GetSubmissionById(this.repository);

  @override
  Future<Either<Failure, Submission>> call(
    GetSubmissionByIdParams params,
  ) async {
    return await repository.getSubmissionById(
      params.submissionId,
      params.quizId,
    );
  }
}

class GetSubmissionByIdParams {
  final String submissionId;
  final String quizId;

  const GetSubmissionByIdParams({
    required this.submissionId,
    required this.quizId,
  });
}
