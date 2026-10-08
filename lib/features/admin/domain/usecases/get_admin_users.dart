import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/admin_user.dart';
import '../repositories/admin_repository.dart';

class GetAdminUsers implements UseCase<List<AdminUser>, NoParams> {
  final AdminRepository repository;
  GetAdminUsers(this.repository);

  @override
  Future<Either<Failure, List<AdminUser>>> call(NoParams params) {
    return repository.getUsers();
  }
}

