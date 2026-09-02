import 'dart:convert';

enum UserRole {
  member,
  trainer;

  static UserRole fromString(String value) {
    return value.toLowerCase() == 'trainer' ? UserRole.trainer : UserRole.member;
  }

  String toValue() => name;
}

class User {
  final String id;
  final UserRole role;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? assignedTrainerId;

  const User({
    required this.id,
    required this.role,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.assignedTrainerId,
  });

  bool get isTrainer => role == UserRole.trainer;
  bool get isMember => role == UserRole.member;

  User copyWith({
    String? id,
    UserRole? role,
    String? name,
    String? email,
    String? avatarUrl,
    String? assignedTrainerId,
  }) {
    return User(
      id: id ?? this.id,
      role: role ?? this.role,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      assignedTrainerId: assignedTrainerId ?? this.assignedTrainerId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role': role.toValue(),
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'assignedTrainerId': assignedTrainerId,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      role: UserRole.fromString(map['role'] as String? ?? 'member'),
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      avatarUrl: map['avatarUrl'] as String?,
      assignedTrainerId: map['assignedTrainerId'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) => User.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          role == other.role &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ role.hashCode ^ name.hashCode;
}
