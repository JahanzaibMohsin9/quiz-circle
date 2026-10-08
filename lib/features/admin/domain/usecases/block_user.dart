import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/admin_user.dart';
import '../../domain/repositories/admin_repository.dart';

class BlockUser implements UseCase<AdminUser, BlockUserParams> {
  final AdminRepository repository;
  BlockUser(this.repository);

  @override
  Future<Either<Failure, AdminUser>> call(BlockUserParams params) {
    return repository.blockUser(params.userId, params.block);
  }
}

class BlockUserParams {
  final String userId;
  final bool block;
  const BlockUserParams(this.userId, this.block);
}

