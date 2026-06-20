import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../services/feed_service.dart';

enum FeedLoadingState { idle, loading, success, error }

class FeedProvider extends ChangeNotifier {
  List<PostModel> _allPosts = [];
  int _displayedCount = 6;
  FeedLoadingState _state = FeedLoadingState.idle;
  String? _errorMessage;
  bool _isCreating = false;

  final Map<String, List<CommentModel>> _commentsMap = {};
  bool _isLoadingComments = false;

  List<PostModel> get posts => List.unmodifiable(_allPosts.take(_displayedCount).toList());
  List<PostModel> get allPosts => List.unmodifiable(_allPosts);
  FeedLoadingState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isCreating => _isCreating;
  bool get hasMore => _displayedCount < _allPosts.length;

  Map<String, List<CommentModel>> get commentsMap => _commentsMap;
  bool get isLoadingComments => _isLoadingComments;

  List<CommentModel> getCommentsForPost(String postId) => _commentsMap[postId] ?? [];

  Future<void> fetchComments(String postId) async {
    _isLoadingComments = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final comments = await FeedService.getComments(postId);
      _commentsMap[postId] = comments;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingComments = false;
      notifyListeners();
    }
  }

  Future<CommentModel?> addComment(String postId, String content, XFile? image) async {
    try {
      final comment = await FeedService.createComment(
        feedId: postId,
        content: content,
        image: image,
      );

      final currentComments = _commentsMap[postId] ?? [];
      _commentsMap[postId] = [...currentComments, comment];

      final index = _allPosts.indexWhere((p) => p.id == postId);
      if (index != -1 && index < _displayedCount) {
        final post = _allPosts[index];
        _allPosts[index] = post.copyWith(commentCount: post.commentCount + 1);
      }

      notifyListeners();
      return comment;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> toggleCommentLike(String postId, String commentId) async {
    final comments = _commentsMap[postId] ?? [];
    final index = comments.indexWhere((c) => c.id == commentId);
    if (index == -1) return;

    final comment = comments[index];
    final wasLiked = comment.isLiked;

    comments[index] = comment.copyWith(
      isLiked: !wasLiked,
      likeCount: wasLiked ? comment.likeCount - 1 : comment.likeCount + 1,
    );
    notifyListeners();

    try {
      await FeedService.toggleLikeComment(commentId);
    } catch (e) {
      comments[index] = comment;
      notifyListeners();
    }
  }

  Future<void> loadFeed() async {
    _state = FeedLoadingState.loading;
    _errorMessage = null;
    _displayedCount = 6;
    notifyListeners();

    try {
      _allPosts = await FeedService.getFeed();
      _state = FeedLoadingState.success;
    } catch (e) {
      _state = FeedLoadingState.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  Future<void> refreshFeed() async {
    try {
      _allPosts = await FeedService.getFeed();
      _displayedCount = 6;
      _state = FeedLoadingState.success;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  void loadMore() {
    if (_displayedCount < _allPosts.length) {
      _displayedCount += 6;
      notifyListeners();
    }
  }

  Future<bool> createPost({
    required String content,
    List<XFile>? images,
    String visibility = 'public',
    List<String>? allowedUserIds,
  }) async {
    _isCreating = true;
    notifyListeners();

    try {
      final post = await FeedService.createPost(
        content: content,
        images: images,
        visibility: visibility,
        allowedUserIds: allowedUserIds,
      );

      _allPosts = [post, ..._allPosts];
      _isCreating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isCreating = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleLike(String postId) async {
    final index = _allPosts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = _allPosts[index];
    final wasLiked = post.isLiked;

    _allPosts[index] = post.copyWith(
      isLiked: !wasLiked,
      likeCount: wasLiked ? post.likeCount - 1 : post.likeCount + 1,
    );
    notifyListeners();

    try {
      if (wasLiked) {
        await FeedService.unlikePost(postId);
      } else {
        await FeedService.likePost(postId);
      }
    } catch (e) {
      _allPosts[index] = post;
      notifyListeners();
    }
  }

  void addPost(PostModel post) {
    _allPosts.insert(0, post);
    notifyListeners();
  }

  void removePost(String postId) {
    _allPosts.removeWhere((p) => p.id == postId);
    notifyListeners();
  }

  void clear() {
    _allPosts = [];
    _displayedCount = 6;
    _state = FeedLoadingState.idle;
    _errorMessage = null;
    notifyListeners();
  }
}
