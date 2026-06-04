import 'models/admin_user.dart';

// ============================================================
// USERS FEATURE - Repository Interface
// ============================================================

abstract interface class UserRepository {
  /// Stream paginated users list with optional search
  Stream<List<AdminUser>> watchUsers({
    String? searchQuery,
    String? statusFilter, // 'active' | 'banned' | null
    int limit = 20,
  });

  /// Get a single user by ID
  Stream<AdminUser?> watchUser(String userId);

  /// Ban user (set status=false)
  Future<void> banUser(String userId);

  /// Unban user (set status=true)
  Future<void> unbanUser(String userId);

  /// Delete user document from Firestore
  /// Note: Does NOT delete Firebase Auth user (requires Admin SDK)
  Future<void> deleteUser(String userId);

  /// Get total user count (uses aggregation)
  Future<int> getUserCount();

  /// Stream newly registered users (last 7 days)
  Stream<List<AdminUser>> watchNewUsers({int limit = 5});
}
