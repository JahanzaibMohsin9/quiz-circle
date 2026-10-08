import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../authentication/domain/entities/user.dart';
import '../../domain/entities/admin_user.dart';
import '../../domain/repositories/admin_repository.dart';

class UpdateUserAccess implements UseCase<AdminUser, UpdateUserAccessParams> {
  final AdminRepository repository;
  UpdateUserAccess(this.repository);

  @override
  Future<Either<Failure, AdminUser>> call(UpdateUserAccessParams params) {
    return repository.updateUserAccess(params.userId, params.role);
  }
}

class UpdateUserAccessParams {
  final String userId;
  final UserRole role;
  const UpdateUserAccessParams(this.userId, this.role);
}

