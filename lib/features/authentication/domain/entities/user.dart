import '../../../../core/utils/timestamp_parser.dart';

enum UserRole { student, admin }

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final List<String> allowedQuizzes;
  final int? totalScore;
  final double? averagePercentage;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.allowedQuizzes = const [],
    this.totalScore,
    this.averagePercentage,
    this.createdAt,
    this.lastLoginAt,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    List<String>? allowedQuizzes,
    int? totalScore,
    double? averagePercentage,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      allowedQuizzes: allowedQuizzes ?? this.allowedQuizzes,
      totalScore: totalScore ?? this.totalScore,
      averagePercentage: averagePercentage ?? this.averagePercentage,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          role == other.role;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ email.hashCode ^ role.hashCode;

  @override
  String toString() {
    return 'User{id: $id, name: $name, email: $email, role: $role}';
  }

  // Convert User to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'allowedQuizzes': allowedQuizzes,
      'totalScore': totalScore,
      'averagePercentage': averagePercentage,
      'createdAt': createdAt != null
          ? TimestampParser.toJson(createdAt!)
          : null,
      'lastLoginAt': lastLoginAt != null
          ? TimestampParser.toJson(lastLoginAt!)
          : null,
    };
  }

  // Create User from JSON from Firestore
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: UserRole.values.firstWhere(
        (role) => role.name == json['role'],
        orElse: () => UserRole.student,
      ),
      allowedQuizzes: (json['allowedQuizzes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      totalScore: json['totalScore'] as int?,
      averagePercentage: (json['averagePercentage'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null
          ? TimestampParser.parse(json['createdAt'])
          : null,
      lastLoginAt: json['lastLoginAt'] != null
          ? TimestampParser.parse(json['lastLoginAt'])
          : null,
    );
  }
}
