import 'models/admin_feed.dart';

abstract interface class FeedRepository {
  Stream<List<AdminFeed>> watchFeeds({
    String? typeFilter,       // 'post' | 'story' | null
    String? privacyFilter,   // 'public' | 'friends' | 'private' | null
    bool? enabledFilter,     // null=all, true=enabled only, false=disabled only
    int limit = 20,
  });

  Stream<AdminFeed?> watchFeed(String feedId);

  /// Disable a feed: sets isEnable = false
  Future<void> disableFeed(String feedId);

  /// Enable a feed: sets isEnable = true
  Future<void> enableFeed(String feedId);

  Future<int> getFeedCount();
  Future<int> getPostCount();

  Stream<List<AdminFeed>> watchRecentFeeds({int limit = 5});
}
