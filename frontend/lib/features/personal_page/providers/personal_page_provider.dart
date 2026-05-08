import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/models.dart';
import '../services/personal_page_service.dart';

/// Provider quản lý state cho màn hình Tường nhà
class PersonalPageProvider extends ChangeNotifier {
  List<FeedModel> _stories = [];
  List<FeedModel> _posts = [];
  bool _isLoading = false;
  bool _isCreating = false;
  String? _error;
  String? _currentUserId;

  List<FeedModel> get stories => _stories;
  List<FeedModel> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  String? get error => _error;
  String get currentUserId => _currentUserId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
  bool get hasLoaded => _stories.isNotEmpty || _posts.isNotEmpty || _error != null;

  /// Tải toàn bộ newsfeed (stories + posts)
  Future<void> loadNewsfeed() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await PersonalPageService.getNewsfeed();
      _stories = result.stories;
      _posts = result.posts;
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tạo bài đăng mới (post)
  Future<bool> createPost({
    required String caption,
    required List<MediaModel> media,
    String privacy = 'public',
  }) async {
    _isCreating = true;
    _error = null;
    notifyListeners();

    try {
      final newFeed = await PersonalPageService.createFeed(
        type: 'post',
        caption: caption,
        media: media,
        privacy: privacy,
      );
      // Thêm bài mới vào đầu danh sách posts
      _posts = [newFeed, ..._posts];
      _isCreating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isCreating = false;
      notifyListeners();
      return false;
    }
  }

  /// Tạo story mới
  Future<bool> createStory({
    required String caption,
    required List<MediaModel> media,
    String privacy = 'public',
  }) async {
    _isCreating = true;
    _error = null;
    notifyListeners();

    try {
      final newFeed = await PersonalPageService.createFeed(
        type: 'story',
        caption: caption,
        media: media,
        privacy: privacy,
      );
      // Thêm story mới vào đầu danh sách stories
      _stories = [newFeed, ..._stories];
      _isCreating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isCreating = false;
      notifyListeners();
      return false;
    }
  }

  /// Toggle like / unlike
  Future<void> toggleLike(FeedModel feed) async {
    try {
      final result = await PersonalPageService.toggleLike(feed.id);
      // Cập nhật state
      _updateFeedStats(
        feed.id,
        result.likeCount,
        result.isLiked,
      );
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  /// Xóa feed
  Future<bool> deleteFeed(String feedId) async {
    try {
      await PersonalPageService.deleteFeed(feedId);
      _posts = _posts.where((p) => p.id != feedId).toList();
      _stories = _stories.where((s) => s.id != feedId).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void _updateFeedStats(String feedId, int likeCount, bool isLiked) {
    bool updated = false;

    final postIdx = _posts.indexWhere((f) => f.id == feedId);
    if (postIdx != -1) {
      final old = _posts[postIdx];
      _posts[postIdx] = FeedModel(
        id: old.id,
        userId: old.userId,
        type: old.type,
        content: old.content,
        privacy: old.privacy,
        stats: StatsModel(
          viewCount: old.stats.viewCount,
          likeCount: likeCount,
          isLiked: isLiked,
        ),
        settings: old.settings,
        createdAt: old.createdAt,
        deletedAt: old.deletedAt,
      );
      updated = true;
    }

    final storyIdx = _stories.indexWhere((f) => f.id == feedId);
    if (storyIdx != -1) {
      final old = _stories[storyIdx];
      _stories[storyIdx] = FeedModel(
        id: old.id,
        userId: old.userId,
        type: old.type,
        content: old.content,
        privacy: old.privacy,
        stats: StatsModel(
          viewCount: old.stats.viewCount,
          likeCount: likeCount,
          isLiked: isLiked,
        ),
        settings: old.settings,
        createdAt: old.createdAt,
        deletedAt: old.deletedAt,
      );
      updated = true;
    }

    if (updated) notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
