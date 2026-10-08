import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/sign_in.dart' as u1;
import '../../domain/usecases/sign_up.dart' as u2;
import '../../domain/usecases/sign_out.dart' as u3;
import '../../domain/usecases/get_current_user.dart' as u4;
import 'auth_repository_provider.dart';

final signInUseCaseProvider = Provider<u1.SignIn>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return u1.SignIn(repo);
});

final signUpUseCaseProvider = Provider<u2.SignUp>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return u2.SignUp(repo);
});

final signOutUseCaseProvider = Provider<u3.SignOut>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return u3.SignOut(repo);
});

final getCurrentUserUseCaseProvider = Provider<u4.GetCurrentUser>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return u4.GetCurrentUser(repo);
});

