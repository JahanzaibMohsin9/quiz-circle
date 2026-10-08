import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../quiz/domain/entities/quiz_permissions.dart';
import '../entities/permission_audit.dart';
import '../repositories/admin_repository.dart';

class PermissionService {
  final AdminRepository _repository;

  PermissionService(this._repository);

  Future<Either<Failure, void>> grantPermission({
    required String quizId,
    required String userId,
    required String grantedBy,
    String? reason,
  }) async {
    try {
      // Get current permissions
      final currentResult = await _repository.getQuizPermissions(quizId);
      return currentResult.fold((failure) => Left(failure), (
        permissions,
      ) async {
        // Update permissions
        final updatedPermissions = permissions.copyWith(
          userSpecificPermissions: {
            ...permissions.userSpecificPermissions,
            userId: PermissionDetails(
              hasAccess: true,
              grantedAt: DateTime.now(),
              grantedBy: grantedBy,
            ),
          },
        );

        // Save updated permissions
        final result = await _repository.updateQuizPermissions(
          quizId,
          updatedPermissions,
        );

        // Log the permission change
        if (result.isRight()) {
          await _logPermissionChange(
            quizId: quizId,
            userId: userId,
            action: PermissionAction.granted,
            performedBy: grantedBy,
            reason: reason,
          );
        }

        return result;
      });
    } catch (e) {
      return Left(ServerFailure('Failed to grant permission: $e'));
    }
  }

  Future<Either<Failure, void>> revokePermission({
    required String quizId,
    required String userId,
    required String revokedBy,
    String? reason,
  }) async {
    try {
      final currentResult = await _repository.getQuizPermissions(quizId);
      return currentResult.fold((failure) => Left(failure), (
        permissions,
      ) async {
        final updatedPermissions = permissions.copyWith(
          userSpecificPermissions: {
            ...permissions.userSpecificPermissions,
            userId: PermissionDetails(
              hasAccess: false,
              grantedAt: permissions.userSpecificPermissions[userId]?.grantedAt,
              grantedBy: permissions.userSpecificPermissions[userId]?.grantedBy,
            ),
          },
        );

        final result = await _repository.updateQuizPermissions(
          quizId,
          updatedPermissions,
        );

        if (result.isRight()) {
          await _logPermissionChange(
            quizId: quizId,
            userId: userId,
            action: PermissionAction.revoked,
            performedBy: revokedBy,
            reason: reason,
          );
        }

        return result;
      });
    } catch (e) {
      return Left(ServerFailure('Failed to revoke permission: $e'));
    }
  }

  Future<Either<Failure, void>> grantBulkPermissions({
    required String quizId,
    required List<String> userIds,
    required String grantedBy,
    String? reason,
  }) async {
    try {
      final currentResult = await _repository.getQuizPermissions(quizId);
      return currentResult.fold((failure) => Left(failure), (
        permissions,
      ) async {
        final updatedPermissions = permissions.copyWith(
          allowedUserIds: {...permissions.allowedUserIds, ...userIds},
        );

        final result = await _repository.updateQuizPermissions(
          quizId,
          updatedPermissions,
        );

        if (result.isRight()) {
          for (final userId in userIds) {
            await _logPermissionChange(
              quizId: quizId,
              userId: userId,
              action: PermissionAction.bulkGranted,
              performedBy: grantedBy,
              reason: reason,
            );
          }
        }

        return result;
      });
    } catch (e) {
      return Left(ServerFailure('Failed to grant bulk permissions: $e'));
    }
  }

  Future<Either<Failure, bool>> hasPermission({
    required String quizId,
    required String userId,
    required String userRole,
  }) async {
    try {
      final result = await _repository.getQuizPermissions(quizId);
      return result.fold(
        (failure) => Left(failure),
        (permissions) => Right(permissions.hasPermission(userId, userRole)),
      );
    } catch (e) {
      return Left(ServerFailure('Failed to check permission: $e'));
    }
  }

  Future<Either<Failure, void>> setScheduledPermissions({
    required String quizId,
    required DateTime availableFrom,
    required DateTime availableUntil,
    required String updatedBy,
  }) async {
    try {
      final currentResult = await _repository.getQuizPermissions(quizId);
      return currentResult.fold((failure) => Left(failure), (
        permissions,
      ) async {
        final updatedPermissions = permissions.copyWith(          availableFrom: availableFrom,
          availableUntil: availableUntil,
        );

        return await _repository.updateQuizPermissions(
          quizId,
          updatedPermissions,
        );
      });
    } catch (e) {
      return Left(ServerFailure('Failed to set scheduled permissions: $e'));
    }
  }

  Future<void> _logPermissionChange({
    required String quizId,
    required String userId,
    required PermissionAction action,
    required String performedBy,
    String? reason,
  }) async {
    try {
      final audit = PermissionAudit(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        quizId: quizId,
        userId: userId,
        action: action,
        performedBy: performedBy,
        oldValues: const {}, // Could be populated if needed
        newValues: {'action': action.name},
        timestamp: DateTime.now(),
        reason: reason,
      );

      await _repository.logPermissionChange(audit);
    } catch (e) {
      // Log error but don't fail the main operation
      // Error is silently handled to not disrupt the main permission operation
    }
  }
}
