import 'package:dio/dio.dart';
import 'dio_client.dart';

class ApiService {
  static final _dio = DioClient.instance;

  // ─────────────────────────────────────────────
  // AUTH
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _dio.get('/api/auth/profile');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─────────────────────────────────────────────
  // MESSAGES  (thêm các hàm mới theo mẫu này)
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> sendMessage(
      Map<String, dynamic> body) async {
    try {
      final response = await _dio.post('/api/messages', data: body);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<List<dynamic>> getMessages(String conversationId) async {
    try {
      final response =
          await _dio.get('/api/messages', queryParameters: {'conversationId': conversationId});
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─────────────────────────────────────────────
  // HELPER — dùng nội bộ
  // ─────────────────────────────────────────────
  static Exception _handleError(DioException e) {
    final status = e.response?.statusCode;
    final body = e.response?.data;

    if (status == 401) return Exception('Chưa đăng nhập hoặc token hết hạn');
    if (status == 403) return Exception('Không có quyền truy cập');
    if (status == 404) return Exception('Không tìm thấy dữ liệu');
    if (status != null) return Exception('Lỗi server $status: $body');

    return Exception('Lỗi kết nối: ${e.message}');
  }
}
