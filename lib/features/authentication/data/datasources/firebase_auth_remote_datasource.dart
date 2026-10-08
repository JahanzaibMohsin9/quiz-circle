import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/errors/exceptions.dart';
import 'auth_remote_datasource.dart';

class FirebaseAuthRemoteDataSource implements AuthRemoteDataSource {
  final firebase_auth.FirebaseAuth _auth = FirebaseService.instance.auth;
  final FirebaseFirestore _firestore = FirebaseService.instance.firestore;

  FirebaseAuthRemoteDataSource();

  @override
  Future<User> signIn(String email, String password) async {
    try {
      // Sign in with Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw const ServerException('User not found');
      }

      // Get user data from Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        // Create user document if it doesn't exist - Default to student for security
        final newUser = User(
          id: firebaseUser.uid,
          name: email.split('@').first,
          email: email,
          role: UserRole.student,
          createdAt: DateTime.now(), // Set creation timestamp
        );
        await _createUserDocument(newUser);
        return newUser;
      }

      // Update lastLoginAt for existing user
      await _updateLastLoginAt(firebaseUser.uid);

      // Return existing user
      return User.fromJson(userDoc.data()!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw ServerException(_getFirebaseAuthErrorMessage(e));
    } catch (e) {
      throw ServerException('Authentication failed: ${e.toString()}');
    }
  }

  @override
  Future<User> signUp(String name, String email, String password) async {
    try {
      // Create user with Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw const ServerException('Failed to create user');
      }

      // Create user document in Firestore
      final newUser = User(
        id: firebaseUser.uid,
        name: name,
        email: email,
        role: UserRole.student, // Default role for new registrations
        createdAt: DateTime.now(), // Set creation timestamp
      );

      await _createUserDocument(newUser);
      return newUser;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw ServerException(_getFirebaseAuthErrorMessage(e));
    } catch (e) {
      throw ServerException('Registration failed: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw ServerException('Sign out failed: ${e.toString()}');
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return null;

      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();
      if (!userDoc.exists) return null;

      return User.fromJson(userDoc.data()!);
    } catch (e) {
      throw ServerException('Failed to get current user: ${e.toString()}');
    }
  }

  Future<void> _createUserDocument(User user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toJson());
    } catch (e) {
      throw ServerException('Failed to create user document: ${e.toString()}');
    }
  }

  Future<void> _updateLastLoginAt(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Don't throw an exception here as this is not critical for sign in
    }
  }

  String _getFirebaseAuthErrorMessage(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'operation-not-allowed':
        return 'Signing in with Email and Password is not enabled.';
      default:
        return 'An authentication error occurred: ${e.message}';
    }
  }
}
