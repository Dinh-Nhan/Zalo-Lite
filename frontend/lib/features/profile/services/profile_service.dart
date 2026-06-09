import 'package:dio/dio.dart';
import 'package:frontend/services/dio_client.dart';
import 'package:frontend/features/newfeed/models/post_model.dart';
import 'package:frontend/features/friends/services/friend_service.dart';

class UserProfileModel {
  final String id;
  final String fullName;
  final String email;
  final String avatar;
  final DateTime? dateOfBirth;
  final String bio;

  const UserProfileModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.avatar,
    this.dateOfBirth,
    required this.bio,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    DateTime? dob;
    if (json['dateOfBirth'] != null && json['dateOfBirth'].toString().isNotEmpty) {
      try {
        dob = DateTime.parse(json['dateOfBirth'].toString());
      } catch (_) {}
    }
    return UserProfileModel(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      dateOfBirth: dob,
      bio: json['bio'] as String? ?? '',
    );
  }

  String? get firstName {
    final parts = fullName.trim().split(' ');
    return parts.isNotEmpty ? parts.first : null;
  }

  String? get lastName {
    final parts = fullName.trim().split(' ');
    return parts.length > 1 ? parts.last : null;
  }
}

class ProfileService {
  static final Dio _dio = DioClient.instance;

  static Future<List<PostModel>> getUserPosts(String userId) async {
    try {
      final response = await _dio.get('/api/feed/user/$userId');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final result = data['result'] as List<dynamic>?;
        if (result == null) return [];
        return result
            .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (_) {
      return [];
    }
  }

  static Future<int> getFriendCount() async {
    try {
      final response = await _dio.get('/api/friends');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final result = data['result'] as List<dynamic>?;
        if (result == null) return 0;
        return result
            .map((e) => FriendSummaryModel.fromJson(e as Map<String, dynamic>))
            .length;
      }
      return 0;
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  static Future<List<FriendSummaryModel>> getFriends() async {
    try {
      final response = await _dio.get('/api/friends');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final result = data['result'] as List<dynamic>?;
        if (result == null) return [];
        return result
            .map((e) => FriendSummaryModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  static Future<UserProfileModel> getCurrentUserProfile() async {
    try {
      final response = await _dio.get('/api/user/me');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final result = data['result'] as Map<String, dynamic>?;
        if (result == null) throw Exception('Không tìm thấy dữ liệu');
        return UserProfileModel.fromJson(result);
      }
      throw Exception('Lỗi khi lấy thông tin');
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  static Future<UserProfileModel> getUserById(String userId) async {
    try {
      final response = await _dio.get('/api/user/$userId');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final result = data['result'] as Map<String, dynamic>?;
        if (result == null) throw Exception('Không tìm thấy dữ liệu');
        return UserProfileModel.fromJson(result);
      }
      throw Exception('Lỗi khi lấy thông tin');
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  static String _handleError(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401) return 'Chưa đăng nhập hoặc token hết hạn';
    if (status == 403) return 'Không có quyền truy cập';
    if (status == 404) return 'Không tìm thấy dữ liệu';
    if (status != null) return 'Lỗi server $status';
    return 'Lỗi kết nối: ${e.message}';
  }
}
