import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../quiz/domain/entities/quiz.dart';
import '../repositories/admin_repository.dart';

class SetQuizActive implements UseCase<Quiz, SetQuizActiveParams> {
  final AdminRepository repository;
  SetQuizActive(this.repository);

  @override
  Future<Either<Failure, Quiz>> call(SetQuizActiveParams params) {
    return repository.setQuizActive(params.id, params.isActive);
  }
}

class SetQuizActiveParams {
  final String id;
  final bool isActive;
  const SetQuizActiveParams(this.id, this.isActive);
}

