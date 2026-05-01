import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Interceptor tự động gắn Firebase ID Token vào Header Authorization
/// của mọi request. Token được refresh tự động khi hết hạn.
class _AuthInterceptor extends Interceptor {
  // Tránh retry loop: chỉ retry 1 lần duy nhất
  static const _retryKey = 'retried';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // forceRefresh: false → dùng cache, tự refresh khi sắp hết hạn
      final idToken = await user.getIdToken(false);
      options.headers['Authorization'] = 'Bearer $idToken';
    }

    handler.next(options); // tiếp tục gửi request
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Nếu backend trả 401 và chưa retry lần nào → thử force refresh rồi retry
    final alreadyRetried = err.requestOptions.extra[_retryKey] == true;
    if (err.response?.statusCode == 401 && !alreadyRetried) {
      _retryWithFreshToken(err, handler);
      return;
    }
    handler.next(err);
  }

  Future<void> _retryWithFreshToken(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        handler.next(err);
        return;
      }

      // Force refresh token mới
      final newToken = await user.getIdToken(true);

      // Tạo lại request với token mới, đánh dấu đã retry
      final opts = err.requestOptions;
      opts.headers['Authorization'] = 'Bearer $newToken';
      opts.extra[_retryKey] = true; // ngăn retry lần 2

      final dio = DioClient.instance;
      final response = await dio.fetch(opts);
      handler.resolve(response);
    } catch (e) {
      handler.next(err);
    }
  }
}

/// Singleton Dio client dùng chung toàn app.
/// Mọi request qua client này đều tự động đính kèm token.
class DioClient {
  DioClient._();

  static final Dio instance = _createDio();

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        // Thay bằng base URL thực tế của backend
        baseUrl: 'http://10.0.2.2:5244',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(_AuthInterceptor());

    // (Tuỳ chọn) log request/response khi debug
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));

    return dio;
  }
}
