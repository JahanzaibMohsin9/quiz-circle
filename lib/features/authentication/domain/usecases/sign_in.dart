import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class SignIn implements UseCase<User, SignInParams> {
  final AuthRepository repo;
  SignIn(this.repo);
  @override
  Future<Either<Failure, User>> call(SignInParams params) {
    return repo.signIn(params.email, params.password);
  }
}

class SignInParams {
  final String email;
  final String password;
  const SignInParams(this.email, this.password);
}
