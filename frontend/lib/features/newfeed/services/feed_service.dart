import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/services/dio_client.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';

class FeedService {
  static final Dio _dio = DioClient.instance;

  static Future<List<PostModel>> getFeed() async {
    try {
      final response = await _dio.get('/api/feed/newsfeed');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final result = data['result'] as List<dynamic>?;
        if (result == null) return [];
        return result
            .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  static Future<PostModel> createPost({
    required String content,
    List<XFile>? images,
    String visibility = 'public',
    List<String>? allowedUserIds,
  }) async {
    try {
      final Map<String, dynamic> formMap = {
        'Type': 'post',
        'Privacy': visibility,
        'Content.Caption': content,
      };

      if (allowedUserIds != null && allowedUserIds.isNotEmpty) {
        formMap['allowedUserIds'] = allowedUserIds;
      }

      if (images != null && images.isNotEmpty) {
        for (int i = 0; i < images.length; i++) {
          final img = images[i];
          final bytes = await img.readAsBytes();
          formMap['Content.Media[$i].File'] = MultipartFile.fromBytes(
            bytes,
            filename: img.name,
          );
        }
      }

      final formData = FormData.fromMap(formMap);

      final response = await _dio.post('/api/feed', data: formData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        final result = data['result'] as Map<String, dynamic>?;
        if (result == null) throw Exception('Invalid response');
        return PostModel.fromJson(result);
      }
      throw Exception('Failed to create post');
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  static Future<void> likePost(String postId) async {
    try {
      await _dio.post('/api/feed/$postId/like');
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  static Future<void> unlikePost(String postId) async {
    try {
      await _dio.post('/api/feed/$postId/like');
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  static Future<void> deletePost(String postId) async {
    try {
      await _dio.delete('/api/feed/$postId');
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  // ── Comments API ────────────────────────────────────────────────

  static Future<List<CommentModel>> getComments(String feedId) async {
    try {
      final response = await _dio.get('/api/feed/$feedId/comments');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final result = data['result'] as List<dynamic>?;
        if (result == null) return [];
        return result
            .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  static Future<CommentModel> createComment({
    required String feedId,
    required String content,
    XFile? image,
  }) async {
    try {
      final Map<String, dynamic> formMap = {
        'Content': content,
      };

      if (image != null) {
        final bytes = await image.readAsBytes();
        formMap['File'] = MultipartFile.fromBytes(
          bytes,
          filename: image.name,
        );
      }

      final formData = FormData.fromMap(formMap);
      final response = await _dio.post('/api/feed/$feedId/comments', data: formData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        final result = data['result'] as Map<String, dynamic>?;
        if (result == null) throw Exception('Invalid response');
        return CommentModel.fromJson(result);
      }
      throw Exception('Failed to create comment');
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  static Future<void> toggleLikeComment(String commentId) async {
    try {
      await _dio.post('/api/feed/comments/$commentId/like');
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  static String _handleError(DioException e) {
    final status = e.response?.statusCode;
    final body = e.response?.data;
    if (status == 401) return 'Chưa đăng nhập hoặc token hết hạn';
    if (status == 403) return 'Không có quyền truy cập';
    if (status == 404) return 'Không tìm thấy bài viết';
    if (status != null) return 'Lỗi server $status';
    return 'Lỗi kết nối: ${e.message}';
  }
}
