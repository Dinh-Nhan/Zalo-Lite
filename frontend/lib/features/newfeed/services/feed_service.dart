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
      final List<MultipartFile> fileList = [];
      if (images != null && images.isNotEmpty) {
        for (int i = 0; i < images.length; i++) {
          final img = images[i];
          String safeName = img.name;
          if (safeName.isEmpty ||
              safeName.contains('/') ||
              safeName.contains('\\') ||
              !safeName.contains('.')) {
            safeName = 'image_$i.jpg';
          }
          fileList.add(MultipartFile.fromBytes(
            await img.readAsBytes(),
            filename: safeName,
          ));
        }
      }

      final formData = FormData.fromMap({
        'Type': 'post',
        'Privacy': visibility,
        'Content.Caption': content,
        if (allowedUserIds != null && allowedUserIds.isNotEmpty)
          'AllowedUserIds': allowedUserIds,
        for (final file in fileList)
          'files': file,
      });

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
      late final Response response;

      if (image == null) {
        response = await _dio.post(
          '/api/feed/$feedId/comments',
          data: {
            'content': content,
          },
        );
      } else {
        final formData = FormData.fromMap({
          'Content': content,
          'File': MultipartFile.fromBytes(
            await image.readAsBytes(),
            filename: image.name.isNotEmpty ? image.name : 'comment.jpg',
          ),
        });
        response = await _dio.post('/api/feed/$feedId/comments', data: formData);
      }

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
    if (status == 401) return 'Chưa đăng nhập hoặc token hết hạn';
    if (status == 403) return 'Không có quyền truy cập';
    if (status == 404) return 'Không tìm thấy bài viết';
    if (status != null) return 'Lỗi server $status';
    return 'Lỗi kết nối: ${e.message}';
  }
}
