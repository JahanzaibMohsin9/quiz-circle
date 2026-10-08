import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/admin_repository.dart';

class DeleteQuiz implements UseCase<void, DeleteQuizParams> {
  final AdminRepository repository;
  DeleteQuiz(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteQuizParams params) {
    return repository.deleteQuiz(params.id);
  }
}

class DeleteQuizParams {
  final String id;
  const DeleteQuizParams(this.id);
}

