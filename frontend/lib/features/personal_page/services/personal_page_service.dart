import 'package:dio/dio.dart';
import '../../../services/dio_client.dart';
import '../data/models/models.dart';

/// Service xử lý toàn bộ nghiệp vụ feed/post/story
/// Wrap các endpoint /api/feed
class PersonalPageService {
  static final _dio = DioClient.instance;

  // ── GET /api/feed ─────────────────────────────────────────────
  /// Lấy toàn bộ newsfeed (stories + posts) trong một request
  static Future<NewsfeedModel> getNewsfeed() async {
    try {
      final res = await _dio.get('/api/feed');
      final data = res.data as Map<String, dynamic>;
      return NewsfeedModel.fromJson(data['result'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── GET /api/feed/stories ─────────────────────────────────────
  /// Lấy danh sách story bar (các story còn hạn từ bạn bè)
  static Future<List<FeedModel>> getStories() async {
    try {
      final res = await _dio.get('/api/feed/stories');
      final data = res.data as Map<String, dynamic>;
      final list = (data['result'] as List? ?? []);
      return list
          .map((e) => FeedModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── GET /api/feed/newsfeed ────────────────────────────────────
  /// Lấy danh sách posts (bài viết từ bạn bè và chính mình)
  static Future<List<FeedModel>> getPosts() async {
    try {
      final res = await _dio.get('/api/feed/newsfeed');
      final data = res.data as Map<String, dynamic>;
      final list = (data['result'] as List? ?? []);
      return list
          .map((e) => FeedModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── POST /api/feed ───────────────────────────────────────────
  /// Tạo bài đăng mới (post hoặc story)
  /// type: "post" | "story"
  /// privacy: "public" | "friends" | "private"
  static Future<FeedModel> createFeed({
    required String type,
    required String caption,
    required List<MediaModel> media,
    String privacy = 'public',
  }) async {
    try {
      final res = await _dio.post(
        '/api/feed',
        data: {
          'type': type,
          'content': {
            'caption': caption,
            'media': media.map((m) => m.toJson()).toList(),
          },
          'privacy': privacy,
        },
      );
      final data = res.data as Map<String, dynamic>;
      return FeedModel.fromJson(data['result'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── POST /api/feed/{feedId}/like ─────────────────────────────
  /// Toggle like / unlike một feed
  static Future<LikeResultModel> toggleLike(String feedId) async {
    try {
      final res = await _dio.post('/api/feed/$feedId/like');
      final data = res.data as Map<String, dynamic>;
      return LikeResultModel.fromJson(data['result'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── DELETE /api/feed/{feedId} ───────────────────────────────
  /// Xóa một feed (post hoặc story)
  static Future<void> deleteFeed(String feedId) async {
    try {
      await _dio.delete('/api/feed/$feedId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── GET /api/user/{userId} ──────────────────────────────────
  /// Lấy thông tin user theo ID (dùng cho hiển thị avatar trong story bar)
  static Future<UserProfileModel> getUserById(String userId) async {
    try {
      final res = await _dio.get('/api/user/$userId');
      final data = res.data as Map<String, dynamic>;
      return UserProfileModel.fromJson(data['result'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Helper ───────────────────────────────────────────────────
  static Exception _handleError(DioException e) {
    final status = e.response?.statusCode;
    final body = e.response?.data;
    if (status == 401) return Exception('Chưa đăng nhập hoặc token hết hạn');
    if (status == 403) return Exception('Không có quyền thực hiện thao tác này');
    if (status == 404) return Exception('Không tìm thấy dữ liệu');
    if (status == 410) return Exception('Nội dung đã hết hạn');
    if (status != null) return Exception('Lỗi server $status: $body');
    return Exception('Lỗi kết nối: ${e.message}');
  }
}
