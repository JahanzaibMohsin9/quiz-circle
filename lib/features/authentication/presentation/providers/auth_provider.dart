import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user.dart';
import 'auth_usecases.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_up.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../student/presentation/providers/profile_provider.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final UserRole? role;
  final String? userId;

  const AuthState({
    required this.isAuthenticated,
    this.isLoading = false,
    this.error,
    this.role,
    this.userId,
  });

  const AuthState.initial() : this(isAuthenticated: false);

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    UserRole? role,
    String? userId,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      role: role ?? this.role,
      userId: userId ?? this.userId,
    );
  }
}

class AuthController extends Notifier<AuthState> {
  static const String _keyIsAuthenticated = 'is_authenticated';
  static const String _keyUserRole = 'user_role';
  static const String _keyUserId = 'user_id';

  @override
  AuthState build() {
    // Attempt to restore authentication state
    _restoreAuthState();
    return const AuthState.initial();
  }

  Future<void> _restoreAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isAuthenticated = prefs.getBool(_keyIsAuthenticated) ?? false;

      if (isAuthenticated) {
        final roleString = prefs.getString(_keyUserRole);
        final userId = prefs.getString(_keyUserId);

        if (roleString != null && userId != null) {
          final role = roleString == 'admin'
              ? UserRole.admin
              : UserRole.student;
          state = AuthState(isAuthenticated: true, role: role, userId: userId);
        }
      }
    } catch (e) {
      // If restoration fails, keep initial state
      state = const AuthState.initial();
    }
  }

  Future<void> _saveAuthState(UserRole role, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsAuthenticated, true);
      await prefs.setString(
        _keyUserRole,
        role == UserRole.admin ? 'admin' : 'student',
      );
      await prefs.setString(_keyUserId, userId);
    } catch (e) {
      // Silently fail - auth will still work for current session
    }
  }

  Future<void> _clearAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyIsAuthenticated);
      await prefs.remove(_keyUserRole);
      await prefs.remove(_keyUserId);
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true);
    final usecase = ref.read(signInUseCaseProvider);
    final result = await usecase.call(SignInParams(email, password));
    await result.fold(
      (l) async {
        state = state.copyWith(isLoading: false, error: l.message);
      },
      (user) async {
        await _saveAuthState(user.role, user.id);
        state = AuthState(
          isAuthenticated: true,
          role: user.role,
          userId: user.id,
        );
        // Invalidate current user provider to fetch fresh user data
        ref.invalidate(currentUserProvider);
      },
    );
  }

  Future<void> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true);
    final usecase = ref.read(signUpUseCaseProvider);
    final result = await usecase.call(SignUpParams(name, email, password));
    await result.fold(
      (l) async {
        state = state.copyWith(isLoading: false, error: l.message);
      },
      (user) async {
        await _saveAuthState(user.role, user.id);
        state = AuthState(
          isAuthenticated: true,
          role: user.role,
          userId: user.id,
        );
        // Invalidate providers to fetch fresh user data
        ref.invalidate(currentUserProvider);
        ref.invalidate(profileProvider);
      },
    );
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    final usecase = ref.read(signOutUseCaseProvider);
    final result = await usecase.call(const NoParams());
    await result.fold(
      (l) async {
        state = state.copyWith(isLoading: false, error: l.message);
      },
      (_) async {
        await _clearAuthState();
        state = const AuthState.initial();
        // Invalidate providers to clear cached user data
        ref.invalidate(currentUserProvider);
        ref.invalidate(profileProvider);
      },
    );
  }
}

final authProvider = NotifierProvider<AuthController, AuthState>(() {
  return AuthController();
});

// Current user provider
final currentUserProvider = FutureProvider<User?>((ref) async {
  final usecase = ref.read(getCurrentUserUseCaseProvider);
  final result = await usecase.call(const NoParams());
  return result.fold((_) => null, (user) => user);
});
