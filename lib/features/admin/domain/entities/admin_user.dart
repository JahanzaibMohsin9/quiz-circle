import 'package:equatable/equatable.dart';
import '../../../authentication/domain/entities/user.dart';

class AdminUser extends Equatable {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final bool isBlocked;
  final int totalScore;
  final double averagePercentage;

  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isBlocked = false,
    this.totalScore = 0,
    this.averagePercentage = 0.0,
  });

  AdminUser copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    bool? isBlocked,
    int? totalScore,
    double? averagePercentage,
  }) {
    return AdminUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isBlocked: isBlocked ?? this.isBlocked,
      totalScore: totalScore ?? this.totalScore,
      averagePercentage: averagePercentage ?? this.averagePercentage,
    );
  }

  @override
  List<Object?> get props => [id, name, email, role, isBlocked, totalScore, averagePercentage];
}

