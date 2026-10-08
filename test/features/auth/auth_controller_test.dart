import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quiz_circle/features/authentication/domain/entities/user.dart';
import 'package:quiz_circle/core/errors/failures.dart';
import 'package:quiz_circle/features/authentication/domain/repositories/auth_repository.dart';
import 'package:quiz_circle/features/authentication/presentation/providers/auth_provider.dart';
import 'package:quiz_circle/features/authentication/presentation/providers/auth_repository_provider.dart';

class FakeAuthRepository implements AuthRepository {
  bool shouldFail = false;
  Failure failure = const AuthenticationFailure('Auth failed');

  @override
  Future<Either<Failure, User>> signIn(String email, String password) async {
    if (shouldFail) return Left(failure);
    return Right(
      User(id: 'u1', name: 'Test', email: email, role: UserRole.student),
    );
  }

  @override
  Future<Either<Failure, User>> signUp(
    String name,
    String email,
    String password,
  ) async {
    if (shouldFail) return Left(failure);
    return Right(
      User(id: 'u2', name: name, email: email, role: UserRole.student),
    );
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    if (shouldFail) return Left(failure);
    return const Right(null);
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    if (shouldFail) return Left(failure);
    return const Right(null);
  }
}

void main() {
  group('AuthController', () {
    test('signIn success updates state and persists', () async {
      SharedPreferences.setMockInitialValues({});
      final fakeRepo = FakeAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authProvider.notifier);
      await notifier.signIn('user@domain.com', 'Passw0rd');
      final state = container.read(authProvider);
      expect(state.isAuthenticated, true);
      expect(state.role, UserRole.student);
      expect(state.userId, 'u1');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('is_authenticated'), true);
      expect(prefs.getString('user_role'), 'student');
      expect(prefs.getString('user_id'), 'u1');
    });

    test('signIn failure sets error', () async {
      SharedPreferences.setMockInitialValues({});
      final fakeRepo = FakeAuthRepository()..shouldFail = true;
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authProvider.notifier);
      await notifier.signIn('user@domain.com', 'bad');
      final state = container.read(authProvider);
      expect(state.isAuthenticated, false);
      expect(state.error, 'Auth failed');
      expect(state.isLoading, false);
    });

    test('register success updates state', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authProvider.notifier);
      await notifier.register('Alice', 'alice@domain.com', 'Passw0rd');
      final state = container.read(authProvider);
      expect(state.isAuthenticated, true);
      expect(state.userId, 'u2');
    });

    test('signOut resets state and clears persistence', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authProvider.notifier);
      await notifier.signIn('user@domain.com', 'Passw0rd');
      await notifier.signOut();
      final state = container.read(authProvider);
      expect(state.isAuthenticated, false);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('is_authenticated'), isNull);
      expect(prefs.getString('user_role'), isNull);
      expect(prefs.getString('user_id'), isNull);
    });

    test('restores auth state from SharedPreferences on build', () async {
      SharedPreferences.setMockInitialValues({
        'is_authenticated': true,
        'user_role': 'admin',
        'user_id': 'u100',
      });
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
      );
      addTearDown(container.dispose);

      // Allow async restoration to complete
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final state = container.read(authProvider);
      expect(state.isAuthenticated, true);
      expect(state.role, UserRole.admin);
      expect(state.userId, 'u100');
    });
  });
}
