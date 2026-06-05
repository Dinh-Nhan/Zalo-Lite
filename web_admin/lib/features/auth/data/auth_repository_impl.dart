import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/auth_repository.dart';

// ============================================================
// AUTH FEATURE - Data (Repository Implementation)
// ============================================================

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth;

  AuthRepositoryImpl(this._auth);

  @override
  Future<void> signIn(String email, String password) async {
    // Guard: Check env vars were injected at build time
    if (AppConstants.adminEmail.isEmpty || AppConstants.adminPassword.isEmpty) {
      throw const AuthException(
        'Admin credentials not configured.\n'
        'Ensure ADMIN_EMAIL and ADMIN_PASSWORD are set in your .env file.',
      );
    }

    // 1. Chỉ cho phép tài khoản Admin được định nghĩa trong .env
    if (email != AppConstants.adminEmail ||
        password != AppConstants.adminPassword) {
      throw const AuthException('Invalid admin credentials.');
    }

    // 2. Tiến hành đăng nhập Firebase ẩn dưới nền để lấy token giao tiếp hợp lệ với Firestore
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        'Đăng nhập Firebase thất bại: ${_mapFirebaseError(e.code)}\n'
        'Hãy chắc chắn bạn đã tạo User này trong Firebase Console -> Authentication.',
      );
    } catch (e) {
      throw AuthException('Đăng nhập thất bại: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {
      throw const AuthException('Sign out failed.');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    } catch (e) {
      throw AuthException('Reset password failed: $e');
    }
  }

  @override
  Stream<bool> get authStateStream =>
      _auth.authStateChanges().map((user) => user != null);

  @override
  bool get isLoggedIn => _auth.currentUser != null;

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Tài khoản admin không tồn tại trên Firebase.';
      case 'wrong-password':
        return 'Sai mật khẩu.';
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'user-disabled':
        return 'Tài khoản admin này đã bị vô hiệu hóa.';
      case 'too-many-requests':
        return 'Quá nhiều lần thử sai. Vui lòng thử lại sau.';
      default:
        return 'Lỗi xác thực: $code';
    }
  }
}

// ── Manual Provider (no code generation needed) ──────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(FirebaseAuth.instance);
});
