import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/models/admin_feed.dart';
import '../domain/feed_repository.dart';

class FeedRepositoryImpl implements FeedRepository {
  final FirebaseFirestore _db;
  static const _col = AppConstants.feedsCollection;

  FeedRepositoryImpl(this._db);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection(_col);

  @override
  Stream<List<AdminFeed>> watchFeeds({
    String? typeFilter,
    String? privacyFilter,
    bool? enabledFilter,
    int limit = 20,
  }) {
    // Only orderBy — composite index not required.
    // All filters applied client-side.
    final query = _collection
        .orderBy('create_at', descending: true)
        .limit(limit);

    return query.snapshots().map((snap) {
      var feeds = snap.docs.map(AdminFeed.fromFirestore).toList();

      if (typeFilter != null) {
        feeds = feeds.where((f) => f.type == typeFilter).toList();
      }
      if (privacyFilter != null) {
        feeds = feeds.where((f) => f.privacy == privacyFilter).toList();
      }
      if (enabledFilter == true) {
        feeds = feeds.where((f) => f.isEnabled).toList();
      } else if (enabledFilter == false) {
        feeds = feeds.where((f) => f.isDisabled).toList();
      }

      return feeds;
    });
  }

  @override
  Stream<AdminFeed?> watchFeed(String feedId) {
    return _collection.doc(feedId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return AdminFeed.fromFirestore(snap);
    });
  }

  @override
  Future<void> disableFeed(String feedId) async {
    try {
      await _collection.doc(feedId).update({'isEnable': false});
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Failed to disable feed');
    }
  }

  @override
  Future<void> enableFeed(String feedId) async {
    try {
      await _collection.doc(feedId).update({'isEnable': true});
    } on FirebaseException catch (e) {
      throw FirestoreException(e.message ?? 'Failed to enable feed');
    }
  }

  @override
  Future<int> getFeedCount() async {
    final snap = await _collection.count().get();
    return snap.count ?? 0;
  }

  @override
  Future<int> getPostCount() async {
    final snap = await _collection
        .where('type', isEqualTo: AppConstants.feedTypePost)
        .count()
        .get();
    return snap.count ?? 0;
  }

  @override
  Stream<List<AdminFeed>> watchRecentFeeds({int limit = 5}) {
    return _collection
        .orderBy('create_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(AdminFeed.fromFirestore).toList());
  }
}

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepositoryImpl(FirebaseFirestore.instance);
});
