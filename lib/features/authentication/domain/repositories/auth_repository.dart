import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> signIn(String email, String password);
  Future<Either<Failure, User>> signUp(String name, String email, String password);
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, User?>> getCurrentUser();
}

