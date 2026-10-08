import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart';
import '../errors/failures.dart';

/// Utility class for handling errors throughout the app
class ErrorHandler {
  /// Show a snackbar with error message
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[400],
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show a success snackbar
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[400],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Handle API errors and show user-friendly messages
  static String getErrorMessage(Failure failure) {
    if (failure is ServerFailure) {
      return 'Server error. Please check your internet connection and try again.';
    } else if (failure is NetworkFailure) {
      return 'No internet connection. Please check your network settings.';
    } else if (failure is CacheFailure) {
      return 'Local data error. Please restart the app.';
    } else if (failure is ValidationFailure) {
      return 'Invalid input. Please check your information and try again.';
    } else if (failure is PermissionFailure) {
      return 'Permission denied. You don\'t have access to this feature.';
    } else if (failure is AuthenticationFailure) {
      return 'Authentication error. Please log in again.';
    } else if (failure is AuthorizationFailure) {
      return 'Access denied. You don\'t have permission to perform this action.';
    } else if (failure is FileFailure) {
      return 'File operation error. Please try again.';
    } else if (failure is FirebaseFailure) {
      return 'Database error. Please try again later.';
    } else if (failure is QuizFailure) {
      return 'Quiz operation error. Please try again.';
    } else if (failure is UserFailure) {
      return 'User operation error. Please try again.';
    } else if (failure is TimeoutFailure) {
      return 'Request timed out. Please check your connection and try again.';
    } else if (failure is ParseFailure) {
      return 'Data parsing error. Please try again.';
    } else {
      return 'An error occurred. Please try again.';
    }
  }

  /// Show a dialog for critical errors
  static void showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Handle and log errors for debugging
  static void logError(String error, {String? context, dynamic data}) {
    debugPrint('ERROR: $error');
    if (context != null) {
      debugPrint('CONTEXT: $context');
    }
    if (data != null) {
      debugPrint('DATA: $data');
    }
  }
}

/// Extension for better error handling in Either types
extension EitherExtension<L, R> on Either<L, R> {
  /// Execute a function and handle errors automatically
  R? foldError(void Function(R) onSuccess) {
    return fold(
      (error) {
        if (error is Failure) {
          ErrorHandler.logError(error.message);
        } else {
          ErrorHandler.logError('Unknown error: $error');
        }
        return null;
      },
      (data) {
        onSuccess(data);
        return null;
      },
    );
  }
}