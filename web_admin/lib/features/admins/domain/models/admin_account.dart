import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================
// ADMINS FEATURE - Domain Model
// ============================================================

class AdminAccount {
  final String id;
  final String email;
  final String displayName;
  final String role; // 'admin' | 'moderator'
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdminAccount({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isModerator => role == 'moderator';

  factory AdminAccount.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminAccount(
      id: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['display_name'] as String? ?? '',
      role: data['role'] as String? ?? 'moderator',
      isActive: data['is_active'] as bool? ?? true,
      createdAt:
          (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'display_name': displayName,
        'role': role,
        'is_active': isActive,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };
}
