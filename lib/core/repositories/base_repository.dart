import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../errors/failures.dart';
import '../network/network_info.dart';

typedef Result<T> = Either<Failure, T>;

abstract class BaseRepository {
  final NetworkInfo networkInfo;
  const BaseRepository(this.networkInfo);

  /// IMPROVED: Specific error handling instead of generic UnknownFailure
  /// This provides better error context for debugging and user feedback
  Future<Result<T>> execute<T>(Future<T> Function() action) async {
    final connected = await networkInfo.isConnected;
    if (!connected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final data = await action();
      return Right(data);
    } on FirebaseException catch (e) {
      // Handle Firebase-specific errors with error codes
      return Left(FirebaseFailure(
        e.message ?? 'Firebase error occurred',
        e.code,
      ));
    } on TimeoutException catch (e) {
      // Handle timeout errors
      return Left(TimeoutFailure(
        e.message ?? 'Request timed out',
      ));
    } on FormatException catch (e) {
      // Handle data parsing errors
      return Left(ParseFailure(
        'Invalid data format: ${e.message}',
      ));
    } on ArgumentError catch (e) {
      // Handle validation errors
      return Left(ValidationFailure(
        e.message?.toString() ?? 'Invalid argument',
      ));
    } catch (e) {
      // Fallback for unexpected errors
      return Left(UnknownFailure(e.toString()));
    }
  }
}

