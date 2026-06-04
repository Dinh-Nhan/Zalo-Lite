import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/models/admin_user.dart';
import '../domain/user_repository.dart';

// ============================================================
// USERS FEATURE - Repository Implementation (no code generation)
// ============================================================

class UserRepositoryImpl implements UserRepository {
  final FirebaseFirestore _db;
  static const _col = AppConstants.usersCollection;

  UserRepositoryImpl(this._db);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection(_col);

  @override
  Stream<List<AdminUser>> watchUsers({
    String? searchQuery,
    String? statusFilter,
    int limit = 20,
  }) {
    Query<Map<String, dynamic>> query =
        _collection.orderBy('created_at', descending: true);

    if (statusFilter == 'active') {
      query = query.where('status', isEqualTo: true);
    } else if (statusFilter == 'banned') {
      query = query.where('status', isEqualTo: false);
    }

    query = query.limit(limit);

    return query.snapshots().map((snap) {
      var users = snap.docs.map(AdminUser.fromFirestore).toList();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        users = users
            .where((u) =>
                u.displayName.toLowerCase().contains(q) ||
                u.email.toLowerCase().contains(q))
            .toList();
      }

      return users;
    });
  }

  @override
  Stream<AdminUser?> watchUser(String userId) {
    return _collection.doc(userId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return AdminUser.fromFirestore(snap);
    });
  }

  @override
  Future<void> banUser(String userId) async {
    try {
      await _collection.doc(userId).update({
        'status': false,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Failed to ban user');
    }
  }

  @override
  Future<void> unbanUser(String userId) async {
    try {
      await _collection.doc(userId).update({
        'status': true,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Failed to unban user');
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    try {
      await _collection.doc(userId).delete();
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Failed to delete user');
    }
  }

  @override
  Future<int> getUserCount() async {
    final snap = await _collection.count().get();
    return snap.count ?? 0;
  }

  @override
  Stream<List<AdminUser>> watchNewUsers({int limit = 5}) {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return _collection
        .where('created_at',
            isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(AdminUser.fromFirestore).toList());
  }
}

// ── Manual Provider ──────────────────────────────────────────

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(FirebaseFirestore.instance);
});
