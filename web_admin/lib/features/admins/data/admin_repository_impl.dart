import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/models/admin_account.dart';
import '../domain/admin_repository.dart';

// ============================================================
// ADMINS FEATURE - Repository Implementation
// ============================================================

class AdminRepositoryImpl implements AdminRepository {
  final FirebaseFirestore _db;
  static const _col = AppConstants.adminsCollection;

  AdminRepositoryImpl(this._db);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection(_col);

  @override
  Stream<List<AdminAccount>> watchAdmins() {
    return _collection
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(AdminAccount.fromFirestore).toList());
  }

  @override
  Future<void> createAdmin({
    required String id,
    required String email,
    required String displayName,
    required String role,
  }) async {
    try {
      await _collection.doc(id).set({
        'email': email,
        'display_name': displayName,
        'role': role,
        'is_active': true,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Failed to create admin');
    }
  }

  @override
  Future<void> updateAdmin(
    String adminId, {
    String? displayName,
    String? role,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': FieldValue.serverTimestamp(),
      };
      if (displayName != null) updates['display_name'] = displayName;
      if (role != null) updates['role'] = role;
      if (isActive != null) updates['is_active'] = isActive;
      await _collection.doc(adminId).update(updates);
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Failed to update admin');
    }
  }

  @override
  Future<void> deleteAdmin(String adminId) async {
    try {
      await _collection.doc(adminId).delete();
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Failed to delete admin');
    }
  }

  @override
  Future<void> assignRole(String adminId, String role) async {
    try {
      await _collection.doc(adminId).update({
        'role': role,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Failed to assign role');
    }
  }

  @override
  Future<int> getAdminCount() async {
    final snap = await _collection.count().get();
    return snap.count ?? 0;
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepositoryImpl(FirebaseFirestore.instance);
});
