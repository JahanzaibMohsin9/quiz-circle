/// Base exception class for all custom exceptions
abstract class AppException implements Exception {
  final String message;
  final String code;
  
  const AppException(this.message, this.code);
  
  @override
  String toString() => 'AppException: $message (Code: $code)';
}

/// Server-related exceptions
class ServerException extends AppException {
  const ServerException(super.message, [super.code = 'server_error']);
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException(super.message, [super.code = 'network_error']);
}

/// Authentication-related exceptions
class AuthenticationException extends AppException {
  const AuthenticationException(super.message, [super.code = 'auth_error']);
}

/// Authorization-related exceptions
class AuthorizationException extends AppException {
  const AuthorizationException(super.message, [super.code = 'authz_error']);
}

/// Validation-related exceptions
class ValidationException extends AppException {
  const ValidationException(super.message, [super.code = 'validation_error']);
}

/// Data parsing exceptions
class ParseException extends AppException {
  const ParseException(super.message, [super.code = 'parse_error']);
}

/// Cache-related exceptions
class CacheException extends AppException {
  const CacheException(super.message, [super.code = 'cache_error']);
}

/// File-related exceptions
class FileException extends AppException {
  const FileException(super.message, [super.code = 'file_error']);
}

/// Firebase-specific exceptions
class FirebaseException extends AppException {
  const FirebaseException(super.message, [super.code = 'firebase_error']);
}

/// Quiz-specific exceptions
class QuizException extends AppException {
  const QuizException(super.message, [super.code = 'quiz_error']);
}

/// User-specific exceptions
class UserException extends AppException {
  const UserException(super.message, [super.code = 'user_error']);
}