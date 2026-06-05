import 'models/hidden_post.dart';

abstract interface class HiddenPostRepository {
  Stream<List<HiddenPost>> watchHiddenPosts({int limit = 20});
  /// Restore: delete the hidden_posts document (unhides for that user)
  Future<void> restoreHiddenPost(String docId);
  /// Permanently delete the actual feed post
  Future<void> permanentlyDeletePost(String postId);
  Future<int> getHiddenPostCount();
}
