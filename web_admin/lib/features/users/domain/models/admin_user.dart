import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================
// USERS FEATURE - Domain Model
// ============================================================

class AdminUser {
  final String id;
  final String role;
  final String firstName;
  final String lastName;
  final String email;
  final String avatar;
  final String bio;
  final bool status; // legacy field
  final bool isEnable; // true = active, false = disabled
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdminUser({
    required this.id,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.avatar,
    required this.bio,
    required this.status,
    required this.isEnable,
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayName => '$firstName $lastName'.trim();
  bool get isActive => isEnable; // dùng is_enable làm nguồn sự thật
  bool get isBanned => !isEnable;

  factory AdminUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminUser(
      id: doc.id,
      role: data['role'] as String? ?? 'client',
      firstName: data['first_name'] as String? ?? '',
      lastName: data['last_name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      avatar: data['avatar'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      status: data['status'] as bool? ?? true,
      isEnable: data['is_enable'] as bool? ?? true,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  AdminUser copyWith({
    bool? status,
    bool? isEnable,
  }) {
    return AdminUser(
      id: id,
      role: role,
      firstName: firstName,
      lastName: lastName,
      email: email,
      avatar: avatar,
      bio: bio,
      status: status ?? this.status,
      isEnable: isEnable ?? this.isEnable,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
