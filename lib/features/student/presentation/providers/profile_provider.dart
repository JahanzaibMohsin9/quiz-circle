import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../../authentication/domain/entities/user.dart';
import '../../../authentication/presentation/providers/auth_usecases.dart';
import '../../../../core/usecases/usecase.dart';

class ProfileState {
  final User? user;
  final int? quizzesTaken;
  final bool isLoading;
  final String? error;

  const ProfileState({
    this.user,
    this.quizzesTaken,
    this.isLoading = false,
    this.error,
  });

  const ProfileState.initial() : this(isLoading: false);

  ProfileState copyWith({
    User? user,
    int? quizzesTaken,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      user: user ?? this.user,
      quizzesTaken: quizzesTaken ?? this.quizzesTaken,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  T when<T>({
    required T Function(User user, int quizzesTaken) data,
    required T Function() loading,
    required T Function(String error) error,
  }) {
    if (isLoading) {
      return loading();
    } else if (this.error != null) {
      return error(this.error!);
    } else if (user != null) {
      return data(user!, quizzesTaken ?? 0);
    } else {
      throw Exception('Invalid state');
    }
  }
}

class ProfileNotifier extends Notifier<ProfileState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  @override
  ProfileState build() {
    Future.microtask(() => loadProfile());
    return const ProfileState.initial();
  }

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final getCurrentUserUseCase = ref.read(getCurrentUserUseCaseProvider);
      final result = await getCurrentUserUseCase.call(const NoParams());
      
      await result.fold(
        (failure) async {
          state = state.copyWith(
            isLoading: false,
            error: failure.message,
          );
        },
        (user) async {
          // Fetch the actual number of quizzes taken from submissions
          final quizzesTaken = await _getQuizzesTaken(user?.id);
          
          state = state.copyWith(
            isLoading: false,
            user: user,
            quizzesTaken: quizzesTaken,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load profile: $e',
      );
    }
  }

  Future<int> _getQuizzesTaken(String? userId) async {
    if (userId == null) return 0;
    
    try {
      final submissionsSnapshot = await _firestore
          .collection('submissions')
          .where('userId', isEqualTo: userId)
          .where('completed', isEqualTo: true)
          .get();
      
      return submissionsSnapshot.docs.length;
    } catch (e) {
      // Return 0 if there's an error fetching submissions
      return 0;
    }
  }

  Future<void> updateProfile(String name) async {
    state = state.copyWith(isLoading: true);
    
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'User not authenticated',
        );
        return;
      }

      await _firestore.collection('users').doc(currentUser.uid).update({
        'name': name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final updatedUser = state.user?.copyWith(name: name);
      state = state.copyWith(isLoading: false, user: updatedUser);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update profile: $e',
      );
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    state = state.copyWith(isLoading: true);
    
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'User not authenticated',
        );
        return;
      }

      // Re-authenticate user
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: currentUser.email!,
        password: currentPassword,
      );
      await currentUser.reauthenticateWithCredential(credential);

      // Update password
      await currentUser.updatePassword(newPassword);
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to change password: $e',
      );
    }
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, ProfileState>(() {
  return ProfileNotifier();
});