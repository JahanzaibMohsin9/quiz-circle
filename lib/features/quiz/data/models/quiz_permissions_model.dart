import '../../domain/entities/quiz_permissions.dart';

class QuizPermissionsModel extends QuizPermissions {
  const QuizPermissionsModel({
    required super.quizId,
    super.allowedUserIds,
    super.allowedRoles,
    super.availableFrom,
    super.availableUntil,
    super.maxAttempts,
    super.userSpecificPermissions,
  });

  factory QuizPermissionsModel.fromJson(
    Map<String, dynamic> json, {
    String quizId = '',
  }) {
    return QuizPermissionsModel(
      quizId: quizId,
      allowedUserIds:
          (json['allowedUserIds'] as List?)?.map((e) => e as String).toSet() ??
          {},
      allowedRoles:
          (json['allowedRoles'] as List?)?.map((e) => e as String).toSet() ??
          {'student'},
      availableFrom: json['availableFrom'] != null
          ? DateTime.parse(json['availableFrom'] as String)
          : null,
      availableUntil: json['availableUntil'] != null
          ? DateTime.parse(json['availableUntil'] as String)
          : null,
      maxAttempts: json['maxAttempts'] as int? ?? 1,
      userSpecificPermissions:
          (json['userSpecificPermissions'] as Map<String, dynamic>?)?.map(
            (key, value) =>
                MapEntry(key, PermissionDetailsModel.fromJson(value)),
          ) ??
          {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allowedUserIds': allowedUserIds.toList(),
      'allowedRoles': allowedRoles.toList(),
      'availableFrom': availableFrom?.toIso8601String(),
      'availableUntil': availableUntil?.toIso8601String(),
      'maxAttempts': maxAttempts,
      'userSpecificPermissions': userSpecificPermissions.map(
        (key, value) =>
            MapEntry(key, (value as PermissionDetailsModel).toJson()),
      ),
    };
  }

  factory QuizPermissionsModel.fromEntity(QuizPermissions entity) {
    return QuizPermissionsModel(
      quizId: entity.quizId,
      allowedUserIds: entity.allowedUserIds,
      allowedRoles: entity.allowedRoles,
      availableFrom: entity.availableFrom,
      availableUntil: entity.availableUntil,
      maxAttempts: entity.maxAttempts,
      userSpecificPermissions: entity.userSpecificPermissions.map(
        (key, value) => MapEntry(key, PermissionDetailsModel.fromEntity(value)),
      ),
    );
  }
}

class PermissionDetailsModel extends PermissionDetails {
  const PermissionDetailsModel({
    required super.hasAccess,
    super.attemptsUsed,
    super.lastAttemptAt,
    super.grantedAt,
    super.grantedBy,
  });

  factory PermissionDetailsModel.fromJson(Map<String, dynamic> json) {
    return PermissionDetailsModel(
      hasAccess: json['hasAccess'] as bool,
      attemptsUsed: json['attemptsUsed'] as int? ?? 0,
      lastAttemptAt: json['lastAttemptAt'] != null
          ? DateTime.parse(json['lastAttemptAt'] as String)
          : null,
      grantedAt: json['grantedAt'] != null
          ? DateTime.parse(json['grantedAt'] as String)
          : null,
      grantedBy: json['grantedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hasAccess': hasAccess,
      'attemptsUsed': attemptsUsed,
      'lastAttemptAt': lastAttemptAt?.toIso8601String(),
      'grantedAt': grantedAt?.toIso8601String(),
      'grantedBy': grantedBy,
    };
  }

  factory PermissionDetailsModel.fromEntity(PermissionDetails entity) {
    return PermissionDetailsModel(
      hasAccess: entity.hasAccess,
      attemptsUsed: entity.attemptsUsed,
      lastAttemptAt: entity.lastAttemptAt,
      grantedAt: entity.grantedAt,
      grantedBy: entity.grantedBy,
    );
  }
}
