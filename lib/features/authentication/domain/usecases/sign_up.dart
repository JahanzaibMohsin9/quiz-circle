import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class SignUp implements UseCase<User, SignUpParams> {
  final AuthRepository repo;
  SignUp(this.repo);
  @override
  Future<Either<Failure, User>> call(SignUpParams params) {
    return repo.signUp(params.name, params.email, params.password);
  }
}

class SignUpParams {
  final String name;
  final String email;
  final String password;
  const SignUpParams(this.name, this.email, this.password);
}
