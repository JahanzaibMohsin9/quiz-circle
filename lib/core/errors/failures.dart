import 'package:equatable/equatable.dart';

/// Base failure class for all failures in the domain layer
abstract class Failure extends Equatable {
  final String message;
  final String code;
  
  const Failure(this.message, this.code);
  
  @override
  List<Object> get props => [message, code];
  
  @override
  String toString() => 'Failure: $message (Code: $code)';
}

/// Server failures
class ServerFailure extends Failure {
  const ServerFailure(super.message, [super.code = 'server_failure']);
}

/// Network failures
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, [super.code = 'network_failure']);
}

/// Authentication failures
class AuthenticationFailure extends Failure {
  const AuthenticationFailure(super.message, [super.code = 'auth_failure']);
}

/// Authorization failures
class AuthorizationFailure extends Failure {
  const AuthorizationFailure(super.message, [super.code = 'authz_failure']);
}

/// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, [super.code = 'validation_failure']);
}

/// Cache failures
class CacheFailure extends Failure {
  const CacheFailure(super.message, [super.code = 'cache_failure']);
}

/// File failures
class FileFailure extends Failure {
  const FileFailure(super.message, [super.code = 'file_failure']);
}

/// Firebase failures
class FirebaseFailure extends Failure {
  const FirebaseFailure(super.message, [super.code = 'firebase_failure']);
}

/// Quiz failures
class QuizFailure extends Failure {
  const QuizFailure(super.message, [super.code = 'quiz_failure']);
}

/// User failures
class UserFailure extends Failure {
  const UserFailure(super.message, [super.code = 'user_failure']);
}

/// Unknown failures for unexpected errors
class UnknownFailure extends Failure {
  const UnknownFailure(super.message, [super.code = 'unknown_failure']);
}

/// Permission failures
class PermissionFailure extends Failure {
  const PermissionFailure(super.message, [super.code = 'permission_failure']);
}

/// Timeout failures
class TimeoutFailure extends Failure {
  const TimeoutFailure(super.message, [super.code = 'timeout_failure']);
}

/// Data parsing failures
class ParseFailure extends Failure {
  const ParseFailure(super.message, [super.code = 'parse_failure']);
}