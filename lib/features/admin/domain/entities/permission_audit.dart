import 'package:equatable/equatable.dart';

enum PermissionAction {
  granted,
  revoked,
  modified,
  bulkGranted,
  bulkRevoked,
  expired,
}

class PermissionAudit extends Equatable {
  final String id;
  final String quizId;
  final String userId;
  final PermissionAction action;
  final String performedBy;
  final Map<String, dynamic> oldValues;
  final Map<String, dynamic> newValues;
  final DateTime timestamp;
  final String? reason;

  const PermissionAudit({
    required this.id,
    required this.quizId,
    required this.userId,
    required this.action,
    required this.performedBy,
    required this.oldValues,
    required this.newValues,
    required this.timestamp,
    this.reason,
  });

  @override
  List<Object?> get props => [
    id, quizId, userId, action, performedBy, 
    oldValues, newValues, timestamp, reason
  ];
}
