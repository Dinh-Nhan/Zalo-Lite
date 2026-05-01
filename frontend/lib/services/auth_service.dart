import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// Hàm xóa sạch dấu vết user (Dữ liệu Backend + Firebase Auth)
  /// Thường dùng cho chức năng "Xóa tài khoản" hoặc "Rollback" khi đăng ký lỗi
  static Future<void> deleteAccountAndData() async {
      // 1. Kiểm tra Authentication: Nếu không có user đang đăng nhập thì không làm gì cả
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final email = user.email;
    final uid = user.uid;

    try {
      // 2. Kiểm tra Dữ liệu (Firestore/Backend):
      // Tìm document ID dựa trên email vì ID document đang bị lệch với UID
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print("Thông báo: Không tìm thấy dữ liệu user trên Database.");
        // Nếu không có dữ liệu DB, ta nhảy thẳng xuống bước xóa Auth
      } else {
        // Nếu có dữ liệu, thực hiện xóa qua Backend
        final documentId = querySnapshot.docs.first.id;
        
        try {
          await DioClient.instance.delete('/api/user/$documentId');
          print("Thành công: Đã xóa dữ liệu Backend (ID: $documentId)");
        } catch (e) {
          print("Lỗi: Không thể gọi API xóa Backend nhưng vẫn sẽ tiếp tục xóa Auth: $e");
        }
      }
    } catch (e) {
      print("Lỗi khi truy vấn Database: $e");
      // Dù lỗi truy vấn DB vẫn nên cố gắng xóa Auth phía dưới
    }

    // 3. Xóa Authentication: Giải phóng Email để có thể đăng ký lại
    try {
      await user.delete();
      print("Thành công: Đã xóa tài khoản khỏi Firebase Auth.");
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        print("Lỗi: User cần đăng nhập lại trước khi xóa do bảo mật.");
        // Ở đây bạn có thể yêu cầu user login lại nếu cần thiết
      } else {
        print("Lỗi khi xóa Auth: ${e.message}");
      }
    } catch (e) {
      print("Lỗi không xác định khi xóa Auth: $e");
    }
  }

  static Future<void> sendOtp(String email) async {
    try {
      final response = await DioClient.instance.post(
        '/api/otp/generate',
        queryParameters: {'email': email.trim()},
      );

      if (response.statusCode == 200) {
        print("Thành công: Mã OTP đã được gửi đến $email");
      }
    } on DioException catch (e) {
      // Xử lý các lỗi từ Server (400, 500...)
      String errorMsg = e.response?.data?['message'] ?? "Không thể gửi OTP";
      throw Exception(errorMsg);
    } catch (e) {
      throw Exception("Lỗi kết nối hệ thống: $e");
    }
  }

  /// 2. Hàm gọi API xác thực mã OTP
  /// Theo hình ảnh Swagger: POST /api/otp/verify?email=...&otp=...
  static Future<bool> verifyOtp(String email, String otp) async {
    try {
      final response = await DioClient.instance.post(
        '/api/otp/verify',
        queryParameters: {
          'email': email.trim(),
          'otp': otp.trim(),
        },
      );

      if (response.statusCode == 200) {
        print("Thành công: Xác thực OTP khớp.");
        return true;
      }
      return false;
    } on DioException catch (e) {
      String errorMsg = e.response?.data?['message'] ?? "Mã OTP không hợp lệ";
      throw Exception(errorMsg);
    } catch (e) {
      throw Exception("Lỗi xác thực: $e");
    }
  }

  // frontend/services/auth_service.dart

  static Future<void> updateUserInfo({
    required String fullName,
    String? password,
  }) async {
    try {
      // 1. Lấy user hiện tại từ hệ thống (Firebase hoặc Token lưu trữ)
      // Giả sử bạn dùng email làm định danh chính
      final String? email = FirebaseAuth.instance.currentUser?.email;

      if (email == null) throw Exception("Không tìm thấy thông tin đăng nhập");

      // 2. Gọi API Backend để cập nhật Database
      final response = await DioClient.instance.put(
        '/api/users/update', // Thay đổi path đúng theo Swagger của bạn
        data: {
          'email': email,
          'last_name': password,
          if (password != null) 'password': password,
        },
      );

      if (response.statusCode == 200) {
        print("Cập nhật thông tin user thành công trên DB");
        
        // 3. Nếu cần cập nhật cả Display Name trên Firebase cho đồng bộ
        await FirebaseAuth.instance.currentUser?.updateDisplayName(fullName);
      }
    } on DioException catch (e) {
      String errorMsg = e.response?.data?['message'] ?? "Lỗi cập nhật thông tin";
      throw Exception(errorMsg);
    } catch (e) {
      throw Exception("Lỗi hệ thống: $e");
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
