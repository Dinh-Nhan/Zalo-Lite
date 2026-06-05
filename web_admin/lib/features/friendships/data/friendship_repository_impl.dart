import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/models/admin_friendship.dart';
import '../domain/friendship_repository.dart';

class FriendshipRepositoryImpl implements FriendshipRepository {
  final FirebaseFirestore _db;
  FriendshipRepositoryImpl(this._db);

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(AppConstants.friendshipsCollection);

  @override
  Stream<List<AdminFriendship>> watchFriendships({
    String? statusFilter,
    String? searchQuery,
    int limit = 20,
  }) {
    Query<Map<String, dynamic>> query =
        _col.orderBy('created_at', descending: true);

    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter);
    }

    query = query.limit(limit);

    return query.snapshots().map((snap) {
      var items = snap.docs.map(AdminFriendship.fromFirestore).toList();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        items = items
            .where((f) =>
                f.senderId.toLowerCase().contains(q) ||
                f.addresseeId.toLowerCase().contains(q) ||
                (f.addresseeName?.toLowerCase().contains(q) ?? false))
            .toList();
      }

      return items;
    });
  }

  @override
  Future<void> deleteFriendship(String docId) async {
    try {
      await _col.doc(docId).delete();
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Failed to delete friendship');
    }
  }

  @override
  Future<int> getFriendshipCount() async {
    final snap = await _col.count().get();
    return snap.count ?? 0;
  }

  @override
  Future<int> getAcceptedFriendshipCount() async {
    final snap = await _col
        .where('status', isEqualTo: AppConstants.friendshipAccepted)
        .count()
        .get();
    return snap.count ?? 0;
  }
}

final friendshipRepositoryProvider = Provider<FriendshipRepository>((ref) {
  return FriendshipRepositoryImpl(FirebaseFirestore.instance);
});
