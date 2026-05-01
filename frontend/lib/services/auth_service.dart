import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/services/dio_client.dart';

class LoginResult {
  final String? token;
  final String? errorCode;
  final String? errorMessage;

  const LoginResult({this.token, this.errorCode, this.errorMessage});

  bool get isSuccess => token != null;
}

// /// Thông tin đăng ký — truyền vào AuthService.register()
class RegisterRequest {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String? dateOfBirth; // format: "yyyy-MM-dd"
  final String? bio;

  const RegisterRequest({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
    this.bio,
  });
}

class AuthService {
  static Future<LoginResult> login(String email, String password) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user != null) {
        final idToken = await user.getIdToken();
        return LoginResult(token: idToken);
      }

      return const LoginResult(errorMessage: 'Không lấy được thông tin user');
    } on FirebaseAuthException catch (e) {
      final msg = _mapFirebaseError(e.code);
      return LoginResult(errorCode: e.code, errorMessage: msg);
    } catch (e) {
      return LoginResult(errorMessage: 'Lỗi không xác định: $e');
    }
  }

  static Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  /// Đăng ký tài khoản gồm 2 bước:
  ///   1. Tạo account trên Firebase Auth (email + password)
  ///   2. Lưu thông tin chi tiết vào backend (POST /api/user)
  static Future<void> register(RegisterRequest req) async {
    UserCredential? credential;

    try {
      // Bước 1: Tạo account Firebase Auth
      credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: req.email,
        password: req.password,
      );

      final uid = credential.user!.uid;

      // Bước 2: Gọi backend lưu thông tin chi tiết
      // Token tự động được gắn bởi DioClient/AuthInterceptor
      await DioClient.instance.post(
        '/api/user',
        data: {
          'email': req.email,
          'password': req.password,
          'firstName': req.firstName,
          'lastName': req.lastName,
          'dateOfBirth': req.dateOfBirth,
          'bio': req.bio ?? '',
          'role': 'client',
          'status': true,
        },
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e.code));
    } on DioException catch (e) {
      // Backend trả về lỗi có cấu trúc JSON: { code, message, result: { errorCode } }
      // → xoá account Firebase để tránh trạng thái không đồng bộ
      if (credential != null) {
        await credential.user?.delete();
      }
      final errorCode = e.response?.data?['result']?['errorCode'] as String?;
      throw Exception(
        _mapBackendErrorCode(errorCode, e.response?.data?['message']),
      );
    } catch (e) {
      // Nếu backend thất bại sau khi Firebase đã tạo account
      // → xoá account Firebase để tránh trạng thái không đồng bộ
      if (credential != null) {
        await credential.user?.delete();
      }
      throw Exception('Đăng ký thất bại: $e');
    }
  }

  /// Chuyển Firebase error code sang tiếng Việt
  static String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Email không tồn tại';
      case 'wrong-password':
        return 'Sai mật khẩu';
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'email-already-in-use':
        return 'Email này đã được đăng ký. Vui lòng dùng email khác.';
      case 'weak-password':
        return 'Mật khẩu phải có ít nhất 8 ký tự, gồm chữ thường và chữ hoa.';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa';
      case 'too-many-requests':
        return 'Quá nhiều lần thử. Vui lòng thử lại sau';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng';
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không đúng';
      default:
        return 'Lỗi: $code';
    }
  }

  /// Chuyển backend errorCode sang tiếng Việt
  static String _mapBackendErrorCode(
    String? errorCode,
    dynamic fallbackMessage,
  ) {
    switch (errorCode) {
      case 'EMAIL_ALREADY_EXISTS':
        return 'Email này đã được đăng ký. Vui lòng dùng email khác.';
      case 'INVALID_EMAIL':
        return 'Địa chỉ email không hợp lệ.';
      case 'PASSWORD_TOO_SHORT':
      case 'WEAK_PASSWORD':
        return 'Mật khẩu phải có ít nhất 8 ký tự, gồm chữ thường và chữ hoa.';
      case 'PASSWORD_NO_UPPERCASE':
        return 'Mật khẩu phải có ít nhất 1 chữ hoa (A-Z).';
      case 'PASSWORD_NO_LOWERCASE':
        return 'Mật khẩu phải có ít nhất 1 chữ thường (a-z).';
      default:
        return fallbackMessage?.toString() ??
            'Đăng ký thất bại. Vui lòng thử lại.';
    }
  }
}
