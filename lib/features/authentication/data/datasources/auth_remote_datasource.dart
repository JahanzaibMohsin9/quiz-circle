import '../../domain/entities/user.dart';

abstract class AuthRemoteDataSource {
  Future<User> signIn(String email, String password);
  Future<User> signUp(String name, String email, String password);
  Future<void> signOut();
  Future<User?> getCurrentUser();
}

