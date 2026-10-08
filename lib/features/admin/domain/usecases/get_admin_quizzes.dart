import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../quiz/domain/entities/quiz.dart';
import '../repositories/admin_repository.dart';

class GetAdminQuizzes implements UseCase<List<Quiz>, NoParams> {
  final AdminRepository repository;
  GetAdminQuizzes(this.repository);

  @override
  Future<Either<Failure, List<Quiz>>> call(NoParams params) {
    return repository.getQuizzes();
  }
}

