import 'package:equatable/equatable.dart';

class PermissionDetails extends Equatable {
  final bool hasAccess;
  final int attemptsUsed;
  final DateTime? lastAttemptAt;
  final DateTime? grantedAt;
  final String? grantedBy;

  const PermissionDetails({
    required this.hasAccess,
    this.attemptsUsed = 0,
    this.lastAttemptAt,
    this.grantedAt,
    this.grantedBy,
  });

  @override
  List<Object?> get props => [
    hasAccess,
    attemptsUsed,
    lastAttemptAt,
    grantedAt,
    grantedBy,
  ];
}

class QuizPermissions extends Equatable {
  final String quizId;
  final Set<String> allowedUserIds;
  final Set<String> allowedRoles;
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final int maxAttempts;
  final Map<String, PermissionDetails> userSpecificPermissions;

  const QuizPermissions({
    required this.quizId,
    this.allowedUserIds = const {},
    this.allowedRoles = const {'student'},
    this.availableFrom,
    this.availableUntil,
    this.maxAttempts = 1,
    this.userSpecificPermissions = const {},
  });

  bool hasPermission(String userId, String userRole) {
    // 1. Check time-based availability first
    final now = DateTime.now();
    if (availableFrom != null && now.isBefore(availableFrom!)) return false;
    if (availableUntil != null && now.isAfter(availableUntil!)) return false;

    // 2. Check user-specific permissions (highest priority)
    if (userSpecificPermissions.containsKey(userId)) {
      return userSpecificPermissions[userId]!.hasAccess;
    }

    // 3. Check if user is explicitly allowed
    if (allowedUserIds.contains(userId)) return true;

    // 4. Check if user's role is allowed
    if (allowedRoles.contains(userRole)) return true;

    // 5. Default deny
    return false;
  }

  QuizPermissions copyWith({
    String? quizId,
    Set<String>? allowedUserIds,
    Set<String>? allowedRoles,
    DateTime? availableFrom,
    DateTime? availableUntil,
    int? maxAttempts,
    Map<String, PermissionDetails>? userSpecificPermissions,
  }) {
    return QuizPermissions(
      quizId: quizId ?? this.quizId,
      allowedUserIds: allowedUserIds ?? this.allowedUserIds,
      allowedRoles: allowedRoles ?? this.allowedRoles,
      availableFrom: availableFrom ?? this.availableFrom,
      availableUntil: availableUntil ?? this.availableUntil,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      userSpecificPermissions:
          userSpecificPermissions ?? this.userSpecificPermissions,
    );
  }

  @override
  List<Object?> get props => [
    quizId,
    allowedUserIds,
    allowedRoles,
    availableFrom,
    availableUntil,
    maxAttempts,
    userSpecificPermissions,
  ];
}
