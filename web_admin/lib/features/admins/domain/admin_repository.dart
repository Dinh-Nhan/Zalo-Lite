import 'models/admin_account.dart';

// ============================================================
// ADMINS FEATURE - Repository Interface
// ============================================================

abstract interface class AdminRepository {
  /// Stream all admin accounts
  Stream<List<AdminAccount>> watchAdmins();

  /// Create a new admin (Firestore only — Firebase Auth user must already exist)
  Future<void> createAdmin({
    required String id,
    required String email,
    required String displayName,
    required String role,
  });

  /// Update admin display name or role
  Future<void> updateAdmin(
    String adminId, {
    String? displayName,
    String? role,
    bool? isActive,
  });

  /// Delete admin document from Firestore
  Future<void> deleteAdmin(String adminId);

  /// Assign a new role ('admin' | 'moderator')
  Future<void> assignRole(String adminId, String role);

  /// Get total admin count
  Future<int> getAdminCount();
}
