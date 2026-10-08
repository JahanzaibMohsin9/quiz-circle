import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/admin_user.dart';
import 'admin_usecases.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/block_user.dart';
import '../../domain/usecases/update_user_access.dart';
import '../../domain/usecases/get_user_analytics.dart';
import '../../../authentication/domain/entities/user.dart';

class AdminUserState {
  final List<AdminUser> users;
  final bool isLoading;
  final String? error;
  const AdminUserState({this.users = const [], this.isLoading = false, this.error});

  AdminUserState copyWith({List<AdminUser>? users, bool? isLoading, String? error}) {
    return AdminUserState(users: users ?? this.users, isLoading: isLoading ?? this.isLoading, error: error);
  }
}

class AdminUserController extends Notifier<AdminUserState> {
  @override
  AdminUserState build() {
    // Load users when provider is first created
    Future.microtask(() => loadUsers());
    return const AdminUserState();
  }

  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true);
    final usecase = ref.read(getAdminUsersUseCaseProvider);
    final result = await usecase.call(const NoParams());
    state = result.fold(
      (l) => state.copyWith(isLoading: false, error: l.message),
      (users) => AdminUserState(users: users),
    );
  }

  Future<void> blockUser(String userId, bool block) async {
    state = state.copyWith(isLoading: true);
    final usecase = ref.read(blockUserUseCaseProvider);
    final result = await usecase.call(BlockUserParams(userId, block));
    state = result.fold(
      (l) => state.copyWith(isLoading: false, error: l.message),
      (_) => state.copyWith(isLoading: false),
    );
    await loadUsers();
  }

  Future<void> updateUserRole(String userId, String role) async {
    state = state.copyWith(isLoading: true);
    final usecase = ref.read(updateUserAccessUseCaseProvider);
    final result = await usecase.call(UpdateUserAccessParams(userId, role == 'admin' ? UserRole.admin : UserRole.student));
    state = result.fold(
      (l) => state.copyWith(isLoading: false, error: l.message),
      (_) => state.copyWith(isLoading: false),
    );
    await loadUsers();
  }

  Future<void> loadUserAnalytics(String userId) async {
    state = state.copyWith(isLoading: true);
    final usecase = ref.read(getUserAnalyticsUseCaseProvider);
    final result = await usecase.call(GetUserAnalyticsParams(userId));
    state = result.fold(
      (l) => state.copyWith(isLoading: false, error: l.message),
      (updated) {
        final list = List<AdminUser>.from(state.users);
        final index = list.indexWhere((u) => u.id == userId);
        if (index != -1) list[index] = updated;
        return AdminUserState(users: list);
      },
    );
  }
}

final adminUserProvider = NotifierProvider<AdminUserController, AdminUserState>(() {
  return AdminUserController();
});

