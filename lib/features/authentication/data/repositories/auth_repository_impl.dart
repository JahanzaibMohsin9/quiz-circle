import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/repositories/base_repository.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl extends BaseRepository implements AuthRepository {
  final AuthRemoteDataSource remote;

  AuthRepositoryImpl({required NetworkInfo networkInfo, required this.remote}) : super(networkInfo);

  @override
  Future<Either<Failure, User>> signIn(String email, String password) {
    return execute(() => remote.signIn(email, password));
  }

  @override
  Future<Either<Failure, User>> signUp(String name, String email, String password) {
    return execute(() => remote.signUp(name, email, password));
  }

  @override
  Future<Either<Failure, void>> signOut() {
    return execute(() => remote.signOut());
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() {
    return execute(() => remote.getCurrentUser());
  }
}

