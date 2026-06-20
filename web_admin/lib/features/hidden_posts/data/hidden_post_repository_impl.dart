import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/models/hidden_post.dart';
import '../domain/hidden_post_repository.dart';

class HiddenPostRepositoryImpl implements HiddenPostRepository {
  final FirebaseFirestore _db;
  HiddenPostRepositoryImpl(this._db);

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(AppConstants.hiddenPostsCollection);

  @override
  Stream<List<HiddenPost>> watchHiddenPosts({int limit = 20}) {
    return _col
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(HiddenPost.fromFirestore).toList());
  }

  @override
  Future<void> restoreHiddenPost(String docId) async {
    try {
      await _col.doc(docId).delete();
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Failed to restore');
    }
  }

  @override
  Future<void> permanentlyDeletePost(String postId) async {
    try {
      await _db.collection(AppConstants.feedsCollection).doc(postId).delete();
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Failed to delete post');
    }
  }

  @override
  Future<int> getHiddenPostCount() async {
    final snap = await _col.count().get();
    return snap.count ?? 0;
  }
}

final hiddenPostRepositoryProvider = Provider<HiddenPostRepository>((ref) {
  return HiddenPostRepositoryImpl(FirebaseFirestore.instance);
});
